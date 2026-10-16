# -*- coding: utf-8 -*-
"""
Gehaeuse fuer COB-LED-Leuchte mit 14500-Li-Ion-Zelle, Micro-USB-Ladeplatine und Taster.
Version v2 -- alle Masse in mm.

BEZUGSSYSTEM
  X = 0  Innenseite der Vorderwand (USB-Seite), +X nach hinten (Taster-Seite)
  Y = 0  Mitte
  Z = 0  Unterseite aussen

AUFBAU
  Unterteil   : Wanne mit Akkumulde unten, Platinenschacht darueber, LED-Kammer oben.
                Alle vier Waende gehen auf volle Hoehe, oben offen.
  Deckel      : Platte mit Lichtfenster, Tasterloch und zwei Fuehrungslippen.
                Wird senkrecht eingesetzt, rastet mit 3 Haken je Seite ein,
                hinten zusaetzlich 2 Schrauben M3.
  Tasterkappe : lose Kappe mit Bund als Auszugssicherung.

Masse mit '# ANNAHME' sind aus den Fotos geschaetzt und NICHT gemessen.
Siehe MESSBLATT.md -- nach dem Messen hier aendern und Skript neu ausfuehren.
"""
import os
import numpy as np
import trimesh
from trimesh.creation import box as _box, cylinder as _cyl

ENG = "manifold"
OUT = os.path.dirname(os.path.abspath(__file__))
VER = "v2"

# =====================================================================
# 1. PARAMETER
# =====================================================================

# --- Druck / Toleranz -------------------------------------------------
WAND      = 2.0    # Seiten- und Stirnwandstaerke
BODEN     = 2.0    # Material unter dem Akku
PLATTE_T  = 2.0    # Deckelplatte
LIP_SP    = 0.25   # Spiel Fuehrungslippe je Seite

# --- Akku 14500 -------------------------------------------------------
AKKU_D    = 14.6   # ANNAHME: 14500 inkl. Wrap
AKKU_L    = 51.0   # ANNAHME
AKKU_SP   = 0.4    # Spiel in der Mulde
AKKU_X0   = 22.0   # Lage Akkuvorderkante (Platzhalter, unkritisch)

# --- Platine ----------------------------------------------------------
PCB_L     = 76.0   # ANNAHME
PCB_B     = 17.0   # ANNAHME
PCB_T     = 1.6    # ANNAHME
PCB_X0    = 4.0    # Vorderkante Platine ab X=0 (haelt den USB-Kanal kurz)
PCB_SP_B  = 0.6    # Spiel Breite im Schacht
PCB_LUFT  = 1.2    # Luft zwischen Akku und Platinenunterseite

# --- COB-LED-Modul auf der Platine ------------------------------------
LED_L     = 62.0   # ANNAHME Laenge Alu-Traeger
LED_B     = 16.0   # ANNAHME Breite Alu-Traeger
LED_H     = 4.0    # ANNAHME Hoehe ueber Platinenoberseite
LED_DX    = 4.0    # Abstand LED-Modul-Vorderkante zur Platinenvorderkante
LED_LUFT  = 3.0    # Luft ueber dem LED-Modul (auch Federweg fuer die Lippe)

# --- Lichtfenster im Deckel ------------------------------------------
FEN_L     = 54.0
FEN_B     = 9.0
DIFF_SP   = 2.0    # Diffusortasche umlaufend groesser
DIFF_T    = 1.0    # Tiefe der Diffusortasche (von unten)

# --- Micro-USB --------------------------------------------------------
USB_B     = 13.0   # ANNAHME Freiraum fuer Steckerumspritzung
USB_H     = 8.5
USB_DZ    = 1.3    # Mitte der Buchse ueber Platinenoberseite

# --- Taster -----------------------------------------------------------
TASTER_DX = 70.0   # ANNAHME Tastermitte ab Platinenvorderkante
TASTER_H  = 1.6    # ANNAHME Bauhoehe Taster ueber Platine
KAPPE_D   = 4.0
KAPPE_LOCH= KAPPE_D + 0.4
KAPPE_BUND= 6.6

