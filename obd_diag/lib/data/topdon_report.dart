import '../obd/uds_dtc.dart';

/// Ein eingelesener Gesamtsystem-Bericht aus einer Werkstatt-App.
///
/// Importiert werden die eigenen Messergebnisse des Nutzers – nicht die
/// Fahrzeugdatenbank des Herstellers der Lese-App.
class ScanReport {
  const ScanReport({
    required this.entries,
    required this.systems,
    this.reportNumber,
    this.vin,
    this.make,
    this.model,
    this.year,
    this.odometer,
    this.scannedAt,
    this.declaredSystemCount,
    this.declaredDtcCount,
  });

  final List<ReportedDtc> entries;
  final List<SystemStatus> systems;

  final String? reportNumber;
  final String? vin;
  final String? make;
  final String? model;
  final String? year;
  final String? odometer;
  final String? scannedAt;

  /// Die vom Bericht selbst genannten Zahlen. Sie gelten als maßgeblich –
  /// die Textextraktion aus einer PDF ist je nach Werkzeug unterschiedlich
  /// zuverlässig, die Eigenangabe nicht.
  final int? declaredSystemCount;
  final int? declaredDtcCount;

  String get displayName =>
      [year, make, model].whereType<String>().join(' ').trim();

  List<SystemStatus> get faultySystems =>
      systems.where((s) => s.dtcCount > 0).toList();

  /// Warnt, wenn die Extraktion weniger gefunden hat, als der Bericht nennt.
  /// Besser ein sichtbarer Hinweis als ein stillschweigend halber Import.
  String? get consistencyWarning {
    final problems = <String>[];
    if (declaredDtcCount != null && declaredDtcCount != entries.length) {
      problems.add(
        'Bericht nennt $declaredDtcCount Fehlercode(s), gelesen wurden '
        '${entries.length}',
      );
    }
    if (declaredSystemCount != null && declaredSystemCount != systems.length) {
      problems.add(
        'Bericht nennt $declaredSystemCount System(e), gelesen wurden '
        '${systems.length}',
      );
    }
    return problems.isEmpty ? null : problems.join('; ');
  }
}

class SystemStatus {
  const SystemStatus({required this.name, required this.dtcCount});
  final String name;
  final int dtcCount;
  bool get hasFault => dtcCount > 0;
}

class ReportedDtc {
  const ReportedDtc({
    required this.rawCode,
    required this.description,
    required this.status,
    this.ecu,
    this.uds,
  });

  /// Wie im Bericht geschrieben, z. B. 'B284613'.
  final String rawCode;

  /// Der Klartext des Berichts.
  final String description;

  /// Der Status des Berichts, z. B. 'Aktuell und gespeichert'.
  final String status;

  /// Das Steuergerät, dem der Code zugeordnet ist.
  final String? ecu;

  /// Aufgeschlüsselt nach ISO 14229-1, sofern das Format passt.
  final UdsDtc? uds;
}

final _noise = RegExp(
  r'^(Berichtsnummer|SN:|Erstellungsdatum|TOPDON ID|Seite \d+|TopGuru)',
);
final _codePattern = RegExp(r'^[PCBU][0-9A-F]{4}[0-9A-F]{2}$');

