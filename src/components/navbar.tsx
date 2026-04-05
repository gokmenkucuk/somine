'use client'

import { useState, useEffect } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import { Menu } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
  SheetClose,
} from '@/components/ui/sheet'

const navLinks = [
  { href: '/#ozellikler', label: 'Özellikler' },
  { href: '/#ekranlar', label: 'Ekranlar' },
  { href: '/#temalar', label: 'Temalar' },
  { href: '/#premium', label: 'Premium' },
]

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 60)
    }
    window.addEventListener('scroll', handleScroll, { passive: true })
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ease-out ${
        scrolled
          ? 'bg-white/80 backdrop-blur-2xl shadow-[0_1px_3px_rgba(0,0,0,0.06)] border-b border-black/[0.04]'
          : 'bg-transparent'
      }`}
    >
      <div className="max-w-6xl mx-auto px-6 sm:px-8">
        <div className="flex items-center justify-between h-14">
          {/* Logo */}
          <Link href="/" className="relative z-50">
            <Image
              src="/images/logo.png"
              alt="Somine"
              width={90}
              height={28}
              className="object-contain transition-all duration-500"
              style={scrolled ? {} : { filter: 'brightness(0) invert(1)' }}
            />
          </Link>

          {/* Desktop Nav Links */}
          <div className="hidden md:flex items-center gap-1">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={`px-4 py-2 text-[13px] font-medium transition-all duration-300 rounded-full ${
                  scrolled ? 'text-gray-600 hover:text-gray-900 hover:bg-black/[0.04]' : 'text-white/80 hover:text-white hover:bg-white/[0.08]'
                }`}
              >
                {link.label}
              </Link>
            ))}
          </div>

          {/* Desktop CTA */}
          <div className="hidden md:flex items-center gap-3">
            <Link href="/support">
              <Button
                variant="ghost"
                size="sm"
                className={`text-[13px] font-medium rounded-full transition-all duration-300 ${
                  scrolled ? 'text-gray-500 hover:text-gray-900 hover:bg-black/[0.04]' : 'text-white/70 hover:text-white hover:bg-white/[0.08]'
                }`}
              >
                Destek
              </Button>
            </Link>
            <a
              href="https://apps.apple.com"
              target="_blank"
              rel="noopener noreferrer"
              className={`inline-flex items-center gap-1.5 text-[13px] font-medium px-4 py-2 rounded-full transition-all duration-300 ${
                scrolled
                  ? 'bg-black text-white hover:bg-gray-800'
                  : 'bg-white/15 text-white border border-white/20 hover:bg-white/25 backdrop-blur-sm'
              }`}
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
              </svg>
              İndir
            </a>
          </div>

          {/* Mobile Menu */}
          <div className="md:hidden relative z-50">
            <Sheet>
              <SheetTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
                  className={`transition-colors duration-300 ${scrolled ? 'text-gray-900' : 'text-white'}`}
                >
                  <Menu className="size-5" />
                </Button>
              </SheetTrigger>
              <SheetContent side="right" className="w-80 bg-white/95 backdrop-blur-2xl p-0 border-l border-black/[0.04]">
                <SheetHeader className="p-6 pb-4 border-b border-gray-100">
                  <SheetTitle className="flex items-center">
                    <Image
                      src="/images/logo.png"
                      alt="Somine"
                      width={80}
                      height={24}
                      className="object-contain"
                    />
                  </SheetTitle>
                </SheetHeader>
                <div className="flex flex-col gap-1 p-4">
                  {navLinks.map((link) => (
                    <SheetClose key={link.href} asChild>
                      <Link
                        href={link.href}
                        className="flex items-center px-4 py-3 text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-xl transition-colors"
                      >
                        {link.label}
                      </Link>
                    </SheetClose>
                  ))}
                  <div className="h-px bg-gray-100 my-2" />
                  <SheetClose asChild>
                    <Link href="/privacy" className="flex items-center px-4 py-3 text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-xl transition-colors">Gizlilik Politikası</Link>
                  </SheetClose>
                  <SheetClose asChild>
                    <Link href="/terms" className="flex items-center px-4 py-3 text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-xl transition-colors">Kullanım Şartları</Link>
                  </SheetClose>
                  <SheetClose asChild>
                    <Link href="/support" className="flex items-center px-4 py-3 text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-xl transition-colors">Destek</Link>
                  </SheetClose>
                </div>
                <div className="p-4 mt-auto">
                  <a href="https://apps.apple.com" target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 justify-center w-full text-sm font-medium bg-black text-white rounded-full px-6 py-3 hover:bg-gray-800 transition-colors">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" /></svg>
                    App Store&apos;dan İndir
                  </a>
                </div>
              </SheetContent>
            </Sheet>
          </div>
        </div>
      </div>
    </nav>
  )
}
