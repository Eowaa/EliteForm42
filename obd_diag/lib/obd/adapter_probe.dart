import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Wie weit ein Adapter gekommen ist.
enum ProbeVerdict {
  /// Verbindung schon auf BLE-Ebene gescheitert.
  connectFailed,

  /// Verbunden, aber kein Dienst mit Schreib- und Benachrichtigungskanal.
  /// Typisch für Geräte, die kein UART-Profil nach außen geben.
  noUartProfile,

  /// Kanal da, aber auf keinen Befehl kam ein Byte zurück. Das Gerät
  /// erwartet vermutlich ein eigenes Protokoll oder eine Freischaltung.
  silent,

  /// Es kamen Daten zurück, aber keine erkennbare ELM327-Kennung.
  respondsUnknown,

  /// Der Adapter hat sich als ELM327-kompatibel zu erkennen gegeben.
  elmCompatible,
}

class ProbeCharacteristic {
  const ProbeCharacteristic({required this.uuid, required this.properties});
  final String uuid;
  final List<String> properties;
}

class ProbeService {
  const ProbeService({required this.uuid, required this.characteristics});
  final String uuid;
  final List<ProbeCharacteristic> characteristics;
}

class ProbeStep {
  const ProbeStep({required this.command, required this.response});
  final String command;

  /// Leer, wenn nichts zurückkam.
  final String response;

  bool get answered => response.isNotEmpty;
}

/// Das Ergebnis eines Adaptertests – gedacht zum Anschauen und Weitergeben.
class ProbeResult {
  ProbeResult({
    required this.deviceName,
    required this.deviceId,
    required this.verdict,
    this.services = const [],
    this.steps = const [],
    this.writeCharacteristic,
    this.notifyCharacteristic,
    this.identification,
    this.error,
  });

  final String deviceName;
  final String deviceId;
  final ProbeVerdict verdict;
  final List<ProbeService> services;
  final List<ProbeStep> steps;
  final String? writeCharacteristic;
  final String? notifyCharacteristic;

  /// Die Antwort auf ATI bzw. STI, also die Selbstauskunft des Adapters.
  final String? identification;
  final String? error;

  String get summary => switch (verdict) {
        ProbeVerdict.elmCompatible =>
          'ELM327-kompatibel – dieser Adapter ist nutzbar.',
        ProbeVerdict.respondsUnknown =>
          'Antwortet, aber ohne ELM327-Kennung. Eigenes Protokoll möglich.',
        ProbeVerdict.silent =>
          'Verbunden, aber keine Antwort auf Standardbefehle.',
        ProbeVerdict.noUartProfile =>
          'Verbunden, aber ohne nutzbaren Datenkanal.',
        ProbeVerdict.connectFailed => 'Verbindung nicht möglich.',
      };

  /// Textbericht zum Teilen – damit sich ein fremder Adapter beurteilen
  /// lässt, ohne ihn selbst in der Hand zu haben.
  String toReport() {
    final out = StringBuffer()
      ..writeln('Adaptertest')
      ..writeln('Gerät: $deviceName ($deviceId)')
      ..writeln('Ergebnis: $summary');
    if (identification != null) out.writeln('Kennung: $identification');
    if (error != null) out.writeln('Fehler: $error');

    out.writeln('\nGATT-Profil:');
    for (final service in services) {
      out.writeln('  Service ${service.uuid}');
      for (final c in service.characteristics) {
        final mark = [
          if (c.uuid == writeCharacteristic) 'SCHREIBEN',
          if (c.uuid == notifyCharacteristic) 'EMPFANGEN',
        ].join('+');
        out.writeln(
          '    ${c.uuid}  [${c.properties.join(', ')}]'
          '${mark.isEmpty ? '' : '  <- $mark'}',
        );
      }
    }

    if (steps.isNotEmpty) {
      out.writeln('\nBefehle:');
      for (final step in steps) {
        out.writeln('  >> ${step.command}');
        out.writeln('  << ${step.answered ? step.response : '(keine Antwort)'}');
      }
    }
    return out.toString();
  }
}

/// Testet, ob sich ein BLE-Gerät als OBD2-Adapter ansprechen lässt.
///
/// Verwendet ausschließlich den öffentlichen GATT-Aufbau des Geräts und den
/// dokumentierten ELM327-Befehlssatz. Antwortet ein Adapter darauf nicht,
/// ist das die Antwort – dann gehört er nicht zu dieser App.
class AdapterProbe {
  static const _commands = ['ATZ', 'ATI', 'STI', 'ATE0', 'ATRV'];
  static const _timeout = Duration(seconds: 3);

