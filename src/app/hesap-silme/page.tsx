import Link from 'next/link'
import { ShieldCheck, Trash2, AlertTriangle, Mail, Smartphone, Clock } from 'lucide-react'
import Navbar from '@/components/navbar'
import Footer from '@/components/footer'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Hesap Silme | Somine',
  description: 'Somine uygulamasında hesap silme işlemi hakkında detaylı bilgi edinin.',
}

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

            {/* Warning */}
            <div className="bg-amber-50 rounded-2xl p-6 border border-amber-200">
              <div className="flex items-start gap-3">
                <AlertTriangle className="w-6 h-6 text-amber-500 shrink-0 mt-0.5" />
                <div>
                  <h3 className="text-lg font-semibold text-amber-800 mb-1">
                    Önemli Uyarı
                  </h3>
                  <p className="text-amber-700 text-sm leading-relaxed">
                    Hesap silme işlemi geri alınamaz. Hesabınızı sildiğinizde tüm
                    verileriniz kalıcı olarak silinecektir. Bu işlemi gerçekleştirmeden
                    önce lütfen dikkatlice okuyunuz.
                  </p>
                </div>
              </div>
            </div>

            {/* How to delete from app */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center">
                  <Smartphone className="w-4 h-4" />
                </span>
                Uygulama İçinden Hesap Silme
              </h2>
              <p className="text-somine-gray leading-relaxed mb-6">
                Hesabınızı Somine uygulaması içinden kolayca silebilirsiniz. Aşağıdaki
                adımları izleyin:
              </p>
              <div className="space-y-4">
                {[
                  { step: '1', text: 'Somine uygulamasını açın ve profilinize gidin.' },
                  { step: '2', text: 'Profil sayfasında "Hesap Bilgileri" bölümüne dokunun.' },
                  { step: '3', text: '"Hesabı Sil" seçeneğine dokunun.' },
                  { step: '4', text: 'Güvenlik doğrulamasını tamamlayın (Apple/Google yeniden kimlik doğrulama).' },
                  { step: '5', text: 'Onay mesajını okuyup "Hesabımı Sil" butonuna dokunun.' },
                ].map((item) => (
                  <div
                    key={item.step}
                    className="flex items-start gap-4 bg-somine-bg rounded-xl p-4 border border-gray-100"
                  >
                    <span className="w-8 h-8 rounded-full bg-gradient-to-br from-turquoise to-turquoise-dark text-white text-sm font-bold flex items-center justify-center shrink-0">
                      {item.step}
                    </span>
                    <p className="text-somine-gray text-sm pt-1">{item.text}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Delete via email */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center">
                  <Mail className="w-4 h-4" />
                </span>
                E-posta ile Hesap Silme
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">
                Uygulamaya erişiminiz yoksa veya uygulama içinden hesap silme
                işlemini gerçekleştiremiyorsanız, e-posta ile hesap silme talebinde
                bulunabilirsiniz:
              </p>
              <div className="bg-somine-bg rounded-2xl p-6 border border-gray-100">
                <p className="text-somine-gray text-sm leading-relaxed mb-4">
                  <strong className="text-somine-text">support@somineapp.com</strong> adresine
                  aşağıdaki bilgileri içeren bir e-posta gönderin:
                </p>
                <ul className="space-y-2 text-somine-gray text-sm">
                  <li className="flex items-start gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-1.5 shrink-0" />
                    Kayıtlı e-posta adresiniz
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-1.5 shrink-0" />
                    Hesap silme talebinizi belirten açık bir ifade
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-1.5 shrink-0" />
                    İsteğe bağlı: Silme nedeniniz (geri bildirim)
                  </li>
                </ul>
                <a
                  href="mailto:support@somineapp.com?subject=Hesap%20Silme%20Talebi"
                  className="inline-flex items-center gap-2 mt-4 bg-turquoise text-white rounded-xl px-5 py-2.5 text-sm font-medium hover:opacity-90 transition-opacity"
                >
                  <Mail className="w-4 h-4" />
                  E-posta Gönder
                </a>
              </div>
            </div>

            {/* What happens */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center">
                  <ShieldCheck className="w-4 h-4" />
                </span>
                Hesap Silindiğinde Ne Olur?
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">
                Hesap silme işlemi tamamlandığında aşağıdaki işlemler
                gerçekleştirilir:
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="bg-red-50 rounded-xl p-4 border border-red-100">
                  <h4 className="font-semibold text-red-700 text-sm mb-3">Kalıcı Olarak Silinen Veriler</h4>
                  <ul className="space-y-2 text-red-600 text-sm">
                    <li className="flex items-center gap-2">
                      <Trash2 className="w-3.5 h-3.5" />
                      Profil bilgileri
                    </li>
                    <li className="flex items-center gap-2">
                      <Trash2 className="w-3.5 h-3.5" />
                      Tüm koleksiyonlar
                    </li>
                    <li className="flex items-center gap-2">
                      <Trash2 className="w-3.5 h-3.5" />
                      Eklenen içerikler ve notlar
                    </li>
                    <li className="flex items-center gap-2">
                      <Trash2 className="w-3.5 h-3.5" />
                      Paylaşım geçmişi
                    </li>
                    <li className="flex items-center gap-2">
                      <Trash2 className="w-3.5 h-3.5" />
                      Premium üyelik bilgileri
                    </li>
                  </ul>
                </div>
                <div className="bg-somine-bg rounded-xl p-4 border border-gray-100">
                  <h4 className="font-semibold text-somine-text text-sm mb-3">İşlem Süreci</h4>
                  <ul className="space-y-2 text-somine-gray text-sm">
                    <li className="flex items-center gap-2">
                      <Clock className="w-3.5 h-3.5 text-turquoise" />
                      Talep işleme süresi: Anında
                    </li>
                    <li className="flex items-center gap-2">
                      <ShieldCheck className="w-3.5 h-3.5 text-turquoise" />
                      Veriler güvenli şekilde silinir
                    </li>
                    <li className="flex items-center gap-2">
                      <ShieldCheck className="w-3.5 h-3.5 text-turquoise" />
                      Üçüncü taraflarla paylaşılmaz
                    </li>
                    <li className="flex items-center gap-2">
                      <ShieldCheck className="w-3.5 h-3.5 text-turquoise" />
                      Yasal yükümlülükler hariç tutulur
                    </li>
                    <li className="flex items-center gap-2">
                      <ShieldCheck className="w-3.5 h-3.5 text-turquoise" />
                      KVKK kapsamında işlenir
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            {/* Important notes */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4">
                Önemli Notlar
              </h2>
              <ul className="space-y-3 text-somine-gray">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Geri alınamaz:</strong> Hesap silme
                    işlemi geri alınamaz. Silinen veriler kurtarılamaz.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Aktif abonelik:</strong> Premium
                    aboneliğiniz varsa, hesap silmeden önce Apple Abonelik ayarlarından
                    iptal etmeniz önerilir.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Paylaşılan koleksiyonlar:</strong>
                    Paylaştığınız koleksiyonlar, diğer kullanıcıların erişimi kalkmak üzere
                    anında kaldırılır.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Yasal saklama:</strong> Yasal
                    yükümlülükler doğrultusunda bazı veriler belirli bir süre saklanabilir.
                  </div>
                </li>
              </ul>
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
                  <Mail className="w-4 h-4" />
                  support@somineapp.com
                </a>
                <Link
                  href="/destek"
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
