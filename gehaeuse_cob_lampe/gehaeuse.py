# -*- coding: utf-8 -*-
"""
Gehaeuse fuer COB-LED-Leuchte mit 14500-Li-Ion-Zelle, Micro-USB-Ladeplatine und Taster.
Version v3 -- alle Masse in mm.

BEFUND AUS DER MESSUNG (siehe MESSBLATT.md)
  COB-Modul und Bauteilseite (IC, Taster, Lade-LEDs) liegen auf gegenueberliegenden
  Platinenseiten. Licht und Bedienseite zeigen deshalb zwangslaeufig in entgegen-
  gesetzte Richtungen, und der Akku kann nicht unter der Platine liegen.
  Daher: Akku NEBEN der Platine, flacher Riegel.

BEZUGSSYSTEM
  X = 0  Innenseite der Vorderwand, +X zur Tasterseite
  Y = 0  Mitte des Gehaeuses; Platine links (-Y), Akku rechts (+Y)
  Z = 0  Unterseite aussen -- dort tritt das Licht aus

AUFBAU (Querschnitt)
  Z = 19,5  Deckeloberseite
  Z = 17,5  Deckelunterseite
  Z = 16,9  Oberkante Akku
  Z = 10,1  Oberkante Bauteile auf der Platinenrueckseite
  Z =  7,6  Platinenoberseite (Bauteilseite, Taster, Lade-LEDs)
  Z =  6,0  Platinenunterseite, liegt auf zwei Leisten
  Z =  2,0  Lichtaustrittsflaeche des COB-Moduls, liegt auf dem Boden
  Z =  0    Boden aussen, darin das Lichtfenster

Masse mit '# ANNAHME' sind noch nicht gemessen.
"""
import os
import numpy as np
import trimesh
from trimesh.creation import box as _box, cylinder as _cyl

ENG = "manifold"
OUT = os.path.dirname(os.path.abspath(__file__))
VER = "v3"

# =====================================================================
# 1. PARAMETER
# =====================================================================

# --- Druck / Toleranz -------------------------------------------------
WAND        = 2.0
BODEN_PCB   = 2.0     # Boden unter dem COB-Modul, darin das Lichtfenster
BODEN_AKKU  = 1.5     # Material unter dem Akku
PLATTE_T    = 2.0     # Deckelplatte
LEISTE_B    = 1.4     # Auflageleisten fuer die Platine

# --- Platine (gemessen) -----------------------------------------------
PCB_L       = 70.0    # gemessen
PCB_B       = 16.0    # Nutzer: 15-17
PCB_T       = 1.6     # ANNAHME
PCB_SP      = 0.6     # Spiel in der Breite
BAUTEIL_H   = 2.5     # ANNAHME Hoehe der Bauteile auf der Rueckseite

# --- COB-Modul, sitzt auf der Platinenunterseite ----------------------
LED_L       = 55.0    # ANNAHME
LED_B       = 13.0    # aus Foto, Verhaeltnis
LED_H       = 4.0     # ANNAHME (Gesamtdicke 8 mm minus Platine minus Bauteile)
LED_DX      = 2.0     # ANNAHME Abstand ab Platinenvorderkante
FEN_SP      = 1.5     # Auflagerand je Seite um das Lichtfenster

# --- Taster (gemessen) ------------------------------------------------
TASTER_DX   = 64.0    # gemessen, ab Platinenvorderkante
TASTER_H    = 1.6     # ANNAHME
KAPPE_D     = 4.0
KAPPE_LOCH  = KAPPE_D + 0.4
KAPPE_BUND  = 6.6

# --- Lade-LEDs (gemessen) ---------------------------------------------
LLED_X0     = 54.0    # gemessen, ab Platinenvorderkante
LLED_X1     = 57.0
LLED_FEN_B  = 12.0    # Fensterbreite quer
LLED_SP     = 1.5     # Fenster ringsum groesser
LLED_DIFF_T = 1.0     # Tasche fuer ein Diffusorplaettchen