# --- Verschraubung ----------------------------------------------------
SCHRAUBE_KERN  = 2.5   # Kernloch fuer M3 selbstschneidend
SCHRAUBE_DURCH = 3.3
SCHRAUBE_KOPF  = 6.2
SCHRAUBE_KOPF_T= 1.0   # Senktiefe (Zylinder-/Linsenkopf)
SCHRAUBE_TIEFE = 10.0
SCHRAUBE_Y     = 6.0

# --- Schnapphaken -----------------------------------------------------
HAKEN_X   = (12.0, 40.0, 68.0)   # je Seite
HAKEN_L   = 9.0                  # Laenge in X
HAKEN_U   = 0.6                  # Hinterschnitt
HAKEN_RMP = 2.2                  # Hoehe der Einfuehrschraege
LIP_T     = 1.2                  # Lippendicke

# =====================================================================
# 2. ABGELEITETE MASSE
# =====================================================================
AKKU_R       = (AKKU_D + AKKU_SP) / 2.0          # Radius Mulde
Z_AKKU_M     = BODEN + AKKU_R                    # Achse der Mulde
Z_AKKU_OK    = BODEN + AKKU_D + AKKU_SP          # Oberkante Akkuraum
PCB_SCHACHT_B= PCB_B + PCB_SP_B
Z_PCB_UK     = Z_AKKU_OK + PCB_LUFT
Z_PCB_OK     = Z_PCB_UK + PCB_T                  # Trennebene
Z_INNEN      = Z_PCB_OK + LED_H + LED_LUFT       # Oberkante Waende
H_GES        = Z_INNEN + PLATTE_T

INNEN_B      = PCB_SCHACHT_B + 2 * 1.5           # Innenbreite oben
INNEN_L      = PCB_X0 + PCB_L + 11.0
YI           = INNEN_B / 2.0                     # halbe Innenbreite
Y_A          = YI + WAND                         # halbe Aussenbreite
X_A, X_E     = -WAND, INNEN_L + WAND

LED_X0, LED_X1 = PCB_X0 + LED_DX, PCB_X0 + LED_DX + LED_L
FEN_X0       = LED_X0 + (LED_L - FEN_L) / 2.0
FEN_X1       = FEN_X0 + FEN_L
TASTER_X     = PCB_X0 + TASTER_DX
USB_ZM       = Z_PCB_OK + USB_DZ

BLOCK_X0     = PCB_X0 + PCB_L + 2.5              # Schraubblock hinten
BLOCK_X1     = INNEN_L
SCHRAUBE_X   = (BLOCK_X0 + BLOCK_X1) / 2.0

LIP_Z0       = Z_PCB_OK + 0.2                    # freies Ende der Lippe
LIP_Y_OUT    = YI - LIP_SP
LIP_Y_IN     = LIP_Y_OUT - LIP_T
HAKEN_Z0     = LIP_Z0
HAKEN_Z1     = HAKEN_Z0 + HAKEN_RMP              # Haltekante

NH_X         = ((PCB_X0 + 0.5, PCB_X0 + 3.0),    # Niederhalter vor dem LED-Modul
                (PCB_X0 + PCB_L - 4.0, PCB_X0 + PCB_L - 1.5))
NH_Y0, NH_Y1 = AKKU_R + 0.0, PCB_B / 2.0         # genau ueber der Auflageleiste
NH_Z0        = Z_PCB_OK + 0.15

