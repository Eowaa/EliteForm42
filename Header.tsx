"use client";

import Link from "next/link";
import { ShoppingCart, Menu, X } from "lucide-react";
import { useCartStore } from "@/store/cart";
import { useState, useEffect } from "react";

export default function Header() {
  const itemCount = useCartStore((s) => s.totalItems());
  const [mounted, setMounted] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <header className="sticky top-0 z-50 glass border-b border-gold-500/20 pt-[env(safe-area-inset-top)]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16 md:h-20">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 group">
            <div className="relative">
              <span className="text-2xl md:text-3xl font-bold tracking-tight gold-text">
                EliteForm
              </span>
              <span className="absolute -top-1 -right-6 text-xs font-mono text-gold-400 opacity-80">
                42
              </span>
            </div>
          </Link>

          {/* Desktop Nav */}
          <nav className="hidden md:flex items-center gap-8">
            <Link
              href="/"
              className="text-sm font-medium text-gray-300 hover:text-gold-400 transition-colors"
            >
              Start
            </Link>
            <Link
              href="/products"
              className="text-sm font-medium text-gray-300 hover:text-gold-400 transition-colors"
            >
              Katalog
            </Link>
            <Link
              href="/cart"
              className="text-sm font-medium text-gray-300 hover:text-gold-400 transition-colors"
            >
              Warenkorb
            </Link>
          </nav>

          {/* Cart + Mobile */}
          <div className="flex items-center gap-4">
            <Link
              href="/cart"
              className="relative p-2 rounded-full hover:bg-gold-500/10 transition-colors group"
              aria-label="Warenkorb"
            >
              <ShoppingCart className="w-5 h-5 text-gray-300 group-hover:text-gold-400 transition-colors" />
              {mounted && itemCount > 0 && (
                <span className="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] flex items-center justify-center rounded-full bg-gold-500 text-dark-950 text-[10px] font-bold">
                  {itemCount}
                </span>
              )}
            </Link>

            <button
              className="md:hidden p-2 rounded-full hover:bg-gold-500/10"
              onClick={() => setMobileOpen(!mobileOpen)}
              aria-label="Menü"
            >
              {mobileOpen ? (
                <X className="w-5 h-5 text-gray-300" />
              ) : (
                <Menu className="w-5 h-5 text-gray-300" />
              )}
            </button>
          </div>
        </div>

        {/* Mobile Nav */}
        {mobileOpen && (
          <nav className="md:hidden pb-4 flex flex-col gap-3 border-t border-gold-500/10 pt-4">
            <Link
              href="/"
              onClick={() => setMobileOpen(false)}
              className="text-sm font-medium text-gray-300 hover:text-gold-400 py-2"
            >
              Start
            </Link>
            <Link
              href="/products"
              onClick={() => setMobileOpen(false)}
              className="text-sm font-medium text-gray-300 hover:text-gold-400 py-2"
            >
              Katalog
            </Link>
            <Link
              href="/cart"
              onClick={() => setMobileOpen(false)}
              className="text-sm font-medium text-gray-300 hover:text-gold-400 py-2"
            >
              Warenkorb
            </Link>
          </nav>
        )}
      </div>
    </header>
  );
}
