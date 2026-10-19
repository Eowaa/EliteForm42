import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../obd/dtc.dart';
import '../obd/elm327_client.dart';
import '../obd/obd_pid.dart';

enum ObdStatus { idle, scanning, connecting, initializing, ready, error }

class ObdProvider extends ChangeNotifier {
  final Elm327Client client = Elm327Client();

  ObdStatus status = ObdStatus.idle;
  String? errorMessage;
  String? adapterVersion;

  List<ScanResult> scanResults = <ScanResult>[];
  StreamSubscription<List<ScanResult>>? _scanSub;

  /// Aktuelle Messwerte je PID-Request ('010C' -> 2480.0).
  final Map<String, double?> values = <String, double?>{};

  /// Kurzer Verlauf für die Sparklines.
  final Map<String, List<double>> history = <String, List<double>>{};
  static const _historyLength = 60;

  List<Dtc> storedDtcs = <Dtc>[];
  List<Dtc> pendingDtcs = <Dtc>[];
  MilStatus? milStatus;
  bool dtcBusy = false;

  bool _polling = false;

  /// PIDs, die das Fahrzeug laut Mode 01 PID 00/20 tatsächlich unterstützt.
  /// Vor der Prüfung werden alle angezeigt.
  Set<String> availablePids = supportedPids.map((p) => p.request).toSet();

  List<ObdPid> get activePids =>
      supportedPids.where((p) => availablePids.contains(p.request)).toList();

  // ---------------------------------------------------------------- Scannen

