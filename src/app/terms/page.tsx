import Link from 'next/link'
import Navbar from '@/components/navbar'
import Footer from '@/components/footer'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Kullanım Şartları | Somine',
  description: 'Somine uygulamasının kullanım şartları ve koşulları hakkında bilgi edinin.',
}

export default function KullanimSartlari() {
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
                <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z" />
              </svg>
            </div>
            <div>
              <h1 className="text-3xl sm:text-4xl font-bold text-somine-text">
                Kullanım Şartları
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
              Somine mobil uygulamasını (&quot;Uygulama&quot;) kullanmadan önce lütfen bu
              Kullanım Şartlarını dikkatle okuyunuz. Uygulamayı indirerek ve
              kullanarak bu şartları kabul etmiş sayılırsınız. Bu şartları kabul
              etmiyorsanız, uygulamayı kullanmamanız gerekmektedir.
            </p>

            {/* Section 1 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">1</span>
                Hizmet Tanımı
              </h2>
              <p className="text-somine-gray leading-relaxed">
                Somine, kullanıcıların dijital içeriklerini (videolar, linkler, görseller)
                kişisel koleksiyonlarında organize etmelerini, saklamalarını ve paylaşmalarını
                sağlayan bir mobil uygulamadır. Uygulama, Apple App Store üzerinden iOS
                cihazlar için sunulmaktadır.
              </p>
            </div>

            {/* Section 2 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">2</span>
                Hesap Oluşturma ve Kullanıcı Yükümlülükleri
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">
                Uygulamayı kullanmak için bir hesap oluşturmanız gerekmektedir. Hesap
                oluştururken aşağıdaki kurallara uymanız beklenmektedir:
              </p>
              <ul className="space-y-3 text-somine-gray">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Gerçek ve doğru bilgiler sağlamak
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Hesap güvenliğini sağlamak ve giriş bilgilerini gizli tutmak
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Uygulamayı yasadışı, zararlı veya başkalarının haklarını ihlal eden
                  amaçlarla kullanmamak
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Telif haklarına, ticari markalara veya diğer fikri mülkiyet haklarına
                  uygun şekilde hareket etmek
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Spam, kötü amaçlı yazılım veya zararlı içerik yaymamak
                </li>
              </ul>
            </div>

            {/* Section 3 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">3</span>
                Fikri Mülkiyet
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">
                Somine uygulaması ve ilgili tüm içerikler (tasarım, logo, kod, grafikler)
                Somine&apos;nin mülkiyetindedir ve uluslararası fikri mülkiyet yasalarıyla
                korunmaktadır.
              </p>
              <p className="text-somine-gray leading-relaxed">
                Kullanıcılar, uygulamaya ekledikleri içeriklerin haklarına sahip olduklarını
                beyan ederler. Somine, kullanıcıların içeriklerine kısıtlı bir lisans
                tanır; bu lisans yalnızca uygulamanın işlevlerini yerine getirmek için
                gereklidir.
              </p>
            </div>

            {/* Section 4 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">4</span>
                Üyelik ve Ödeme
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">
                Somine, ücretsiz ve premium üyelik seçenekleri sunmaktadır:
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
                <div className="bg-somine-bg rounded-xl p-4 border border-gray-100">
                  <h4 className="font-semibold text-somine-text text-sm mb-2">Ücretsiz Üyelik</h4>
                  <ul className="space-y-1.5 text-somine-gray text-sm">
                    <li className="flex items-center gap-2">
                      <span className="text-turquoise">✓</span> Sınırlı sayıda koleksiyon
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="text-turquoise">✓</span> İçerik ekleme ve düzenleme
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="text-turquoise">✓</span> Temel arama özelliği
                    </li>
                  </ul>
                </div>
                <div className="bg-turquoise/5 rounded-xl p-4 border border-turquoise/10">
                  <h4 className="font-semibold text-somine-text text-sm mb-2">Premium Üyelik</h4>
                  <ul className="space-y-1.5 text-somine-gray text-sm">
                    <li className="flex items-center gap-2">
                      <span className="text-turquoise">✓</span> Sınırsız koleksiyon
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="text-turquoise">✓</span> Gizli kasa (FaceID/TouchID)
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="text-turquoise">✓</span> Premium temalar ve ikonlar
                    </li>
                  </ul>
                </div>
              </div>
              <p className="text-somine-gray leading-relaxed mb-4">
                Premium üyelik aşağıdaki planlar ile sunulmaktadır:
              </p>
              <ul className="space-y-3 text-somine-gray mb-4">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Haftalık Plan:</strong> $0.99 / hafta
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Aylık Plan:</strong> $1.99 / ay (Popüler)
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Yıllık Plan:</strong> $9.99 / yıl (En avantajlı)
                  </div>
                </li>
              </ul>
              <p className="text-somine-gray leading-relaxed text-sm">
                Premium üyelik ücretleri Apple App Store üzerinden tahsil edilir ve
                Apple&apos;ın abonelik yönetimi kuralları geçerlidir.
              </p>
            </div>

            {/* Section 5 — Auto Renewal */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">5</span>
                Otomatik Yenileme ve İptal
              </h2>
              <div className="bg-somine-bg rounded-2xl p-6 border border-turquoise/10 mb-4">
                <h3 className="text-base font-semibold text-somine-text mb-3">
                  Otomatik Yenileme
                </h3>
                <p className="text-somine-gray text-sm leading-relaxed mb-3">
                  Premium aboneliğiniz, geçerli dönemin sonunda aynı fiyat ve süre ile otomatik olarak yenilenir.
                  Abonelik ücreti, her yenileme döneminde Apple hesabınızdan tahsil edilir.
                </p>
                <ul className="space-y-2 text-somine-gray text-sm">
                  <li className="flex items-start gap-3">
                    <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                    Abonelik, iptal edilmediği sürece otomatik olarak yenilenir
                  </li>
                  <li className="flex items-start gap-3">
                    <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                    Hesabınızdan yenileme tarihinden en fazla 24 saat öncesine kadar iptal edilebilir
                  </li>
                  <li className="flex items-start gap-3">
                    <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                    İptal sonrası mevcut dönem sonuna kadar premium özelliklerinize erişmeye devam edersiniz
                  </li>
                </ul>
              </div>
              <p className="text-somine-gray leading-relaxed mb-3">
                Aboneliğinizi iptal etmek için:
              </p>
              <ul className="space-y-2 text-somine-gray text-sm">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <strong className="text-somine-text">iOS:</strong> Ayarlar &gt; Apple ID &gt; Abonelikler &gt; Somine &gt; İptal Et
                </li>
              </ul>
            </div>

            {/* Section 6 — Refund */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">6</span>
                İade Politikası
              </h2>
              <p className="text-somine-gray leading-relaxed">
                Premium üyelik satın alma işlemleri Apple App Store üzerinden gerçekleştirildiğinden,
                tüm iade talepleri Apple&apos;ın iade politikasına tabidir. İade taleplerinizi
                Apple&apos;ın &quot;Sorun Bildir&quot; sayfası üzerinden veya cihazınızın Ayarlar &gt; Apple ID &gt;
                Satın Almalar bölümünden iletebilirsiniz. Somine, doğrudan iade işlemi yapamaz;
                iade kararları tamamen Apple&apos;ın takdir yetkisindedir.
              </p>
            </div>

            {/* Section 7 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">7</span>
                Hesap Sonlandırma
              </h2>
              <p className="text-somine-gray leading-relaxed mb-4">
                Hesabınızı istediğiniz zaman aşağıdaki yollarla sonlandırabilirsiniz:
              </p>
              <ul className="space-y-3 text-somine-gray">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">Uygulama İçinden:</strong> Profil &gt; Hesap Bilgileri &gt; Hesabı Sil seçeneğini kullanarak
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  <div>
                    <strong className="text-somine-text">E-posta ile:</strong>{' '}
                    <a href="mailto:support@somineapp.com" className="text-turquoise-dark hover:underline">
                      support@somineapp.com
                    </a>{' '}
                    adresine hesap silme talebi göndererek
                  </div>
                </li>
              </ul>
              <p className="text-somine-gray leading-relaxed mt-4">
                Hesap silme işlemleri hakkında detaylı bilgi için{' '}
                <Link href="/delete-account" className="text-turquoise-dark hover:underline font-medium">
                  Hesap Silme sayfamızı
                </Link>{' '}
                ziyaret edebilirsiniz.
              </p>
            </div>

            {/* Section 6 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">8</span>
                Sorumluluk Sınırları
              </h2>
              <ul className="space-y-3 text-somine-gray">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Somine, kullanıcıların eklediği içeriklerden sorumlu değildir.
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Uygulama, &quot;olduğu gibi&quot; sunulmaktadır; belirli bir amaca uygunluk,
                  ticarete uygunluk veya ihmal etmeme konusunda hiçbir garanti verilmemektedir.
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Somine, uygulamanın kesintisiz veya hatasız çalışacağına dair garanti vermez.
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-turquoise mt-2 shrink-0" />
                  Herhangi bir doğrudan, dolaylı, özel veya sonuç olarak doğan zararlardan
                  Somine sorumlu tutulamaz.
                </li>
              </ul>
            </div>

            {/* Section 7 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">9</span>
                Değişiklikler
              </h2>
              <p className="text-somine-gray leading-relaxed">
                Somine, bu Kullanım Şartlarını zaman zaman güncelleme hakkını saklı tutar.
                Önemli değişiklikler durumunda, uygulama içinde bildirim yapılacaktır.
                Şartların güncellenmiş sürümünü bu sayfada bulabilirsiniz. Değişiklikler
                yayınlandıktan sonra uygulamayı kullanmaya devam etmeniz, güncellenmiş
                şartları kabul ettiğiniz anlamına gelir.
              </p>
            </div>

            {/* Section 8 */}
            <div>
              <h2 className="text-xl font-bold text-somine-text mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-turquoise/10 text-turquoise-dark flex items-center justify-center text-sm font-bold">10</span>
                Uygulanacak Hukuk
              </h2>
              <p className="text-somine-gray leading-relaxed">
                Bu Kullanım Şartları, Türkiye Cumhuriyeti yasalarına tabi olup
                bu yasalara uygun olarak yorumlanacaktır. Şartlardan doğan herhangi
                bir anlaşmazlık durumunda, Türkiye mahkemeleri yetkili kılınacaktır.
              </p>
            </div>

            {/* Contact */}
            <div className="bg-gradient-to-br from-turquoise/5 to-turquoise-dark/5 rounded-2xl p-6 border border-turquoise/10 mt-8">
              <h3 className="text-lg font-semibold text-somine-text mb-3">
                Sorularınız mı var?
              </h3>
              <p className="text-somine-gray text-sm leading-relaxed">
                Kullanım şartları hakkında sorularınız veya endişeleriniz için bizimle
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