/// Liest einen Bericht aus bereits extrahiertem PDF-Text.
///
/// Erwartet die Lesereihenfolge, nicht die Spaltenansicht: Werte stehen dann
/// als eigene Absätze untereinander. Zusammenhängende Zeilen werden zu einem
/// Absatz verbunden, weil PDF-Extraktion Umbrüche willkürlich setzt.
ScanReport parseScanReport(String text) {
  final blocks = _toBlocks(text);

  String? field(String pattern) {
    final match = RegExp(pattern).firstMatch(text);
    final value = match?.group(1)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  // Die Eigenangabe des Berichts als Gegenprobe zur Extraktion.
  final summary = RegExp(
    r'(\d+)\s*Systeme wurden gescannt.*?insgesamt\s*(\d+)\s*DTC',
    dotAll: true,
  ).firstMatch(text);

  final systems = <SystemStatus>[];
  final entries = <ReportedDtc>[];
  String? currentEcu;

  for (var i = 0; i < blocks.length; i++) {
    final block = blocks[i];

    // Tabellenzeile: Name / Status / Anzahl als drei Absätze.
    //
    // Unzuverlässig: manche PDF-Extraktionen lesen die Namensspalte und die
    // Statusspalte als getrennte Blöcke, dann steht vor dem Status nicht der
    // Name, sondern die Zahl der Vorzeile. Solche Treffer werden verworfen,
    // statt einen falschen Namen anzuzeigen – die Lücke macht
    // [ScanReport.consistencyWarning] sichtbar. Die Fehlercodes selbst
    // tragen ihr Steuergerät ohnehin aus dem Detailteil.
    if ((block == 'Kein Fehler' || block == 'Fehler') &&
        i > 0 &&
        i + 1 < blocks.length) {
      final count = int.tryParse(blocks[i + 1]);
      final name = blocks[i - 1];
      if (count != null && _isPlausibleSystemName(name)) {
        systems.add(SystemStatus(name: name, dtcCount: count));
      }
    }

    // Im Detailteil klebt der Steuergerätename an der Spaltenüberschrift
    // 'DTC', weil die Extraktion benachbarte Zeilen zusammenzieht.
    if (block == 'DTC' && i > 0) {
      currentEcu = blocks[i - 1];
    } else if (block.endsWith(' DTC')) {
      currentEcu = block.substring(0, block.length - 4).trim();
    }

    if (_codePattern.hasMatch(block)) {
      entries.add(
        ReportedDtc(
          rawCode: block,
          description: i + 1 < blocks.length ? blocks[i + 1] : '',
          status: i + 2 < blocks.length ? blocks[i + 2] : '',
          ecu: currentEcu,
          uds: parseUdsDtcString(block),
        ),
      );
    }
  }

  return ScanReport(
    entries: entries,
    systems: systems,
    reportNumber: field(r'Berichtsnummer\s*:\s*(\S+)'),
    vin: field(r'VIN:\s*([A-HJ-NPR-Z0-9]{17})'),
    make: field(r'Marke:\s*(.+)'),
    model: field(r'Modell:\s*(.+)'),
    year: field(r'Jahr:\s*(\d{4})'),
    odometer: field(r'Zur.ckgelegte Distanz:\s*(.+)'),
    scannedAt: field(r'Diagnosezeit:\s*(.+)'),
    declaredSystemCount:
        summary == null ? null : int.tryParse(summary.group(1)!),
    declaredDtcCount: summary == null ? null : int.tryParse(summary.group(2)!),
  );
}

/// Ein Steuergerätename enthält Buchstaben und ist keine Zahl und kein
/// Statuswort. Ohne diese Prüfung landen Spaltenreste als Systemnamen im
/// Bericht.
bool _isPlausibleSystemName(String name) {
  if (name.length < 3) return false;
  if (name == 'Kein Fehler' || name == 'Fehler' || name == 'System') {
    return false;
  }
  if (int.tryParse(name) != null) return false;
  return RegExp('[A-Za-zÄÖÜäöü]').hasMatch(name);
}

/// Fasst zusammenhängende Zeilen zu Absätzen zusammen und wirft Kopf- und
/// Fußzeilen weg, die auf jeder Seite wiederkehren.
List<String> _toBlocks(String text) {
  final blocks = <String>[];
  final current = <String>[];

  void flush() {
    if (current.isEmpty) return;
    final joined = current.join(' ').trim();
    current.clear();
    if (joined.isNotEmpty && !_noise.hasMatch(joined)) blocks.add(joined);
  }

  for (final line in text.split('\n')) {
    final trimmed = line.replaceAll('\f', ' ').trim();
    if (trimmed.isEmpty) {
      flush();
    } else if (_noise.hasMatch(trimmed)) {
      flush(); // Seitenkopf trennt, gehört aber nicht zum Inhalt.
    } else {
      current.add(trimmed);
    }
  }
  flush();
  return blocks;
}
