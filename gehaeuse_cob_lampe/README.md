# Gehaeuse fuer die COB-LED-Leuchte (v3)

Flacher Riegel fuer das Leuchtmittel aus den Fotos: COB-LED-Modul auf Platine,
14500-Li-Ion-Zelle (3,7 V / 750 mAh), Micro-USB-Ladebuchse an der Laengsseite,
Taster und vierstellige Ladeanzeige.

**Aussenmasse 89,5 x 37,6 x 19,5 mm.**

## Warum die Bauform gegenueber v2 gewechselt hat

Die Messung hat ergeben, dass **COB-Modul und Bauteilseite auf gegenueberliegenden
Platinenseiten** sitzen: auf der einen Seite nur das weisse COB-Modul, auf der
anderen IC, Taster und die vier Lade-LEDs, verschraubt mit zwei Torx-Schrauben
durch die Platine. Licht und Bedienseite zeigen damit zwangslaeufig in
entgegengesetzte Richtungen, und der Akku kann nicht unter der Platine liegen —
er wuerde entweder das Licht oder den Taster verdecken.

Deshalb liegt der Akku jetzt **neben** der Platine: das Licht tritt nach unten
aus dem Boden aus, Taster und Ladeanzeige sitzen oben im Deckel.

## Dateien

| Datei | Inhalt | Druckzeit ca. |
|-------|--------|---------------|
| `04_Passprobe_v3.stl`  | **Zuerst drucken.** 34-mm-Scheibe durch den USB-Durchbruch, Unter- und Oberteil, beide in Drucklage | 30 min |
| `01_Unterteil_v3.stl`  | Wanne mit Modulschacht, Lichtfenster im Boden, Akkumulde, USB-Durchbruch, 4 Schraubdomen | 2,5 h |
| `02_Deckel_v3.stl`     | Platte mit Tasterloch, Fenster fuer die Ladeanzeige, Niederhaltern und 4 Senkungen | 1 h |
| `03_Tasterkappe_v3.stl`| Druckkappe mit Bund als Auszugssicherung, 11 mm Schaft | 5 min |
| `gehaeuse.py`          | parametrisches Modell, erzeugt alle STLs und prueft sie | — |
| `schnitte.py`          | masstaebliche Schnittzeichnungen | — |
| `explosion.py`         | Explosionszeichnung und Innenansicht (eigener Z-Buffer-Renderer) | — |
| `MESSBLATT.md`         | was gemessen ist und was noch fehlt | — |

## Aufbau

```
Querschnitt, von links nach rechts:

  Platinengasse 16,6            Steg 1,6     Akkugasse 15,4
  ┌──────────────────┐          ┌──┐         ┌──────────────┐
  │ Bauteile 2,5     │ Z=10,1   │  │         │              │
  │ Platine 1,6      │ Z= 7,6   │  │         │  Akku Ø14,6  │ Z=16,9
  │ COB-Modul 4,0    │ Z= 6,0   │  │         │              │
  │ Lichtfenster     │ Z= 2,0   │  │         │              │ Z= 1,5
  └──────────────────┘ Z= 0     └──┘         └──────────────┘
```

Das COB-Modul liegt flach auf dem Boden, rings um das Lichtfenster bleiben 1,5 mm
Auflagerand. Die Platine liegt auf zwei durchgehenden Leisten (1,1 mm Auflage je
Kante) und wird vom Deckel mit fuenf Niederhaltern gehalten. Der Akku liegt in
einer Halbrundmulde; die Kabel laufen hinten ueber den Trennsteg.

## Druck

- **Material: PETG.** Das COB-Modul liegt direkt auf dem Boden, dort wird es warm.
  Fuer Passprobe und Testlauf reicht PLA.
- 0,2 mm Schichthoehe, 3 Perimeter, 20 % Infill, Duese 0,4 mm.
- **Keine Stuetzen noetig:**
  - Unterteil: Boden auf dem Bett.
  - Deckel: **Oberseite auf dem Bett**, Niederhalter nach oben. Die Senkungen
    liegen dann auf dem Bett und werden sauber.
  - Tasterkappe: aufrecht, wie in der Datei.

## Zusaetzlich noetig

- 4 x Schraube M3 x 12, selbstschneidend fuer Kunststoff (Kernloch 2,5 mm vorgesehen)
- optional: Diffusorplaettchen 9 x 15 x 1 mm fuer das Fenster der Ladeanzeige,
  Tasche ist vorgesehen
- optional: das Lichtfenster von aussen mit klarer Folie abdecken, wenn es
  staubdicht sein soll

Die vier Lade-LEDs sitzen 9,9 mm unter dem Deckelfenster. Sichtbar sind sie so
schon, deutlich heller wird es mit vier Stiften aus klarem Filament (1,75 mm,
auf 9,8 mm abgelaengt) als Lichtleiter.

## Montage

1. Tasterkappe von unten durch das Loch im Deckel stecken, der Bund bleibt innen.
2. Platine mit dem COB-Modul nach unten von oben in die linke Gasse legen. Das
   Modul laeuft in den Schacht und sitzt auf dem Boden, die USB-Buchse zeigt in
   den Durchbruch der Laengswand.
3. Akku in die Mulde legen, Kabel hinten ueber den Trennsteg zur Platine fuehren.
4. Deckel auflegen und die vier Schrauben eindrehen.

## Masse aendern

Alle Masse stehen als benannte Parameter oben in `gehaeuse.py`. Danach:

```bash
python3 gehaeuse.py     # prueft und exportiert
python3 schnitte.py     # Schnittzeichnung
python3 explosion.py    # Explosion und Innenansicht
```

Das Skript bricht mit `FEHLER` ab, wenn sich Teile durchdringen oder wenn Akku
oder Platine nicht mehr senkrecht einlegbar waeren.

Haeufige Korrekturen:
- USB-Buchse sitzt woanders als angenommen → `USB_DX` (Abstand ab Platinen-
  vorderkante). Die Oeffnung ist mit 16 x 11 mm bewusst grosszuegig.
- USB-Buchse zeigt zur anderen Laengsseite → Platine und Akkugasse tauschen,
  dazu das Vorzeichen von `PCB_YM` und `AKKU_YM` drehen.
- COB-Modul laenger oder kuerzer → `LED_L`, `LED_DX`. Das Lichtfenster folgt
  automatisch.

## Was gemessen ist und was nicht

Gemessen sind Platinenlaenge, die Lage von Taster und Lade-LEDs sowie die
Gesamtdicke der Baugruppe — alles aus den Zollstock-Fotos, siehe `MESSBLATT.md`.
Geschaetzt sind noch Laenge und Hoehe des COB-Moduls und die Lage der
USB-Buchse in Laengsrichtung. Deshalb zuerst die Passprobe drucken.

## Sicherheit

Die Zelle ist fest verloetet und sitzt in einem geschlossenen Gehaeuse. Beim
Schliessen darauf achten, dass kein Kabel zwischen Deckel und Wand oder Trennsteg
eingeklemmt wird — eine gequetschte Litze an einer Li-Ion-Zelle ist ein
Kurzschlussrisiko. Das Lichtfenster nicht abkleben, es ist der Waermeabfuhrweg
des COB-Moduls.