# =====================================================================
# 3. HILFSFUNKTIONEN
# =====================================================================
def B(x0, x1, y0, y1, z0, z1):
    return _box(extents=[x1 - x0, y1 - y0, z1 - z0],
                transform=trimesh.transformations.translation_matrix(
                    [(x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2]))

def CYL_X(r, x0, x1, y, z, sections=128):
    m = _cyl(radius=r, height=x1 - x0, sections=sections)
    m.apply_transform(trimesh.transformations.rotation_matrix(np.pi / 2, [0, 1, 0]))
    m.apply_translation([(x0 + x1) / 2, y, z])
    return m

def CYL_Z(r, z0, z1, x, y, sections=96):
    m = _cyl(radius=r, height=z1 - z0, sections=sections)
    m.apply_translation([x, y, (z0 + z1) / 2])
    return m

def prism_yz(pts_yz, x0, x1):
    """Prisma: Profil in der Y-Z-Ebene, entlang X extrudiert."""
    pts = np.asarray(pts_yz, dtype=float)
    n = len(pts)
    v = np.vstack([np.column_stack([np.full(n, x0), pts]),
                   np.column_stack([np.full(n, x1), pts])])
    f = []
    for i in range(1, n - 1):
        f += [[0, i, i + 1], [n, n + i + 1, n + i]]
    for i in range(n):
        j = (i + 1) % n
        f += [[i, n + i, n + j], [i, n + j, j]]
    m = trimesh.Trimesh(vertices=v, faces=np.array(f), process=True)
    m.fix_normals()
    return m

def uni(*ms):    return trimesh.boolean.union(list(ms), engine=ENG)
def dif(a, *ms): return trimesh.boolean.difference([a] + list(ms), engine=ENG)
def isec(a, b):  return trimesh.boolean.intersection([a, b], engine=ENG)

# =====================================================================
# 4. UNTERTEIL
# =====================================================================
def unterteil():
    teil = B(X_A, X_E, -Y_A, Y_A, 0, Z_INNEN)

    # Innenraum: Akkuraum (schmal, oben offen) -> Platinenschacht -> LED-Kammer
    kav = uni(
        CYL_X(AKKU_R, 0, INNEN_L, 0, Z_AKKU_M),                              # Muldenboden
        B(0, INNEN_L, -AKKU_R, AKKU_R, Z_AKKU_M, Z_PCB_UK),                  # Akkuraum, oben offen
        B(0, INNEN_L, -PCB_SCHACHT_B/2, PCB_SCHACHT_B/2, Z_PCB_UK, Z_PCB_OK),# Platinenschacht
        B(0, INNEN_L, -YI, YI, Z_PCB_OK, Z_INNEN + 1),                       # LED-Kammer
    )
    teil = dif(teil, kav)

    # Schraubblock hinten
    teil = uni(teil, B(BLOCK_X0, BLOCK_X1, -YI, YI, 0, Z_INNEN))
    for s in (-1, 1):
        teil = dif(teil, CYL_Z(SCHRAUBE_KERN / 2, Z_INNEN - SCHRAUBE_TIEFE,
                               Z_INNEN + 1, SCHRAUBE_X, s * SCHRAUBE_Y))

    # Micro-USB-Durchbruch in der Vorderwand
    teil = dif(teil, B(X_A - 1, 1.0, -USB_B/2, USB_B/2,
                       USB_ZM - USB_H/2, USB_ZM + USB_H/2))

    # Rastfenster in den Seitenwaenden
    for s in (-1, 1):
        for hx in HAKEN_X:
            y0, y1 = sorted([s * (YI - 0.05), s * (Y_A + 1)])
            teil = dif(teil, B(hx - HAKEN_L/2 - 0.2, hx + HAKEN_L/2 + 0.2,
                               y0, y1, HAKEN_Z0 - 0.3, HAKEN_Z1 + 0.15))
    return teil

# =====================================================================
# 5. DECKEL
# =====================================================================
def deckel():
    teil = B(X_A, X_E, -Y_A, Y_A, Z_INNEN, H_GES)

    # Fuehrungslippen laengs, mit Freischnitten neben den Haken
    for s in (-1, 1):
        y0, y1 = sorted([s * LIP_Y_OUT, s * LIP_Y_IN])
        teil = uni(teil, B(3.0, BLOCK_X0 - 1.5, y0, y1, LIP_Z0, Z_INNEN + 0.01))
        for hx in HAKEN_X:
            for sx in (-1, 1):                       # Entlastungsschlitze
                xm = hx + sx * (HAKEN_L / 2 + 0.6)
                teil = dif(teil, B(xm - 0.4, xm + 0.4, y0 - 1, y1 + 1,
                                   LIP_Z0 - 1, Z_INNEN - 1.2))

    # Schnapphaken mit flacher Einfuehrschraege
    for s in (-1, 1):
        for hx in HAKEN_X:
            prof = [(s * LIP_Y_OUT, HAKEN_Z0),
                    (s * (YI + HAKEN_U), HAKEN_Z1),
                    (s * LIP_Y_OUT, HAKEN_Z1)]
            teil = uni(teil, prism_yz(prof, hx - HAKEN_L/2, hx + HAKEN_L/2))

    # Niederhalter: druecken die Platine auf die Auflageleisten
    for s in (-1, 1):
        for x0, x1 in NH_X:
            y0, y1 = sorted([s * NH_Y0, s * NH_Y1])
            teil = uni(teil, B(x0, x1, y0, y1, NH_Z0, Z_INNEN + 0.01))

    # Lichtfenster + Diffusortasche von unten
    teil = dif(teil, B(FEN_X0, FEN_X1, -FEN_B/2, FEN_B/2, Z_INNEN - 1, H_GES + 1))
    teil = dif(teil, B(FEN_X0 - DIFF_SP, FEN_X1 + DIFF_SP,
                       -(FEN_B/2 + DIFF_SP), FEN_B/2 + DIFF_SP,
                       Z_INNEN - 0.01, Z_INNEN + DIFF_T))

    # Tasterloch
    teil = dif(teil, CYL_Z(KAPPE_LOCH/2, Z_INNEN - 1, H_GES + 1, TASTER_X, 0))

    # Schraubloecher mit Senkung von oben
    for s in (-1, 1):
        teil = dif(teil, CYL_Z(SCHRAUBE_DURCH/2, Z_INNEN - 1, H_GES + 1,
                               SCHRAUBE_X, s * SCHRAUBE_Y))
        teil = dif(teil, CYL_Z(SCHRAUBE_KOPF/2, H_GES - SCHRAUBE_KOPF_T, H_GES + 1,
                               SCHRAUBE_X, s * SCHRAUBE_Y))
    return teil

# =====================================================================
# 6. TASTERKAPPE
# =====================================================================
def tasterkappe():
    z_u     = Z_PCB_OK + TASTER_H + 0.3
    z_bund0 = Z_INNEN - 1.7
    z_bund1 = z_bund0 + 1.2
    return uni(CYL_Z(KAPPE_D/2, z_u, H_GES + 1.0, TASTER_X, 0),
               CYL_Z(KAPPE_BUND/2, z_bund0, z_bund1, TASTER_X, 0))

# =====================================================================
# 7. PLATZHALTER DER EINBAUTEILE
# =====================================================================
def platzhalter():
    return {
        "Akku 14500":  CYL_X(AKKU_D/2, AKKU_X0, AKKU_X0 + AKKU_L, 0, BODEN + AKKU_D/2),
        "Platine":     B(PCB_X0, PCB_X0 + PCB_L, -PCB_B/2, PCB_B/2, Z_PCB_UK, Z_PCB_OK),
        "LED-Modul":   B(LED_X0, LED_X1, -LED_B/2, LED_B/2, Z_PCB_OK, Z_PCB_OK + LED_H),
        "USB-Stecker": B(X_A - 10, PCB_X0 - 0.5, -(USB_B-0.5)/2, (USB_B-0.5)/2,
                         USB_ZM - (USB_H-0.4)/2, USB_ZM + (USB_H-0.4)/2),
        "Taster":      B(TASTER_X-3, TASTER_X+3, -3, 3, Z_PCB_OK, Z_PCB_OK + TASTER_H),
    }

# =====================================================================
# 8. BAUEN, PRUEFEN, EXPORTIEREN
# =====================================================================
if __name__ == "__main__":
    print("=" * 70)
    print("Aussenmasse  L x B x H : %.1f x %.1f x %.1f mm" % (X_E - X_A, 2*Y_A, H_GES))
    print("Innenraum    L x B     : %.1f x %.1f mm" % (INNEN_L, INNEN_B))
    print("Trennebene (Platinen-OK) Z = %.1f   Innendecke Z = %.1f" % (Z_PCB_OK, Z_INNEN))
    print("=" * 70)

    u_, d_, k_ = unterteil(), deckel(), tasterkappe()
    ok = True
    for n, m in (("Unterteil", u_), ("Deckel", d_), ("Tasterkappe", k_)):
        print("%-12s wasserdicht=%-5s  Volumen=%8.1f mm^3  Dreiecke=%d"
              % (n, m.is_watertight, m.volume, len(m.faces)))
        if not m.is_watertight or m.volume <= 0:
            ok = False

    print("-" * 70)
    print("Kollisionspruefung (Grenze 0,05 mm^3):")
    def check(a, an, b, bn):
        global ok
        v = isec(a, b)
        vv = v.volume if (v is not None and len(v.faces)) else 0.0
        if vv >= 0.05:
            ok = False
        print("   %-13s / %-11s %8.3f mm^3  %s" % (bn, an, vv, "OK" if vv < 0.05 else "FEHLER"))
    for n, p in platzhalter().items():
        check(u_, "Unterteil", p, n)
        check(d_, "Deckel", p, n)
    check(u_, "Unterteil", d_, "Deckel")
    check(d_, "Deckel", k_, "Tasterkappe")

    # Einbaubarkeit: Bahn, die der Akku beim senkrechten Einlegen ueberstreicht
    gasse = uni(CYL_X(AKKU_D/2, 1, BLOCK_X0 - 0.5, 0, Z_AKKU_M),
                B(1, BLOCK_X0 - 0.5, -AKKU_D/2, AKKU_D/2, Z_AKKU_M, Z_INNEN))
    v = isec(u_, gasse)
    vv = v.volume if (v is not None and len(v.faces)) else 0.0
    print("   %-13s / %-11s %8.3f mm^3  %s"
          % ("Akku-Einlegegasse", "Unterteil", vv, "OK" if vv < 0.05 else "FEHLER"))
    if vv >= 0.05:
        ok = False

    print("-" * 70)
    print("Kritische Abstaende:")
    print("   Auflage je Platinenkante        : %.2f mm" % (PCB_B/2 - AKKU_R))
    print("   Luft Akku -> Platinenunterseite : %.2f mm" % PCB_LUFT)
    print("   Luft LED-Modul -> Innendecke    : %.2f mm" % LED_LUFT)
    print("   Luft Lippe <-> LED-Modul (Y)    : %.2f mm" % (LIP_Y_IN - LED_B/2))
    print("   USB-Oeffnung Z von %.1f bis %.1f, Kanaltiefe %.1f mm"
          % (USB_ZM - USB_H/2, USB_ZM + USB_H/2, PCB_X0 + WAND))
    print("   Platinenschacht B x T           : %.1f x %.1f mm" % (PCB_SCHACHT_B, PCB_T))
    print("   Haken: Hinterschnitt %.1f mm, Federarm %.1f mm, Schraege %.0f Grad"
          % (HAKEN_U, Z_INNEN - (HAKEN_Z0 + HAKEN_Z1)/2,
             np.degrees(np.arctan2(HAKEN_U, HAKEN_RMP))))
    print("   Niederhalter Luft zur Platine   : %.2f mm" % (NH_Z0 - Z_PCB_OK))
    print("   Tasterweg bis Anschlag Bund     : %.2f mm" % 0.5)

    u_.export(os.path.join(OUT, "01_Unterteil_%s.stl" % VER))
    d_.export(os.path.join(OUT, "02_Deckel_%s.stl" % VER))
    k_.export(os.path.join(OUT, "03_Tasterkappe_%s.stl" % VER))

    # Passprobe: 30 mm vom vorderen Ende, Deckelstueck in Drucklage daneben
    sl = B(X_A - 1, X_A + 30, -50, 50, -1, 60)
    pu, pd = isec(u_, sl), isec(d_, sl)
    pd.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [1, 0, 0]))
    pd.apply_translation([0, 2 * Y_A + 8, -pd.bounds[0][2]])
    trimesh.util.concatenate([pu, pd]).export(os.path.join(OUT, "04_Passprobe_%s.stl" % VER))

    print("-" * 70)
    print("Export: 01_Unterteil / 02_Deckel / 03_Tasterkappe / 04_Passprobe  (%s)" % VER)
    print("GESAMT:", "OK" if ok else "FEHLER -- Meldungen oben pruefen")
