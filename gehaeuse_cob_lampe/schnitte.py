# -*- coding: utf-8 -*-
"""Massstaebliche 2D-Schnitte (Laengs- und Querschnitt) zur Kontrolle."""
import numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as MPoly
import gehaeuse as G

u, d, k = G.unterteil(), G.deckel(), G.tasterkappe()
ph = G.platzhalter()

TEILE = [("Unterteil", u, "#8c97a3"), ("Deckel", d, "#b9c2cc"), ("Tasterkappe", k, "#d94444"),
         ("Akku 14500", ph["Akku 14500"], "#3070cc"), ("Platine", ph["Platine"], "#1f7a3d"),
         ("COB-Modul", ph["COB-Modul"], "#e8d36a"), ("Bauteile", ph["Bauteile"], "#7a5aa8"),
         ("USB-Stecker", ph["USB-Stecker"], "#999999")]

def schnitt(ax, origin, normal, h_idx, v_idx, hlab, vlab, titel, skip=()):
    seen = set()
    for name, mesh, col in TEILE:
        if name in skip:
            continue
        sec = mesh.section(plane_origin=origin, plane_normal=normal)
        if sec is None:
            continue
        p2, _ = sec.to_planar()
        for poly in p2.polygons_full:
            pts = np.array(poly.exterior.coords)
            # to_planar legt eine eigene 2D-Basis an -> ueber die 3D-Punkte zuruecksetzen
            ax.add_patch(MPoly(pts, closed=True, facecolor=col, edgecolor="#333",
                               lw=0.7, label=None))
    ax.set_title(titel, fontsize=10)

# to_planar ist fuer die Achsbeschriftung unhandlich -> direkt aus den Dreiecken schneiden
def polys_on_plane(mesh, axis, value, h, v):
    """Schnittpolygone als Liniensegmente in der (h,v)-Ebene."""
    segs = []
    tri = mesh.triangles
    for t in tri:
        dvals = t[:, axis] - value
        pts = []
        for i in range(3):
            a, b = i, (i + 1) % 3
            if (dvals[a] > 0) != (dvals[b] > 0):
                f = dvals[a] / (dvals[a] - dvals[b])
                pts.append(t[a] + f * (t[b] - t[a]))
            if abs(dvals[a]) < 1e-9:
                pts.append(t[a])
        if len(pts) >= 2:
            p = np.array(pts)
            segs.append([(p[0][h], p[0][v]), (p[1][h], p[1][v])])
    return segs

def zeichne(ax, axis, value, h, v, titel, skip=()):
    from matplotlib.collections import LineCollection
    for name, mesh, col in TEILE:
        if name in skip:
            continue
        segs = polys_on_plane(mesh, axis, value, h, v)
        if segs:
            ax.add_collection(LineCollection(segs, colors=col, linewidths=2.0))
    ax.set_aspect("equal"); ax.grid(True, lw=0.3, alpha=0.5)
    ax.set_title(titel, fontsize=10)

fig, axs = plt.subplots(3, 1, figsize=(13, 12))

zeichne(axs[0], 0, 40.0, 1, 2,
        "Querschnitt x = 40 mm   links Platine mit COB nach unten, rechts der Akku  (Y horizontal, Z vertikal, mm)")
axs[0].set_xlim(-22, 22); axs[0].set_ylim(-2, 23)

zeichne(axs[1], 1, G.PCB_YM, 0, 2,
        "Laengsschnitt durch die Platinenachse y = %.1f mm" % G.PCB_YM)
axs[1].set_xlim(-5, 93); axs[1].set_ylim(-2, 23)

zeichne(axs[2], 0, G.USB_X, 1, 2,
        "Querschnitt x = %.1f mm   durch den Micro-USB-Durchbruch in der Laengswand" % G.USB_X)
axs[2].set_xlim(-22, 22); axs[2].set_ylim(-2, 23)

for a in axs:
    a.set_xlabel("mm"); a.set_ylabel("mm")
from matplotlib.lines import Line2D
fig.legend(handles=[Line2D([], [], color=c, lw=3, label=n) for n, _, c in TEILE],
           loc="lower center", ncol=8, fontsize=9, frameon=False)
fig.tight_layout(rect=[0, 0.04, 1, 1])
fig.savefig("bild_3_schnitte.png", dpi=140)
print("bild_3_schnitte.png geschrieben")
