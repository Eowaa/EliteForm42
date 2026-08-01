import Link from "next/link";

export default function Footer() {
  return (
    <footer className="border-t border-gold-500/20 mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <h3 className="text-lg font-bold gold-text mb-3">EliteForm42</h3>
            <p className="text-sm text-gray-400 leading-relaxed">
              Premium 3D-gedruckte humorvolle Schilder & Figuren.  
              Für Nerds, Memer und alle, die den Antwort-Code kennen.
            </p>
          </div>
          <div>
            <h4 className="text-sm font-semibold text-gold-400 mb-3 uppercase tracking-wider">
              Navigation
            </h4>
            <ul className="space-y-2 text-sm text-gray-400">
              <li>
                <Link href="/" className="hover:text-gold-300 transition-colors">
                  Startseite
                </Link>
              </li>
              <li>
                <Link
                  href="/products"
                  className="hover:text-gold-300 transition-colors"
                >
                  Produktkatalog
                </Link>
              </li>
              <li>
                <Link
                  href="/cart"
                  className="hover:text-gold-300 transition-colors"
                >
                  Warenkorb
                </Link>
              </li>
            </ul>
          </div>
          <div>
            <h4 className="text-sm font-semibold text-gold-400 mb-3 uppercase tracking-wider">
              Info
            </h4>
            <p className="text-sm text-gray-400">
              Alle Produkte werden in Deutschland mit hochwertigem PLA gedruckt.
              <br />
              <span className="text-gold-500/80 mt-2 inline-block">
                Die Antwort ist 42.
              </span>
            </p>
          </div>
        </div>
        <div className="mt-10 pt-6 border-t border-gold-500/10 text-center text-xs text-gray-500">
          © {new Date().getFullYear()} EliteForm42 · Made with ☕ & Filament
        </div>
      </div>
    </footer>
  );
}
