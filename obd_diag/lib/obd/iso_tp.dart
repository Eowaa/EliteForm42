import 'elm327_client.dart';

/// Eine zusammengesetzte ISO-TP-Nachricht eines Steuergeräts.
class IsoTpMessage {
  const IsoTpMessage({required this.header, required this.data});

  /// CAN-Header der Antwort, z. B. '7E8' für das Motorsteuergerät.
  final String header;
  final List<int> data;

  @override
  String toString() => '$header: ${data.map((b) => b.toRadixString(16)).join(' ')}';
}

/// Setzt mehrrahmige Antworten nach ISO 15765-2 (ISO-TP) zusammen.
///
/// Voraussetzung ist `ATH1`: ohne CAN-Header lässt sich nicht erkennen, von
/// welchem Steuergerät eine Zeile kommt, und bei mehreren Antwortenden wird
/// das Ergebnis Müll.
///
/// Das erste Nibble des PCI-Bytes gibt den Rahmentyp an:
/// 0 = Einzelrahmen, 1 = Erstrahmen, 2 = Folgerahmen, 3 = Flusskontrolle.
/// Die Flusskontrolle sendet der ELM327 selbst, deshalb kommen hier nur
/// die Typen 0 bis 2 an.
List<IsoTpMessage> reassembleIsoTp(String raw) {
  if (isErrorResponse(raw)) return const [];

  // Pufferung je Header, weil mehrere Steuergeräte gleichzeitig antworten.
  final buffers = <String, List<int>>{};
  final expected = <String, int>{};
  final order = <String>[];

  for (final line in hexLines(raw)) {
    // 11-Bit-Header sind 3 Zeichen lang, 29-Bit-Header 8. Da die Nutzdaten
    // immer in Byte-Paaren folgen, ist die Zeile bei 11 Bit ungerade lang
    // und bei 29 Bit gerade.
    final headerLength = line.length.isOdd ? 3 : 8;
    if (line.length < headerLength + 2) continue;

    final header = line.substring(0, headerLength);
    final body = line.substring(headerLength);

    final bytes = <int>[];
    for (var i = 0; i + 1 < body.length; i += 2) {
      bytes.add(int.parse(body.substring(i, i + 2), radix: 16));
    }
    if (bytes.isEmpty) continue;

    final frameType = (bytes[0] >> 4) & 0x0F;

    switch (frameType) {
      case 0x0: // Einzelrahmen: untere Nibble ist die Länge
        final length = bytes[0] & 0x0F;
        final payload = bytes.skip(1).take(length).toList();
        buffers[header] = payload;
        expected[header] = length;
        if (!order.contains(header)) order.add(header);

      case 0x1: // Erstrahmen: 12 Bit Gesamtlänge über zwei Bytes
        if (bytes.length < 2) continue;
        final total = ((bytes[0] & 0x0F) << 8) | bytes[1];
        buffers[header] = bytes.skip(2).toList();
        expected[header] = total;
        if (!order.contains(header)) order.add(header);

      case 0x2: // Folgerahmen: untere Nibble ist die Sequenznummer
        final buffer = buffers[header];
        if (buffer == null) continue; // Erstrahmen verpasst
        buffer.addAll(bytes.skip(1));

      default: // Flusskontrolle oder unbekannt – ignorieren
        continue;
    }
  }

  final messages = <IsoTpMessage>[];
  for (final header in order) {
    final buffer = buffers[header];
    final total = expected[header];
    if (buffer == null || total == null) continue;
    // Die letzte Zeile ist mit 0x00 oder 0x55 aufgefüllt – auf die
    // angekündigte Länge kürzen.
    messages.add(
      IsoTpMessage(
        header: header,
        data: buffer.length > total ? buffer.sublist(0, total) : buffer,
      ),
    );
  }
  return messages;
}

/// Liest die Fahrzeugidentnummer aus einer Antwort auf Mode 09 PID 02.
///
/// Aufbau: 49 02 <Anzahl Datensätze> <17 ASCII-Bytes>.
String? parseVin(String raw) {
  for (final message in reassembleIsoTp(raw)) {
    final d = message.data;
    if (d.length < 4 || d[0] != 0x49 || d[1] != 0x02) continue;

    // Das Zählerbyte fehlt bei manchen Steuergeräten, daher beide Varianten.
    for (final offset in [3, 2]) {
      if (d.length < offset + 17) continue;
      final vin = String.fromCharCodes(d.sublist(offset, offset + 17));
      if (isPlausibleVin(vin)) return vin;
    }
  }
  return null;
}

/// Eine VIN ist 17-stellig und enthält nie I, O oder Q (ISO 3779), damit sie
/// nicht mit 1 und 0 verwechselbar ist.
bool isPlausibleVin(String vin) =>
    RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(vin.toUpperCase());