# --- Micro-USB, an der Laengsseite ------------------------------------
USB_DX      = 26.0    # ANNAHME ab Platinenvorderkante, Foto-Schaetzung
USB_OEFF_X  = 16.0    # grosszuegig, faengt Lagefehler ab
USB_OEFF_Z  = 11.0
USB_ZM      = 9.0     # Mitte der Oeffnung ueber dem Boden

# --- Akku 14500 -------------------------------------------------------
AKKU_D      = 14.6
AKKU_L      = 50.5
AKKU_SP     = 0.8     # Spiel, auch fuer den Ableiterstreifen am Mantel

# --- Verschraubung, 4 Ecken -------------------------------------------
SCHR_KERN   = 2.5
SCHR_DURCH  = 3.3
SCHR_KOPF   = 6.2
SCHR_KOPF_T = 1.0
SCHR_TIEFE  = 11.0
DOM_D       = 6.5

# =====================================================================
# 2. ABGELEITETE MASSE
# =====================================================================
Z_MOD_UK   = BODEN_PCB
Z_PCB_UK   = Z_MOD_UK + LED_H
Z_PCB_OK   = Z_PCB_UK + PCB_T
Z_BAUT_OK  = Z_PCB_OK + BAUTEIL_H
Z_TASTER   = Z_PCB_OK + TASTER_H

AKKU_SLOT  = AKKU_D + AKKU_SP
AKKU_R     = AKKU_SLOT / 2.0
Z_AKKU_M   = BODEN_AKKU + AKKU_R
Z_AKKU_OK  = BODEN_AKKU + AKKU_SLOT
Z_INNEN    = Z_AKKU_OK + 0.6
H_GES      = Z_INNEN + PLATTE_T

PCB_GASSE  = PCB_B + PCB_SP          # 16,6
TRENN_B    = 1.6                     # Trennsteg zwischen Platine und Akku
INNEN_B    = PCB_GASSE + TRENN_B + AKKU_SLOT
YI         = INNEN_B / 2.0
Y_A        = YI + WAND

PCB_Y0     = -YI                     # Platinengasse von ...
PCB_Y1     = -YI + PCB_GASSE         # ... bis
PCB_YM     = (PCB_Y0 + PCB_Y1) / 2.0 # Mittelachse der Platine
TRENN_Y0   = PCB_Y1
TRENN_Y1   = PCB_Y1 + TRENN_B
AKKU_YM    = TRENN_Y1 + AKKU_R

VORN       = 7.5                     # Freizone vorn (Schraubdom + Spiel zur Platine)
HINTEN     = 8.0                     # Freizone hinten (Schraubdome, Kabel)
PCB_X0     = VORN
PCB_X1     = PCB_X0 + PCB_L
INNEN_L    = PCB_X1 + HINTEN
X_A, X_E   = -WAND, INNEN_L + WAND

LED_X0, LED_X1 = PCB_X0 + LED_DX, PCB_X0 + LED_DX + LED_L
FEN_X0, FEN_X1 = LED_X0 + 2.0, LED_X1 - 2.0
FEN_B          = LED_B - 2 * FEN_SP
TASTER_X       = PCB_X0 + TASTER_DX
USB_X          = PCB_X0 + USB_DX
LLED_XM        = PCB_X0 + (LLED_X0 + LLED_X1) / 2.0

AKKU_X0    = PCB_X0 + 8.0
AKKU_X1    = AKKU_X0 + AKKU_L
TROG_X0, TROG_X1 = AKKU_X0 - 3.0, AKKU_X1 + 3.0

SCHR_X     = (3.5, INNEN_L - 4.0)
SCHR_Y     = (PCB_YM, AKKU_YM)

NH_X       = (PCB_X0 + 6, PCB_X0 + 44)   # Niederhalter, bewusst nicht bei der USB-Buchse
NH_B       = 1.4
NH_Z       = Z_PCB_OK + 0.15

# =====================================================================
# 3. HILFSFUNKTIONEN
# =====================================================================
def B(x0, x1, y0, y1, z0, z1):
    return _box(extents=[x1-x0, y1-y0, z1-z0],
                transform=trimesh.transformations.translation_matrix(
                    [(x0+x1)/2, (y0+y1)/2, (z0+z1)/2]))