  Future<void> startScan() async {
    errorMessage = null;

    // Android 12+ verlangt BLUETOOTH_SCAN/CONNECT zur Laufzeit, iOS nur den
    // Info.plist-Eintrag.
    if (defaultTargetPlatform == TargetPlatform.android) {
      final granted = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      if (granted.values.any((s) => !s.isGranted)) {
        _fail('Bluetooth-Berechtigung verweigert.');
        return;
      }
    }

    scanResults = <ScanResult>[];
    status = ObdStatus.scanning;
    notifyListeners();

    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      // Namenlose Geräte sind für den Nutzer nicht unterscheidbar.
      scanResults = results
          .where((r) => r.device.platformName.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi));
      notifyListeners();
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await FlutterBluePlus.isScanning.where((on) => !on).first;
      if (status == ObdStatus.scanning) {
        status = ObdStatus.idle;
        notifyListeners();
      }
    } catch (e) {
      _fail('Scan fehlgeschlagen: $e');
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    if (status == ObdStatus.scanning) {
      status = ObdStatus.idle;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------- Verbinden

  Future<void> connect(BluetoothDevice device) async {
    await stopScan();
    status = ObdStatus.connecting;
    errorMessage = null;
    notifyListeners();

    try {
      await client.connect(device);
      status = ObdStatus.initializing;
      notifyListeners();

      adapterVersion = await client.initialize();
      await _probeSupportedPids();

      status = ObdStatus.ready;
      notifyListeners();
      _startPolling();
    } on ObdException catch (e) {
      await client.disconnect();
      _fail(e.message);
    } catch (e) {
      await client.disconnect();
      _fail('Verbindung fehlgeschlagen: $e');
    }
  }

  Future<void> disconnect() async {
    _polling = false;
    await client.disconnect();
    values.clear();
    history.clear();
    storedDtcs = <Dtc>[];
    pendingDtcs = <Dtc>[];
    milStatus = null;
    adapterVersion = null;
    status = ObdStatus.idle;
    notifyListeners();
  }

  /// Mode 01 PID 00 und 20 liefern Bitmasken der unterstützten PIDs. Das
  /// erspart es, auf jeden Zyklus "NO DATA" für nicht vorhandene Sensoren zu
  /// bekommen.
  Future<void> _probeSupportedPids() async {
    final supported = <String>{};
    for (final base in ['0100', '0120']) {
      final raw = await client.send(base);
      final bytes = extractPayload(raw, base);
      if (bytes == null || bytes.length < 4) continue;

      final offset = int.parse(base.substring(2), radix: 16);
      for (var byteIndex = 0; byteIndex < 4; byteIndex++) {
        for (var bit = 0; bit < 8; bit++) {
          final isSet = (bytes[byteIndex] & (0x80 >> bit)) != 0;
          if (!isSet) continue;
          final pidNumber = offset + byteIndex * 8 + bit + 1;
          supported.add(
            '01${pidNumber.toRadixString(16).toUpperCase().padLeft(2, '0')}',
          );
        }
      }
    }

    if (supported.isEmpty) return; // Prüfung fehlgeschlagen -> alles anzeigen
    availablePids = supportedPids
        .map((p) => p.request)
        .where(supported.contains)
        .toSet();
  }

  // ------------------------------------------------------------- Live-Daten

  void _startPolling() {
    if (_polling) return;
    _polling = true;
    unawaited(_pollLoop());
  }

  /// Der ELM327 schafft nur ca. 10–20 Anfragen pro Sekunde, deshalb werden die
  /// PIDs sequenziell und ohne festen Timer abgefragt.
  Future<void> _pollLoop() async {
    while (_polling && client.isConnected) {
      final pids = activePids;
      if (pids.isEmpty) break;

      for (final pid in pids) {
        if (!_polling || !client.isConnected) return;
        try {
          final raw = await client.send(pid.request);
          final bytes = extractPayload(raw, pid.request);
          final value = bytes == null ? null : pid.parse(bytes);
          values[pid.request] = value;
          if (value != null) {
            final series = history.putIfAbsent(pid.request, () => <double>[]);
            series.add(value);
            if (series.length > _historyLength) series.removeAt(0);
          }
        } on ObdException {
          values[pid.request] = null;
        }
        notifyListeners();
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  // ---------------------------------------------------------- Fehlerspeicher

  Future<void> readDtcs() async {
    if (!client.isConnected || dtcBusy) return;
    dtcBusy = true;
    errorMessage = null;
    notifyListeners();

    final wasPolling = _polling;
    _polling = false; // Live-Abfragen pausieren, sonst kollidieren Antworten

    try {
      final statusRaw = await client.send('0101');
      milStatus = parseMilStatus(extractPayload(statusRaw, '0101') ?? const []);

      storedDtcs = parseDtcResponse(
        await client.send('03', timeout: const Duration(seconds: 10)),
      );
      pendingDtcs = parseDtcResponse(
        await client.send('07', timeout: const Duration(seconds: 10)),
        mode: 0x07,
      );
    } on ObdException catch (e) {
      errorMessage = e.message;
    } finally {
      dtcBusy = false;
      notifyListeners();
      if (wasPolling) _startPolling();
    }
  }

  /// Mode 04 löscht Fehlerspeicher UND Readiness-Monitore. Nach dem Löschen
  /// ist das Fahrzeug nicht mehr AU-/HU-fähig, bis die Monitore neu
  /// durchgelaufen sind – deshalb nur mit Rückfrage aufrufen.
  Future<bool> clearDtcs() async {
    if (!client.isConnected || dtcBusy) return false;
    dtcBusy = true;
    notifyListeners();

    final wasPolling = _polling;
    _polling = false;

    try {
      final raw = await client.send('04', timeout: const Duration(seconds: 10));
      final ok = raw.toUpperCase().contains('44');
      if (ok) {
        storedDtcs = <Dtc>[];
        pendingDtcs = <Dtc>[];
        milStatus = const MilStatus(lampOn: false, dtcCount: 0);
      } else {
        errorMessage = 'Löschen abgelehnt ($raw).';
      }
      return ok;
    } on ObdException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      dtcBusy = false;
      notifyListeners();
      if (wasPolling) _startPolling();
    }
  }

  void _fail(String message) {
    status = ObdStatus.error;
    errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _polling = false;
    _scanSub?.cancel();
    client.disconnect();
    super.dispose();
  }
}
