import Link from 'next/link'
import { Trash2, AlertTriangle, Smartphone, X } from 'lucide-react'
import Navbar from '@/components/navbar'
import Footer from '@/components/footer'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Hesap Silme | Somine',
  description: 'Somine uygulamasında hesap silme işlemi hakkında detaylı bilgi edinin.',
}

const deleteSteps = [
  'So Mine uygulamasını açın',
  'Alt menüden Profil sekmesine gidin',
  'Hesap Bilgileri bölümüne tıklayın',
  'En altta "Hesabımı Sil" seçeneğine dokunun',
  'Onay diyalogunda "Sil" butonuna basın',
]

const deletedData = [
  { label: 'Kaydettiğiniz tüm içerikler (linkler, notlar)', status: 'Kalıcı olarak silinir' },
  { label: 'Oluşturduğunuz koleksiyonlar ve kategoriler', status: 'Kalıcı olarak silinir' },
  { label: 'Profil bilgileriniz (ad, kullanıcı adı, fotoğraf)', status: 'Kalıcı olarak silinir' },
  { label: 'Firebase Authentication hesabınız', status: 'Kalıcı olarak silinir' },
  { label: 'Google/Apple oturum bağlantıları', status: 'Kaldırılır' },
]

export default function HesapSilme() {
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
            <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-red-400 to-red-500 flex items-center justify-center shadow-lg">
              <Trash2 className="w-7 h-7 text-white" />
            </div>
            <div>
              <h1 className="text-3xl sm:text-4xl font-bold text-somine-text">
                Hesap Silme
              </h1>
              <p className="text-somine-gray text-sm mt-1">
                Hesabınızı kalıcı olarak silme hakkında bilgi
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Content */}
      <section className="flex-1 bg-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="prose prose-slate max-w-none space-y-8">

            {/* How to delete */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-6 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center">
                  <Smartphone className="w-4 h-4" />
                </span>
                Hesabınızı Nasıl Silebilirsiniz?
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">Adımlar:</p>
              <div className="space-y-3">
                {deleteSteps.map((text, i) => (
                  <div
                    key={i}
                    className="flex items-start gap-4 bg-somine-bg rounded-xl p-4 border border-gray-100"
                  >
                    <span className="w-8 h-8 rounded-full bg-gradient-to-br from-turquoise to-turquoise-dark text-white text-sm font-bold flex items-center justify-center shrink-0">
                      {i + 1}
                    </span>
                    <p className="text-somine-gray text-sm pt-1">{text}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* What gets deleted */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-6 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-red-50 text-red-500 flex items-center justify-center">
                  <Trash2 className="w-4 h-4" />
                </span>
                Silme İşleminde Neler Kaldırılır?
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">
                Hesabınız silindiğinde aşağıdaki tüm veriler kalıcı olarak kaldırılır:
              </p>
              <div className="bg-red-50/50 rounded-2xl border border-red-100 overflow-hidden">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-red-100">
                      <th className="text-left text-sm font-semibold text-somine-text px-5 py-3">Veri</th>
                      <th className="text-left text-sm font-semibold text-somine-text px-5 py-3">Durum</th>
                    </tr>
                  </thead>
                  <tbody>
                    {deletedData.map((item, i) => (
                      <tr key={i} className="border-b border-red-100/50 last:border-0">
                        <td className="text-sm text-somine-gray px-5 py-3">{item.label}</td>
                        <td className="text-sm px-5 py-3">
                          <span className="inline-flex items-center gap-1.5 text-red-500">
                            <X className="w-3.5 h-3.5" />
                            {item.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Warning */}
            <div className="bg-amber-50 rounded-2xl p-6 border border-amber-200">
              <div className="flex items-start gap-3">
                <AlertTriangle className="w-6 h-6 text-amber-500 shrink-0 mt-0.5" />
                <div>
                  <h3 className="text-lg font-semibold text-amber-800 mb-2">
                    Önemli Bilgiler
                  </h3>
                  <ul className="space-y-3 text-amber-700 text-sm leading-relaxed">
                    <li className="flex items-start gap-2">
                      <span className="w-1.5 h-1.5 rounded-full bg-amber-500 mt-1.5 shrink-0" />
                      Bu işlem geri alınamaz.
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="w-1.5 h-1.5 rounded-full bg-amber-500 mt-1.5 shrink-0" />
                      Aktif bir aboneliğiniz varsa, hesabınızı silmeden önce aboneliğinizi Ayarlar &gt; Apple Kimliği &gt; Abonelikler bölümünden iptal etmeniz önerilir. Aksi takdirde abonelik otomatik yenilenmeye devam edebilir.
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="w-1.5 h-1.5 rounded-full bg-amber-500 mt-1.5 shrink-0" />
                      Silme işlemi anında gerçekleşir; ek bir bekleme süresi yoktur.
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            {/* Contact */}
            <div className="bg-gradient-to-br from-turquoise/5 to-turquoise-dark/5 rounded-2xl p-6 border border-turquoise/10">
              <h3 className="text-lg font-semibold text-somine-text mb-3">
                Yardıma mı İhtiyacınız Var?
              </h3>
              <p className="text-somine-gray text-sm leading-relaxed">
                Hesap silme süreciyle ilgili herhangi bir sorunuz veya yardıma
                ihtiyacınız varsa, bizimle iletişime geçmekten çekinmeyin.
              </p>
              <div className="flex flex-col sm:flex-row gap-3 mt-4">
                <a
                  href="mailto:support@somineapp.com?subject=Hesap%20Silme%20Talebi"
                  className="inline-flex items-center gap-2 bg-turquoise text-white rounded-xl px-5 py-2.5 text-sm font-medium hover:opacity-90 transition-opacity"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75" />
                  </svg>
                  support@somineapp.com
                </a>
                <Link
                  href="/support"
                  className="inline-flex items-center gap-2 bg-white rounded-xl px-5 py-2.5 text-sm font-medium text-turquoise-dark border border-turquoise/20 hover:bg-turquoise/5 transition-colors"
                >
                  Destek Sayfasına Git
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
