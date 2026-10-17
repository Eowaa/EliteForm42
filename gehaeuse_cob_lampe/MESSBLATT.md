# Messblatt — COB-LED-Leuchte

Stand: ausgewertet aus den Zollstock-Fotos (2. Fotoserie).
Massstab ueber die cm-Teilung des Zollstocks bestimmt: 110 px/cm, Nullpunkt an der
Kappe. **Nur Masse laengs des Zollstocks sind so belastbar** — quer zur Zollstock-
richtung ist das Bild perspektivisch gestaucht, dort gilt die Angabe des Nutzers.

## Gemessen

| Nr  | Mass                                                  | Wert    | Quelle |
|-----|-------------------------------------------------------|--------:|--------|
| M1  | Platine Gesamtlaenge                                   | 70 mm   | Foto 1, ±1 |
| M1a | davon breiter Hauptteil                                | 58 mm   | Foto 1 |
| M1b | davon schmale Zunge mit Taster                         | 12 mm   | Foto 1 |
| M2  | Platine Breite (Hauptteil)                             | 16 mm   | Nutzer: 15–17 |
| M2a | Zunge Breite                                           | ~9,5 mm | Foto 1, Verhaeltnis |
| M12 | Taster: Mitte ab USB-seitiger Plattenkante             | 64 mm   | Foto 1 |
| M19 | 4 Lade-LEDs in einer Reihe, ab USB-seitiger Kante      | 54–57 mm| Foto 1 |
| M4a | COB-Modul Breite                                       | ~13 mm  | Foto E, Verhaeltnis |
| M8  | COB-Leuchtflaeche Breite                               | ~5,5 mm | Foto E, Verhaeltnis |
| M21 | **Gesamtdicke der Baugruppe (COB + Platine + Bauteile)**| ~8 mm  | Foto 3, Kantenansicht |
| M20 | Kabel zum Akku: am Zungenende                          | —       | Foto 1 |
| M15 | Akku Durchmesser                                       | 14,6 mm | Norm 14500 |
| M16 | Akku Laenge                                            | 50,5 mm | Norm 14500 |

## Befunde, die die Konstruktion aendern

1. **COB-Modul und Bauteilseite liegen auf gegenueberliegenden Platinenseiten.**
   Auf der COB-Seite ist nur das weisse Modul zu sehen, ringsum schmale Streifen
   nackte Platine; Taster, IC und Lade-LEDs sitzen auf der Rueckseite, zwei
   Torx-Schrauben halten den Alu-Traeger von dort durch die Platine.
   Folge: Licht und Bedienseite zeigen zwangslaeufig in entgegengesetzte Richtungen,
   und der Akku kann **nicht** unter der Platine liegen — er wuerde entweder das
   Licht oder den Taster verdecken. Die Bauform aus v2 ist damit hinfaellig.

2. **Micro-USB sitzt vermutlich an der Laengsseite**, nicht stirnseitig: in der
   Kantenansicht und in der Gesamtansicht blickt man frontal in die Buchse,
   waehrend die Platinenlaengsachse quer dazu laeuft. Die Oeffnung misst dort
   7,4 x 2,5 mm, also eine normale Micro-USB-Buchse. Sicher ist das nicht.

## Noch offen

| Nr  | Mass                                                        | gemessen |
|-----|-------------------------------------------------------------|----------|
| Nr  | Mass                                                        | in v3 angenommen |
|-----|-------------------------------------------------------------|------------------|
| M4  | COB-Modul Laenge                                             | 55 mm (`LED_L`) |
| M6  | COB-Modul Hoehe ueber der Platinenunterseite                 | 4,0 mm (`LED_H`) |
| M7  | COB-Modul-Vorderkante ab Platinenvorderkante                 | 2,0 mm (`LED_DX`) |
| M11 | Micro-USB: Mitte ab Platinenvorderkante                      | 26 mm (`USB_DX`), Oeffnung 16 x 11 mm faengt Fehler ab |
| M13 | Taster: Bauhoehe ueber der Platine                           | 1,6 mm (`TASTER_H`) |
| M22 | Hoechste Bauteile auf der Rueckseite                         | 2,5 mm (`BAUTEIL_H`) |

M9 ist beantwortet: **Micro-USB an der Laengsseite.**
