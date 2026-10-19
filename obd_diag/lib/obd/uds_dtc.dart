/// Fehlercodes nach ISO 14229-1 (UDS) – drei Bytes statt der fünf Zeichen
/// von OBD2.
///
/// Die ersten zwei Bytes sind der Code selbst (gleiche P/C/B/U-Systematik wie
/// bei OBD2), das dritte ist der Failure Type Byte (FTB). Der FTB ist
/// **genormt**: auch bei einem herstellerspezifischen Code, dessen Bedeutung
/// nirgends frei dokumentiert ist, lässt sich damit die Fehlerart benennen.
/// Aus 'B2846-13' wird so "Unterbrechung im Stromkreis", ohne zu wissen,
/// welches Bauteil B2846 ist.
library;

class UdsDtc {
  const UdsDtc({
    required this.code,
    required this.failureType,
    this.status,
  });

  /// Der Code ohne FTB, z. B. 'B2846'.
  final String code;

  /// Der Failure Type Byte, z. B. 0x13.
  final int failureType;

  final DtcStatus? status;

  /// Vollständige Schreibweise wie in Werkstattberichten: 'B2846-13'.
  String get fullCode =>
      '$code-${failureType.toRadixString(16).toUpperCase().padLeft(2, '0')}';

  String get failureDescription => describeFailureType(failureType);

  @override
  String toString() => '$fullCode ($failureDescription)';
}

/// Zerlegt drei Rohbytes in Code und Fehlerart.
UdsDtc? parseUdsDtc(int high, int low, int ftb, {int? statusByte}) {
  if (high == 0 && low == 0 && ftb == 0) return null;

  const systems = ['P', 'C', 'B', 'U'];
  final system = systems[(high >> 6) & 0x03];
  final d1 = (high >> 4) & 0x03;
  final d2 = high & 0x0F;
  final d3 = (low >> 4) & 0x0F;
  final d4 = low & 0x0F;

  final code = '$system$d1'
      '${d2.toRadixString(16).toUpperCase()}'
      '${d3.toRadixString(16).toUpperCase()}'
      '${d4.toRadixString(16).toUpperCase()}';

  return UdsDtc(
    code: code,
    failureType: ftb,
    status: statusByte == null ? null : DtcStatus(statusByte),
  );
}

/// Liest eine Schreibweise wie 'B2846-13' oder 'B284613' ein.
UdsDtc? parseUdsDtcString(String input) {
  final cleaned = input.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  // Systembuchstabe + 4 Hex-Stellen Code + 2 Hex-Stellen FTB.
  final match = RegExp(r'^([PCBU])([0-9A-F]{4})([0-9A-F]{2})$').firstMatch(cleaned);
  if (match == null) return null;

  return UdsDtc(
    code: '${match.group(1)}${match.group(2)}',
    failureType: int.parse(match.group(3)!, radix: 16),
  );
}

/// Der Status eines UDS-Fehlers (statusOfDTC, ISO 14229-1 Anhang D.2).
///
/// Werkstattberichte zeigen davon meist nur "aktuell" und "gespeichert" –
/// die Bits tragen deutlich mehr Information.
class DtcStatus {
  const DtcStatus(this.raw);
  final int raw;

  /// Der Fehler liegt beim letzten Test an.
  bool get testFailed => (raw & 0x01) != 0;

  /// Der Fehler trat in diesem Fahrzyklus auf.
  bool get failedThisCycle => (raw & 0x02) != 0;

  /// Sporadisch erkannt, noch nicht bestätigt.
  bool get pending => (raw & 0x04) != 0;

  /// Bestätigt und im Speicher abgelegt.
  bool get confirmed => (raw & 0x08) != 0;

  /// Seit dem letzten Löschen wurde der Test nicht abgeschlossen.
  bool get notCompletedSinceClear => (raw & 0x10) != 0;

  /// Seit dem letzten Löschen ist der Test schon einmal fehlgeschlagen.
  bool get failedSinceClear => (raw & 0x20) != 0;

  bool get notCompletedThisCycle => (raw & 0x40) != 0;

  /// Das Steuergerät fordert eine Warnleuchte an.
  bool get warningIndicatorRequested => (raw & 0x80) != 0;

  /// Kurzfassung, wie sie in einen Bericht gehört.
  String get summary {
    if (testFailed && confirmed) return 'aktuell und gespeichert';
    if (testFailed) return 'aktuell';
    if (confirmed) return 'gespeichert';
    if (pending) return 'sporadisch';
    return 'inaktiv';
  }
}

