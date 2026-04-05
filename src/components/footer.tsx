'use client'

import Image from 'next/image'
import Link from 'next/link'

const footerLinks = {
  uygulama: [
    { href: '/#ozellikler', label: 'Özellikler' },
    { href: '/#premium', label: 'Premium' },
    { href: '/#ekranlar', label: 'Ekranlar' },
    { href: '/#nasil-calisir', label: 'Nasıl Çalışır' },
  ],
  yasal: [
    { href: '/privacy', label: 'Gizlilik Politikası' },
    { href: '/terms', label: 'Kullanım Şartları' },
    { href: '/delete-account', label: 'Hesap Silme' },
  ],
  destek: [
    { href: '/support', label: 'Sıkça Sorulan Sorular' },
    { href: 'mailto:support@somineapp.com', label: 'Bize Ulaşın' },
  ],
}

export default function Footer() {
  return (
    <footer className="bg-[#688E8B] border-t border-white/[0.08]">
      <div className="max-w-6xl mx-auto px-6 sm:px-8 py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-12">

          {/* Brand */}
          <div className="lg:col-span-2">
            <Link href="/" className="inline-block mb-4">
              <Image
                src="/images/logo.png"
                alt="Somine"
                width={110}
                height={34}
                className="object-contain brightness-0 invert"
              />
            </Link>
            <p className="text-white/50 text-sm leading-relaxed max-w-xs mb-6">
              Beğendiğin içerikleri tek bir yerde topla. Platform fark etmez — Somine hepsini bir araya getirir.
            </p>

            {/* Social */}
            <div className="flex items-center gap-3">
              <a
                href="https://instagram.com"
                target="_blank"
                rel="noopener noreferrer"
                className="w-9 h-9 rounded-full bg-white/[0.04] border border-white/[0.08] flex items-center justify-center text-white/50 hover:text-white hover:border-white/[0.2] transition-all duration-300"
              >
                <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M7.8 2h8.4C19.4 2 22 4.6 22 7.8v8.4a5.8 5.8 0 0 1-5.8 5.8H7.8C4.6 22 2 19.4 2 16.2V7.8A5.8 5.8 0 0 1 7.8 2m-.2 2A3.6 3.6 0 0 0 4 7.6v8.8C4 18.39 5.61 20 7.6 20h8.8a3.6 3.6 0 0 0 3.6-3.6V7.6C20 5.61 18.39 4 16.4 4H7.6m9.65 1.5a1.25 1.25 0 0 1 1.25 1.25A1.25 1.25 0 0 1 17.25 8 1.25 1.25 0 0 1 16 6.75a1.25 1.25 0 0 1 1.25-1.25M12 7a5 5 0 0 1 5 5 5 5 0 0 1-5 5 5 5 0 0 1-5-5 5 5 0 0 1 5-5m0 2a3 3 0 0 0-3 3 3 3 0 0 0 3 3 3 3 0 0 0 3-3 3 3 0 0 0-3-3z" />
                </svg>
              </a>
            </div>
          </div>

          {/* App Links */}
          <div>
            <h3 className="text-[11px] font-semibold text-white/40 mb-4 uppercase tracking-widest">
              Uygulama
            </h3>
            <ul className="space-y-3">
              {footerLinks.uygulama.map((link) => (
                <li key={link.label}>
                  <Link href={link.href} className="text-sm text-white/50 hover:text-white transition-colors duration-300">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Legal Links */}
          <div>
            <h3 className="text-[11px] font-semibold text-white/40 mb-4 uppercase tracking-widest">
              Yasal
            </h3>
            <ul className="space-y-3">
              {footerLinks.yasal.map((link) => (
                <li key={link.label}>
                  <Link href={link.href} className="text-sm text-white/50 hover:text-white transition-colors duration-300">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Support Links */}
          <div>
            <h3 className="text-[11px] font-semibold text-white/40 mb-4 uppercase tracking-widest">
              Destek
            </h3>
            <ul className="space-y-3">
              {footerLinks.destek.map((link) => (
                <li key={link.label}>
                  <Link href={link.href} className="text-sm text-white/50 hover:text-white transition-colors duration-300">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

        </div>

        {/* Bottom */}
        <div className="mt-16 pt-8 border-t border-white/[0.06] flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-xs text-white/30">
            © 2026 Somine. Tüm hakları saklıdır.
          </p>
          <div className="flex items-center gap-6">
            <a
              href="https://apps.apple.com"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 bg-white/[0.12] border border-white/[0.15] text-white text-xs font-medium px-4 py-2 rounded-full hover:bg-white/[0.2] transition-colors duration-300"
            >
              <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
              </svg>
              App Store&apos;dan İndir
            </a>
            <Link href="/privacy" className="text-xs text-white/50 hover:text-white transition-colors duration-300">
              Gizlilik
            </Link>
            <Link href="/terms" className="text-xs text-white/50 hover:text-white transition-colors duration-300">
              Şartlar
            </Link>
          </div>
        </div>

      </div>
    </footer>
  )
}
