'use client'

import { useRef, useState, useEffect } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import { motion, useInView } from 'framer-motion'
import {
  Play,
  FolderOpen,
  StickyNote,
  ShieldCheck,
  Share2,
  Palette,
  BookmarkPlus,
  LayoutGrid,
  Sparkles,
  ArrowRight,
  Star,
  Fingerprint,
  Search,
  Infinity,
  Layers,
  Zap,
  MousePointerClick,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import Navbar from '@/components/navbar'
import Footer from '@/components/footer'

/* ─── animation helpers ─── */
const fadeUp = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.8, ease: [0.22, 1, 0.36, 1] } },
}
const stagger = {
  visible: { transition: { staggerChildren: 0.1 } },
}
const scaleIn = {
  hidden: { opacity: 0, scale: 0.9 },
  visible: { opacity: 1, scale: 1, transition: { duration: 0.7, ease: [0.22, 1, 0.36, 1] } },
}

function Section({ children, className = '', id }: { children: React.ReactNode; className?: string; id?: string }) {
  const ref = useRef(null)
  const inView = useInView(ref, { once: true, margin: '-60px' })
  return (
    <motion.section
      ref={ref}
      id={id}
      initial="hidden"
      animate={inView ? 'visible' : 'hidden'}
      variants={stagger}
      className={className}
    >
      {children}
    </motion.section>
  )
}

/* ─── phone mockup ─── */
function PhoneMockup({ src, alt, size = 'md' }: { src: string; alt: string; size?: 'sm' | 'md' | 'lg' }) {
  const sizes = { sm: 'w-40 md:w-48', md: 'w-52 md:w-60', lg: 'w-60 md:w-72' }
  return (
    <div className={`${sizes[size]} mx-auto`}>
      <div className="phone-frame-apple">
        <Image src={src} alt={alt} width={300} height={650} className="w-full" />
      </div>
    </div>
  )
}

/* ─── app showcase carousel ─── */
const carouselImages = [
  '/images/mockups/vibe/home.png',
  '/images/mockups/air/koleksiyon.png',
  '/images/mockups/vibe/koleksiyon.png',
  '/images/mockups/air/home_feed.png',
  '/images/mockups/vibe/home_feed.png',
  '/images/mockups/air/search.png',
  '/images/mockups/vibe/tema.png',
  '/images/mockups/air/profil.png',
  '/images/mockups/vibe/koleksiyon_duzenle.png',
  '/images/mockups/air/login.png',
]

function AppShowcase() {
  const scrollRef = useRef<HTMLDivElement>(null)
  const [transforms, setTransforms] = useState<{ scale: number; opacity: number; y: number }[]>(
    carouselImages.map(() => ({ scale: 0.8, opacity: 0.35, y: 16 }))
  )

  useEffect(() => {
    const el = scrollRef.current
    if (!el) return
    let animId: number
    const speed = 0.6
    const itemW = 224

    const updateTransforms = () => {
      const center = el.scrollLeft + el.clientWidth / 2
      const newTransforms = [...carouselImages, ...carouselImages].map((_, i) => {
        const itemCenter = i * itemW + itemW / 2
        const dist = Math.abs(center - itemCenter)
        if (dist < itemW * 0.6) {
          return { scale: 1.15, opacity: 1, y: 0 }
        } else if (dist < itemW * 1.5) {
          return { scale: 0.85, opacity: 0.4, y: 12 }
        } else {
          return { scale: 0.75, opacity: 0.2, y: 20 }
        }
      })
      setTransforms(newTransforms)
    }

    const animate = () => {
      el.scrollLeft += speed
      const maxScroll = el.scrollWidth / 2
      if (el.scrollLeft >= maxScroll) {
        el.scrollLeft -= maxScroll
      }
      updateTransforms()
      animId = requestAnimationFrame(animate)
    }
    animId = requestAnimationFrame(animate)
    return () => cancelAnimationFrame(animId)
  }, [])

  const doubled = [...carouselImages, ...carouselImages]

  return (
    <Section id="ekranlar" className="py-32 bg-white overflow-hidden">
      <div className="max-w-6xl mx-auto px-6 sm:px-8">
        <motion.div variants={fadeUp} className="text-center mb-16">
          <p className="text-sm font-medium text-[#688E8B] uppercase tracking-widest mb-4">Uygulama Ekranları</p>
          <h2 className="text-4xl sm:text-5xl font-semibold text-gray-900 tracking-tight mb-4">
            Basit. Güçlü. Güzel.
          </h2>
          <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
            Somine&apos;nin her ekranı özenle tasarlandı. Kullanıcı dostu arayüz ile içeriklerini kolayca yönet.
          </p>
        </motion.div>

        <motion.div variants={fadeUp} className="relative">
          {/* Fade edges */}
          <div className="absolute left-0 top-0 bottom-0 w-24 bg-gradient-to-r from-white to-transparent z-10 pointer-events-none" />
          <div className="absolute right-0 top-0 bottom-0 w-24 bg-gradient-to-l from-white to-transparent z-10 pointer-events-none" />

          <div
            ref={scrollRef}
            className="flex gap-6 overflow-hidden py-8"
            style={{ scrollbarWidth: 'none' }}
          >
            {doubled.map((src, i) => {
              const t = transforms[i] || { scale: 0.75, opacity: 0.2, y: 20 }
              return (
                <div
                  key={`carousel-${i}`}
                  className="shrink-0 w-[180px] md:w-[200px] transition-transform duration-500 ease-out"
                  style={{
                    transform: `scale(${t.scale}) translateY(${t.y}px)`,
                    opacity: t.opacity,
                  }}
                >
                  <div style={{ borderRadius: '1.5rem', overflow: 'hidden' }}>
                    <Image
                      src={src}
                      alt={`Somine ekran ${(i % carouselImages.length) + 1}`}
                      width={200}
                      height={433}
                      className="w-full h-auto"
                    />
                  </div>
                </div>
              )
            })}
          </div>
        </motion.div>
      </div>
    </Section>
  )
}