def CYL_X(r, x0, x1, y, z, sections=128):
    m = _cyl(radius=r, height=x1-x0, sections=sections)
    m.apply_transform(trimesh.transformations.rotation_matrix(np.pi/2, [0, 1, 0]))
    m.apply_translation([(x0+x1)/2, y, z]); return m

def CYL_Z(r, z0, z1, x, y, sections=96):
    m = _cyl(radius=r, height=z1-z0, sections=sections)
    m.apply_translation([x, y, (z0+z1)/2]); return m

def uni(*ms):    return trimesh.boolean.union(list(ms), engine=ENG)
def dif(a, *ms): return trimesh.boolean.difference([a]+list(ms), engine=ENG)
def isec(a, b):  return trimesh.boolean.intersection([a, b], engine=ENG)

# =====================================================================
# 4. UNTERTEIL
# =====================================================================
def unterteil():
    teil = B(X_A, X_E, -Y_A, Y_A, 0, Z_INNEN)

    kav = uni(
        # Platinengasse: unten schmal (Modulschacht), ab Platinenunterseite voll
        B(0, INNEN_L, PCB_Y0 + LEISTE_B, PCB_Y1 - LEISTE_B, BODEN_PCB, Z_PCB_UK),
        B(0, INNEN_L, PCB_Y0, PCB_Y1, Z_PCB_UK, Z_INNEN + 1),
        # Akkugasse: Mulde unten, ab Mittelachse nach oben offen
        CYL_X(AKKU_R, TROG_X0, TROG_X1, AKKU_YM, Z_AKKU_M),
        B(TROG_X0, TROG_X1, AKKU_YM - AKKU_R, AKKU_YM + AKKU_R, Z_AKKU_M, Z_INNEN + 1),
        B(0, INNEN_L, TRENN_Y1, YI, Z_AKKU_OK, Z_INNEN + 1),   # Kabelraum ueber dem Akku
        # Trennsteg nur bis zur Akkumitte, darueber Kabeldurchlass
        B(PCB_X1 - 4, INNEN_L, TRENN_Y0, TRENN_Y1, 0, Z_INNEN + 1),
    )
    teil = dif(teil, kav)

    # Lichtfenster im Boden
    teil = dif(teil, B(FEN_X0, FEN_X1, PCB_YM - FEN_B/2, PCB_YM + FEN_B/2, -1, BODEN_PCB + 0.01))

    # Micro-USB an der Laengsseite
    teil = dif(teil, B(USB_X - USB_OEFF_X/2, USB_X + USB_OEFF_X/2,
                       -Y_A - 1, PCB_Y0 + 0.5,
                       USB_ZM - USB_OEFF_Z/2, USB_ZM + USB_OEFF_Z/2))

    # Schraubdome in den vier Ecken
    for sx in SCHR_X:
        for sy in SCHR_Y:
            teil = uni(teil, CYL_Z(DOM_D/2, 0, Z_INNEN, sx, sy))
            teil = dif(teil, CYL_Z(SCHR_KERN/2, Z_INNEN - SCHR_TIEFE, Z_INNEN + 1, sx, sy))
    return teil

