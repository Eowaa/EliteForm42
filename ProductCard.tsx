"use client";

import Link from "next/link";
import Image from "next/image";
import { ShoppingCart } from "lucide-react";
import { Product } from "@/types/product";
import { useCartStore } from "@/store/cart";
import { useState } from "react";

interface ProductCardProps {
  product: Product;
}

export default function ProductCard({ product }: ProductCardProps) {
  const addItem = useCartStore((s) => s.addItem);
  const [added, setAdded] = useState(false);

  const handleAdd = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    addItem(product);
    setAdded(true);
    setTimeout(() => setAdded(false), 1500);
  };

  return (
    <Link
      href={`/products/${product.id}`}
      className="group relative flex flex-col bg-dark-900/60 rounded-2xl overflow-hidden gold-border hover:border-gold-500/50 transition-all duration-300 hover:shadow-gold"
    >
      {/* Image */}
      <div className="relative aspect-square overflow-hidden bg-dark-800">
        <Image
          src={product.image}
          alt={product.name}
          fill
          sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 25vw"
          className="object-cover transition-transform duration-500 group-hover:scale-105"
          unoptimized
        />
        <div className="absolute inset-0 bg-gradient-to-t from-dark-950/80 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
        <span className="absolute top-3 left-3 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wider rounded-full bg-dark-950/80 text-gold-400 border border-gold-500/30">
          {product.category}
        </span>
      </div>

      {/* Content */}
      <div className="flex flex-col flex-1 p-4">
        <h3 className="text-sm font-semibold text-gray-100 group-hover:text-gold-300 transition-colors line-clamp-2">
          {product.name}
        </h3>
        <p className="mt-1 text-xs text-gray-500 line-clamp-2 flex-1">
          {product.description}
        </p>
        <div className="mt-4 flex items-center justify-between gap-2">
          <span className="text-lg font-bold gold-text">
            {product.price.toFixed(2).replace(".", ",")} €
          </span>
          <button
            onClick={handleAdd}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
              added
                ? "bg-gold-500 text-dark-950"
                : "bg-gold-500/10 text-gold-400 hover:bg-gold-500 hover:text-dark-950 border border-gold-500/30"
            }`}
          >
            <ShoppingCart className="w-3.5 h-3.5" />
            {added ? "Hinzugefügt" : "In den Warenkorb"}
          </button>
        </div>
      </div>
    </Link>
  );
}
