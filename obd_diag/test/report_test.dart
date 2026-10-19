import 'package:flutter_test/flutter_test.dart';
import 'package:obd_diag/data/topdon_report.dart';
import 'package:obd_diag/obd/uds_dtc.dart';

/// Nachbau eines echten Gesamtsystem-Berichts in der Lesereihenfolge, wie
/// PDF-Textextraktion sie liefert. Fahrzeug- und Gerätekennungen sind durch
/// Platzhalter ersetzt – echte VINs gehören nicht in ein Repository.
const _report = '''
Berichtsnummer : TD0000000000

SN: 000000000000000

Erstellungsdatum : 2026-09-17

TOPDON ID: XXXXXXXXXX

MERCEDES-BENZ-CLA (117)-2014_Vor
Reparatur_Gesamtsystem-Bericht
Nummernschild:

Marke: MERCEDES-BENZ

Modell: CLA (117)

Jahr: 2014

Zurückgelegte Distanz: 66495.289 miles

Diagnosezeit: 2026-09-17 01 14 26

VIN: WDD1170001A000001

Zusammenfassung
44 Systeme wurden gescannt, und 1 davon wurden mit DTC erkannt. Es wurden insgesamt 2 DTC
gefunden.

Gesamtsystem-Bericht(44)
System

Systemstatus

ECM-Motorsteuerungssystem(ECM)

Kein Fehler

0

VGS-Getriebesteuerung(VGS)

Kein Fehler

0

SG-SW-Scheinwerfer(SG-SW)
DTC

Beschreibung

Status

B284613

Das Abbiegelicht links hat Funktionsstörung.Es liegt eine
Unterbrechung vor.

Aktuell und
gespeichert

B284713

Das Abbiegelicht rechts hat Funktionsstörung.Es liegt eine
Unterbrechung vor.

Aktuell und
gespeichert
''';

void main() {
  group('parseScanReport', () {
    final report = parseScanReport(_report);

    test('liest die Kopfdaten', () {
      expect(report.make, 'MERCEDES-BENZ');
      expect(report.model, 'CLA (117)');
      expect(report.year, '2014');
      expect(report.vin, 'WDD1170001A000001');
      expect(report.odometer, '66495.289 miles');
      expect(report.displayName, '2014 MERCEDES-BENZ CLA (117)');
    });

    test('übernimmt die Eigenangaben des Berichts als Gegenprobe', () {
      expect(report.declaredSystemCount, 44);
      expect(report.declaredDtcCount, 2);
    });

    test('liest beide Fehlercodes mit Beschreibung und Status', () {
      expect(report.entries, hasLength(2));
      expect(report.entries[0].rawCode, 'B284613');
      expect(report.entries[0].description, contains('Abbiegelicht links'));
      expect(report.entries[0].status, 'Aktuell und gespeichert');
      expect(report.entries[1].rawCode, 'B284713');
    });

    test('ordnet die Codes dem Steuergerät zu', () {
      // Der Name klebt in der Extraktion an der Spaltenüberschrift 'DTC'.
      expect(report.entries.every((e) => e.ecu == 'SG-SW-Scheinwerfer(SG-SW)'),
          isTrue);
    });

    test('verwirft Spaltenreste als Systemnamen', () {
      expect(report.systems.map((s) => s.name), ['ECM-Motorsteuerungssystem(ECM)', 'VGS-Getriebesteuerung(VGS)']);
      expect(report.systems.any((s) => int.tryParse(s.name) != null), isFalse);
    });

    test('meldet, wenn weniger gelesen wurde als der Bericht nennt', () {
      // Im Auszug stehen nur 2 der 44 Systeme – das muss auffallen.
      expect(report.consistencyWarning, contains('44 System'));
    });

    test('schlüsselt die Codes nach ISO 14229-1 auf', () {
      final uds = report.entries.first.uds!;
      expect(uds.code, 'B2846');
      expect(uds.failureType, 0x13);
      expect(uds.fullCode, 'B2846-13');
      // Gegenprobe gegen den Klartext des Berichts selbst.
      expect(uds.failureDescription, 'Unterbrechung im Stromkreis');
      expect(report.entries.first.description, contains('Unterbrechung'));
    });
  });

  group('UDS-Fehlercodes', () {
    test('zerlegt drei Rohbytes', () {
      final dtc = parseUdsDtc(0xB2, 0x84, 0x13)!;
      expect(dtc.code, 'B2846');
      expect(dtc.fullCode, 'B2846-13');
    });

    test('erkennt das System am oberen Bitpaar', () {
      expect(parseUdsDtc(0x01, 0x33, 0x00)!.code, 'P0133');
      expect(parseUdsDtc(0xC1, 0x00, 0x87)!.code, 'U0100');
    });

    test('drei Nullbytes sind kein Fehler', () {
      expect(parseUdsDtc(0, 0, 0), isNull);
    });

    test('liest beide Schreibweisen', () {
      expect(parseUdsDtcString('B2846-13')!.failureType, 0x13);
      expect(parseUdsDtcString('B284613')!.failureType, 0x13);
      expect(parseUdsDtcString('P0133'), isNull); // OBD2, kein UDS-Code
    });

    test('benennt die gängigen Fehlerarten', () {
      expect(describeFailureType(0x11), 'Kurzschluss nach Masse');
      expect(describeFailureType(0x13), 'Unterbrechung im Stromkreis');
      expect(describeFailureType(0x87), 'Nachricht fehlt');
    });

    test('fällt bei unbekanntem FTB auf die Gruppe zurück', () {
      // Nicht in der Tabelle, aber das obere Nibble sagt: Stromkreis.
      final text = describeFailureType(0x10);
      expect(text, contains('Stromkreis'));
      expect(text, contains('0x10'));
    });

    test('nennt die Fehlerart auch ohne bekannte Gruppe', () {
      expect(describeFailureType(0xF5), contains('0xF5'));
    });
  });

  group('DtcStatus', () {
    test('fasst die Statusbits zusammen', () {
      expect(const DtcStatus(0x09).summary, 'aktuell und gespeichert');
      expect(const DtcStatus(0x01).summary, 'aktuell');
      expect(const DtcStatus(0x08).summary, 'gespeichert');
      expect(const DtcStatus(0x04).summary, 'sporadisch');
      expect(const DtcStatus(0x00).summary, 'inaktiv');
    });

    test('liest die Warnleuchten-Anforderung', () {
      expect(const DtcStatus(0x89).warningIndicatorRequested, isTrue);
      expect(const DtcStatus(0x09).warningIndicatorRequested, isFalse);
    });
  });
}
