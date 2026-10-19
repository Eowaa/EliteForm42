import 'elm327_client.dart';

/// Ein Live-Messwert nach SAE J1979 (Mode 01).
class ObdPid {
  const ObdPid({
    required this.request,
    required this.label,
    required this.unit,
    required this.parse,
    this.decimals = 0,
  });

  /// Vollständige Anfrage, z. B. '010C'.
  final String request;
  final String label;
  final String unit;
  final int decimals;

  /// Erhält die Datenbytes NACH Mode + PID.
  final double? Function(List<int> bytes) parse;

  String get pid => request.substring(2);
}

/// Schneidet aus einer Rohantwort die Datenbytes heraus.
///
/// Bei `ATS0`/`ATH0` antwortet der Adapter auf '010C' mit '410C1AF8'. Mehrere
/// Steuergeräte können hintereinander antworten – es wird der erste Treffer
/// verwendet.
List<int>? extractPayload(String raw, String request) {
  if (isErrorResponse(raw)) return null;

  final clean = hexOnly(raw);
  final mode = int.parse(request.substring(0, 2), radix: 16);
  final marker =
      (mode + 0x40).toRadixString(16).toUpperCase().padLeft(2, '0') +
          request.substring(2);

  final index = clean.indexOf(marker);
  if (index < 0) return null;

  final hex = clean.substring(index + marker.length);
  final bytes = <int>[];
  for (var i = 0; i + 1 < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return bytes;
}

double? _byteAt(List<int> b, int i) => i < b.length ? b[i].toDouble() : null;

/// Standard-PIDs, die praktisch jedes OBD2-Fahrzeug ab Bj. 2001 (Benzin)
/// bzw. 2004 (Diesel) unterstützt.
const supportedPids = <ObdPid>[
  ObdPid(
    request: '010C',
    label: 'Drehzahl',
    unit: '1/min',
    parse: _parseRpm,
  ),
  ObdPid(
    request: '010D',
    label: 'Geschwindigkeit',
    unit: 'km/h',
    parse: _parseSpeed,
  ),
  ObdPid(
    request: '0105',
    label: 'Kühlmittel',
    unit: '°C',
    parse: _parseTempA,
  ),
  ObdPid(
    request: '010F',
    label: 'Ansaugluft',
    unit: '°C',
    parse: _parseTempA,
  ),
  ObdPid(
    request: '0104',
    label: 'Motorlast',
    unit: '%',
    parse: _parsePercentA,
    decimals: 1,
  ),
  ObdPid(
    request: '0111',
    label: 'Drosselklappe',
    unit: '%',
    parse: _parsePercentA,
    decimals: 1,
  ),
  ObdPid(
    request: '0110',
    label: 'Luftmasse',
    unit: 'g/s',
    parse: _parseMaf,
    decimals: 2,
  ),
  ObdPid(
    request: '012F',
    label: 'Tankfüllung',
    unit: '%',
    parse: _parsePercentA,
    decimals: 0,
  ),
  ObdPid(
    request: '0142',
    label: 'Bordspannung',
    unit: 'V',
    parse: _parseVoltage,
    decimals: 2,
  ),
  ObdPid(
    request: '0106',
    label: 'Gemischkorrektur',
    unit: '%',
    parse: _parseFuelTrim,
    decimals: 1,
  ),
];

double? _parseRpm(List<int> b) {
  if (b.length < 2) return null;
  return ((b[0] * 256) + b[1]) / 4;
}

double? _parseSpeed(List<int> b) => _byteAt(b, 0);

double? _parseTempA(List<int> b) {
  final a = _byteAt(b, 0);
  return a == null ? null : a - 40;
}

double? _parsePercentA(List<int> b) {
  final a = _byteAt(b, 0);
  return a == null ? null : a * 100 / 255;
}

double? _parseMaf(List<int> b) {
  if (b.length < 2) return null;
  return ((b[0] * 256) + b[1]) / 100;
}

double? _parseVoltage(List<int> b) {
  if (b.length < 2) return null;
  return ((b[0] * 256) + b[1]) / 1000;
}

double? _parseFuelTrim(List<int> b) {
  final a = _byteAt(b, 0);
  return a == null ? null : (a - 128) * 100 / 128;
}