/* ─── main page ─── */
export default function Home() {
  const heroRef = useRef(null)

  const features = [
    {
      icon: Play,
      title: 'Video Koleksiyonları',
      desc: 'YouTube videolarını doğrudan koleksiyonlarına ekle. Beğendiğin videoları tek bir yerde topla, istediğin zaman izle.',
      accent: '#6FBFAC',
    },
    {
      icon: FolderOpen,
      title: 'Akıllı Kategoriler',
      desc: 'Gitmek istediğin yerler, müzik, tarifler ve daha fazlası. Kendi kategorilerini oluştur, düzenli tut.',
      accent: '#95C5C1',
    },
    {
      icon: StickyNote,
      title: 'Kişisel Notlar',
      desc: 'Her içeriğe özel not ekle. Düşüncelerini ve hatırlatmalarını kaydet, arşivini zenginleştir.',
      accent: '#B8DDD9',
    },
    {
      icon: ShieldCheck,
      title: 'Gizli Kasa',
      desc: 'Apple/Google yeniden kimlik doğrulama ile korunan özel koleksiyonlar. En özel içeriklerini güvenle sakla.',
      accent: '#688E8B',
    },
    {
      icon: Share2,
      title: 'Kolay Paylaşım',
      desc: 'Koleksiyonlarını arkadaşlarınla tek tıkla paylaş. İçerikleri keşfet ve başkalarıyla paylaş.',
      accent: '#6FBFAC',
    },
    {
      icon: Palette,
      title: 'Premium Temalar',
      desc: 'Uygulamana özel görünüm kazandır. Farklı temalar ve ikonlarla kişiselleştir, tarzını yansıt.',
      accent: '#95C5C1',
    },
  ]

  const premiumFeatures = [
    { icon: Infinity, label: 'Sınırsız koleksiyon' },
    { icon: Fingerprint, label: 'FaceID gizli kasa' },
    { icon: Palette, label: 'Premium temalar' },
    { icon: Star, label: 'Özel koleksiyon ikonları' },
    { icon: Search, label: 'Akıllı arama' },
    { icon: Layers, label: 'Widget desteği' },
  ]

  return (
    <main className="min-h-screen">
      <Navbar />

      {/* ══════════ HERO ══════════ */}
      <section ref={heroRef} className="relative min-h-screen flex items-center overflow-hidden" style={{ background: 'linear-gradient(135deg, #688E8B 0%, #7AA39F 30%, #6FBFAC 60%, #8DD0C0 80%, #A8DDD0 100%)' }}>
        {/* Ambient glow */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-gradient-to-r from-[#95C5C1]/25 via-[#B8DDD9]/15 to-[#D4EDE9]/25 rounded-full blur-[120px]" style={{ animation: 'pulse-glow 6s ease-in-out infinite' }} />
          <div className="absolute top-[20%] left-[10%] w-[300px] h-[300px] bg-gradient-to-br from-[#95C5C1]/15 to-transparent rounded-full blur-[80px]" />
        </div>

        {/* Grid pattern overlay */}
        <div className="absolute inset-0 opacity-[0.03]" style={{ backgroundImage: 'radial-gradient(circle, #fff 1px, transparent 1px)', backgroundSize: '40px 40px' }} />

        {/* Floating particles */}
        <motion.div
          animate={{ y: [0, -25, 0], opacity: [0.3, 0.6, 0.3] }}
          transition={{ duration: 7, repeat: 9999, ease: 'easeInOut' }}
          className="absolute top-[18%] left-[12%] w-1.5 h-1.5 rounded-full bg-white/40 hidden lg:block"
        />
        <motion.div
          animate={{ y: [0, 18, 0], opacity: [0.2, 0.5, 0.2] }}
          transition={{ duration: 5, repeat: 9999, ease: 'easeInOut', delay: 1 }}
          className="absolute top-[35%] right-[18%] w-1 h-1 rounded-full bg-white/30 hidden lg:block"
        />
        <motion.div
          animate={{ y: [0, -15, 0], x: [0, 10, 0] }}
          transition={{ duration: 9, repeat: 9999, ease: 'easeInOut', delay: 2 }}
          className="absolute bottom-[30%] left-[25%] w-2 h-2 rounded-full bg-white/20 hidden lg:block"
        />
        <motion.div
          animate={{ y: [0, 20, 0], x: [0, -8, 0] }}
          transition={{ duration: 11, repeat: 9999, ease: 'easeInOut', delay: 3 }}
          className="absolute top-[50%] right-[10%] w-1.5 h-1.5 rounded-full bg-white/30 hidden lg:block"
        />

        <div className="max-w-6xl mx-auto px-6 sm:px-8 w-full py-12 md:py-20 relative z-10">
          <div className="grid lg:grid-cols-2 gap-16 lg:gap-12 items-center">
            {/* Left: Text */}
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 1, ease: [0.22, 1, 0.36, 1] }}
              className="text-center lg:text-left"
            >
              <motion.h1
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3, duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
                className="text-5xl sm:text-6xl lg:text-7xl font-semibold text-white leading-[1.08] mb-8 tracking-tight"
              >
                Dijital Dünyanı{' '}
                <span className="bg-gradient-to-r from-white to-[#D4EDE9] bg-clip-text text-transparent">
                  Tasarla
                </span>
              </motion.h1>

              <motion.p
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5, duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
                className="text-lg sm:text-xl text-white max-w-lg mx-auto lg:mx-0 mb-10 leading-relaxed font-light"
              >
                Özenle sakla, keyifle paylaş! Videolar, linkler ve ilham kaynaklarını kişisel koleksiyonlarında organize et.
              </motion.p>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.7, duration: 0.6 }}
                className="flex flex-col sm:flex-row items-center gap-4 justify-center lg:justify-start"
              >
                <motion.a
                  href="https://apps.apple.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  whileHover={{ scale: 1.04, y: -2 }}
                  whileTap={{ scale: 0.98 }}
                  className="inline-flex items-center gap-3 bg-white text-[#1a3b38] text-base font-medium px-7 py-3.5 rounded-full shadow-[0_0_40px_rgba(255,255,255,0.15)] hover:shadow-[0_0_60px_rgba(255,255,255,0.25)] transition-shadow"
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                  </svg>
                  <div className="text-left">
                    <div className="text-[10px] opacity-50 leading-none font-normal">İndir</div>
                    <div className="font-semibold leading-tight text-sm">App Store</div>
                  </div>
                </motion.a>

                <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                  <Link href="/#ozellikler">
                    <Button
                      variant="outline"
                      size="lg"
                      className="rounded-full bg-white/[0.08] border-white/[0.15] text-white/80 hover:bg-white/[0.15] hover:text-white hover:border-white/[0.25] gap-2 backdrop-blur-sm font-medium"
                    >
                      Özellikleri Keşfet
                      <ArrowRight className="w-4 h-4" />
                    </Button>
                  </Link>
                </motion.div>
              </motion.div>

              {/* Stats */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.9, duration: 0.6 }}
                className="flex items-center gap-10 mt-12 justify-center lg:justify-start"
              >
                {[
                  { value: '1K+', label: 'Kullanıcı' },
                  { value: '50K+', label: 'İçerik' },
                  { value: '4.8', label: 'Puan' },
                ].map((stat, i) => (
                  <motion.div
                    key={stat.label}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ delay: 1.0 + i * 0.1 }}
                    className="text-center"
                  >
                    <div className="text-xl font-semibold text-white">{stat.value}</div>
                    <div className="text-xs text-white/40 mt-0.5">{stat.label}</div>
                  </motion.div>
                ))}
              </motion.div>
            </motion.div>

            {/* Right: Phone mockup */}
            <motion.div
              initial={{ opacity: 0, y: 60, scale: 0.9 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 1.2, delay: 0.4, ease: [0.22, 1, 0.36, 1] }}
              className="flex justify-center lg:justify-end"
            >
              <div className="relative">
                {/* Glow behind phone */}
                <div className="absolute inset-0 bg-gradient-to-b from-[#95C5C1]/25 via-[#B8DDD9]/10 to-transparent rounded-[3rem] blur-3xl scale-110" />

                {/* Orbiting ring */}
                <motion.div
                  animate={{ rotate: 360 }}
                  transition={{ duration: 25, repeat: 9999, ease: 'linear' }}
                  className="absolute -inset-10 rounded-full border border-white/[0.08]"
                />

                <div className="relative animate-float">
                  <PhoneMockup src="/images/mockups/vibe/home.png" alt="Somine Ana Sayfa" size="lg" />
                </div>
              </div>
            </motion.div>
          </div>
        </div>

        {/* Scroll indicator */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 2 }}
          className="absolute bottom-10 left-1/2 -translate-x-1/2 z-10"
        >
          <motion.div
            animate={{ y: [0, 6, 0] }}
            transition={{ repeat: 9999, duration: 2.5, ease: 'easeInOut' }}
            className="flex flex-col items-center gap-2"
          >
            <span className="text-[11px] text-white/30 uppercase tracking-widest">Keşfet</span>
            <div className="w-5 h-8 rounded-full border border-white/15 flex items-start justify-center pt-1.5">
              <motion.div
                animate={{ opacity: [0.5, 0], y: [0, 6] }}
                transition={{ repeat: 9999, duration: 2.5 }}
                className="w-1 h-1 rounded-full bg-white/50"
              />
            </div>
          </motion.div>
        </motion.div>
      </section>

      {/* ══════════ FEATURES BENTO ══════════ */}
      <Section id="ozellikler" className="py-32 bg-[#E8F1EF]">
        <div className="max-w-6xl mx-auto px-6 sm:px-8">
          <motion.div variants={fadeUp} className="text-center mb-20">
            <p className="text-sm font-medium text-[#688E8B] uppercase tracking-widest mb-4">Özellikler</p>
            <h2 className="text-4xl sm:text-5xl font-semibold text-gray-900 tracking-tight mb-4">
              Her Şeyi Tek Bir Yerde Topla
            </h2>
            <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
              Somine ile dijital hayatını organize et. İçeriklerini kaydet, kategorize et ve istediğin zaman eriş.
            </p>
          </motion.div>

          <motion.div variants={stagger} className="grid grid-cols-1 md:grid-cols-3 gap-5">
            {features.map((f) => (
              <motion.div
                key={f.title}
                variants={fadeUp}
                whileHover={{ y: -4 }}
                transition={{ type: 'spring', stiffness: 300, damping: 25 }}
                className="group relative rounded-2xl border border-gray-100 bg-white p-8 hover:border-[#D4EDE9] hover:shadow-[0_8px_40px_rgba(104,142,139,0.08)] transition-all duration-500"
              >
                <div
                  className="w-16 h-16 rounded-2xl flex items-center justify-center mb-6"
                  style={{ background: `linear-gradient(135deg, ${f.accent}, #B8DDD9)` }}
                >
                  <f.icon className="w-7 h-7 text-white" />
                </div>
                <h3 className="text-base font-semibold text-gray-900 mb-2">{f.title}</h3>
                <p className="text-gray-500 text-sm leading-relaxed">{f.desc}</p>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </Section>

      {/* ══════════ APP SHOWCASE ══════════ */}
      <AppShowcase />

      {/* ══════════ HOW IT WORKS ══════════ */}
      <Section id="nasil-calisir" className="py-32 bg-[#E8F1EF]">
        <div className="max-w-6xl mx-auto px-6 sm:px-8">
          <motion.div variants={fadeUp} className="text-center mb-20">
            <p className="text-sm font-medium text-[#688E8B] uppercase tracking-widest mb-4">Nasıl Çalışır</p>
            <h2 className="text-4xl sm:text-5xl font-semibold text-gray-900 tracking-tight mb-4">
              Tek Tıkla Koleksiyonuna Ekle
            </h2>
            <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
              Herhangi bir uygulamadan içeriklerini Somine koleksiyonlarına kaydetmek sadece 3 adım — hiçbir şey kopyalayıp yapıştırmaya gerek yok.
            </p>
          </motion.div>

          {/* Steps with connecting line */}
          <div className="relative">
            {/* Connecting line — Segment 1 (desktop) */}
            <div className="hidden md:block absolute top-[4.5rem] left-[22%] w-[23%] h-[2px] overflow-hidden">
              <div className="absolute inset-0 bg-[#D4EDE9]" />
              <div
                className="absolute inset-y-[-5px] w-[35%] animate-glow-seg1"
                style={{ background: 'linear-gradient(90deg, transparent, rgba(111,191,172,0.5), transparent)', filter: 'blur(4px)' }}
              />
              <div
                className="absolute inset-y-0 w-[25%] animate-pulse-seg1"
                style={{ background: 'linear-gradient(90deg, transparent, #6FBFAC, #6FBFAC, transparent)' }}
              />
            </div>
            {/* Connecting line — Segment 2 (desktop) */}
            <div className="hidden md:block absolute top-[4.5rem] left-[55%] w-[23%] h-[2px] overflow-hidden">
              <div className="absolute inset-0 bg-[#D4EDE9]" />
              <div
                className="absolute inset-y-[-5px] w-[35%] animate-glow-seg2"
                style={{ background: 'linear-gradient(90deg, transparent, rgba(111,191,172,0.5), transparent)', filter: 'blur(4px)' }}
              />
              <div
                className="absolute inset-y-0 w-[25%] animate-pulse-seg2"
                style={{ background: 'linear-gradient(90deg, transparent, #6FBFAC, #6FBFAC, transparent)' }}
              />
            </div>

            <motion.div variants={stagger} className="grid grid-cols-1 md:grid-cols-3 gap-10 md:gap-6">
              {[
                {
                  icon: Share2,
                  title: 'Platformtan Paylaş',
                  desc: 'Desteklediğimiz platformlardan share (paylaş) seçimi yap.',
                  num: '01',
                },
                {
                  icon: MousePointerClick,
                  title: 'Somine\'ye Tıkla',
                  desc: 'Çıkan uygulama listesinden Somine logosuna tıkla.',
                  num: '02',
                },
                {
                  icon: BookmarkPlus,
                  title: 'Koleksiyona Ekle',
                  desc: '"Koleksiyona Ekle" ile içeriğini kaydet — İşte bu kadar kolay!',
                  num: '03',
                },
              ].map((step, idx) => (
                <motion.div
                  key={step.title}
                  variants={fadeUp}
                  className="relative text-center group"
                >
                  {/* Step circle with icon */}
                  <div
                    className="relative inline-flex items-center justify-center mb-8 animate-step-bounce"
                    style={{ animationDelay: `${idx * 1.5}s` }}
                  >
                    {/* Number badge */}
                    <span
                      className="absolute -top-3 -right-3 w-8 h-8 rounded-full text-white text-xs font-bold flex items-center justify-center z-10 shadow-md"
                      style={{ background: 'linear-gradient(135deg, #688E8B, #6FBFAC)' }}
                    >
                      {step.num}
                    </span>

                    {/* Icon container */}
                    <div
                      className="w-[7.5rem] h-[7.5rem] rounded-2xl flex items-center justify-center group-hover:scale-105 transition-transform duration-300 shadow-lg"
                      style={{ background: 'linear-gradient(135deg, #688E8B, #6FBFAC)' }}
                    >
                      <step.icon className="w-10 h-10 text-white" />
                    </div>
                  </div>

                  <h3 className="text-lg font-semibold text-[#688E8B] mb-2">{step.title}</h3>
                  <p className="text-gray-500 text-sm leading-relaxed max-w-[250px] mx-auto">
                    {step.desc}
                  </p>

                  {/* Mobile connector */}
                  {idx < 2 && (
                    <div className="md:hidden flex justify-center my-4">
                      <div className="relative w-[2px] h-8 overflow-hidden">
                        <div className="absolute inset-0 bg-gradient-to-b from-[#B8DDD9] to-transparent" />
                        <div
                          className="absolute inset-x-0 h-[40%] animate-electric-pulse-v"
                          style={{ background: 'linear-gradient(180deg, transparent, #6FBFAC, transparent)' }}
                        />
                      </div>
                    </div>
                  )}
                </motion.div>
              ))}
            </motion.div>
          </div>
        </div>
      </Section>

      {/* ══════════ THEMES SHOWCASE ══════════ */}
      <Section id="temalar" className="py-32 bg-[#FAFAFA] overflow-hidden">
        <div className="max-w-6xl mx-auto px-6 sm:px-8">
          <motion.div variants={fadeUp} className="text-center mb-20">
            <p className="text-sm font-medium text-gray-400 uppercase tracking-widest mb-4">Premium Temalar</p>
            <h2 className="text-4xl sm:text-5xl font-semibold text-gray-900 tracking-tight mb-4">
              Kendi Tarzını Yansıt
            </h2>
            <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
              Air&apos;ın sadeliğinden Vibe&apos;ın enerjisine kadar her zevke uygun premium temalar. Uygulamana özel bir görünüm kazandır.
            </p>
          </motion.div>

          <motion.div variants={stagger} className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Air Theme */}
            <motion.div
              variants={fadeUp}
              whileHover={{ y: -8 }}
              transition={{ type: 'spring', stiffness: 300, damping: 25 }}
              className="group rounded-2xl overflow-hidden bg-white border border-gray-100 hover:shadow-[0_20px_60px_rgba(0,0,0,0.08)] transition-all duration-500"
            >
              <div className="aspect-[9/16] relative">
                <div className="absolute inset-0 bg-gradient-to-b from-[#D4E8E4] to-[#E8F1EF]" />
                <div className="absolute inset-0 flex flex-col items-center justify-center p-8 gap-4">
                  <div className="w-full flex flex-col items-center gap-3 bg-gradient-to-br from-[#688E8B] to-[#6FBFAC] rounded-2xl py-5 px-4 shadow-md">
                    <div className="w-14 h-14 rounded-xl bg-white/20 flex items-center justify-center backdrop-blur-sm">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                        <circle cx="12" cy="12" r="4" />
                        <path d="M12 2v2" /><path d="M12 20v2" />
                        <path d="m4.93 4.93 1.41 1.41" /><path d="m17.66 17.66 1.41 1.41" />
                        <path d="M2 12h2" /><path d="M20 12h2" />
                        <path d="m6.34 17.66-1.41 1.41" /><path d="m19.07 4.93-1.41 1.41" />
                      </svg>
                    </div>
                    <div className="text-center">
                      <p className="text-lg font-semibold text-white">Air</p>
                      <p className="text-xs text-white/70">Minimalist & Ferah</p>
                    </div>
                  </div>
                  <div className="w-full space-y-2.5 mt-2">
                    <div className="h-3 rounded-md bg-[#688E8B]/20 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer rounded-md" /></div>
                    <div className="h-3 rounded-md bg-[#688E8B]/20 w-4/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer rounded-md" style={{ animationDelay: '0.3s' }} /></div>
                    <div className="h-3 rounded-md bg-[#95C5C1]/25 w-3/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer rounded-md" style={{ animationDelay: '0.6s' }} /></div>
                    <div className="h-8 rounded-md bg-[#688E8B]/15 w-2/5 mt-3 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer rounded-md" style={{ animationDelay: '0.9s' }} /></div>
                  </div>
                </div>
              </div>
              <div className="p-5 border-t border-[#D4E8E4] bg-[#E8F1EF]">
                <p className="font-semibold text-[#2D312F] text-sm">Air Teması</p>
                <p className="text-xs text-[#636E72] mt-0.5">Açık renkler, sade tasarım</p>
              </div>
            </motion.div>

            {/* Midnight Theme */}
            <motion.div
              variants={fadeUp}
              whileHover={{ y: -8 }}
              transition={{ type: 'spring', stiffness: 300, damping: 25 }}
              className="group rounded-2xl overflow-hidden bg-white border border-gray-100 hover:shadow-[0_20px_60px_rgba(0,0,0,0.08)] transition-all duration-500"
            >
              <div className="aspect-[9/16] relative">
                <div className="absolute inset-0 bg-gradient-to-b from-[#1E1E1E] to-[#121212]" />
                <div className="absolute inset-0 flex flex-col items-center justify-center p-8 gap-4">
                  <div className="w-full flex flex-col items-center gap-3 bg-gradient-to-br from-[#2DD4BF] to-[#0EA5E9] rounded-2xl py-5 px-4 shadow-md">
                    <div className="w-14 h-14 rounded-xl bg-white/20 flex items-center justify-center backdrop-blur-sm">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z" />
                      </svg>
                    </div>
                    <div className="text-center">
                      <p className="text-lg font-semibold text-white">Midnight</p>
                      <p className="text-xs text-white/70">Karanlık & Şık</p>
                    </div>
                  </div>
                  <div className="w-full space-y-2.5 mt-2">
                    <div className="h-3 rounded-md bg-white/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" /></div>
                    <div className="h-3 rounded-md bg-white/5 w-4/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.3s' }} /></div>
                    <div className="h-3 rounded-md bg-white/5 w-3/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.6s' }} /></div>
                    <div className="h-8 rounded-md bg-white/3 w-2/5 mt-3 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.9s' }} /></div>
                  </div>
                </div>
              </div>
              <div className="p-5 bg-[#1E1E1E] border-t border-white/5">
                <p className="font-semibold text-[#F1F5F9] text-sm">Midnight Teması</p>
                <p className="text-xs text-[#94A3B8] mt-0.5">Koyu tonlar, göz dostu</p>
              </div>
            </motion.div>

            {/* Vibe Theme */}
            <motion.div
              variants={fadeUp}
              whileHover={{ y: -8 }}
              transition={{ type: 'spring', stiffness: 300, damping: 25 }}
              className="group rounded-2xl overflow-hidden bg-white border border-gray-100 hover:shadow-[0_20px_60px_rgba(0,0,0,0.08)] transition-all duration-500"
            >
              <div className="aspect-[9/16] relative">
                <div className="absolute inset-0 bg-gradient-to-b from-[#2A3A4A] to-[#1A2A3A]" />
                <div className="absolute inset-0 flex flex-col items-center justify-center p-8 gap-4">
                  <div className="w-full flex flex-col items-center gap-3 bg-gradient-to-br from-[#E86B8A] to-[#5A8AB5] rounded-2xl py-5 px-4 shadow-md">
                    <div className="w-14 h-14 rounded-xl bg-white/20 flex items-center justify-center backdrop-blur-sm">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                      </svg>
                    </div>
                    <div className="text-center">
                      <p className="text-lg font-semibold text-white">Vibe</p>
                      <p className="text-xs text-white/70">Enerjik & Cesur</p>
                    </div>
                  </div>
                  <div className="w-full space-y-2.5 mt-2">
                    <div className="h-3 rounded-md bg-white/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" /></div>
                    <div className="h-3 rounded-md bg-white/5 w-4/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.3s' }} /></div>
                    <div className="h-3 rounded-md bg-white/5 w-3/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.6s' }} /></div>
                    <div className="h-8 rounded-md bg-white/3 w-2/5 mt-3 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.9s' }} /></div>
                  </div>
                </div>
              </div>
              <div className="p-5 bg-[#1A2A3A] border-t border-[#E86B8A]/10">
                <p className="font-semibold text-[#F5F5F5] text-sm">Vibe Teması</p>
                <p className="text-xs text-[#B0C0C8] mt-0.5">Pembe-mavi gradient, enerjik</p>
              </div>
            </motion.div>
          </motion.div>

          <motion.div variants={fadeUp} className="text-center mt-14">
            <p className="text-sm text-gray-400">
              Premium&apos;a geçerek tüm temalara ve özel uygulama ikonlarına eriş
            </p>
          </motion.div>
        </div>
      </Section>

      {/* ══════════ PREMIUM ══════════ */}
      <Section id="premium" className="py-32 bg-[#0A0A0A] relative overflow-hidden">
        {/* Ambient glow */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-gradient-to-r from-[#95C5C1]/8 to-[#D4EDE9]/5 rounded-full blur-[100px]" />
        </div>

        <div className="max-w-6xl mx-auto px-6 sm:px-8 relative z-10">
          <motion.div variants={fadeUp} className="text-center mb-20">
            <p className="text-sm font-medium text-gray-500 uppercase tracking-widest mb-4">Premium</p>
            <h2 className="text-4xl sm:text-5xl lg:text-6xl font-semibold text-white tracking-tight mb-4">
              Sınırları{' '}
              <span className="bg-gradient-to-r from-[#95C5C1] to-[#D4EDE9] bg-clip-text text-transparent">Kaldır</span>
            </h2>
            <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
              Premium ile Somine&apos;yi tam potansiyeliyle kullan. Sınırsız koleksiyon, özel güvenlik ve çok daha fazlası.
            </p>
          </motion.div>

          {/* Features grid */}
          <motion.div
            variants={stagger}
            className="grid grid-cols-2 md:grid-cols-3 gap-3 max-w-2xl mx-auto mb-20"
          >
            {premiumFeatures.map((pf) => (
              <motion.div
                key={pf.label}
                variants={fadeUp}
                className="flex items-center gap-3 bg-white/[0.03] border border-white/[0.06] rounded-xl p-4 hover:bg-white/[0.06] transition-colors"
              >
                <pf.icon className="w-4 h-4 text-[#95C5C1] shrink-0" />
                <span className="text-sm text-gray-400">{pf.label}</span>
              </motion.div>
            ))}
          </motion.div>

          {/* Pricing cards */}
          <motion.div variants={stagger} className="grid grid-cols-1 sm:grid-cols-2 gap-5 max-w-xl mx-auto">
            {/* Weekly */}
            <motion.div
              variants={scaleIn}
              className="rounded-2xl border border-white/[0.08] bg-white/[0.02] p-8 text-center hover:border-white/[0.12] transition-colors"
            >
              <p className="text-sm text-gray-500 mb-3">Haftalık</p>
              <div className="flex items-baseline justify-center gap-1 mb-1">
                <span className="text-4xl font-semibold text-white">$0</span>
                <span className="text-2xl font-semibold text-white">.99</span>
              </div>
              <p className="text-xs text-gray-600 mb-8">haftada bir</p>
              <a
                href="https://apps.apple.com"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2 w-full text-sm font-medium bg-white/[0.06] border border-white/[0.08] text-white rounded-full px-6 py-3 hover:bg-white/[0.1] transition-colors"
              >
                <Zap className="w-4 h-4" />
                Denemek İçin Tıkla
              </a>
            </motion.div>

            {/* Monthly - Popular */}
            <motion.div
              variants={scaleIn}
              className="rounded-2xl border border-[#95C5C1]/20 bg-[#95C5C1]/[0.04] p-8 text-center relative"
            >
              <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                <span className="inline-flex items-center gap-1.5 bg-[#95C5C1] text-white text-[11px] font-medium rounded-full px-3 py-1">
                  <Star className="w-3 h-3" />
                  Popüler
                </span>
              </div>
              <p className="text-sm text-gray-500 mb-3">Aylık</p>
              <div className="flex items-baseline justify-center gap-1 mb-1">
                <span className="text-4xl font-semibold text-white">$1</span>
                <span className="text-2xl font-semibold text-white">.99</span>
              </div>
              <p className="text-xs text-gray-600 mb-8">ayda bir · %50 tasarruf</p>
              <a
                href="https://apps.apple.com"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2 w-full text-sm font-medium bg-white text-black rounded-full px-6 py-3 hover:bg-gray-100 transition-colors"
              >
                Premium&apos;a Geç
              </a>
            </motion.div>
          </motion.div>
        </div>
      </Section>

      {/* ══════════ CTA ══════════ */}
      <Section className="py-32 bg-[#0A0A0A] relative overflow-hidden">
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-[1000px] h-[400px] bg-gradient-to-t from-[#95C5C1]/10 to-transparent rounded-full blur-[80px]" />
        </div>

        <div className="max-w-4xl mx-auto px-6 sm:px-8 text-center relative z-10">
          <motion.div variants={fadeUp}>
            <motion.h2
              variants={fadeUp}
              className="text-4xl sm:text-5xl lg:text-6xl font-semibold text-white tracking-tight mb-6"
            >
              Hemen Başla
            </motion.h2>
            <motion.p
              variants={fadeUp}
              className="text-lg text-gray-500 max-w-xl mx-auto mb-12 leading-relaxed"
            >
              Dijital dünyanı Somine ile tasarla. Ücretsiz indir ve hemen koleksiyonlarına içerik eklemeye başla.
            </motion.p>
            <motion.div variants={fadeUp}>
              <motion.a
                href="https://apps.apple.com"
                target="_blank"
                rel="noopener noreferrer"
                whileHover={{ scale: 1.04, y: -2 }}
                whileTap={{ scale: 0.98 }}
                className="inline-flex items-center gap-3 bg-white text-black text-lg font-medium px-8 py-4 rounded-full shadow-[0_0_40px_rgba(255,255,255,0.08)] hover:shadow-[0_0_60px_rgba(255,255,255,0.12)] transition-shadow"
              >
                <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
                <div className="text-left">
                  <div className="text-[11px] opacity-50 leading-none font-normal">Ücretsiz İndir</div>
                  <div className="font-semibold leading-tight text-sm">App Store</div>
                </div>
              </motion.a>
            </motion.div>
          </motion.div>
        </div>
      </Section>

      <Footer />
    </main>
  )
}
