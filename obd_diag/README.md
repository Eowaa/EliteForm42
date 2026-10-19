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
| OBDLink MX+ / CX | ✓ | ✓ | MFi, deutlich schneller und stabiler, eigenes SDK |

Der UART-Service wird nicht über eine festgelegte UUID gesucht, sondern über
den ersten Service, der eine beschreibbare **und** eine benachrichtigende
Characteristic hat. Damit laufen FFF0-, FFE0- und Nordic-UART-Adapter ohne
Anpassung.

## Architektur

```
lib/
├── obd/
│   ├── elm327_client.dart   BLE-Transport, Kommando-Serialisierung, Handshake
│   ├── obd_pid.dart         PID-Definitionen + Messwert-Parser (Mode 01)
│   ├── dtc.dart             Mode 03/07/01-01-Dekodierung
│   └── dtc_database.dart    Klartext zu genormten Codes
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

- **Mehrrahmen-CAN-Antworten** (mehr als 3 DTCs, oder VIN über Mode 09) werden
  noch nicht zusammengesetzt. Dafür braucht es `ATH1` und eine Auswertung je
  CAN-Header.
- **Mehrere Steuergeräte** antworten teils gleichzeitig; ohne Header lässt sich
  nicht zuordnen, von wem ein Wert kommt. Aktuell wird der erste Treffer
  genommen.
- **Herstellerspezifische Diagnose** (ABS, Airbag, Serviceintervall-Reset,
  Stellgliedtests) ist **nicht** enthalten und auch nicht trivial nachzurüsten:
  diese Protokolle sind proprietär und nicht öffentlich dokumentiert. Das ist
  der Punkt, an dem freie OBD2-Apps gegenüber Werkstatt-Testern aufhören.
- Die Code-Tabelle deckt nur genormte Codes ab. Für P1xxx/P3xxx gibt es keine
  freie Quelle.

## Roadmap

- Fahrzeugverwaltung + Wartungsintervalle (`shared_preferences` oder `sqflite`)
- Freeze-Frame-Daten (Mode 02)
- Readiness-Monitore (Mode 01 PID 01 Bytes B–D) für die AU-Vorprüfung
- VIN über Mode 09 PID 02 (braucht Mehrrahmen-Unterstützung)
- PDF-Bericht für die Werkstatt
- Debug-Tab auf Basis von `Elm327Client.trace` – hilft bei fremden Adaptern

## Rechtliches

Fehlerspeicher löschen setzt auch die Readiness-Monitore zurück. Bis diese neu
durchgelaufen sind, ist das Fahrzeug nicht AU-fähig. „ELM327" ist eine Marke
von Elm Electronics; die App implementiert lediglich das öffentlich
dokumentierte Befehlsformat.
