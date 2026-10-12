# Route A – Shortcuts-Warteschlange (Standard)

## Idee

Claude kann das iPhone nicht anrufen. Also dreht man die Richtung um: **das iPhone holt sich den Auftrag ab.** Claude legt einen Befehl in eine JSON-Datei an einem Ort, den das Telefon per HTTPS lesen kann. Ein Kurzbefehl auf dem iPhone liest diese Datei und führt die darin genannten Aktionen aus.

Der schöne Nebeneffekt: **das Auslösen durch den Nutzer ist die Freigabe.** Nichts passiert auf dem Telefon, solange er nicht "Hey Siri, Claude ausführen" sagt (oder einen NFC-Tag antippt, oder das Ladekabel ansteckt – je nach Auslöser).

Voraussetzungen: ein iPhone mit der Kurzbefehle-App. Kein Mac, kein Abo, keine Entwicklerwerkzeuge.

```
Claude  ──schreibt──▶  pending.json  (öffentlich lesbar per HTTPS)
                            │
   Nutzer: "Hey Siri, Claude ausführen"
                            ▼
iPhone-Kurzbefehl "Claude"  ──liest──▶  führt CL_*-Kurzbefehle aus
```

## Ablageort für die Queue wählen

Die Datei muss vom iPhone per HTTPS erreichbar sein. Realistische Optionen, in dieser Reihenfolge:

1. **GitHub Gist (öffentlich oder geheim)** – einfachster Weg. Die Raw-URL eines geheimen Gists ist nicht erratbar, aber auch nicht geheim im kryptografischen Sinn. Achtung: Raw-URLs eines Gists sind an die Revision gebunden; nutze die URL ohne Commit-Hash (`https://gist.githubusercontent.com/<user>/<id>/raw/pending.json`), sonst liest das Telefon ewig den alten Stand.
2. **Datei in einem Repo des Nutzers**, gelesen über `raw.githubusercontent.com`. Gut, wenn Claude in der Session ohnehin Repo-Zugriff hat. Nachteil: GitHubs Raw-Cache kann ein paar Minuten alt sein – für "sofort" ungeeignet, für "wenn ich Siri frage" meist unproblematisch. Mit einem `?t=<zeitstempel>` an der URL umgeht der Kurzbefehl den Cache.
3. **iCloud Drive**, wenn Claude auf einem Mac des Nutzers läuft: Datei nach `~/Library/Mobile Documents/com~apple~CloudDocs/Claude/pending.json` schreiben, der Kurzbefehl liest sie mit "Datei holen". Kein öffentlicher Endpunkt nötig – die sauberste Variante, wenn ein Mac im Spiel ist.

**Lege nie Geheimnisse in die Queue** (Passwörter, Tokens, private Nachrichteninhalte, wenn der Ablageort öffentlich ist). Bei öffentlichem Gist gilt: der Nachrichtentext steht dort im Klartext. Darauf hinweisen, bevor Stufe-2-Aktionen über einen öffentlichen Ablageort laufen.

## Datenformat

```json
{
  "version": 1,
  "issued_at": "2026-10-12T14:03:00Z",
  "expires_at": "2026-10-12T15:03:00Z",
  "nonce": "7af3",
  "commands": [
    { "id": "c1", "shortcut": "CL_Timer",  "input": "10",                  "note": "Timer 10 Minuten" },
    { "id": "c2", "shortcut": "CL_Notiz",  "input": "Milch, Brot, Kaffee", "note": "Einkaufsnotiz" }
  ]
}
```

- `shortcut` ist der **exakte Name** eines kleinen Kurzbefehls auf dem Telefon. Namenskonvention `CL_*`, damit sie in der Kurzbefehle-App beieinander stehen und nicht mit anderen kollidieren.
- `input` ist immer ein **Text**; die Umwandlung in Zahl/Datum macht der jeweilige Kurzbefehl. Das hält den Dispatcher einfach.
- `expires_at` verhindert, dass ein alter Auftrag Tage später feuert, wenn der Nutzer Siri zufällig auslöst. Nicht optional – ohne das wird aus der Queue eine Zeitbombe.
- `nonce` dient dem Nutzer zur Sichtprüfung: der Dispatcher zeigt sie in der Abschlussmeldung, Claude nennt sie beim Absetzen. Stimmen sie überein, hat das Telefon den gemeinten Auftrag geholt und nicht einen zwischengespeicherten alten.

## Einrichtung am iPhone (einmalig, ca. 10 Minuten)

Führe den Nutzer in dieser Reihenfolge – es ist seine Reihenfolge am Gerät, nicht deine Logik.

### 1. Einen Fähigkeits-Kurzbefehl anlegen (als Vorlage)

Kurzbefehle-App → **+** → Umbenennen in `CL_Timer` → Aktion suchen "Timer starten" → in der Aktion die Dauer auf **Kurzbefehl-Eingabe** setzen (auf das Dauer-Feld tippen, dann unter "Variablen" → "Kurzbefehl-Eingabe" wählen).

