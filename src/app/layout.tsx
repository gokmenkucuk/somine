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
  title: "Somine — Dijital Dünyanı Tasarla",
  description:
    "Somine ile dijital içeriklerini özenle sakla, keyifle paylaş! Video, link ve görsellerini kişisel koleksiyonlarında organize et.",
  keywords: [
    "Somine", "içerik koleksiyonlama", "video kaydet", "link koleksiyonu",
    "dijital düzen", "YouTube entegrasyonu", "kişisel koleksiyon",
    "mobil uygulama", "iOS uygulama",
  ],
  authors: [{ name: "Somine" }],
  icons: {
    icon: "/images/logo-gradient.png",
    apple: "/images/logo-gradient.png",
  },
  openGraph: {
    title: "Somine — Dijital Dünyanı Tasarla",
    description: "Video, link ve görsellerini özenle sakla, keyifle paylaş!",
    url: "https://somineapp.com",
    siteName: "Somine",
    type: "website",
    locale: "tr_TR",
    images: [{ url: "/images/logo-gradient.png", width: 512, height: 512, alt: "Somine App" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "Somine — Dijital Dünyanı Tasarla",
    description: "Video, link ve görsellerini özenle sakla, keyifle paylaş!",
    images: ["/images/logo-gradient.png"],
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="tr" suppressHydrationWarning>
      <body className={`${outfit.variable} ${poppins.variable} antialiased bg-background text-foreground`}>
        {children}
        <Toaster />
      </body>
    </html>
  );
}
