'use client'

import Image from 'next/image'
import Link from 'next/link'

const footerLinks = {
  uygulama: [
    { href: '/#ozellikler', label: 'Özellikler' },
    { href: '/#premium', label: 'Premium' },
    { href: '/#ekranlar', label: 'Ekranlar' },
  ],
  yasal: [
    { href: '/privacy', label: 'Gizlilik Politikası' },
    { href: '/terms', label: 'Kullanım Şartları' },
    { href: '/delete-account', label: 'Hesap Silme' },
  ],
  destek: [
    { href: '/support', label: 'Sıkça Sorulan Sorular' },
    { href: '/support', label: 'Bize Ulaşın' },
    { href: 'mailto:support@somineapp.com', label: 'support@somineapp.com' },
  ],
}

export default function Footer() {
  return (
    <footer className="bg-[#688E8B] border-t border-white/[0.08]">
      <div className="max-w-6xl mx-auto px-6 sm:px-8 py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-12">
          {/* Brand */}
          <div className="lg:col-span-2">
            <Link href="/" className="inline-block mb-3">
              <Image
                src="/images/logo.png"
                alt="Somine"
                width={110}
                height={34}
                className="object-contain brightness-0 invert"
              />
            </Link>
            <p className="text-white/70 text-sm leading-relaxed max-w-xs">
              Somine ile dijital içeriklerini özenle sakla, keyifle paylaş!
              Videolar, linkler ve görsellerini kişisel koleksiyonlarında organize et.
            </p>
          </div>

          {/* App Links */}
          <div>
            <h3 className="text-[11px] font-semibold text-white/80 mb-4 uppercase tracking-widest">
              Uygulama
            </h3>
            <ul className="space-y-3">
              {footerLinks.uygulama.map((link) => (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="text-sm text-white/60 hover:text-white transition-colors duration-300"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Legal Links */}
          <div>
            <h3 className="text-[11px] font-semibold text-white/80 mb-4 uppercase tracking-widest">
              Yasal
            </h3>
            <ul className="space-y-3">
              {footerLinks.yasal.map((link) => (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="text-sm text-white/60 hover:text-white transition-colors duration-300"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Support Links */}
          <div>
            <h3 className="text-[11px] font-semibold text-white/80 mb-4 uppercase tracking-widest">
              Destek
            </h3>
            <ul className="space-y-3">
              {footerLinks.destek.map((link) => (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="text-sm text-white/60 hover:text-white transition-colors duration-300"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Bottom */}
        <div className="mt-16 pt-8 border-t border-white/[0.06] flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-xs text-white/50">
            © 2026 Somine. Tüm hakları saklıdır.
          </p>
          <div className="flex items-center gap-6">
            <Link
              href="/privacy"
              className="text-xs text-white/50 hover:text-white transition-colors duration-300"
            >
              Gizlilik
            </Link>
            <Link
              href="/terms"
              className="text-xs text-white/50 hover:text-white transition-colors duration-300"
            >
              Şartlar
            </Link>
            <Link
              href="/delete-account"
              className="text-xs text-white/50 hover:text-white transition-colors duration-300"
            >
              Hesap Silme
            </Link>
          </div>
        </div>
      </div>
    </footer>
  )
}
