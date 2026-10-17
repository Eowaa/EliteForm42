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
ph = G.platzhalter()
def versetzt(m, dz, dy=0.0):
    m = m.copy(); m.apply_translation([0, dy, dz]); return m

TEILE = [
    ("Unterteil",                   versetzt(G.unterteil(), 0),    "#9fa8b4"),
    ("COB-Modul, Licht nach unten", versetzt(ph["COB-Modul"], 24),        "#d8b43a"),
    ("Platine",                     versetzt(ph["Platine"], 33),          "#1d7a3c"),
    ("Bauteile, Taster, Lade-LEDs", versetzt(ph["Bauteile"], 33),         "#7a5aa8"),
    ("Akku 14500  3,7 V / 750 mAh", versetzt(ph["Akku 14500"], 30, 24.0), "#2f6fd0"),
    ("Deckel",                      versetzt(G.deckel(), 58),             "#c2cad4"),
    ("Tasterkappe",                 versetzt(G.tasterkappe(), 80),        "#d94444"),
]
img, proj, (w, h) = render(TEILE, 40, 24, 1500, 1200)
fig, ax = plt.subplots(figsize=(15, 12))
ax.imshow(img, interpolation="bilinear"); ax.set_axis_off()

LAB = {"Unterteil": (-0.30, 0.06), "COB-Modul, Licht nach unten": (-0.32, 0.02),
       "Platine": (-0.32, -0.07), "Bauteile, Taster, Lade-LEDs": (-0.32, -0.15),
       "Akku 14500  3,7 V / 750 mAh": (0.26, 0.10),
       "Deckel": (0.28, -0.02), "Tasterkappe": (0.28, -0.06)}
for name, mesh, _ in TEILE:
    beschrifte(ax, proj(mesh.vertices).mean(0), name, *LAB[name], 13, w, h)

ax.set_title("COB-LED-Leuchte — Explosionszeichnung v3       "
             "Gehaeuse %.0f x %.1f x %.1f mm" % (G.X_E-G.X_A, 2*G.Y_A, G.H_GES),
             fontsize=15, pad=14)
ax.text(0.5, 0.012, "Akku neben der Platine. Das COB-Modul liegt auf dem Boden und strahlt nach "
        "unten durch das Fenster; Taster und Lade-LEDs sitzen auf der Platinenrueckseite "
        "und zeigen nach oben zum Deckel",
        transform=fig.transFigure, ha="center", fontsize=11, color="#404850")
fig.tight_layout(rect=[0, 0.035, 1, 1])
fig.savefig("bild_1_explosion.png", dpi=110, facecolor="white"); plt.close(fig)

# ===================================================================== 2
img2, proj2, (w2, h2) = render([("Unterteil", G.unterteil(), "#9fa8b4")], 40, 42, 1400, 950, 0.80)
fig, ax = plt.subplots(figsize=(14, 9.5))
ax.imshow(img2, interpolation="bilinear"); ax.set_axis_off()

ANKER = [
    ("Akkumulde",                 (42, G.AKKU_YM, G.Z_AKKU_M - G.AKKU_R + 1),      0.30,  0.10),
    ("Trennsteg",                 (42, (G.TRENN_Y0+G.TRENN_Y1)/2, G.Z_INNEN),       0.30, -0.02),
    ("Kabeldurchlass",            (G.INNEN_L-5, (G.TRENN_Y0+G.TRENN_Y1)/2, 8.0),    0.30,  0.20),
    ("Modulschacht 13,8 mm",      (30, G.PCB_YM, G.BODEN_PCB + 0.5),               -0.32,  0.08),
    ("Auflageleisten fuer die Platine", (20, G.PCB_Y0 + G.LEISTE_B/2, G.Z_PCB_UK), -0.32,  0.00),
    ("Lichtfenster 51 x 10 im Boden",   (G.FEN_X0+12, G.PCB_YM, 0.0),              -0.32,  0.18),
    ("Micro-USB-Durchbruch",      (G.USB_X, -G.Y_A, G.USB_ZM),                     -0.32, -0.12),
    ("Schraubdom, 4x M3",         (G.SCHR_X[0], G.SCHR_Y[0], G.Z_INNEN),            0.30, -0.18),
]
for text, p, dx, dy in ANKER:
    beschrifte(ax, proj2(np.asarray(p, float))[0], text, dx, dy, 12.5, w2, h2)

ax.set_title("Unterteil von oben — Platinengasse links, Akkugasse rechts", fontsize=15, pad=14)
ax.text(0.5, 0.015, "In dieser Lage wird gedruckt: Boden auf dem Bett, keine Stuetzen noetig",
        transform=fig.transFigure, ha="center", fontsize=11, color="#404850")
fig.tight_layout(rect=[0, 0.04, 1, 1])
fig.savefig("bild_4_unterteil_innen.png", dpi=110, facecolor="white"); plt.close(fig)
print("bild_1_explosion.png und bild_4_unterteil_innen.png geschrieben")
