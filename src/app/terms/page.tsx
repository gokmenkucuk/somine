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

      <section className="pt-32 pb-16 bg-[#E8F1EF]">
        <div className="max-w-4xl mx-auto px-6 sm:px-8">
          <Link href="/" className="inline-flex items-center gap-2 text-sm text-[#688E8B] hover:text-[#4a6e6b] transition-colors mb-8">
            ← Ana Sayfaya Dön
          </Link>
          <p className="text-sm font-medium text-[#688E8B] uppercase tracking-widest mb-3">Yasal</p>
          <h1 className="text-4xl sm:text-5xl font-semibold text-gray-900 tracking-tight mb-3">Kullanım Şartları</h1>
          <p className="text-gray-500 text-lg">Son güncelleme: 1 Ocak 2026</p>
        </div>
      </section>

      <section className="flex-1 bg-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="prose prose-slate max-w-none space-y-8">
            <p className="text-gray-500 leading-relaxed">
              Somine mobil uygulamasını (&quot;Uygulama&quot;) kullanmadan önce lütfen bu
              Kullanım Şartlarını dikkatle okuyunuz. Uygulamayı indirerek ve
              kullanarak bu şartları kabul etmiş sayılırsınız. Bu şartları kabul
              etmiyorsanız, uygulamayı kullanmamanız gerekmektedir.
            </p>

            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">1</span>
                Hizmet Tanımı
              </h2>
              <p className="text-gray-500 leading-relaxed">
                Somine, kullanıcıların dijital içeriklerini (videolar, linkler, görseller)
                kişisel koleksiyonlarında organize etmelerini, saklamalarını ve paylaşmalarını
                sağlayan bir mobil uygulamadır. Uygulama, Apple App Store üzerinden iOS
                cihazlar için sunulmaktadır.
              </p>
            </div>

            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">2</span>
                Hesap Oluşturma ve Kullanıcı Yükümlülükleri
              </h2>
              <p className="text-gray-500 leading-relaxed mb-4">
                Uygulamayı kullanmak için bir hesap oluşturmanız gerekmektedir. Hesap
                oluştururken aşağıdaki kurallara uymanız beklenmektedir:
              </p>
              <ul className="space-y-3 text-gray-500">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Gerçek ve doğru bilgiler sağlamak
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Hesap güvenliğini sağlamak ve giriş bilgilerini gizli tutmak
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Uygulamayı yasadışı, zararlı veya başkalarının haklarını ihlal eden
                  amaçlarla kullanmamak
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Telif haklarına, ticari markalara veya diğer fikri mülkiyet haklarına
                  uygun şekilde hareket etmek
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Spam, kötü amaçlı yazılım veya zararlı içerik yaymamak
                </li>
              </ul>
            </div>

            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">3</span>
                Fikri Mülkiyet
              </h2>
              <p className="text-gray-500 leading-relaxed mb-4">
                Somine uygulaması ve ilgili tüm içerikler (tasarım, logo, kod, grafikler)
                Somine&apos;nin mülkiyetindedir ve uluslararası fikri mülkiyet yasalarıyla
                korunmaktadır.
              </p>
              <p className="text-gray-500 leading-relaxed">
                Kullanıcılar, uygulamaya ekledikleri içeriklerin haklarına sahip olduklarını
                beyan ederler. Somine, kullanıcıların içeriklerine kısıtlı bir lisans
                tanır; bu lisans yalnızca uygulamanın işlevlerini yerine getirmek için
                gereklidir.
              </p>
            </div>

            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">4</span>
                Üyelik ve Ödeme
              </h2>
              <p className="text-gray-500 leading-relaxed mb-4">
                Somine, ücretsiz ve premium üyelik seçenekleri sunmaktadır:
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
                <div className="bg-[#E8F1EF] rounded-xl p-4 border border-gray-100">
                  <h4 className="font-semibold text-gray-900 text-sm mb-2">Ücretsiz Üyelik</h4>
                  <ul className="space-y-1.5 text-gray-500 text-sm">
                    <li className="flex items-center gap-2">
                      <span className="text-[#688E8B]">✓</span> Sınırlı sayıda koleksiyon
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="text-[#688E8B]">✓</span> İçerik ekleme ve düzenleme
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="text-[#688E8B]">✓</span> Temel arama özelliği
                    </li>
                  </ul>
                </div>
                <div className="bg-[#688E8B]/5 rounded-xl p-4 border border-[#688E8B]/10">
                  <h4 className="font-semibold text-gray-900 text-sm mb-2">Premium Üyelik</h4>
                  <ul className="space-y-1.5 text-gray-500 text-sm">
                    <li className="flex items-center gap-2">
                      <span className="text-[#688E8B]">✓</span> Sınırsız koleksiyon
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="text-[#688E8B]">✓</span> Gizli kasa (FaceID/TouchID)
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="text-[#688E8B]">✓</span> Premium temalar ve ikonlar
                    </li>
                  </ul>
                </div>
              </div>
              <p className="text-gray-500 leading-relaxed mb-4">
                Premium üyelik aşağıdaki planlar ile sunulmaktadır:
              </p>
              <ul className="space-y-3 text-gray-500 mb-4">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Haftalık Plan:</strong> $0.99 / hafta
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Aylık Plan:</strong> $1.99 / ay (Popüler)
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Yıllık Plan:</strong> $9.99 / yıl (En avantajlı)
                  </div>
                </li>
              </ul>
              <p className="text-gray-500 leading-relaxed text-sm">
                Premium üyelik ücretleri Apple App Store üzerinden tahsil edilir ve
                Apple&apos;ın abonelik yönetimi kuralları geçerlidir.
              </p>
            </div>

            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">5</span>
                Otomatik Yenileme ve İptal
              </h2>
              <div className="bg-[#E8F1EF] rounded-2xl p-6 border border-[#688E8B]/10 mb-4">
                <h3 className="text-base font-semibold text-gray-900 mb-3">
                  Otomatik Yenileme
                </h3>
                <p className="text-gray-500 text-sm leading-relaxed mb-3">
                  Premium aboneliğiniz, geçerli dönemin sonunda aynı fiyat ve süre ile otomatik olarak yenilenir.
                  Abonelik ücreti, her yenileme döneminde Apple hesabınızdan tahsil edilir.
                </p>
                <ul className="space-y-2 text-gray-500 text-sm">
                  <li className="flex items-start gap-3">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                    Abonelik, iptal edilmediği sürece otomatik olarak yenilenir
                  </li>
                  <li className="flex items-start gap-3">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                    Hesabınızdan yenileme tarihinden en fazla 24 saat öncesine kadar iptal edilebilir
                  </li>
                  <li className="flex items-start gap-3">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                    İptal sonrası mevcut dönem sonuna kadar premium özelliklerinize erişmeye devam edersiniz
                  </li>
                </ul>
              </div>
              <p className="text-gray-500 leading-relaxed mb-3">
                Aboneliğinizi iptal etmek için:
              </p>
              <ul className="space-y-2 text-gray-500 text-sm">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <strong className="text-gray-900">iOS:</strong> Ayarlar &gt; Apple ID &gt; Abonelikler &gt; Somine &gt; İptal Et
                </li>
              </ul>
            </div>

            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">6</span>
                İade Politikası
              </h2>
              <p className="text-gray-500 leading-relaxed">
                Premium üyelik satın alma işlemleri Apple App Store üzerinden gerçekleştirildiğinden,
                tüm iade talepleri Apple&apos;ın iade politikasına tabidir. İade taleplerinizi
                Apple&apos;ın &quot;Sorun Bildir&quot; sayfası üzerinden veya cihazınızın Ayarlar &gt; Apple ID &gt;
                Satın Almalar bölümünden iletebilirsiniz. Somine, doğrudan iade işlemi yapamaz;
                iade kararları tamamen Apple&apos;ın takdir yetkisindedir.
              </p>
            </div>

            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">7</span>
                Hesap Sonlandırma
              </h2>
              <p className="text-gray-500 leading-relaxed mb-4">
                Hesabınızı istediğiniz zaman aşağıdaki yollarla sonlandırabilirsiniz:
              </p>
              <ul className="space-y-3 text-gray-500">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">Uygulama İçinden:</strong> Profil &gt; Hesap Bilgileri &gt; Hesabı Sil seçeneğini kullanarak
                  </div>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  <div>
                    <strong className="text-gray-900">E-posta ile:</strong>{' '}
                    <a href="mailto:support@somineapp.com" className="text-[#688E8B] hover:underline">
                      support@somineapp.com
                    </a>{' '}
                    adresine hesap silme talebi göndererek
                  </div>
                </li>
              </ul>
              <p className="text-gray-500 leading-relaxed mt-4">
                Hesap silme işlemleri hakkında detaylı bilgi için{' '}
                <Link href="/delete-account" className="text-[#688E8B] hover:underline font-medium">
                  Hesap Silme sayfamızı
                </Link>{' '}
                ziyaret edebilirsiniz.
              </p>
            </div>

            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">8</span>
                Sorumluluk Sınırları
              </h2>
              <ul className="space-y-3 text-gray-500">
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Somine, kullanıcıların eklediği içeriklerden sorumlu değildir.
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Uygulama, &quot;olduğu gibi&quot; sunulmaktadır; belirli bir amaca uygunluk,
                  ticarete uygunluk veya ihmal etmeme konusunda hiçbir garanti verilmemektedir.
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Somine, uygulamanın kesintisiz veya hatasız çalışacağına dair garanti vermez.
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#688E8B] mt-2 shrink-0" />
                  Herhangi bir doğrudan, dolaylı, özel veya sonuç olarak doğan zararlardan
                  Somine sorumlu tutulamaz.
                </li>
              </ul>
            </div>

            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">9</span>
                Değişiklikler
              </h2>
              <p className="text-gray-500 leading-relaxed">
                Somine, bu Kullanım Şartlarını zaman zaman güncelleme hakkını saklı tutar.
                Önemli değişiklikler durumunda, uygulama içinde bildirim yapılacaktır.
                Şartların güncellenmiş sürümünü bu sayfada bulabilirsiniz. Değişiklikler
                yayınlandıktan sonra uygulamayı kullanmaya devam etmeniz, güncellenmiş
                şartları kabul ettiğiniz anlamına gelir.
              </p>
            </div>

            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-[#688E8B]/10 text-[#688E8B] flex items-center justify-center text-sm font-bold">10</span>
                Uygulanacak Hukuk
              </h2>
              <p className="text-gray-500 leading-relaxed">
                Bu Kullanım Şartları, Türkiye Cumhuriyeti yasalarına tabi olup
                bu yasalara uygun olarak yorumlanacaktır. Şartlardan doğan herhangi
                bir anlaşmazlık durumunda, Türkiye mahkemeleri yetkili kılınacaktır.
              </p>
            </div>

            <div className="bg-gradient-to-br from-[#688E8B]/5 to-[#688E8B]/5 rounded-2xl p-6 border border-[#688E8B]/10 mt-8">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                Sorularınız mı var?
              </h3>
              <p className="text-gray-500 text-sm leading-relaxed">
                Kullanım şartları hakkında sorularınız veya endişeleriniz için bizimle
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
