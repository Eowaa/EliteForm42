import 'dtc_database.dart';
import 'elm327_client.dart';

class Dtc {
  const Dtc(this.code);
  final String code;

  String get description => dtcDescriptions[code] ?? _genericDescription();

  /// Wenn der Code nicht in der Tabelle steht, lässt sich aus der Struktur
  /// immerhin das betroffene System ableiten (ISO 15031-6).
  String _genericDescription() {
    final system = switch (code[0]) {
      'P' => 'Antrieb (Motor/Getriebe)',
      'C' => 'Fahrwerk (Chassis)',
      'B' => 'Karosserie (Body)',
      'U' => 'Netzwerk / Kommunikation',
      _ => 'Unbekanntes System',
    };
    final scope = code[1] == '0' || code[1] == '2'
        ? 'genormter Code'
        : 'herstellerspezifischer Code';
    return '$system – $scope, keine Beschreibung hinterlegt.';
  }
}

/// Dekodiert zwei Bytes in einen DTC wie 'P0133' (ISO 15031-6).
String decodeDtcBytes(int a, int b) {
  const systems = ['P', 'C', 'B', 'U'];
  final system = systems[(a >> 6) & 0x03];
  final d1 = (a >> 4) & 0x03;
  final d2 = a & 0x0F;
  final d3 = (b >> 4) & 0x0F;
  final d4 = b & 0x0F;
  return '$system$d1'
      '${d2.toRadixString(16).toUpperCase()}'
      '${d3.toRadixString(16).toUpperCase()}'
      '${d4.toRadixString(16).toUpperCase()}';
}

/// Parst die Antwort auf Mode 03 (gespeicherte Fehler) bzw. Mode 07
/// (sporadische Fehler).
///
/// Das Antwortformat ist nicht einheitlich: über CAN (ISO 15765) steht hinter
/// dem Mode-Byte 0x43 ein Zähler-Byte, über KWP/ISO 9141 nicht. Deshalb wird
/// geprüft, ob das erste Byte genau zur Anzahl der folgenden DTC-Paare passt –
/// nur dann wird es als Zähler behandelt.
List<Dtc> parseDtcResponse(String raw, {int mode = 0x03}) {
  if (isErrorResponse(raw)) return const [];

  final marker = (mode + 0x40).toRadixString(16).toUpperCase().padLeft(2, '0');
  final codes = <Dtc>[];
  final seen = <String>{};

  // Zeilenweise auswerten: über ISO 9141/KWP wiederholt der Adapter das
  // Mode-Byte in JEDER Zeile. Würde man die Zeilen vorher aneinanderhängen,
  // landete das zweite "43" als DTC-Datenbyte in der Auswertung.
  for (final line in hexLines(raw)) {
    if (!line.startsWith(marker)) continue;

    final payload = line.substring(marker.length);
    final bytes = <int>[];
    for (var i = 0; i + 1 < payload.length; i += 2) {
      bytes.add(int.parse(payload.substring(i, i + 2), radix: 16));
    }
    if (bytes.isEmpty) continue;

    // Über CAN (ISO 15765) steht hinter dem Mode-Byte ein Zähler-Byte, über
    // KWP/ISO 9141 nicht. Als Zähler wird es nur gelesen, wenn die restlichen
    // Bytes eine gerade Anzahl bilden UND der Wert exakt zur Anzahl der
    // DTC-Paare passt. Sonst wäre z. B. "43 01 33 01 34" fehlinterpretiert.
    final rest = bytes.length - 1;
    final start = (rest.isEven && rest > 0 && bytes[0] == rest ~/ 2) ? 1 : 0;

    for (var i = start; i + 1 < bytes.length; i += 2) {
      final a = bytes[i];
      final b = bytes[i + 1];
      if (a == 0 && b == 0) continue; // Füllbytes
      final code = decodeDtcBytes(a, b);
      if (seen.add(code)) codes.add(Dtc(code));
    }
  }

  return codes;
}

/// Mode 01 PID 01: Status der Fehlerspeicher-Lampe und Anzahl der Codes.
class MilStatus {
  const MilStatus({required this.lampOn, required this.dtcCount});
  final bool lampOn;
  final int dtcCount;
}

MilStatus? parseMilStatus(List<int> bytes) {
  if (bytes.isEmpty) return null;
  final a = bytes[0];
  return MilStatus(lampOn: (a & 0x80) != 0, dtcCount: a & 0x7F);
}