# =====================================================================
# 5. DECKEL
# =====================================================================
def deckel():
    teil = B(X_A, X_E, -Y_A, Y_A, Z_INNEN, H_GES)

    # Niederhalter auf den bauteilfreien Platinenraendern
    for y0, y1 in ((PCB_Y0 + 0.3, PCB_Y0 + 0.3 + NH_B),
                   (PCB_Y1 - 0.3 - NH_B, PCB_Y1 - 0.3)):
        for x in NH_X:
            teil = uni(teil, B(x - 1.2, x + 1.2, y0, y1, NH_Z, Z_INNEN + 0.01))
    # Niederhalter mittig auf der Zunge, hinter dem Taster
    teil = uni(teil, B(TASTER_X + 3.5, TASTER_X + 6.0, PCB_YM - 2.5, PCB_YM + 2.5,
                       NH_Z, Z_INNEN + 0.01))

    # Tasterloch
    teil = dif(teil, CYL_Z(KAPPE_LOCH/2, Z_INNEN - 1, H_GES + 1, TASTER_X, PCB_YM))

    # Fenster fuer die 4 Lade-LEDs, mit Tasche fuer ein Diffusorplaettchen
    lx0, lx1 = LLED_XM - (LLED_X1 - LLED_X0)/2 - 1.5, LLED_XM + (LLED_X1 - LLED_X0)/2 + 1.5
    teil = dif(teil, B(lx0, lx1, PCB_YM - LLED_FEN_B/2, PCB_YM + LLED_FEN_B/2,
                       Z_INNEN - 1, H_GES + 1))
    teil = dif(teil, B(lx0 - LLED_SP, lx1 + LLED_SP,
                       PCB_YM - LLED_FEN_B/2 - LLED_SP, PCB_YM + LLED_FEN_B/2 + LLED_SP,
                       Z_INNEN - 0.01, Z_INNEN + LLED_DIFF_T))

    # Schraubloecher mit Senkung von oben
    for sx in SCHR_X:
        for sy in SCHR_Y:
            teil = dif(teil, CYL_Z(SCHR_DURCH/2, Z_INNEN - 1, H_GES + 1, sx, sy))
            teil = dif(teil, CYL_Z(SCHR_KOPF/2, H_GES - SCHR_KOPF_T, H_GES + 1, sx, sy))
    return teil

# =====================================================================
# 6. TASTERKAPPE
# =====================================================================
def tasterkappe():
    z_u = Z_TASTER + 0.3
    zb0 = Z_INNEN - 1.7
    return uni(CYL_Z(KAPPE_D/2, z_u, H_GES + 1.0, TASTER_X, PCB_YM),
               CYL_Z(KAPPE_BUND/2, zb0, zb0 + 1.2, TASTER_X, PCB_YM))

# =====================================================================
# 7. PLATZHALTER
# =====================================================================
def platzhalter():
    return {
        "Akku 14500":  CYL_X(AKKU_D/2, AKKU_X0, AKKU_X1, AKKU_YM, BODEN_AKKU + AKKU_D/2),
        "Platine":     B(PCB_X0, PCB_X1, PCB_YM - PCB_B/2, PCB_YM + PCB_B/2, Z_PCB_UK, Z_PCB_OK),
        "COB-Modul":   B(LED_X0, LED_X1, PCB_YM - LED_B/2, PCB_YM + LED_B/2, Z_MOD_UK, Z_PCB_UK),
        "Bauteile":    B(PCB_X0 + 2, PCB_X0 + 56, PCB_YM - PCB_B/2 + 1.5, PCB_YM + PCB_B/2 - 1.5,
                         Z_PCB_OK, Z_BAUT_OK),
        "USB-Stecker": B(USB_X - 6.25, USB_X + 6.25, -Y_A - 10, PCB_Y0 + 0.3,
                         USB_ZM - 4.25, USB_ZM + 4.25),
        "Taster":      B(TASTER_X-3, TASTER_X+3, PCB_YM-3, PCB_YM+3, Z_PCB_OK, Z_TASTER),
    }

