import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        foreground: "var(--foreground)",
        gold: {
          50: "#FBF6E9",
          100: "#F5E9C8",
          200: "#EBD28F",
          300: "#E0B85A",
          400: "#D4A017",
          500: "#C9A227",
          600: "#A67C00",
          700: "#8B6914",
          800: "#6B5010",
          900: "#4A360B",
        },
        dark: {
          50: "#f7f7f7",
          100: "#e3e3e3",
          200: "#c8c8c8",
          300: "#a4a4a4",
          400: "#818181",
          500: "#666666",
          600: "#515151",
          700: "#434343",
          800: "#383838",
          900: "#1a1a1a",
          950: "#0a0a0a",
        },
      },
      fontFamily: {
        sans: ["var(--font-geist-sans)", "system-ui", "sans-serif"],
        mono: ["var(--font-geist-mono)", "monospace"],
      },
      boxShadow: {
        gold: "0 0 20px rgba(201, 162, 39, 0.3)",
        "gold-lg": "0 0 40px rgba(201, 162, 39, 0.4)",
      },
      animation: {
        "spin-slow": "spin 8s linear infinite",
        float: "float 6s ease-in-out infinite",
      },
      keyframes: {
        float: {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-10px)" },
        },
      },
    },
  },
  plugins: [],
};
export default config;
