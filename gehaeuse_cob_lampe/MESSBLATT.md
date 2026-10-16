# Messblatt — COB-LED-Leuchte

Die Fotos haben keinen Massstab und sind perspektivisch verzerrt. Ich konnte daraus
nur die **Topologie** ablesen (was sitzt wo, in welcher Reihenfolge), keine Masse.
Die Spalte "angenommen" ist das, womit v2 gerechnet ist.

**So messen:** Messschieber, jeweils an der breitesten/laengsten Stelle.
Bezugskante fuer alle X-Masse ist die **Vorderkante der Platine auf der USB-Seite**.

| Nr  | Mass                                                        | angenommen | gemessen | Parameter im Skript |
|-----|-------------------------------------------------------------|-----------:|----------|---------------------|
| M1  | Platine Laenge                                               | 76,0       |          | `PCB_L`             |
| M2  | Platine Breite                                               | 17,0       |          | `PCB_B`             |
| M3  | Platine Dicke                                                | 1,6        |          | `PCB_T`             |
| M4  | LED-Modul (Alu-Traeger) Laenge                               | 62,0       |          | `LED_L`             |
| M5  | LED-Modul Breite                                             | 16,0       |          | `LED_B`             |
| M6  | LED-Modul Hoehe ueber Platinenoberseite                      | 4,0        |          | `LED_H`             |
| M7  | Abstand LED-Modul-Vorderkante zur Platinenvorderkante        | 4,0        |          | `LED_DX`            |
| M8  | Leuchtflaeche COB: Laenge x Breite                           | 54 x 9     |          | `FEN_L`, `FEN_B`    |
| M9  | **Micro-USB-Richtung: stirnseitig (nach vorn) oder seitlich?**| stirnseitig|          | siehe Hinweis unten |
| M10 | Micro-USB: Buchsenmitte ueber Platinenoberseite              | 1,3        |          | `USB_DZ`            |
| M11 | Micro-USB: Buchsenvorderkante zur Platinenvorderkante        | 0,0        |          | `PCB_X0`            |
| M12 | Taster: Mitte ab Platinenvorderkante                         | 70,0       |          | `TASTER_DX`         |
| M13 | Taster: Bauhoehe ueber Platine                               | 1,6        |          | `TASTER_H`          |
| M14 | Taster: Versatz aus der Mittellinie (0 = mittig)             | 0          |          | —                   |
| M15 | Akku: Durchmesser ueber dem Schrumpfschlauch                 | 14,6       |          | `AKKU_D`            |
| M16 | Akku: Laenge                                                 | 51,0       |          | `AKKU_L`            |
| M17 | **Bauteile auf der Platinen-UNTERSEITE: hoechstes Mass**     | 0,0        |          | `PCB_LUFT`          |
| M18 | Weitere Bauteile oben hoeher als das LED-Modul? Lage + Hoehe | keine      |          | —                   |
| M19 | Lade-LEDs: Position ab Vorderkante, soll ein Loch dahin?     | —          |          | —                   |
| M20 | Kabel zum Akku: an welchem Ende, Querschnitt                 | hinten     |          | —                   |

## Wichtigste Unsicherheiten

1. **M2 (Platinenbreite)** — aus dem Verhaeltnis Akkudurchmesser zu Platinenbreite
   im Foto geschaetzt. Streubereich 15–20 mm. Das Mass bestimmt die ganze Gehaeusebreite.
2. **M9 (USB-Richtung)** — auf Foto 2 sieht die Buchse stirnseitig aus, auf Foto 1 eher
   seitlich. v2 setzt stirnseitig voraus. Ist sie seitlich, muss der Durchbruch in
   die Seitenwand wandern (das ist eine Zeile im Skript, ich mache das).
3. **M17 (Unterseite)** — v2 laesst 1,2 mm Luft zwischen Akku und Platine. Ragen dort
   Loetstellen oder Bauteile weiter herunter, muss der Wert groesser werden.

## Fotos fuer eine zweite Runde

Senkrecht von oben, Lineal oder Messschieber **in derselben Ebene** daneben, je ein
Bild von Ober- und Unterseite der Platine. Damit kann ich die Masse nachrechnen,
statt sie zu schaetzen.
