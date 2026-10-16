# -*- coding: utf-8 -*-
"""Explosionszeichnung und Deckel-Unteransicht, eigener Z-Buffer-Renderer."""
import numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import trimesh, gehaeuse as G

SS = 2
L1 = np.array([0.45, -0.55, 0.70]); L1 /= np.linalg.norm(L1)
L2 = np.array([-0.60, 0.35, 0.40]); L2 /= np.linalg.norm(L2)

def render(teile, az_deg, el_deg, w=1500, h=1150, fill=0.82):
    """teile: Liste (name, mesh, farbe). Liefert Bild und Projektionsfunktion."""
    W, H = w * SS, h * SS
    az, el = np.radians(az_deg), np.radians(el_deg)
    v = np.array([np.cos(el)*np.cos(az), np.cos(el)*np.sin(az), np.sin(el)])
    r = np.cross([0, 0, 1.0], v); r /= np.linalg.norm(r)
    u = np.cross(v, r)
    M = np.vstack([r, u, v])

    alle = np.vstack([m.vertices for _, m, _ in teile])
    mitte = (alle.min(0) + alle.max(0)) / 2
    P = (alle - mitte) @ M.T
    scale = min(W / np.ptp(P[:, 0]), H / np.ptp(P[:, 1])) * fill
    cx, cy = W / 2, H / 2

    def pix(V):
        p = (np.atleast_2d(V) - mitte) @ M.T
        return np.column_stack([cx + p[:, 0]*scale, cy - p[:, 1]*scale, p[:, 2]])

    rgb   = np.ones((H, W, 3), np.float32)
    zbuf  = np.full((H, W), -1e9, np.float32)
    idbuf = np.full((H, W), -1, np.int32)

    for pid, (_, mesh, col) in enumerate(teile):
        base = np.array(matplotlib.colors.to_rgb(col))
        sv = pix(mesh.vertices)
        nrm = mesh.face_normals @ M.T
        for fi, f in enumerate(mesh.faces):
            a, b, c = sv[f[0]], sv[f[1]], sv[f[2]]
            x0 = max(int(min(a[0], b[0], c[0])), 0); x1 = min(int(max(a[0], b[0], c[0])) + 2, W)
            y0 = max(int(min(a[1], b[1], c[1])), 0); y1 = min(int(max(a[1], b[1], c[1])) + 2, H)
            if x1 <= x0 or y1 <= y0:
                continue
            area = (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])
            if abs(area) < 1e-9:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
            w0 = ((b[0]-a[0])*(gy-a[1]) - (b[1]-a[1])*(gx-a[0])) / area
            w1 = ((c[0]-b[0])*(gy-b[1]) - (c[1]-b[1])*(gx-b[0])) / area
            w2 = 1.0 - w0 - w1
            m = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
            if not m.any():
                continue
            z = w1*a[2] + w2*b[2] + w0*c[2]
            sub = zbuf[y0:y1, x0:x1]
            hit = m & (z > sub)
            if not hit.any():
                continue
            n = nrm[fi]
            if n[2] < 0:
                n = -n
            sh = 0.30 + 0.60*max(0.0, float(n @ (M @ L1))) + 0.22*max(0.0, float(n @ (M @ L2)))
            rgb[y0:y1, x0:x1][hit] = np.clip(base * sh, 0, 1)
            sub[hit] = z[hit]
            idbuf[y0:y1, x0:x1][hit] = pid

    e = np.zeros((H, W), bool)
    for d in ((0, 1), (1, 0)):
        e |= (idbuf != np.roll(idbuf, d, (0, 1))) | \
             (np.abs(zbuf - np.roll(zbuf, d, (0, 1))) > 0.45)
    e[:2] = e[-2:] = e[:, :2] = e[:, -2:] = False
    rgb[e] *= 0.35
    img = rgb.reshape(H//SS, SS, W//SS, SS, 3).mean((1, 3))
    return img, (lambda V: pix(V)[:, :2] / SS), (w, h)

def beschrifte(ax, anker, text, dx, dy, groesse, w, h):
    ax.annotate(text, xy=(anker[0], anker[1]),
                xytext=(anker[0] + dx*w, anker[1] + dy*h),
                fontsize=groesse, va="center", ha="right" if dx < 0 else "left",
                color="#1b1f24", zorder=5,
                arrowprops=dict(arrowstyle="-", lw=1.0, color="#6b7076",
                                shrinkA=0, shrinkB=6))

# ===================================================================== 1
ph  = G.platzhalter()
cob = G.B(G.FEN_X0 - 1, G.FEN_X1 + 1, -(G.FEN_B/2 + 1), G.FEN_B/2 + 1,
          G.Z_PCB_OK + G.LED_H - 0.4, G.Z_PCB_OK + G.LED_H + 0.06)  # 0,06 gegen Z-Fighting
hoch = lambda m, dz: (m.copy().apply_translation([0, 0, dz]) or m)

def versetzt(m, dz):
    m = m.copy(); m.apply_translation([0, 0, dz]); return m

TEILE = [
    ("Unterteil",                    versetzt(G.unterteil(), 0),      "#9fa8b4"),
    ("Akku 14500  3,7 V / 750 mAh",  versetzt(ph["Akku 14500"], 26),  "#2f6fd0"),
    ("Platine",                      versetzt(ph["Platine"], 48),     "#1d7a3c"),
    ("COB-LED-Modul",                versetzt(ph["LED-Modul"], 48),   "#b9bec6"),
    ("Leuchtflaeche",                versetzt(cob, 48),               "#f6e07a"),
    ("Deckel",                       versetzt(G.deckel(), 82),        "#c2cad4"),
    ("Tasterkappe",                  versetzt(G.tasterkappe(), 108),  "#d94444"),
]
img, proj, (w, h) = render(TEILE, 38, 22)
fig, ax = plt.subplots(figsize=(15, 11.5))
ax.imshow(img, interpolation="bilinear"); ax.set_axis_off()

mitten = [proj(m.vertices).mean(0) for _, m, _ in TEILE]
for i in range(len(TEILE) - 1):
    ax.plot(*zip(mitten[i], mitten[i+1]), ls=(0, (6, 6)), lw=1.1, color="#8a8f96", zorder=3)

LAB = {"Unterteil": (-0.33, 0.04), "Akku 14500  3,7 V / 750 mAh": (-0.33, 0.0),
       "Platine": (-0.33, 0.0), "COB-LED-Modul": (0.34, 0.03),
       "Leuchtflaeche": (0.34, -0.03), "Deckel": (0.34, 0.0), "Tasterkappe": (0.34, 0.0)}
for (name, _, _), mp in zip(TEILE, mitten):
    beschrifte(ax, mp, name, *LAB[name], 13, w, h)

ax.set_title("COB-LED-Leuchte — Explosionszeichnung v2       "
             "Gehaeuse 95 x 24,6 x 28,8 mm", fontsize=15, pad=14)
ax.text(0.5, 0.012, "Montage von unten nach oben: Akku einlegen, Platine einlegen, Tasterkappe "
        "von unten in den Deckel, Deckel senkrecht aufsetzen bis die Haken einrasten, "
        "2 Schrauben M3x10 hinten",
        transform=fig.transFigure, ha="center", fontsize=11, color="#404850")
fig.tight_layout(rect=[0, 0.035, 1, 1])
fig.savefig("bild_1_explosion.png", dpi=110, facecolor="white"); plt.close(fig)

# ===================================================================== 2
dk = G.deckel()
T = trimesh.transformations.rotation_matrix(np.pi, [1, 0, 0], [G.INNEN_L/2, 0, G.H_GES/2])
dk.apply_transform(T)
def ank(p):                       # Weltpunkt -> gedreht -> Bildpunkt
    q = np.append(np.asarray(p, float), 1.0) @ T.T
    return q[:3]

img2, proj2, (w2, h2) = render([("Deckel", dk, "#c2cad4")], 38, 26, 1400, 900, 0.80)
fig, ax = plt.subplots(figsize=(14, 9))
ax.imshow(img2, interpolation="bilinear"); ax.set_axis_off()

ANKER = [
    ("Schnapphaken, 3 je Seite", (G.HAKEN_X[1], G.YI + G.HAKEN_U, G.HAKEN_Z1), -0.30, 0.10),
    ("Fuehrungslippe",           (58.0, G.LIP_Y_OUT, G.LIP_Z0 + 1.5),          -0.30, -0.06),
    ("Platinen-Niederhalter",    (5.8, G.NH_Y1, G.NH_Z0),                       0.28, 0.20),
    ("Diffusortasche 58 x 13 x 1", (G.FEN_X1 + 1, G.FEN_B/2 + G.DIFF_SP, G.Z_INNEN + G.DIFF_T),
                                                                               -0.30, 0.14),
    ("Lichtfenster 54 x 9",      (G.FEN_X0 + 30, 0.0, G.Z_INNEN + G.DIFF_T),    0.28, -0.04),
    ("Tasterloch",               (G.TASTER_X, 0.0, G.Z_INNEN),                  0.40, 0.13),
    ("Senkung M3, 2x",           (G.SCHRAUBE_X, G.SCHRAUBE_Y, G.H_GES),         0.27, 0.14),
]
for text, p, dx, dy in ANKER:
    beschrifte(ax, proj2(ank(p))[0], text, dx, dy, 12.5, w2, h2)

ax.set_title("Deckel von unten — Rast- und Fuehrungsgeometrie", fontsize=15, pad=14)
ax.text(0.5, 0.015, "In dieser Lage wird der Deckel auch gedruckt: Lichtfenster-Seite auf dem "
        "Bett, Lippen und Haken nach oben, keine Stuetzen noetig",
        transform=fig.transFigure, ha="center", fontsize=11, color="#404850")
fig.tight_layout(rect=[0, 0.04, 1, 1])
fig.savefig("bild_4_deckel_unten.png", dpi=110, facecolor="white"); plt.close(fig)
print("bild_1_explosion.png und bild_4_deckel_unten.png geschrieben")
