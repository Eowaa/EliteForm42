# obd_diag

OBD2-Diagnose-App in Flutter. Liest Fehlercodes und Live-Daten über einen
ELM327-kompatiblen **BLE**-Adapter – auf Android und iOS aus einer Codebasis.

Eigenständige Implementierung auf Basis öffentlicher Normen
(SAE J1979 / ISO 15031, ELM327-Befehlssatz). Kein Code und keine Assets aus
fremden Apps.

## Stand

Funktionsfähig:

- BLE-Scan, Verbindung, ELM327-Initialisierung (`ATZ`/`ATE0`/`ATS0`/`ATH0`/`ATSP0`)
- Automatische Erkennung der unterstützten PIDs (Mode 01 PID 00 + 20)
- Live-Daten mit Verlaufsgraph: Drehzahl, Geschwindigkeit, Kühlmittel-/
  Ansauglufttemperatur, Motorlast, Drosselklappe, Luftmasse, Tankfüllung,
  Bordspannung, Gemischkorrektur
- Fehlerspeicher lesen (Mode 03 gespeichert, Mode 07 sporadisch)
- Status der Motorkontrollleuchte + Code-Anzahl (Mode 01 PID 01)
- Fehlerspeicher löschen (Mode 04) mit Rückfrage
- Klartext zu den gängigen genormten Codes, auf Deutsch
- **ISO-TP-Mehrrahmen** (ISO 15765-2) mit Trennung nach CAN-Header
- **VIN** über Mode 09 PID 02, dekodiert über die NHTSA-vPIC-Datenbank
- **Readiness-Monitore** für die AU-Vorprüfung, Benzin und Diesel getrennt benannt

Noch offen – siehe Roadmap unten.

## Einrichten

Das Repo enthält nur `lib/`, `test/` und `pubspec.yaml`. Die Plattformordner
werden generiert:

```bash
cd obd_diag
flutter create --platforms=android,ios --org com.deinname --project-name obd_diag .
flutter pub get
flutter test
flutter run
```

`flutter create` kann `lib/main.dart` überschreiben. Deshalb vorher committen
und danach `git status` prüfen – notfalls `git checkout lib/`.

### iOS

In `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Verbindung zum OBD2-Adapter im Fahrzeug.</string>
```

Mindestziel iOS 13 in `ios/Podfile` (`platform :ios, '13.0'`). Bluetooth
funktioniert nicht im Simulator – es braucht ein echtes Gerät.

### Android

