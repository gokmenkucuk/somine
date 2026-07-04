'use client'

import { useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { Send, Mail, MessageCircle, ChevronDown } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion'
import Navbar from '@/components/navbar'
import Footer from '@/components/footer'

const faqItems = [
  {
    question: 'Somine nasıl çalışır?',
    answer:
      'Somine, Instagram, YouTube, Pinterest ve diğer platformlardaki beğendiğin içerikleri tek bir yerde toplamanı sağlar. Herhangi bir uygulamada paylaş butonuna basıp Somine\'yi seçmen yeterli — içerik orijinal haliyle platforma bağlı kalır, kopyalanmaz.',
  },
  {
    question: 'Koleksiyonlar nasıl oluşturulur?',
    answer:
      'Koleksiyonlar sekmesinde sağ üstteki + butonuna basarak yeni koleksiyon oluşturabilirsiniz. Koleksiyonlarınıza isim ve ikon atayabilirsiniz.',
  },
  {
    question: 'Ücretsiz sürümde neler var?',
    answer:
      'Ücretsiz sürümde 10 koleksiyon ve koleksiyon başına 5 içerik ekleyebilirsin. Gizli Kasa (Face ID/Touch ID), bulut senkronizasyonu, koleksiyon paylaşımı ve Air teması tamamen ücretsizdir.',
  },
  {
    question: 'Premium ile ne değişiyor?',
    answer:
      'Premium ile koleksiyon ve içerik sınırı kalkar, sınırsız ekleyebilirsin. Ayrıca 5 özel ana ekran uygulama ikonu, Midnight ve Vibe temaları Premium\'a özeldir.',
  },
  {
    question: 'Gizli Kasa nasıl çalışır?',
    answer:
      'Gizli Kasa tamamen ücretsizdir. Sadece senin görmeni istediğin içerikler için Face ID veya Touch ID ile korunan özel bir alan oluşturur.',
  },
  {
    question: 'Koleksiyonumu arkadaşımla nasıl paylaşırım?',
    answer:
      'Koleksiyon detay sayfasında paylaş butonuna basarak arkadaşının kullanıcı adı veya e-postasını girebilirsin. Arkadaşın kabul ettiği anda koleksiyon direkt onun kütüphanesine eklenir.',
  },
]

export default function Destek() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    message: '',
  })
  const [submitted, setSubmitted] = useState(false)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const subject = encodeURIComponent(`Somine Destek - ${formData.name}`)
    const body = encodeURIComponent(`Ad: ${formData.name}\nE-posta: ${formData.email}\n\n${formData.message}`)
    window.location.href = `mailto:support@somineapp.com?subject=${subject}&body=${body}`
    setSubmitted(true)
  }

  return (
    <main className="min-h-screen flex flex-col bg-white">
      <Navbar />

      <section className="pt-32 pb-16 bg-[#E8F1EF]">
        <div className="max-w-4xl mx-auto px-6 sm:px-8">
          <Link href="/" className="inline-flex items-center gap-2 text-sm text-[#688E8B] hover:text-[#4a6e6b] transition-colors mb-8">
            ← Ana Sayfaya Dön
          </Link>
          <p className="text-sm font-medium text-[#688E8B] uppercase tracking-widest mb-3">Destek</p>
          <h1 className="text-4xl sm:text-5xl font-semibold text-gray-900 tracking-tight mb-3">
            Nasıl yardımcı olabiliriz?
          </h1>
          <p className="text-gray-500 text-lg">
            Somine hakkında aklına takılan her şeyi sor.
          </p>
        </div>
      </section>

      <section className="flex-1 bg-white">
        <div className="max-w-4xl mx-auto px-6 sm:px-8 py-16">

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-16">
            <div className="flex items-center gap-4 bg-[#F4F9F8] rounded-2xl p-5 border border-[#E8F1EF]">
              <div className="w-11 h-11 rounded-xl bg-[#688E8B]/10 flex items-center justify-center shrink-0">
                <Mail className="w-5 h-5 text-[#688E8B]" />
              </div>
              <div>
                <p className="font-medium text-gray-800 text-sm mb-0.5">E-posta</p>
                <a href="mailto:support@somineapp.com" className="text-[#688E8B] text-sm hover:underline">
                  support@somineapp.com
                </a>
              </div>
            </div>
            <div className="flex items-center gap-4 bg-[#F4F9F8] rounded-2xl p-5 border border-[#E8F1EF]">
              <div className="w-11 h-11 rounded-xl bg-[#688E8B]/10 flex items-center justify-center shrink-0">
                <svg className="w-5 h-5 text-[#688E8B]" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                </svg>
              </div>
              <div>
                <p className="font-medium text-gray-800 text-sm mb-0.5">Yanıt Süresi</p>
                <p className="text-gray-500 text-sm">Genellikle 24 saat içinde</p>
              </div>
            </div>
          </div>

          <div className="mb-20">
            <h2 className="text-2xl font-semibold text-gray-900 tracking-tight mb-8">
              Sıkça Sorulan Sorular
            </h2>
            <Accordion type="single" collapsible className="space-y-3">
              {faqItems.map((item, i) => (
                <AccordionItem
                  key={i}
                  value={`faq-${i}`}
                  className="bg-white rounded-2xl border border-gray-100 px-6 data-[state=open]:border-[#688E8B]/20 data-[state=open]:shadow-sm transition-all"
                >
                  <AccordionTrigger className="text-left text-gray-800 font-medium hover:text-[#688E8B] hover:no-underline py-5">
                    {item.question}
                  </AccordionTrigger>
                  <AccordionContent className="text-gray-500 leading-relaxed pb-5">
                    {item.answer}
                  </AccordionContent>
                </AccordionItem>
              ))}
            </Accordion>
          </div>

          <div>
            <h2 className="text-2xl font-semibold text-gray-900 tracking-tight mb-2">
              Bize Ulaşın
            </h2>
            <p className="text-gray-500 mb-8">Formu doldur, mail uygulamanla gönder.</p>

            {submitted ? (
              <div className="bg-[#E8F1EF] rounded-2xl p-10 text-center border border-[#688E8B]/15">
                <div className="w-14 h-14 rounded-full bg-[#688E8B]/15 flex items-center justify-center mx-auto mb-4">
                  <svg className="w-7 h-7 text-[#688E8B]" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                  </svg>
                </div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">Mail uygulaması açıldı!</h3>
                <p className="text-gray-500 text-sm mb-6">Bilgilerin otomatik dolduruldu. Gönder butonuna basman yeterli.</p>
                <button
                  onClick={() => { setSubmitted(false); setFormData({ name: '', email: '', message: '' }) }}
                  className="text-sm text-[#688E8B] hover:underline"
                >
                  Yeni mesaj oluştur
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-5">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                  <div className="space-y-2">
                    <Label htmlFor="name" className="text-sm font-medium text-gray-700">Adınız</Label>
                    <Input
                      id="name"
                      placeholder="Adınızı giriniz"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      required
                      className="rounded-xl border-gray-200 focus:border-[#688E8B] focus:ring-[#688E8B]/20 h-11"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="email" className="text-sm font-medium text-gray-700">E-posta</Label>
                    <Input
                      id="email"
                      type="email"
                      placeholder="ornek@email.com"
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      required
                      className="rounded-xl border-gray-200 focus:border-[#688E8B] focus:ring-[#688E8B]/20 h-11"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="message" className="text-sm font-medium text-gray-700">Mesajınız</Label>
                  <Textarea
                    id="message"
                    placeholder="Mesajınızı buraya yazabilirsiniz..."
                    value={formData.message}
                    onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                    required
                    rows={6}
                    className="rounded-xl border-gray-200 focus:border-[#688E8B] focus:ring-[#688E8B]/20 resize-none"
                  />
                </div>
                <button
                  type="submit"
                  className="inline-flex items-center gap-2 bg-[#688E8B] hover:bg-[#5a7e7b] text-white text-sm font-medium px-7 py-3 rounded-full transition-colors duration-300"
                >
                  <Send className="w-4 h-4" />
                  Mesaj Gönder
                </button>
              </form>
            )}
          </div>

        </div>
      </section>

      <Footer />
    </main>
  )
}
