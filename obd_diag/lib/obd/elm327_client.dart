import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ObdException implements Exception {
  ObdException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Antworten, die kein Messergebnis sind. Muss VOR dem Hex-Parsing geprüft
/// werden, weil der Hex-Filter aus "SEARCHING..." sonst "EAC" macht.
const _errorResponses = <String>[
  'NO DATA',
  'UNABLE TO CONNECT',
  'CAN ERROR',
  'BUS INIT',
  'BUS ERROR',
  'DATA ERROR',
  'STOPPED',
  'ERROR',
  '?',
];

bool isErrorResponse(String raw) {
  final up = raw.toUpperCase();
  return _errorResponses.any(up.contains);
}

/// Transport für einen ELM327-kompatiblen Adapter über BLE.
///
/// Wichtig für iOS: klassisches Bluetooth SPP/RFCOMM (die billigen
/// "ELM327 v1.5"-Dongles) ist auf iOS nicht ansprechbar. Es braucht einen
/// BLE-Adapter (oder ein MFi-Gerät wie OBDLink mit eigenem SDK).
class Elm327Client {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  StreamSubscription<List<int>>? _notifySub;

  final StringBuffer _rx = StringBuffer();
  Completer<String>? _pending;
  Future<void> _chain = Future<void>.value();

  /// Mitschnitt für den Debug-Tab – hilft enorm bei fremden Adaptern.
  final List<String> trace = <String>[];

  bool get isConnected => _writeChar != null && _notifyChar != null;
  String? get deviceName => _device?.platformName;

  Future<void> connect(BluetoothDevice device) async {
    await disconnect();
    _device = device;

    await device.connect(timeout: const Duration(seconds: 15));

    // Ein ELM327-BLE-Adapter bietet einen UART-artigen Service. Die UUIDs
    // unterscheiden sich je Hersteller (FFF0/FFE0/Nordic UART), deshalb wird
    // nicht nach UUID gesucht, sondern nach einem Service, der sowohl eine
    // beschreibbare als auch eine benachrichtigende Characteristic enthält.
    final services = await device.discoverServices();
    for (final service in services) {
      BluetoothCharacteristic? write;
      BluetoothCharacteristic? notify;
      for (final c in service.characteristics) {
        final p = c.properties;
        write ??= (p.write || p.writeWithoutResponse) ? c : null;
        notify ??= (p.notify || p.indicate) ? c : null;
      }
      if (write != null && notify != null) {
        _writeChar = write;
        _notifyChar = notify;
        break;
      }
    }

    if (!isConnected) {
      await disconnect();
      throw ObdException(
        'Kein UART-Service gefunden. Das Gerät ist wahrscheinlich kein '
        'BLE-ELM327-Adapter.',
      );
    }

    await _notifyChar!.setNotifyValue(true);
    _notifySub = _notifyChar!.onValueReceived.listen(_onData);
  }

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    _notifySub = null;
    _writeChar = null;
    _notifyChar = null;
    _rx.clear();
    _pending = null;
    final d = _device;
    _device = null;
    if (d != null) {
      try {
        await d.disconnect();
      } catch (_) {
        // Gerät war schon weg – nicht weiter wichtig.
      }
    }
  }

  void _onData(List<int> data) {
    _rx.write(ascii.decode(data, allowInvalid: true));
    final text = _rx.toString();
    // Der ELM327 beendet jede Antwort mit dem Prompt '>'.
    if (!text.contains('>')) return;
    _rx.clear();
    final response = text.replaceAll('>', '').replaceAll('\r', '\n').trim();
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(response);
  }

  /// Sendet ein Kommando. Die Aufrufe werden serialisiert – der ELM327
  /// verarbeitet immer nur eine Anfrage und würde sonst Antworten vermischen.
  Future<String> send(
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    final result = Completer<String>();
    _chain = _chain.then((_) async {
      try {
        result.complete(await _sendNow(command, timeout));
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<String> _sendNow(String command, Duration timeout) async {
    final write = _writeChar;
    if (write == null) throw ObdException('Nicht verbunden.');

    _rx.clear();
    final pending = Completer<String>();
    _pending = pending;

    await write.write(
      ascii.encode('$command\r'),
      withoutResponse: write.properties.writeWithoutResponse,
    );

    try {
      final response = await pending.future.timeout(timeout);
      trace.add('>> $command\n<< $response');
      if (trace.length > 200) trace.removeAt(0);
      return response;
    } on TimeoutException {
      _pending = null;
      trace.add('>> $command\n<< [timeout]');
      throw ObdException('Timeout bei "$command".');
    }
  }

  /// Bringt den Adapter in einen definierten Zustand und prüft, ob überhaupt
  /// ein Fahrzeugbus antwortet.
  Future<String> initialize() async {
    await send('ATZ', timeout: const Duration(seconds: 8)); // Reset
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await send('ATE0'); // Echo aus
    await send('ATL0'); // keine Linefeeds
    await send('ATS0'); // keine Leerzeichen
    await send('ATH0'); // keine CAN-Header
    await send('ATSP0'); // Protokoll automatisch wählen

    final probe = await send('0100', timeout: const Duration(seconds: 12));
    if (isErrorResponse(probe) || !probe.toUpperCase().contains('41')) {
      throw ObdException(
        'Adapter antwortet, aber kein Fahrzeug erreichbar ($probe). '
        'Zündung an?',
      );
    }

    final version = await send('ATI');
    return version.trim();
  }
}

/// Reduziert eine Rohantwort auf reine Hex-Nutzdaten.
///
/// Zeilenweise, weil der Adapter Statuszeilen wie "SEARCHING..." einstreut.
/// Würde man nur Nicht-Hex-Zeichen global entfernen, blieben daraus die
/// Buchstaben E, A und C übrig – das verschiebt die Byte-Ausrichtung und
/// macht jede folgende Auswertung falsch.
List<String> hexLines(String raw) {
  final lines = <String>[];
  for (final line in raw.split(RegExp('[\r\n]+'))) {
    final trimmed = line.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (trimmed.isEmpty) continue;
    // Reine Textzeilen und Mehrrahmen-Präfixe ("0:", "1:") verwerfen.
    if (!RegExp('^[0-9A-F]+\$').hasMatch(trimmed)) continue;
    lines.add(trimmed);
  }
  return lines;
}

String hexOnly(String raw) => hexLines(raw).join();