  Future<ProbeResult> run(BluetoothDevice device) async {
    final name = device.platformName.isEmpty
        ? '(ohne Namen)'
        : device.platformName;
    final id = device.remoteId.str;

    try {
      await device.connect(timeout: const Duration(seconds: 15));
    } catch (e) {
      return ProbeResult(
        deviceName: name,
        deviceId: id,
        verdict: ProbeVerdict.connectFailed,
        error: '$e',
      );
    }

    try {
      final discovered = await device.discoverServices();

      final services = <ProbeService>[];
      BluetoothCharacteristic? write;
      BluetoothCharacteristic? notify;

      for (final service in discovered) {
        final characteristics = <ProbeCharacteristic>[];
        BluetoothCharacteristic? localWrite;
        BluetoothCharacteristic? localNotify;

        for (final c in service.characteristics) {
          final p = c.properties;
          characteristics.add(
            ProbeCharacteristic(
              uuid: c.uuid.str,
              properties: [
                if (p.read) 'read',
                if (p.write) 'write',
                if (p.writeWithoutResponse) 'writeNoResp',
                if (p.notify) 'notify',
                if (p.indicate) 'indicate',
              ],
            ),
          );
          if (localWrite == null && (p.write || p.writeWithoutResponse)) {
            localWrite = c;
          }
          if (localNotify == null && (p.notify || p.indicate)) localNotify = c;
        }

        services.add(
          ProbeService(uuid: service.uuid.str, characteristics: characteristics),
        );

        // Beide Kanäle müssen im selben Dienst liegen.
        if (write == null && localWrite != null && localNotify != null) {
          write = localWrite;
          notify = localNotify;
        }
      }

      if (write == null || notify == null) {
        return ProbeResult(
          deviceName: name,
          deviceId: id,
          verdict: ProbeVerdict.noUartProfile,
          services: services,
        );
      }

      final steps = await _runCommands(write, notify);
      final answered = steps.where((s) => s.answered).toList();

      final identification = answered
          .where((s) => s.command == 'ATI' || s.command == 'STI')
          .map((s) => s.response)
          .firstWhere((r) => r.isNotEmpty, orElse: () => '');

      // ELM327-Klone melden sich mit "ELM327 v1.5", STN-Chips mit "STN2120".
      final joined = answered.map((s) => s.response).join(' ').toUpperCase();
      final recognised = joined.contains('ELM32') ||
          joined.contains('STN') ||
          joined.contains('OBDLINK');

      return ProbeResult(
        deviceName: name,
        deviceId: id,
        verdict: answered.isEmpty
            ? ProbeVerdict.silent
            : recognised
                ? ProbeVerdict.elmCompatible
                : ProbeVerdict.respondsUnknown,
        services: services,
        steps: steps,
        writeCharacteristic: write.uuid.str,
        notifyCharacteristic: notify.uuid.str,
        identification: identification.isEmpty ? null : identification,
      );
    } catch (e) {
      return ProbeResult(
        deviceName: name,
        deviceId: id,
        verdict: ProbeVerdict.connectFailed,
        error: '$e',
      );
    } finally {
      try {
        await device.disconnect();
      } catch (_) {
        // Beim Aufräumen nicht stolpern.
      }
    }
  }

  Future<List<ProbeStep>> _runCommands(
    BluetoothCharacteristic write,
    BluetoothCharacteristic notify,
  ) async {
    final steps = <ProbeStep>[];
    final buffer = StringBuffer();
    Completer<String>? pending;

    await notify.setNotifyValue(true);
    final subscription = notify.onValueReceived.listen((data) {
      buffer.write(ascii.decode(data, allowInvalid: true));
      final text = buffer.toString();
      // Im Test wird auf den Prompt gewartet, aber nicht darauf bestanden –
      // ein fremdes Gerät muss ihn nicht senden.
      if (text.contains('>') && pending != null && !pending!.isCompleted) {
        pending!.complete(text);
      }
    });

    try {
      for (final command in _commands) {
        buffer.clear();
        pending = Completer<String>();
        try {
          await write.write(
            ascii.encode('$command\r'),
            withoutResponse: write.properties.writeWithoutResponse,
          );
          await pending!.future.timeout(_timeout);
        } on TimeoutException {
          // Kein Prompt – trotzdem auswerten, was im Puffer liegt.
        } catch (_) {
          // Schreibfehler: als unbeantwortet werten.
        }
        steps.add(
          ProbeStep(
            command: command,
            response: buffer.toString().replaceAll('>', '').trim(),
          ),
        );
      }
    } finally {
      await subscription.cancel();
    }
    return steps;
  }
}