In `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

`minSdkVersion 21` in `android/app/build.gradle`.

## Adapter

**Wichtig:** iOS kann klassisches Bluetooth SPP/RFCOMM nicht ansprechen. Die
billigen „ELM327 v1.5"-Dongles funktionieren deshalb **nur auf Android**. Für
iOS braucht es zwingend einen BLE-Adapter oder ein MFi-Gerät.

| Adapter | Android | iOS | Anmerkung |
|---|---|---|---|
| ELM327 BLE (Vgate iCar Pro BLE o. ä.) | ✓ | ✓ | ~25–40 €, gute Wahl für den Start |
| ELM327 Bluetooth Classic | ✓ | ✗ | iOS-seitig systemisch nicht ansprechbar |
| OBDLink CX / MX+ (STN2120) | ✓ | ✓ | **Empfehlung**: veröffentlichtes Datenblatt, RAW-CAN für UDS und opendbc |
| Topdon TopScan | ? | ? | Pairing erfolgt in Topdons eigener App; Dritt-App-Support ist nicht dokumentiert. Vor dem Einplanen mit einer generischen App testen |

Der UART-Service wird nicht über eine festgelegte UUID gesucht, sondern über
den ersten Service, der eine beschreibbare **und** eine benachrichtigende
Characteristic hat. Damit laufen FFF0-, FFE0- und Nordic-UART-Adapter ohne
Anpassung.

## Architektur

```
lib/
├── obd/
│   ├── elm327_client.dart   BLE-Transport, Kommando-Serialisierung, Handshake
│   ├── iso_tp.dart          ISO 15765-2 Mehrrahmen-Zusammensetzung, VIN
│   ├── obd_pid.dart         PID-Definitionen + Messwert-Parser (Mode 01)
│   ├── dtc.dart             Mode 03/07/01-01-Dekodierung
│   ├── readiness.dart       Prüfbereitschaft aus Mode 01 PID 01 Bytes B–D
│   └── dtc_database.dart    Klartext zu genormten Codes
├── data/vin_decoder.dart    VIN-Auflösung über NHTSA vPIC (kostenlos)
├── state/obd_provider.dart  Verbindungszustand, Polling-Loop, Fehlerspeicher
└── ui/                      Verbinden / Live / Fehler
```

Zwei Dinge, die in der Praxis die meisten Probleme machen und hier bewusst
gelöst sind:

1. **Serialisierung.** Der ELM327 verarbeitet immer nur ein Kommando. Alle
   Sendeaufrufe laufen über eine Future-Kette, sonst vermischen sich
   Antworten. Eine Antwort gilt erst mit dem Prompt-Zeichen `>` als komplett.
2. **Zeilenweises Hex-Filtern.** Der Adapter streut Statuszeilen wie
   `SEARCHING...` ein. Ein globales „alles außer 0-9A-F entfernen" lässt daraus
   `EAC` übrig und verschiebt die Byte-Ausrichtung – jede folgende Auswertung
   wird dann falsch. Genauso wiederholt ISO 9141 das Mode-Byte pro Zeile.
   Beides deckt `test/dtc_test.dart` ab.

## Bekannte Grenzen

- **Mehr als 3 DTCs** werden noch nicht mehrrahmig gelesen. Die ISO-TP-Schicht
  dafür steht (`iso_tp.dart`), der Fehlerspeicher nutzt sie noch nicht.
- **Live-Daten** nehmen bei mehreren antwortenden Steuergeräten den ersten
  Treffer. Für die Zuordnung müsste das Polling auf `ATH1` umgestellt werden.
- **vPIC** ist eine US-Datenbank: bei rein europäischen Modellen bleiben Felder
  leer. Die VIN selbst wird trotzdem korrekt gelesen und angezeigt.
- **Herstellerspezifische Diagnose** (ABS, Airbag, Serviceintervall-Reset,
  Stellgliedtests) ist **nicht** enthalten und auch nicht trivial nachzurüsten:
  diese Protokolle sind proprietär und nicht öffentlich dokumentiert. Das ist
  der Punkt, an dem freie OBD2-Apps gegenüber Werkstatt-Testern aufhören.
- Die Code-Tabelle deckt nur genormte Codes ab. Für P1xxx/P3xxx gibt es keine
  freie Quelle.

## Roadmap

- Fahrzeugverwaltung + Wartungsintervalle (`shared_preferences` oder `sqflite`)
- Freeze-Frame-Daten (Mode 02)
- Fehlerspeicher über ISO-TP, damit mehr als 3 Codes ankommen
- UDS (ISO 14229): Steuergeräte-Scan, Mode $22 DIDs, Service-Reset.
  **Braucht RAW-CAN**, also einen STN-basierten Adapter (OBDLink CX/MX+),
  kein ELM327
- opendbc-Signale (MIT-Lizenz) für Werte jenseits von OBD2
- PDF-Bericht für die Werkstatt
- Debug-Tab auf Basis von `Elm327Client.trace` – hilft bei fremden Adaptern

## Rechtliches

Fehlerspeicher löschen setzt auch die Readiness-Monitore zurück. Bis diese neu
durchgelaufen sind, ist das Fahrzeug nicht AU-fähig. „ELM327" ist eine Marke
von Elm Electronics; die App implementiert lediglich das öffentlich
dokumentierte Befehlsformat.