/// Die gebräuchlichen Failure Type Bytes aus ISO 14229-1.
///
/// Bewusst **nicht vollständig**: die Norm definiert deutlich mehr Werte, und
/// erfundene Einträge wären schlimmer als eine Lücke. Was fehlt, fängt
/// [describeFailureType] über die Gruppe des oberen Nibbles ab.
const udsFailureTypes = <int, String>{
  0x00: 'keine nähere Angabe',

  // 0x1x – Stromkreis
  0x11: 'Kurzschluss nach Masse',
  0x12: 'Kurzschluss nach Plus',
  0x13: 'Unterbrechung im Stromkreis',
  0x14: 'Unterbrechung oder Kurzschluss nach Masse',
  0x15: 'Unterbrechung oder Kurzschluss nach Plus',
  0x16: 'Spannung unter Grenzwert',
  0x17: 'Spannung über Grenzwert',
  0x18: 'Strom unter Grenzwert',
  0x19: 'Strom über Grenzwert',
  0x1A: 'Widerstand unter Grenzwert',
  0x1B: 'Widerstand über Grenzwert',
  0x1C: 'Spannung außerhalb des Bereichs',
  0x1D: 'Strom außerhalb des Bereichs',
  0x1E: 'Widerstand außerhalb des Bereichs',
  0x1F: 'Stromkreis zeitweise unterbrochen',

  // 0x2x/0x3x – Signal
  0x21: 'Signalamplitude zu klein',
  0x22: 'Signalamplitude zu groß',
  0x23: 'Signal bleibt auf niedrigem Pegel',
  0x24: 'Signal bleibt auf hohem Pegel',
  0x29: 'Signal ungültig',
  0x2A: 'Signal sprunghaft',
  0x2F: 'Signal zeitweise gestört',
  0x31: 'kein Signal',
  0x38: 'Signalfrequenz zu niedrig',
  0x39: 'Signalfrequenz zu hoch',

  // 0x4x – Steuergerät-intern
  0x41: 'Prüfsummenfehler',
  0x42: 'Speicherfehler',
  0x44: 'Datenspeicherfehler',
  0x45: 'Programmspeicherfehler',
  0x46: 'Kalibrierungsspeicherfehler',
  0x49: 'interner elektronischer Fehler',
  0x4A: 'falsches Bauteil verbaut',
  0x4B: 'Übertemperatur',

  // 0x5x – Konfiguration
  0x51: 'nicht programmiert',
  0x52: 'nicht konfiguriert',
  0x53: 'deaktiviert',
  0x54: 'Kalibrierung fehlt',

  // 0x7x – Mechanik
  0x71: 'Stellglied klemmt',
  0x72: 'Stellglied klemmt offen',
  0x73: 'Stellglied klemmt geschlossen',
  0x77: 'Sollposition nicht erreichbar',
  0x78: 'Einstellung oder Justage fehlerhaft',

  // 0x8x – Bus
  0x81: 'ungültige Busdaten empfangen',
  0x82: 'Zählerstand der Nachricht falsch',
  0x86: 'Bussignal ungültig',
  0x87: 'Nachricht fehlt',
  0x88: 'Bus abgeschaltet (Bus off)',

  // 0x9x – Betriebsbedingungen
  0x92: 'Funktion fehlerhaft',
  0x93: 'keine Funktion',
  0x94: 'unerwartete Funktion',
  0x97: 'Bauteil zu heiß',
  0x98: 'Bauteil zu kalt',
};

/// Gruppen des oberen Nibbles – der Rettungsanker für FTBs, die nicht in der
/// Tabelle stehen. "Fehler im Stromkreis, Art unbekannt" ist brauchbar,
/// "unbekannt" ist es nicht.
const _failureGroups = <int, String>{
  0x1: 'Fehler im Stromkreis',
  0x2: 'Signalfehler',
  0x3: 'Signalfehler (Frequenz/Zeit)',
  0x4: 'interner Steuergerätefehler',
  0x5: 'Konfigurations- oder Programmierfehler',
  0x6: 'Berechnungs- oder Plausibilitätsfehler',
  0x7: 'mechanischer Fehler',
  0x8: 'Kommunikationsfehler',
  0x9: 'Fehler der Betriebsbedingungen',
};

String describeFailureType(int ftb) {
  final known = udsFailureTypes[ftb];
  if (known != null) return known;

  final group = _failureGroups[(ftb >> 4) & 0x0F];
  final hex = ftb.toRadixString(16).toUpperCase().padLeft(2, '0');
  if (group != null) return '$group (Typ 0x$hex, nicht näher bestimmt)';
  return 'Fehlerart 0x$hex unbekannt';
}
