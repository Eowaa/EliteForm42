# -*- coding: utf-8 -*-
"""Vorschaubilder zum Gehaeuse (Explosion, Innenansicht, Laengsschnitt)."""
import numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
import trimesh, gehaeuse as G

LIGHT = np.array([0.4, -0.7, 0.85]); LIGHT = LIGHT / np.linalg.norm(LIGHT)

def shade(mesh, base):
    tri = mesh.triangles
    n = mesh.face_normals
    b = np.clip(n @ LIGHT, 0, 1) * 0.55 + 0.45
    base = np.array(matplotlib.colors.to_rgb(base))
    return tri, np.clip(base[None, :] * b[:, None], 0, 1)

def draw(ax, items, alpha=1.0):
    for mesh, col, a in items:
        if mesh is None or len(mesh.faces) == 0:
            continue
        tri, c = shade(mesh, col)
        pc = Poly3DCollection(tri, facecolors=c, edgecolors="none", alpha=a)
        ax.add_collection3d(pc)

def frame(ax, meshes, elev, azim, title):
    pts = np.vstack([m.vertices for m, _, _ in meshes if m is not None and len(m.faces)])
    c = (pts.min(0) + pts.max(0)) / 2
    r = (pts.max(0) - pts.min(0)).max() / 2 * 1.05
    ax.set_xlim(c[0]-r, c[0]+r); ax.set_ylim(c[1]-r, c[1]+r); ax.set_zlim(c[2]-r, c[2]+r)
    ax.set_box_aspect((1, 1, 1)); ax.view_init(elev=elev, azim=azim)
    ax.set_axis_off(); ax.set_title(title, fontsize=11)

u = G.unterteil(); d = G.deckel(); k = G.tasterkappe(); ph = G.platzhalter()

# ---- 1) Explosionsdarstellung mit Einbauteilen -----------------------
d1 = d.copy(); d1.apply_translation([0, 0, 26])
k1 = k.copy(); k1.apply_translation([0, 0, 34])
akku = ph["Akku 14500"].copy();  akku.apply_translation([0, 0, 9])
pcb  = ph["Platine"].copy();     pcb.apply_translation([0, 0, 17])
led  = ph["LED-Modul"].copy();   led.apply_translation([0, 0, 17])
items = [(u, "#9aa4b0", 1), (d1, "#c6ced8", 1), (k1, "#e03b3b", 1),
         (pcb, "#1f7a3d", 1), (led, "#f2e089", 1), (akku, "#2f6fd0", 1)]
fig = plt.figure(figsize=(11, 7)); ax = fig.add_subplot(111, projection="3d")
draw(ax, items); frame(ax, items, 22, -58, "Explosion: Unterteil, Deckel, Tasterkappe, Einbauteile")
fig.savefig("bild_1_explosion.png", dpi=130, bbox_inches="tight"); plt.close(fig)

# ---- 2) Unterteil von oben -------------------------------------------
items = [(u, "#9aa4b0", 1)]
fig = plt.figure(figsize=(11, 6)); ax = fig.add_subplot(111, projection="3d")
draw(ax, items); frame(ax, items, 62, -75, "Unterteil von oben: Akkumulde, Platinenschacht, Schraubblock")
fig.savefig("bild_2_unterteil_innen.png", dpi=130, bbox_inches="tight"); plt.close(fig)

print("Bilder geschrieben (Schnitte: siehe schnitte.py)")
