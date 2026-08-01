# EliteForm42

Moderne, dunkle Premium-Web-App für 3D-gedruckte humorvolle Schilder und Figuren.

## Tech Stack

- **Next.js 14** (App Router)
- **Tailwind CSS**
- **React Three Fiber** + Drei (interaktiver 3D-Viewer)
- **Zustand** (Warenkorb mit Persistenz)
- **Lucide React** (Icons)

## Features

- Dunkles Premium-Design (Schwarz + Gold)
- Interaktiver 3D-Viewer auf Start- und Produktseiten
- Produktkatalog mit Kategorie-Filtern (Schilder, Figuren, Horror, Meme)
- Produkt-Detailseiten
- Warenkorb + einfacher Demo-Checkout
- Responsive (Mobile + Desktop)
- Platzhalter-Bilder (picsum.photos) – später durch echte Produktfotos ersetzen

## Starten

```bash
cd eliteform42
npm install
npm run dev
```

Öffne [http://localhost:3000](http://localhost:3000).

## Struktur

```
src/
├── app/
│   ├── page.tsx              # Startseite + 3D-Viewer
│   ├── products/
│   │   ├── page.tsx          # Katalog + Filter
│   │   └── [id]/page.tsx    # Detailseite
│   ├── cart/page.tsx         # Warenkorb
│   └── checkout/page.tsx     # Checkout
├── components/
│   ├── Header.tsx
│   ├── Footer.tsx
│   ├── ProductCard.tsx
│   └── Scene3D.tsx           # React Three Fiber Viewer
├── lib/products.ts           # Produktdaten
├── store/cart.ts             # Zustand Cart Store
└── types/product.ts
```

## Nächste Schritte

1. Echte Produktfotos in `public/products/` legen und in `lib/products.ts` referenzieren
2. Optional: echte 3D-Modelle (.glb) mit `useGLTF` von drei laden
3. Backend / Stripe für echten Checkout anbinden
