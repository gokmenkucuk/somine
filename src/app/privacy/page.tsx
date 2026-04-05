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
      <section className="pt-32 pb-16 bg-[#E8F1EF]">
        <div className="max-w-4xl mx-auto px-6 sm:px-8">
          <Link href="/" className="inline-flex items-center gap-2 text-sm text-[#688E8B] hover:text-[#4a6e6b] transition-colors mb-8">
            ← Ana Sayfaya Dön
          </Link>
          <p className="text-sm font-medium text-[#688E8B] uppercase tracking-widest mb-3">Yasal</p>
          <h1 className="text-4xl sm:text-5xl font-semibold text-gray-900 tracking-tight mb-3">Gizlilik Politikası</h1>
          <p className="text-gray-500 text-lg">Son güncelleme: 1 Ocak 2026</p>
        </div>
      </section>

      {/* Content */}
      <section className="flex-1 bg-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="prose prose-slate max-w-none space-y-8">
            <p className="text-gray-500 leading-relaxed">
              Somine olarak kişisel verilerinizin güvenliği bizim için çok önemlidir.
              Bu Gizlilik Politikası, Somine mobil uygulamasını (&quot;Uygulama&quot;) kullanırken
              hangi verilerin toplandığını, nasıl kullanıldığını ve korunduğunu açıklamaktadır.
              Uygulamayı kullanarak bu politikayı kabul etmiş sayılırsınız.
            </p>

            <div className="bg-[#E8F1EF] rounded-2xl p-6 border border-[#688E8B]/10">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                KVKK Uyarısı
              </h3>
              <p className="text-gray-500 text-sm leading-relaxed">
                Bu gizlilik politikası, 6698 sayılı Kişisel Verilerin Korunması Kanunu
                (KVKK) ve ilgili mevzuata uygun olarak hazırlanmıştır. Kişisel verileriniz,
                KVKK&apos;nın belirlediği ilkelere ve kurallara göre işlenmektedir.
              </p>
            </div>

            {/* Section 1 */}
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">1</span>
                Toplanan Veriler
              </h2>
              <p className="text-gray-500 leading-relaxed mb-4">
                Somine uygulamasını kullanırken aşağıdaki verileri toplayabiliriz:
              </p>
              <ul className="space-y-3 text-gray-500">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Hesap Bilgileri:</strong> Ad, e-posta adresi, profil fotoğrafı ve sosyal medya hesapları (Apple, Google) aracılığıyla sağlanan bilgiler.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Kullanım Verileri:</strong> Uygulama içindeki etkileşimler, oluşturulan koleksiyonlar, eklenen içerikler, tercih edilen kategoriler.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Cihaz Bilgileri:</strong> Cihaz türü, işletim sistemi sürümü, uygulama sürümü, benzersiz cihaz tanımlayıcısı.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Log Verileri:</strong> Uygulama kullanım istatistikleri, çökme raporları, performans verileri.
                  </div>
                </li>
              </ul>
            </div>

            {/* Section 2 */}
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">2</span>
                Verilerin Kullanım Amacı
              </h2>
              <p className="text-gray-500 leading-relaxed mb-4">
                Toplanan veriler aşağıdaki amaçlarla kullanılmaktadır:
              </p>
              <ul className="space-y-3 text-gray-500">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Uygulamanın temel işlevlerinin sağlanması ve koleksiyon yönetimi
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Kullanıcı deneyiminin iyileştirilmesi ve kişiselleştirilmesi
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Teknik sorunların giderilmesi ve uygulama güvenliğinin sağlanması
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Premium üyelik yönetimi ve faturalandırma işlemleri
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Yasal yükümlülüklerin yerine getirilmesi
                </li>
              </ul>
            </div>

            {/* Section 3 */}
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">3</span>
                Çerezler ve Benzeri Teknolojiler
              </h2>
              <p className="text-gray-500 leading-relaxed">
                Somine uygulaması, kullanıcı deneyimini iyileştirmek amacıyla çerezler ve benzeri
                takip teknolojilerini kullanabilir. Bu teknolojiler, oturum bilgilerinizi hatırlamak,
                tercihlerinizi saklamak ve kullanım istatistikleri toplamak için kullanılır.
                Uygulama ayarlarınızdan çerez tercihlerinizi yönetebilirsiniz.
              </p>
            </div>

            {/* Section 4 */}
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">4</span>
                Üçüncü Taraf Hizmetleri
              </h2>
              <p className="text-gray-500 leading-relaxed mb-4">
                Somine, aşağıdaki üçüncü taraf hizmetlerini kullanmaktadır:
              </p>
              <ul className="space-y-3 text-gray-500">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Firebase:</strong> Kullanıcı kimlik doğrulama, veri saklama ve uygulama altyapı hizmetleri. Firebase, Google LLC tarafından sağlanmaktadır ve verileri güvenli sunucularda işler.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">RevenueCat:</strong> Premium abonelik yönetimi, satın alma doğrulama ve faturalandırma işlemleri. RevenueCat, abonelik durumunuzu güvenli bir şekilde yönetir.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Apple Sign-In:</strong> Kullanıcı girişi için Apple kimlik doğrulama hizmeti. Apple, yalnızca adınızı ve e-posta adresinizi paylaşır.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Google Sign-In:</strong> Kullanıcı girişi için Google kimlik doğrulama hizmeti. Temel profil bilgileriniz Google üzerinden doğrulanır.
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Apple App Store / Google Play:</strong> Premium üyelik satın alma işlemleri. Ödeme işlemleri doğrudan Apple veya Google tarafından gerçekleştirilir.
                  </div>
                </li>
              </ul>
              <p className="text-gray-500 leading-relaxed mt-4">
                Bu hizmetlerin kendi gizlilik politikaları geçerlidir ve Somine, üçüncü
                taraf hizmetlerinin veri işleme uygulamalarından sorumlu değildir.
              </p>
            </div>

            {/* Section 5 */}
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">5</span>
                Veri Güvenliği
              </h2>
              <p className="text-gray-500 leading-relaxed">
                Kişisel verilerinizin güvenliğini sağlamak için endüstri standardı güvenlik
                önlemleri uygulanmaktadır. Verileriniz SSL/TLS şifreleme ile aktarılır ve
                güvenli sunucularda saklanır. Gizli Kasa özelliği, FaceID ve TouchID biyometrik
                doğrulama ile korunmaktadır; bu koleksiyonlara yalnızca siz erişebilirsiniz.
                Ancak, internet üzerinden hiçbir veri iletiminin %100 güvenli olduğu garanti edilemez.
              </p>
            </div>

            {/* Section 6 */}
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">6</span>
                Kullanıcı Hakları (KVKK)
              </h2>
              <p className="text-gray-500 leading-relaxed mb-4">
                KVKK kapsamında aşağıdaki haklara sahipsiniz:
              </p>
              <ul className="space-y-3 text-gray-500">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Kişisel verilerinizin işlenip işlenmediğini öğrenme
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Kişisel verileriniz işlenmişse buna ilişkin bilgi talep etme
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Kişisel verilerinizin eksik veya yanlış işlenmiş olması halinde düzeltilmesini isteme
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  KVKK&apos;nın 7. maddesinde öngörülen şartlar çerçevesinde kişisel verilerinizin silinmesini isteme
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  İşlenen verilerin üçüncü kişilere bildirilmesini isteme
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Aleyhinize bir sonuç doğurması durumunda itiraz etme
                </li>
              </ul>
              <p className="text-gray-500 leading-relaxed mt-4">
                Bu haklarınızı kullanmak için{' '}
                <a
                  href="mailto:support@somineapp.com"
                  className="text-[#688E8B] hover:underline font-medium"
                >
                  support@somineapp.com
                </a>{' '}
                adresine e-posta gönderebilirsiniz.
              </p>
            </div>

            {/* Section 7 */}
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">7</span>
                Veri Saklama Süresi
              </h2>
              <p className="text-gray-500 leading-relaxed">
                Kişisel verileriniz, hesabınız aktif olduğu sürece saklanacaktır. Hesabınızı
                sildiğinizde veya belirli bir süre boyunca kullanmadığınızda, verileriniz
                yasal yükümlülükler dışında silinecektir. Yasal gereklilikler doğrultusunda
                bazı veriler daha uzun süre saklanabilir.
              </p>
            </div>

            {/* Section 8 */}
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">8</span>
                Çocukların Gizliliği
              </h2>
              <p className="text-gray-500 leading-relaxed">
                Somine, 13 yaşından küçük çocuklardan bilerek kişisel veri toplamaz.
                13 yaşından küçük bir çocuğun kişisel verisi toplandığının farkına
                varırsanız, lütfen bizimle iletişime geçiniz.
              </p>
            </div>

            {/* Section 9 */}
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">9</span>
                Politika Değişiklikleri
              </h2>
              <p className="text-gray-500 leading-relaxed">
                Bu gizlilik politikasını zaman zaman güncelleyebiliriz. Önemli değişiklikler
                durumunda, uygulama içinde bildirim yapılacaktır. Bu sayfanın en üstündeki
                &quot;Son güncelleme&quot; tarihini kontrol ederek politikanın ne zaman güncellendiğini
                öğrenebilirsiniz.
              </p>
            </div>

            {/* Contact */}
            <div className="bg-gradient-to-br from-[#688E8B]/5 to-[#688E8B]/5 rounded-2xl p-6 border border-[#688E8B]/10 mt-8">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                İletişim
              </h3>
              <p className="text-gray-500 text-sm leading-relaxed">
                Gizlilik politikamız hakkında sorularınız veya talepleriniz için bizimle
                iletişime geçebilirsiniz:
              </p>
              <a
                href="mailto:support@somineapp.com"
                className="inline-flex items-center gap-2 mt-3 text-[#688E8B] hover:underline font-medium text-sm"
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
