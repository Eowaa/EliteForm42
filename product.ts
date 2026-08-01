export type Category = "Schilder" | "Figuren" | "Horror" | "Meme";

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  category: Category;
  image: string;
  featured?: boolean;
  tags?: string[];
}

export interface CartItem {
  product: Product;
  quantity: number;
}
