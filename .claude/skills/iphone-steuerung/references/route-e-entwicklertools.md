# Route E – kabelgebundene Entwicklerwerkzeuge

Nur empfehlen, wenn der Nutzer ohnehin mit Xcode arbeitet. Für "stell mir einen Timer" ist das grotesk überdimensioniert; für automatisierte App-Tests ist es der einzig richtige Weg.

## Was es gibt

- **Appium + XCUITest** (`appium-xcuitest-driver`): echte UI-Automatisierung, findet Elemente über Bezeichner statt Pixelkoordinaten und ist damit viel robuster als Route C. Braucht einen Mac mit Xcode und einen **Apple-Entwickleraccount**, weil der WebDriverAgent auf das Gerät signiert werden muss. Freier Account geht, muss aber alle sieben Tage neu signiert werden.
- **pymobiledevice3** / **libimobiledevice**: Gerätedienste über USB oder Netzwerk – Logs, Screenshots, App-Installation, Entwickler-Tunnel für iOS 17+. Keine UI-Steuerung ohne WebDriverAgent.
- **`xcrun devicectl`** (Xcode 15+): Apps installieren und starten, Gerätedaten lesen. Ersetzt das alte `instruments`.

## Typischer Einstieg

```bash
pip install pymobiledevice3
pymobiledevice3 usbmux list                 # erkannte Geräte
sudo pymobiledevice3 lockdown start-tunnel  # nötig ab iOS 17
pymobiledevice3 developer dvt screenshot out.png
```

## Harte Voraussetzungen

Gerät per Kabel oder im gleichen Netz, **entsperrt**, dem Rechner vertraut ("Diesem Computer vertrauen"), Entwicklermodus in *Einstellungen → Datenschutz & Sicherheit → Entwicklermodus* aktiviert (verlangt einen Neustart). Fehlt eines davon, scheitert alles mit wenig aussagekräftigen Meldungen – diese Liste zuerst durchgehen, bevor man Fehler sucht.

Jailbreak-Wege und Umgehungen von Geräteschutz gehören nicht hierher und sind kein Teil dieses Skills.
