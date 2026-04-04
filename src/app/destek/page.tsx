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
    question: 'Somine nedir?',
    answer:
      'Somine, dijital içeriklerinizi (videolar, linkler, görseller) kişisel koleksiyonlarda organize etmenizi sağlayan bir mobil uygulamadır. YouTube entegrasyonu, kategoriler, kişisel notlar ve paylaşım özellikleri ile içeriklerinizi kolayca yönetebilirsiniz.',
  },
  {
    question: 'Somine hangi platformlarda kullanılabilir?',
    answer:
      'Somine şu anda iOS platformunda (iPhone ve iPad) Apple App Store üzerinden kullanılabilmektedir. Android sürümü için çalışma devam etmektedir.',
  },
  {
    question: 'Uygulama ücretli mi?',
    answer:
      'Somine temel özellikleri ücretsiz olarak sunulmaktadır. Sınırsız koleksiyon, gizli kasa (FaceID/TouchID), premium temalar, özel ikonlar, akıllı arama ve widget gibi gelişmiş özellikler için Premium üyelik sunulmaktadır. Haftalık $0.99 veya aylık $1.99 seçenekleri mevcuttur.',
  },
  {
    question: 'Koleksiyonlarımı başkalarıyla paylaşabilir miyim?',
    answer:
      'Evet! Somine ile koleksiyonlarınızı arkadaşlarınızla tek tıkla paylaşabilirsiniz. Paylaşılan koleksiyonlar alıcı tarafından görüntülenebilir ve beğenebilir.',
  },
  {
    question: 'YouTube videolarını kaydedebilir miyim?',
    answer:
      'Evet, Somine YouTube entegrasyonu sayesinde beğendiğiniz YouTube videolarını doğrudan koleksiyonlarınıza ekleyebilirsiniz. Video bağlantısını yapıştırmanız yeterlidir, uygulama otomatik olarak video bilgilerini çeker.',
  },
  {
    question: 'Verilerim güvenli mi?',
    answer:
      'Evet, verilerinizin güvenliği bizim önceliğimizdir. Tüm veri iletişimleri SSL/TLS şifrelemesi ile korunmaktadır. Premium kullanıcılara özel FaceID/TouchID ile korunan gizli kasa özelliği mevcuttur. Detaylı bilgi için Gizlilik Politikası sayfamızı inceleyebilirsiniz.',
  },
  {
    question: 'Premium aboneliğimi nasıl iptal edebilirim?',
    answer:
      'Premium aboneliğinizi iOS Ayarlar > Apple ID > Abonelikler bölümünden iptal edebilirsiniz. İptal işlemi mevcut abonelik döneminin sonunda yürürlüğe girer.',
  },
  {
    question: 'Hesabımı nasıl silebilirim?',
    answer:
      'Hesabınızı Profil > Hesap Bilgileri > Hesabı Sil bölümünden silebilirsiniz. Alternatif olarak support@somineapp.com adresine e-posta göndererek hesap silme talebinde bulunabilirsiniz. Detaylı bilgi için Hesap Silme sayfamızı ziyaret edin.',
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
    // UI only - no backend
    setSubmitted(true)
  }

  return (
    <main className="min-h-screen flex flex-col">
      <Navbar />

      {/* Header */}
      <section className="bg-somine-bg pt-32 pb-16">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <Link
            href="/"
            className="inline-flex items-center gap-2 text-sm text-somine-gray hover:text-turquoise-dark transition-colors mb-6"
          >
            ← Ana Sayfaya Dön
          </Link>
          <div className="flex items-center gap-4 mb-4">
            <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-turquoise to-turquoise-dark flex items-center justify-center shadow-lg">
              <MessageCircle className="w-7 h-7 text-white" />
            </div>
            <div>
              <h1 className="text-3xl sm:text-4xl font-bold text-somine-text">
                Destek
              </h1>
              <p className="text-somine-gray text-sm mt-1">
                Sorularınız mı var? Yardımcı olmaktan memnuniyet duyarız.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Content */}
      <section className="flex-1 bg-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Quick contact */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-12">
            <div className="flex items-center gap-4 bg-somine-bg rounded-2xl p-5 border border-gray-100">
              <div className="w-12 h-12 rounded-xl bg-turquoise/10 flex items-center justify-center shrink-0">
                <Mail className="w-6 h-6 text-turquoise-dark" />
              </div>
              <div>
                <p className="font-semibold text-somine-text text-sm">E-posta</p>
                <a
                  href="mailto:support@somineapp.com"
                  className="text-somine-gray text-sm hover:text-turquoise-dark transition-colors"
                >
                  support@somineapp.com
                </a>
              </div>
            </div>
            <div className="flex items-center gap-4 bg-somine-bg rounded-2xl p-5 border border-gray-100">
              <div className="w-12 h-12 rounded-xl bg-turquoise/10 flex items-center justify-center shrink-0">
                <svg className="w-6 h-6 text-turquoise-dark" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                </svg>
              </div>
              <div>
                <p className="font-semibold text-somine-text text-sm">Yanıt Süresi</p>
                <p className="text-somine-gray text-sm">Genellikle 24 saat içinde</p>
              </div>
            </div>
          </div>

          {/* FAQ */}
          <div className="mb-16">
            <h2 className="text-2xl font-bold text-somine-text mb-6">
              Sıkça Sorulan Sorular
            </h2>
            <Accordion type="single" collapsible className="space-y-2">
              {faqItems.map((item, i) => (
                <AccordionItem
                  key={i}
                  value={`faq-${i}`}
                  className="bg-white rounded-xl border border-gray-100 px-6 data-[state=open]:shadow-sm transition-shadow"
                >
                  <AccordionTrigger className="text-left text-somine-text font-medium hover:text-turquoise-dark hover:no-underline">
                    {item.question}
                  </AccordionTrigger>
                  <AccordionContent className="text-somine-gray leading-relaxed">
                    {item.answer}
                  </AccordionContent>
                </AccordionItem>
              ))}
            </Accordion>
          </div>

          {/* Contact Form */}
          <div className="mb-8">
            <h2 className="text-2xl font-bold text-somine-text mb-6">
              Bize Ulaşın
            </h2>

            {submitted ? (
              <div className="bg-turquoise/5 rounded-2xl p-8 text-center border border-turquoise/10">
                <div className="w-16 h-16 rounded-full bg-turquoise/10 flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-turquoise-dark" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                  </svg>
                </div>
                <h3 className="text-lg font-semibold text-somine-text mb-2">
                  Mesajınız Alındı!
                </h3>
                <p className="text-somine-gray text-sm mb-6">
                  En kısa sürede size dönüş yapacağız. Teşekkür ederiz!
                </p>
                <Button
                  variant="outline"
                  onClick={() => {
                    setSubmitted(false)
                    setFormData({ name: '', email: '', message: '' })
                  }}
                  className="rounded-xl border-turquoise/20 text-turquoise-dark"
                >
                  Yeni Mesaj Gönder
                </Button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-5">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                  <div className="space-y-2">
                    <Label htmlFor="name" className="text-sm font-medium text-somine-text">
                      Adınız
                    </Label>
                    <Input
                      id="name"
                      placeholder="Adınızı giriniz"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      required
                      className="rounded-xl border-gray-200 focus:border-turquoise focus:ring-turquoise/20"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="email" className="text-sm font-medium text-somine-text">
                      E-posta Adresiniz
                    </Label>
                    <Input
                      id="email"
                      type="email"
                      placeholder="ornek@email.com"
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      required
                      className="rounded-xl border-gray-200 focus:border-turquoise focus:ring-turquoise/20"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="message" className="text-sm font-medium text-somine-text">
                    Mesajınız
                  </Label>
                  <Textarea
                    id="message"
                    placeholder="Mesajınızı buraya yazabilirsiniz..."
                    value={formData.message}
                    onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                    required
                    rows={6}
                    className="rounded-xl border-gray-200 focus:border-turquoise focus:ring-turquoise/20 resize-none"
                  />
                </div>
                <Button
                  type="submit"
                  className="bg-gradient-to-r from-turquoise to-turquoise-dark hover:opacity-90 text-white rounded-xl px-8"
                >
                  <Send className="w-4 h-4 mr-2" />
                  Mesaj Gönder
                </Button>
              </form>
            )}
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
