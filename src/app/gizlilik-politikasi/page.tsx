import Image from 'next/image'
import Link from 'next/link'
import Navbar from '@/components/navbar'
import Footer from '@/components/footer'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Gizlilik Politikası | Somine',
  description: 'Somine uygulamasının gizlilik politikası ve veri işleme uygulamaları hakkında bilgi edinin.',
}

export default function GizlilikPolitikasi() {
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
              <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z" />
              </svg>
            </div>
            <div>
              <h1 className="text-3xl sm:text-4xl font-bold text-somine-text">
                Gizlilik Politikası
              </h1>
              <p className="text-somine-gray text-sm mt-1">
                Son güncelleme: 1 Ocak 2026
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Content */}
      <section className="flex-1 bg-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="prose prose-slate max-w-none space-y-8">
            <p className="text-somine-gray leading-relaxed">
              Somine olarak kişisel verilerinizin güvenliği bizim için çok önemlidir.
              Bu Gizlilik Politikası, Somine mobil uygulamasını (&quot;Uygulama&quot;) kullanırken
              hangi verilerin toplandığını, nasıl kullanıldığını ve korunduğunu açıklamaktadır.
              Uygulamayı kullanarak bu politikayı kabul etmiş sayılırsınız.
            </p>

            <div className="bg-somine-bg rounded-2xl p-6 border border-turquoise/10">
              <h3 className="text-lg font-semibold text-somine-text mb-3">
                KVKK Uyarısı
              </h3>
              <p className="text-somine-gray text-sm leading-relaxed">
                Bu gizlilik politikası, 6698 sayılı Kişisel Verilerin Korunması Kanunu
                (KVKK) ve ilgili mevzuata uygun olarak hazırlanmıştır. Kişisel verileriniz,
                KVKK&apos;nın belirlediği ilkelere ve kurallara göre işlenmektedir.
              </p>
            </div>

            {/* Section 1 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">1</span>
                Toplanan Veriler
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">
                Somine uygulamasını kullanırken aşağıdaki verileri toplayabiliriz:
              </p>
              <ul className="space-y-3 text-somine-gray">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Hesap Bilgileri:</strong> Ad, e-posta adresi, profil fotoğrafı ve sosyal medya hesapları (Apple, Google) aracılığıyla sağlanan bilgiler.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Kullanım Verileri:</strong> Uygulama içindeki etkileşimler, oluşturulan koleksiyonlar, eklenen içerikler, tercih edilen kategoriler.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Cihaz Bilgileri:</strong> Cihaz türü, işletim sistemi sürümü, uygulama sürümü, benzersiz cihaz tanımlayıcısı.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Log Verileri:</strong> Uygulama kullanım istatistikleri, çökme raporları, performans verileri.
                  </div>
                </li>
              </ul>
            </div>

            {/* Section 2 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">2</span>
                Verilerin Kullanım Amacı
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">
                Toplanan veriler aşağıdaki amaçlarla kullanılmaktadır:
              </p>
              <ul className="space-y-3 text-somine-gray">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Uygulamanın temel işlevlerinin sağlanması ve koleksiyon yönetimi
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Kullanıcı deneyiminin iyileştirilmesi ve kişiselleştirilmesi
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Teknik sorunların giderilmesi ve uygulama güvenliğinin sağlanması
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Premium üyelik yönetimi ve faturalandırma işlemleri
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Yasal yükümlülüklerin yerine getirilmesi
                </li>
              </ul>
            </div>

            {/* Section 3 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">3</span>
                Çerezler ve Benzeri Teknolojiler
              </h2>
              <p className="text-somine-gray leading-relaxed">
                Somine uygulaması, kullanıcı deneyimini iyileştirmek amacıyla çerezler ve benzeri
                takip teknolojilerini kullanabilir. Bu teknolojiler, oturum bilgilerinizi hatırlamak,
                tercihlerinizi saklamak ve kullanım istatistikleri toplamak için kullanılır.
                Uygulama ayarlarınızdan çerez tercihlerinizi yönetebilirsiniz.
              </p>
            </div>

            {/* Section 4 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">4</span>
                Üçüncü Taraf Hizmetleri
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">
                Somine, aşağıdaki üçüncü taraf hizmetlerini kullanmaktadır:
              </p>
              <ul className="space-y-3 text-somine-gray">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Apple Sign-In:</strong> Kullanıcı girişi için Apple kimlik doğrulama hizmeti.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Google Sign-In:</strong> Kullanıcı girişi için Google kimlik doğrulama hizmeti.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Apple App Store:</strong> Premium üyelik satın alma işlemleri.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Crashlytics:</strong> Uygulama performansı ve çökme raporlaması.
                  </div>
                </li>
              </ul>
              <p className="text-somine-gray leading-relaxed mt-4">
                Bu hizmetlerin kendi gizlilik politikaları geçerlidir ve Somine, üçüncü
                taraf hizmetlerinin veri işleme uygulamalarından sorumlu değildir.
              </p>
            </div>

            {/* Section 5 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">5</span>
                Veri Güvenliği
              </h2>
              <p className="text-somine-gray leading-relaxed">
                Kişisel verilerinizin güvenliğini sağlamak için endüstri standardı güvenlik
                önlemleri uygulanmaktadır. Verileriniz SSL/TLS şifreleme ile aktarılır ve
                güvenli sunucularda saklanır. Ancak, internet üzerinden hiçbir veri
                iletiminin %100 güvenli olduğu garanti edilemez.
              </p>
            </div>

            {/* Section 6 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">6</span>
                Kullanıcı Hakları (KVKK)
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">
                KVKK kapsamında aşağıdaki haklara sahipsiniz:
              </p>
              <ul className="space-y-3 text-somine-gray">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Kişisel verilerinizin işlenip işlenmediğini öğrenme
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Kişisel verileriniz işlenmişse buna ilişkin bilgi talep etme
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Kişisel verilerinizin eksik veya yanlış işlenmiş olması halinde düzeltilmesini isteme
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  KVKK&apos;nın 7. maddesinde öngörülen şartlar çerçevesinde kişisel verilerinizin silinmesini isteme
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  İşlenen verilerin üçüncü kişilere bildirilmesini isteme
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Aleyhinize bir sonuç doğurması durumunda itiraz etme
                </li>
              </ul>
              <p className="text-somine-gray leading-relaxed mt-4">
                Bu haklarınızı kullanmak için{' '}
                <a
                  href="mailto:support@somineapp.com"
                  className="text-turquoise-dark hover:underline font-medium"
                >
                  support@somineapp.com
                </a>{' '}
                adresine e-posta gönderebilirsiniz.
              </p>
            </div>

            {/* Section 7 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">7</span>
                Veri Saklama Süresi
              </h2>
              <p className="text-somine-gray leading-relaxed">
                Kişisel verileriniz, hesabınız aktif olduğu sürece saklanacaktır. Hesabınızı
                sildiğinizde veya belirli bir süre boyunca kullanmadığınızda, verileriniz
                yasal yükümlülükler dışında silinecektir. Yasal gereklilikler doğrultusunda
                bazı veriler daha uzun süre saklanabilir.
              </p>
            </div>

            {/* Section 8 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">8</span>
                Çocukların Gizliliği
              </h2>
              <p className="text-somine-gray leading-relaxed">
                Somine, 13 yaşından küçük çocuklardan bilerek kişisel veri toplamaz.
                13 yaşından küçük bir çocuğun kişisel verisi toplandığının farkına
                varırsanız, lütfen bizimle iletişime geçiniz.
              </p>
            </div>

            {/* Section 9 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">9</span>
                Politika Değişiklikleri
              </h2>
              <p className="text-somine-gray leading-relaxed">
                Bu gizlilik politikasını zaman zaman güncelleyebiliriz. Önemli değişiklikler
                durumunda, uygulama içinde bildirim yapılacaktır. Bu sayfanın en üstündeki
                &quot;Son güncelleme&quot; tarihini kontrol ederek politikanın ne zaman güncellendiğini
                öğrenebilirsiniz.
              </p>
            </div>

            {/* Contact */}
            <div className="bg-gradient-to-br from-turquoise/5 to-turquoise-dark/5 rounded-2xl p-6 border border-turquoise/10 mt-8">
              <h3 className="text-lg font-semibold text-somine-text mb-3">
                İletişim
              </h3>
              <p className="text-somine-gray text-sm leading-relaxed">
                Gizlilik politikamız hakkında sorularınız veya talepleriniz için bizimle
                iletişime geçebilirsiniz:
              </p>
              <a
                href="mailto:support@somineapp.com"
                className="inline-flex items-center gap-2 mt-3 text-turquoise-dark hover:underline font-medium text-sm"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75" />
                </svg>
                support@somineapp.com
              </a>
            </div>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
