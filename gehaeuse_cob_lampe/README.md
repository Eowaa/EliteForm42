# Gehaeuse fuer die COB-LED-Leuchte (v2)

Zweiteiliges Gehaeuse fuer das Leuchtmittel aus den Fotos: COB-LED-Modul auf Platine,
14500-Li-Ion-Zelle (3,7 V / 750 mAh), Micro-USB-Ladebuchse, Taster.

**Aussenmasse 95 x 24,6 x 28,8 mm.**

## Dateien

| Datei | Inhalt | Druckzeit ca. |
|-------|--------|---------------|
| `04_Passprobe_v2.stl`  | **Zuerst drucken.** 30-mm-Scheibe vom vorderen Ende, Unter- und Oberteil, beide bereits in Drucklage | 25 min |
| `01_Unterteil_v2.stl`  | Wanne mit Akkumulde, Platinenschacht, USB-Durchbruch, Rastfenstern, Schraubblock | 2,5 h |
| `02_Deckel_v2.stl`     | Platte mit Lichtfenster, Diffusortasche, Tasterloch, Fuehrungslippen und 6 Schnapphaken | 1 h |
| `03_Tasterkappe_v2.stl`| Druckkappe mit Bund als Auszugssicherung | 5 min |
| `gehaeuse.py`          | parametrisches Modell, erzeugt alle STLs neu | — |
| `schnitte.py`          | masstaebliche Schnittzeichnungen | — |
| `render.py`            | 3D-Vorschaubilder | — |
| `MESSBLATT.md`         | welche Masse noch gemessen werden muessen | — |

## Aufbau

```
Z = 28,8  Deckeloberseite
Z = 26,8  Innendecke / Deckelauflage      3,0 mm Luft ueber dem LED-Modul
Z = 19,8  Platinenoberseite (Trennebene)
Z = 18,2  Platinenunterseite              1,2 mm Luft ueber dem Akku
Z =  2,0  Akkuboden                       2,0 mm Material darunter
```

Der Akku liegt unten in einer halbrunden Mulde, die oben offen ist — er wird von
oben eingelegt. Darueber sitzt die Platine auf zwei durchgehenden Auflageleisten
(je 1,0 mm Auflage pro Kante) in einem 17,6 mm breiten Schacht. Darueber die
LED-Kammer. Der Deckel wird **senkrecht** aufgesetzt, rastet mit 3 Haken je Seite
in die Fenster der Seitenwaende und wird hinten mit 2 Schrauben gesichert.

## Druck

- **Material: PETG.** Die COB-LED wird warm, PLA steht bei Dauerbetrieb direkt
  unter der Leuchtflaeche ueber die Zeit. PLA geht fuer Passprobe und Testlauf.
- 0,2 mm Schichthoehe, 3 Perimeter, 20 % Infill, Duese 0,4 mm.
- **Keine Stuetzen noetig** bei dieser Ausrichtung:
  - Unterteil: Boden auf dem Bett.
  - Deckel: **Oberseite (die mit dem Lichtfenster) auf dem Bett**, Lippen und
    Haken zeigen nach oben. Die Senkungen fuer die Schraubenkoepfe liegen dann
    auf dem Bett und werden sauber.
  - Tasterkappe: aufrecht, so wie sie in der Datei liegt.
- Die Schnapphaken sind das empfindlichste Teil. Bei sproedem Filament lieber
  `HAKEN_U` im Skript von 0,6 auf 0,4 setzen.

## Zusaetzlich noetig

- 2 x Schraube M3 x 10, selbstschneidend fuer Kunststoff (Kernloch 2,5 mm ist vorgesehen)
- optional: Diffusor 58 x 13 x 1 mm aus Acryl oder PETG, wird von innen in die
  Tasche hinter dem Fenster gelegt. Ohne Diffusor leuchtet die COB frei durch den
  54 x 9 mm Durchbruch.

## Montage

1. Akku von oben in die Mulde legen, Kabel nach hinten durch den Spalt neben dem
   Platinenende fuehren.
2. Platine von oben in den Schacht legen, USB-Buchse nach vorn in den Durchbruch.
3. Tasterkappe von unten durch das Tasterloch im Deckel stecken (Bund bleibt innen).
4. Deckel senkrecht aufsetzen und gleichmaessig niederdruecken, bis alle 6 Haken
   hoerbar einrasten.
5. Die 2 Schrauben hinten eindrehen.

Oeffnen: Schrauben heraus, mit einer duennen Klinge durch die Rastfenster der
Seitenwand die Haken nacheinander nach innen druecken.

## Masse aendern

Alle Masse stehen als benannte Parameter oben in `gehaeuse.py`. Nach einer Aenderung:

```bash
python3 gehaeuse.py     # prueft Dichtheit, Kollisionen, Einbaubarkeit und exportiert
python3 schnitte.py     # Schnittzeichnung zur Kontrolle
```

Das Skript bricht mit `FEHLER` ab, wenn sich Teile durchdringen oder der Akku nicht
mehr von oben einlegbar waere.

## Was gemessen ist und was nicht

**Gemessen: nichts.** Alle Masse der Einbauteile sind aus den Fotos geschaetzt —
die Bilder haben keinen Massstab und sind perspektivisch verzerrt. Verlaessliche
Groessen sind nur die Normmasse der 14500-Zelle (Ø 14,5 x 50 mm).
Siehe `MESSBLATT.md`. Deshalb zuerst die Passprobe drucken.

## Sicherheit

Die Zelle ist fest verloetet und sitzt in einem geschlossenen Gehaeuse. Beim
Schliessen darauf achten, dass kein Kabel zwischen Deckel und Wand eingeklemmt wird
— eine gequetschte Litze an einer Li-Ion-Zelle ist ein Kurzschlussrisiko. Das
Lichtfenster nicht abkleben, es ist der Waermeabfuhrweg der COB-LED.
