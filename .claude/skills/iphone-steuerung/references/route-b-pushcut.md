# Route B – Pushcut (Push von außen, sofort)

## Wann diese Route

Wenn der Nutzer will, dass eine Aktion losgeht, **ohne** dass er am Telefon etwas auslöst – "schick das jetzt auf mein iPhone, ich hab's in der Tasche". Das kann iOS von Haus aus nicht; Pushcut (App Store, von Simon Støvring unabhängig, kostenpflichtige Zusatzfunktionen) füllt die Lücke.

**Preisvorbehalt vorab nennen, nicht hinterher:** Benachrichtigungs-Webhooks gehen im kostenlosen Rahmen; der *Automationsserver*, der Kurzbefehle wirklich ohne Antippen ausführt, braucht ein Abo (Pushcut Extras) und ein Gerät, auf dem Pushcut im Vordergrund bzw. als Server läuft. Prüf- und Preisstand ändert sich – lass den Nutzer das im App Store bestätigen, statt eine Zahl zu behaupten.

## Zwei Betriebsarten

**1. Benachrichtigung mit Aktion (einfach, mit einem Antippen)**

```bash
curl -X POST "https://api.pushcut.io/<SECRET>/notifications/<NAME>" \
  -H "Content-Type: application/json" \
  -d '{"title":"Claude","text":"Timer 10 Minuten starten?","input":"10"}'
```

Auf dem Telefon erscheint eine Mitteilung; der Nutzer tippt sie an, der verknüpfte Kurzbefehl läuft. Das ist Route A mit Push statt Siri – und das Antippen ist wieder die Freigabe. Für die meisten Fälle die richtige Wahl.

**2. Automationsserver (läuft ohne Zutun)**

```bash
curl "https://api.pushcut.io/<SECRET>/execute?shortcut=CL_Timer&input=10"
```

Führt den Kurzbefehl direkt aus. Mächtig – und damit fällt die implizite Freigabe weg, die Route A eingebaut hat. Hier greift das Stufenmodell aus SKILL.md deshalb strenger: **jede Stufe-2-Aktion einzeln freigeben lassen**, und bei Stufe 1 den Trockenlauf nicht weglassen. Der Nutzer merkt sonst erst am Ergebnis, dass du etwas getan hast.

## Einrichtung

1. Pushcut installieren, in der App unter *Integrations* das API-Secret kopieren.
2. Unter *Notifications* eine Mitteilung anlegen, Name z. B. `claude`, und ihr den Zielkurzbefehl zuweisen.
3. Für Betriebsart 2: *Automation Server* in der App aktivieren (Abo nötig), möglichst auf einem Gerät, das am Strom hängt.
4. Secret **nicht** in eine Datei im Repo schreiben. In eine Umgebungsvariable (`PUSHCUT_SECRET`) oder in die Shell-Historie-freie Eingabe des Nutzers. Wer das Secret hat, kann sein Telefon auslösen.

## Alternativen mit gleichem Muster

- **Scriptable** + `x-callback-url`: eher für eigene JS-Automationen als für Fernsteuerung.
- **Home Assistant** mit iOS-App: wenn der Nutzer das ohnehin betreibt, kann es Mitteilungen mit Aktionen auslösen und ist dann der bessere Weg, weil ohne Zusatzabo.
- **Apple Kurzbefehle über HomeKit-Szene**: nur für Heimautomation, keine allgemeine Steuerung.