# =====================================================================
# 8. BAUEN, PRUEFEN, EXPORTIEREN
# =====================================================================
if __name__ == "__main__":
    print("=" * 72)
    print("Aussenmasse  L x B x H : %.1f x %.1f x %.1f mm" % (X_E-X_A, 2*Y_A, H_GES))
    print("Innenraum    L x B     : %.1f x %.1f mm" % (INNEN_L, INNEN_B))
    print("Platinengasse  y = %.1f .. %.1f     Akkuachse y = %.1f" % (PCB_Y0, PCB_Y1, AKKU_YM))
    print("Lichtfenster %.0f x %.0f mm im Boden" % (FEN_X1-FEN_X0, FEN_B))
    print("=" * 72)

    u_, d_, k_ = unterteil(), deckel(), tasterkappe()
    ok = True
    for n, m in (("Unterteil", u_), ("Deckel", d_), ("Tasterkappe", k_)):
        print("%-12s wasserdicht=%-5s  Volumen=%8.1f mm^3  Dreiecke=%d"
              % (n, m.is_watertight, m.volume, len(m.faces)))
        if not m.is_watertight or m.volume <= 0:
            ok = False

    print("-" * 72)
    print("Kollisionspruefung (Grenze 0,05 mm^3):")
    def check(a, an, b, bn):
        global ok
        v = isec(a, b)
        vv = v.volume if (v is not None and len(v.faces)) else 0.0
        if vv >= 0.05:
            ok = False
        print("   %-20s / %-11s %8.3f mm^3  %s" % (bn, an, vv, "OK" if vv < 0.05 else "FEHLER"))
    for n, p in platzhalter().items():
        check(u_, "Unterteil", p, n)
        check(d_, "Deckel", p, n)
    check(u_, "Unterteil", d_, "Deckel")
    check(d_, "Deckel", k_, "Tasterkappe")

    # Einbaubarkeit: senkrecht einlegen
    gasse_akku = uni(CYL_X(AKKU_D/2, AKKU_X0, AKKU_X1, AKKU_YM, BODEN_AKKU + AKKU_D/2),
                     B(AKKU_X0, AKKU_X1, AKKU_YM - AKKU_D/2, AKKU_YM + AKKU_D/2,
                       BODEN_AKKU + AKKU_D/2, Z_INNEN))
    gasse_pcb = uni(B(PCB_X0, PCB_X1, PCB_YM-PCB_B/2, PCB_YM+PCB_B/2, Z_PCB_UK, Z_INNEN),
                    B(LED_X0, LED_X1, PCB_YM-LED_B/2, PCB_YM+LED_B/2, Z_MOD_UK, Z_INNEN))
    for nm, g in (("Akku-Einlegebahn", gasse_akku), ("Platinen-Einlegebahn", gasse_pcb)):
        v = isec(u_, g)
        vv = v.volume if (v is not None and len(v.faces)) else 0.0
        if vv >= 0.05:
            ok = False
        print("   %-20s / %-11s %8.3f mm^3  %s" % (nm, "Unterteil", vv, "OK" if vv < 0.05 else "FEHLER"))

    print("-" * 72)
    print("Kritische Abstaende:")
    print("   Auflage je Platinenkante        : %.2f mm"
          % ((PCB_Y0 + LEISTE_B) - (PCB_YM - PCB_B/2)))
    print("   Modulschacht Breite             : %.2f mm  (Modul %.1f)" % (PCB_GASSE - 2*LEISTE_B, LED_B))
    print("   Auflagerand um das Lichtfenster : %.2f mm je Seite" % ((LED_B - FEN_B)/2))
    print("   Luft Bauteile -> Deckel         : %.2f mm" % (Z_INNEN - Z_BAUT_OK))
    print("   Luft Akku -> Deckel             : %.2f mm" % (Z_INNEN - Z_AKKU_OK))
    print("   Tasterkappe Schaftlaenge        : %.2f mm" % (H_GES + 1.0 - (Z_TASTER + 0.3)))
    print("   Lade-LED-Fenster ueber den LEDs : %.2f mm" % (Z_INNEN - Z_PCB_OK))
    print("   USB-Oeffnung %.0f x %.0f mm, Mitte Z = %.1f" % (USB_OEFF_X, USB_OEFF_Z, USB_ZM))

    u_.export(os.path.join(OUT, "01_Unterteil_%s.stl" % VER))
    d_.export(os.path.join(OUT, "02_Deckel_%s.stl" % VER))
    k_.export(os.path.join(OUT, "03_Tasterkappe_%s.stl" % VER))

    # Passprobe: 34 mm aus der Mitte, beide Teile in Drucklage
    xm = (USB_X + 6)
    sl = B(xm - 34, xm, -99, 99, -1, 99)
    pu, pd = isec(u_, sl), isec(d_, sl)
    pd.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [1, 0, 0]))
    pd.apply_translation([0, 2*Y_A + 8, -pd.bounds[0][2]])
    trimesh.util.concatenate([pu, pd]).export(os.path.join(OUT, "04_Passprobe_%s.stl" % VER))

    print("-" * 72)
    print("Export v3: Unterteil / Deckel / Tasterkappe / Passprobe")
    print("GESAMT:", "OK" if ok else "FEHLER -- Meldungen oben pruefen")
