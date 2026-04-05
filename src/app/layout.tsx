import type { Metadata } from "next";
import { Outfit, Poppins } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";

const outfit = Outfit({
  variable: "--font-outfit",
  subsets: ["latin"],
  display: "swap",
});

const poppins = Poppins({
  variable: "--font-poppins",
  weight: ["300", "400", "500", "600", "700"],
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://somineapp.com"),
  title: {
    default: "Somine — Dijital Dünyanı Tasarla",
    template: "%s | Somine",
  },
  description:
    "Somine ile sevdiğin platformların içerikleri ile web linklerini kişisel koleksiyonlarında organize ederek tek bir yerden yönet. Özenle sakla, keyifle paylaş!",
  keywords: [
    "Somine", "içerik koleksiyonlama", "video kaydet", "link koleksiyonu",
    "dijital düzen", "YouTube kaydet", "Instagram kaydet", "kişisel koleksiyon",
    "mobil uygulama", "iOS uygulama", "bookmark manager", "içerik organize",
    "Pinterest alternatif", "link yönetimi", "koleksiyon uygulaması",
  ],
  authors: [{ name: "Somine", url: "https://somineapp.com" }],
  creator: "Somine",
  category: "Productivity",
  icons: {
    icon: "/images/logo.png",
    apple: "/images/logo.png",
  },
  manifest: "/manifest.json",
  alternates: {
    canonical: "https://somineapp.com",
  },
  openGraph: {
    title: "Somine — Dijital Dünyanı Tasarla",
    description: "Sevdiğin platformların içerikleri ile web linklerini kişisel koleksiyonlarında organize ederek tek bir yerden yönet.",
    url: "https://somineapp.com",
    siteName: "Somine",
    type: "website",
    locale: "tr_TR",
    images: [{ url: "/images/logo-gradient.png", width: 512, height: 512, alt: "Somine App" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "Somine — Dijital Dünyanı Tasarla",
    description: "Sevdiğin platformların içerikleri ile web linklerini kişisel koleksiyonlarında organize ederek tek bir yerden yönet.",
    images: ["/images/logo-gradient.png"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: { index: true, follow: true, "max-video-preview": -1, "max-image-preview": "large", "max-snippet": -1 },
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="tr" suppressHydrationWarning>
      <body className={`${outfit.variable} ${poppins.variable} antialiased bg-[#688E8B] text-foreground`}>
        {children}
        <Toaster />
      </body>
    </html>
  );
}