In den Kurzbefehl-Einstellungen (Info-Symbol): **"Bei Freigabe anzeigen"** aktivieren – sonst kann der Dispatcher ihm keine Eingabe übergeben.

Weitere nach gleichem Muster, je nach Bedarf: `CL_Notiz` ("Zu Notiz hinzufügen"), `CL_Erinnerung`, `CL_Musik`, `CL_Fokus`, `CL_Lautstärke`, `CL_Nachricht`, `CL_AppÖffnen`. Nur anlegen, was der Nutzer wirklich will – jeder zusätzliche Kurzbefehl ist Pflegeaufwand.

### 2. Den Dispatcher anlegen

Neuer Kurzbefehl, Name **`Claude`** (der Name ist der Siri-Befehl: "Hey Siri, Claude"). Aktionen in dieser Folge:

1. **"Inhalte von URL abrufen"** – URL = der gewählte Ablageort. Unter "Weitere anzeigen" Methode `GET`, Header `Cache-Control: no-cache`.
2. **"Wörterbuchwert abrufen"** – Schlüssel `expires_at`.
3. **"Datum abrufen"** aus diesem Text → **"Wenn"** Datum *ist vor* **"Aktuelles Datum"** → **"Meldung anzeigen"** ("Auftrag abgelaufen") → **"Kurzbefehl stoppen"**. Ende "Wenn".
4. **"Wörterbuchwert abrufen"** – Schlüssel `commands` (ergibt eine Liste).
5. **"Mit jedem Element wiederholen"**:
   - "Wörterbuchwert abrufen" → Schlüssel `shortcut` → Variable `name`
   - "Wörterbuchwert abrufen" → Schlüssel `input` → Variable `eingabe`
   - **"Kurzbefehl ausführen"** → auf das Kurzbefehl-Feld tippen → **Variable `name` einsetzen** (das ist der Kern des Ganzen: der auszuführende Kurzbefehl kommt aus den Daten), Eingabe = `eingabe`.
6. Nach der Wiederholung: **"Wörterbuchwert abrufen"** → `nonce` → **"Meldung anzeigen"** mit Text "Erledigt – <nonce>".

Dass "Kurzbefehl ausführen" einen variablen Namen annimmt, ist der Trick, der diese Route überhaupt tragfähig macht – sonst bräuchte man für jede Fähigkeit eine eigene Wenn-Verzweigung im Dispatcher.

### 3. Auslöser festlegen

- **Siri** funktioniert ohne weiteres Zutun: der Kurzbefehlname ist das Kommando.
- **Zum Home-Bildschirm hinzufügen** für einen Ein-Tipp-Auslöser (Teilen-Symbol → "Zum Home-Bildschirm").
- **NFC-Tag**: Automation → "NFC" → Tag scannen → "Sofort ausführen" einschalten. Praktisch für "Tag am Schreibtisch antippen = Claude darf".
- **Automation** (Ladekabel, Ankunft, Uhrzeit) nur, wenn der Nutzer das bewusst will. Das verschiebt die Freigabe von "ich löse aus" zu "es passiert von selbst" – darauf ausdrücklich hinweisen, bevor du es vorschlägst.

### 4. Testen

Setze einen harmlosen Befehl ab (`CL_Timer`, 1 Minute), lass den Nutzer auslösen und nach der Nonce schauen. Erst danach echte Aufgaben. Beim allerersten Lauf fragt iOS je Aktion nach Berechtigungen – das muss der Nutzer einmal bestätigen, danach ist Ruhe.

## Optionaler Rückkanal

Ohne Rückkanal siehst du das Ergebnis nicht – sag das klar, statt Erfolg zu behaupten. Zwei Wege:

- **Nutzer berichtet.** Völlig ausreichend für die meisten Aufgaben, kostet eine Zeile Dialog.
- **Der Dispatcher schreibt zurück.** Am Ende eine Aktion "Inhalte von URL abrufen" mit `PATCH` auf die Gist-API (`https://api.github.com/gists/<id>`, Header `Authorization: Bearer <PAT>`, Body `{"files":{"result.json":{"content":"…"}}}`). Das heißt: ein GitHub-Token liegt im Kurzbefehl auf dem Telefon. Nur mit einem feingranularen Token empfehlen, dessen Rechte sich auf genau diesen Gist beschränken, und dem Nutzer die Abwägung nennen, statt sie ihm abzunehmen.

## Grenzen dieser Route

- Nichts passiert ohne Auslöser. "Mach das in einer Stunde" geht nur über eine iOS-Automation mit Zeitauslöser.
- Nur vorbereitete Fähigkeiten. Beliebige App-Bedienung ("tippe in dieser App auf …") kann die Route nicht – dafür Route C.
- Kurzbefehle-Aktionen sind von iOS-Version zu iOS-Version leicht verschieden benannt. Wenn der Nutzer eine Aktion nicht findet, nach dem Zweck suchen lassen, nicht nach deinem exakten Wortlaut.
