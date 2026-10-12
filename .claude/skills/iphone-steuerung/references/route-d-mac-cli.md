# Route D – indirekt über den Mac und iCloud

## Idee

Oft will der Nutzer kein Gerät steuern, sondern **einen Inhalt auf seinem iPhone haben**: eine Notiz, eine Erinnerung, einen Termin, eine Nachricht. Wenn Claude Zugriff auf einen Mac des Nutzers hat, ist das der kürzeste Weg – iCloud synchronisiert, das Telefon muss nichts tun.

Voraussetzung: Session läuft auf dem Mac des Nutzers (Desktop-App oder verbundener Rechner), gleiche Apple-ID, iCloud-Synchronisierung für die betroffene App aktiv.

## Kurzbefehle vom Terminal

```bash
shortcuts list                       # was ist vorhanden
shortcuts run "CL_Notiz" -i "Milch"  # mit Eingabe
```

Wichtig und leicht zu verwechseln: `shortcuts run` läuft **auf dem Mac**. Ein Kurzbefehl, der eine Notiz anlegt, landet über iCloud auf dem iPhone. Ein Kurzbefehl, der "Taschenlampe an" macht, betrifft den Mac und tut dort nichts Sinnvolles. Vor dem Vorschlag also fragen: wirkt die Aktion auf *Daten* (dann geht's) oder auf *Gerätehardware* (dann Route A/B/C)?

Kurzbefehle synchronisieren über iCloud: ein auf dem Mac angelegter `CL_*`-Kurzbefehl erscheint auf dem iPhone. Das ist der bequemste Weg, die Fähigkeiten für Route A anzulegen – man muss sie nicht am kleinen Bildschirm zusammentippen.

## Direkt über AppleScript

```bash
osascript -e 'tell application "Reminders" to make new reminder with properties {name:"Rückruf Steuerberater"}'
osascript -e 'tell application "Notes" to make new note at folder "Notizen" with properties {body:"Einkauf: Milch, Brot"}'
osascript -e 'tell application "Calendar" to tell calendar "Privat" to make new event with properties {summary:"Zahnarzt", start date:date "Montag, 20. Oktober 2026 um 09:00"}'
```

Beim ersten Lauf fragt macOS pro App nach Automatisierungsrechten – der Nutzer muss das im Dialog bestätigen, sonst bricht es mit `-1743` ab. Das ist der häufigste Stolperstein; direkt darauf hinweisen, statt zu rätseln.

## iMessage vom Mac

```bash
osascript -e 'tell application "Messages" to send "Text" to buddy "+4915112345678" of service 1'
```

Das ist eine Stufe-2-Aktion: **Empfänger und Text vorher zeigen**, immer. Eine an die falsche Nummer gesendete Nachricht lässt sich nicht zurückholen. Die `service 1`-Indizierung ist fragil (iMessage vs. SMS); wenn möglich lieber einen Kurzbefehl mit der Aktion "Nachricht senden" nutzen, der zeigt vor dem Absenden noch das Nachrichtenfenster.

## Was diese Route nicht kann

Alles, was am Telefon selbst passieren muss: Fokus umschalten, Musik auf dem iPhone starten, App dort öffnen, Screenshot des iPhones. Dafür Route A, B oder C.
