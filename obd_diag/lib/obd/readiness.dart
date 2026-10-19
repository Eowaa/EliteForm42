/// Ein Readiness-Monitor (Prüfbereitschaft) nach SAE J1979.
///
/// Für die AU ist entscheidend: ein Monitor, der vorhanden aber noch nicht
/// durchgelaufen ist, führt zum Nichtbestehen. Nach dem Löschen des
/// Fehlerspeichers sind alle Monitore zurückgesetzt.
class Monitor {
  const Monitor({
    required this.name,
    required this.supported,
    required this.complete,
  });

  final String name;
  final bool supported;
  final bool complete;

  /// Nur unterstützte, nicht abgeschlossene Monitore blockieren die AU.
  bool get blocksInspection => supported && !complete;
}

class ReadinessReport {
  const ReadinessReport({
    required this.compressionIgnition,
    required this.monitors,
  });

  /// true = Selbstzünder (Diesel), false = Fremdzünder (Benzin). Davon hängt
  /// ab, welche Monitore die Bytes C und D überhaupt beschreiben.
  final bool compressionIgnition;
  final List<Monitor> monitors;

  List<Monitor> get pending =>
      monitors.where((m) => m.blocksInspection).toList();

  bool get readyForInspection => pending.isEmpty;
}

/// Wertet die Bytes B, C und D von Mode 01 PID 01 aus.
///
/// Byte B trägt die drei dauerhaft laufenden Monitore. Byte C sagt, welche
/// der nicht-dauerhaften Monitore vorhanden sind, Byte D, welche davon noch
/// nicht abgeschlossen sind.
ReadinessReport? parseReadiness(List<int> bytes) {
  if (bytes.length < 4) return null;

  final b = bytes[1];
  final c = bytes[2];
  final d = bytes[3];

  final diesel = (b & 0x08) != 0;

  // Byte B: Bits 0-2 vorhanden, Bits 4-6 unvollständig.
  const continuous = ['Verbrennungsaussetzer', 'Kraftstoffsystem', 'Komponenten'];
  final monitors = <Monitor>[
    for (var i = 0; i < 3; i++)
      Monitor(
        name: continuous[i],
        supported: (b & (1 << i)) != 0,
        complete: (b & (1 << (i + 4))) == 0,
      ),
  ];

  // Bytes C/D: Bit für Bit dieselbe Reihenfolge, je nach Motorart anders
  // belegt. Bit 3 ist bei Benzinern die Sekundärluft, bei Dieseln der
  // Ladedruck; Bit 1 ist beim Diesel reserviert.
  const spark = [
    'Katalysator',
    'Katalysatorheizung',
    'Tankentlüftung',
    'Sekundärluftsystem',
    'Klimaanlagen-Kältemittel',
    'Lambdasonde',
    'Lambdasondenheizung',
    'Abgasrückführung',
  ];
  const compression = [
    'NMHC-Katalysator',
    'NOx-Nachbehandlung',
    null, // reserviert
    'Ladedruck',
    null, // reserviert
    'Abgassensor',
    'Partikelfilter',
    'Abgasrückführung / VVT',
  ];

  final names = diesel ? compression : spark;
  for (var i = 0; i < 8; i++) {
    final name = names[i];
    if (name == null) continue;
    monitors.add(
      Monitor(
        name: name,
        supported: (c & (1 << i)) != 0,
        complete: (d & (1 << i)) == 0,
      ),
    );
  }

  return ReadinessReport(compressionIgnition: diesel, monitors: monitors);
}
