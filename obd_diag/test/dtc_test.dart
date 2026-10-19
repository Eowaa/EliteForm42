import 'package:flutter_test/flutter_test.dart';
import 'package:obd_diag/obd/dtc.dart';
import 'package:obd_diag/obd/obd_pid.dart';

List<String> codes(String raw, {int mode = 0x03}) =>
    parseDtcResponse(raw, mode: mode).map((d) => d.code).toList();

void main() {
  group('decodeDtcBytes', () {
    test('ordnet die Systemkennung zu', () {
      expect(decodeDtcBytes(0x01, 0x33), 'P0133');
      expect(decodeDtcBytes(0x41, 0x33), 'C0133');
      expect(decodeDtcBytes(0x81, 0x23), 'B0123');
      expect(decodeDtcBytes(0xC1, 0x00), 'U0100');
    });

    test('behandelt herstellerspezifische Codes', () {
      expect(decodeDtcBytes(0x12, 0x34), 'P1234');
    });
  });

  group('parseDtcResponse', () {
    test('CAN-Antwort mit Zähler-Byte', () {
      expect(codes('43020133 0134'), ['P0133', 'P0134']);
    });

    test('ISO 9141 ohne Zähler-Byte, mit Füllbytes', () {
      expect(codes('430133013400 00'), ['P0133', 'P0134']);
    });

    test('mehrzeilige Antwort wiederholt das Mode-Byte', () {
      // Zusammengeklebt würde das zweite "43" als DTC-Datenbyte gelesen.
      expect(
        codes('43 01 33 01 34\r43 04 20 00 00'),
        ['P0133', 'P0134', 'P0420'],
      );
    });

    test('DTC, dessen Bytes selbst 0x43 enthalten', () {
      expect(codes('4301 0433'), ['P0433']);
    });

    test('Statuszeilen des Adapters verschieben die Ausrichtung nicht', () {
      expect(codes('SEARCHING...\r43020133 0134'), ['P0133', 'P0134']);
    });

    test('leerer Speicher', () {
      expect(codes('4300 0000'), isEmpty);
      expect(codes('NO DATA'), isEmpty);
    });

    test('Duplikate werden zusammengefasst', () {
      expect(codes('4302 0133 0133'), ['P0133']);
    });

    test('Mode 07 für sporadische Fehler', () {
      expect(codes('4701 0420', mode: 0x07), ['P0420']);
    });
  });

  group('extractPayload und PID-Parser', () {
    double? value(String request, String raw) {
      final pid = supportedPids.firstWhere((p) => p.request == request);
      final bytes = extractPayload(raw, request);
      return bytes == null ? null : pid.parse(bytes);
    }

    test('Drehzahl', () => expect(value('010C', '410C1AF8'), 1726.0));
    test('Geschwindigkeit', () => expect(value('010D', '410D3C'), 60.0));
    test('Kühlmitteltemperatur', () => expect(value('0105', '41055A'), 50.0));
    test('Bordspannung', () => expect(value('0142', '414236B0'), 14.0));

    test('Motorlast in Prozent', () {
      expect(value('0104', '41047F'), closeTo(49.8, 0.1));
    });

    test('Gemischkorrektur ist vorzeichenbehaftet', () {
      expect(value('0106', '410680'), 0.0);
      expect(value('0106', '410670'), closeTo(-12.5, 0.1));
    });

    test('Fehlerantworten ergeben keinen Wert', () {
      expect(extractPayload('NO DATA', '010C'), isNull);
      expect(extractPayload('410D3C', '010C'), isNull); // falscher PID
    });
  });

  group('parseMilStatus', () {
    test('liest Lampe und Anzahl getrennt', () {
      final status = parseMilStatus([0x83, 0x07, 0x65, 0x04]);
      expect(status!.lampOn, isTrue);
      expect(status.dtcCount, 3);
    });

    test('Lampe aus', () {
      expect(parseMilStatus([0x00])!.lampOn, isFalse);
    });
  });
}
