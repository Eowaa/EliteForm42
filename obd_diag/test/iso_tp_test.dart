import 'package:flutter_test/flutter_test.dart';
import 'package:obd_diag/obd/iso_tp.dart';
import 'package:obd_diag/obd/readiness.dart';

void main() {
  group('reassembleIsoTp', () {
    test('Einzelrahmen', () {
      final messages = reassembleIsoTp('7E8 04 41 0C 1A F8');
      expect(messages, hasLength(1));
      expect(messages.first.header, '7E8');
      expect(messages.first.data, [0x41, 0x0C, 0x1A, 0xF8]);
    });

    test('hält zwei gleichzeitig antwortende Steuergeräte getrennt', () {
      final messages = reassembleIsoTp(
        '7E8 04 41 00 BE 3F\r7E9 04 41 00 80 10',
      );
      expect(messages.map((m) => m.header), ['7E8', '7E9']);
      expect(messages[0].data[2], 0xBE);
      expect(messages[1].data[2], 0x80);
    });

    test('29-Bit-Header werden an der Zeilenlänge erkannt', () {
      final messages = reassembleIsoTp('18DAF110 04 41 0C 1A F8');
      expect(messages.first.header, '18DAF110');
      expect(messages.first.data, [0x41, 0x0C, 0x1A, 0xF8]);
    });

    test('kürzt Füllbytes auf die angekündigte Länge', () {
      final messages = reassembleIsoTp(
        '7E8 10 08 49 02 01 31 44 34\r7E8 21 47 50 55 55 55 55 55',
      );
      expect(messages.first.data, hasLength(8));
    });

    test('Folgerahmen ohne Erstrahmen wird verworfen', () {
      expect(reassembleIsoTp('7E8 21 47 50 30'), isEmpty);
    });

    test('Fehlerantwort ergibt keine Nachricht', () {
      expect(reassembleIsoTp('NO DATA'), isEmpty);
    });
  });

  group('parseVin', () {
    test('setzt eine VIN über drei Rahmen zusammen', () {
      // Länge 0x014 = 20 Bytes: 49 02 01 + 17 ASCII-Zeichen.
      const raw = '7E8 10 14 49 02 01 31 44 34\r'
          '7E8 21 47 50 30 30 52 35 35\r'
          '7E8 22 42 31 32 33 34 35 36';
      expect(parseVin(raw), '1D4GP00R55B123456');
    });

    test('ohne Mode-09-Unterstützung null', () {
      expect(parseVin('NO DATA'), isNull);
      expect(parseVin('7E8 04 41 0C 1A F8'), isNull);
    });
  });

  group('isPlausibleVin', () {
    test('verwirft I, O und Q sowie falsche Längen', () {
      expect(isPlausibleVin('1D4GP00R55B123456'), isTrue);
      expect(isPlausibleVin('1D4GP00R55B12345I'), isFalse);
      expect(isPlausibleVin('1D4GP00R55B12345O'), isFalse);
      expect(isPlausibleVin('1D4GP00R55B12345Q'), isFalse);
      expect(isPlausibleVin('1D4GP00R55B12345'), isFalse);
    });
  });

  group('parseReadiness', () {
    List<String> pending(List<int> bytes) =>
        parseReadiness(bytes)!.pending.map((m) => m.name).toList();

    test('alles vorhanden und abgeschlossen', () {
      final report = parseReadiness([0x00, 0x07, 0xFF, 0x00])!;
      expect(report.compressionIgnition, isFalse);
      expect(report.readyForInspection, isTrue);
    });

    test('offene Monitore blockieren die AU', () {
      // Byte D Bit 0 und Bit 5: Katalysator und Lambdasonde.
      expect(
        pending([0x00, 0x07, 0xFF, 0x21]),
        ['Katalysator', 'Lambdasonde'],
      );
      expect(parseReadiness([0x00, 0x07, 0xFF, 0x21])!.readyForInspection,
          isFalse);
    });

    test('Diesel wird über Byte B Bit 3 erkannt und anders benannt', () {
      final report = parseReadiness([0x00, 0x0F, 0xFF, 0x40])!;
      expect(report.compressionIgnition, isTrue);
      expect(report.pending.map((m) => m.name), ['Partikelfilter']);
    });

    test('dauerhafte Monitore aus Byte B', () {
      // Bit 0 vorhanden, Bit 4 unvollständig.
      expect(pending([0x00, 0x11, 0x00, 0x00]), ['Verbrennungsaussetzer']);
    });

    test('nicht unterstützte Monitore blockieren nicht', () {
      final report = parseReadiness([0x00, 0x00, 0x00, 0xFF])!;
      expect(report.pending, isEmpty);
    });

    test('zu kurze Antwort ergibt null', () {
      expect(parseReadiness([0x00, 0x07]), isNull);
    });
  });
}
