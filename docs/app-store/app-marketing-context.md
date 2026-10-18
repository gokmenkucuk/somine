# somine — Pazarlama Bağlam Belgesi

Son güncelleme: 2026-10-18 · Hazırlayan: Claude (app-marketing-context becerisi) · Kaynak: kod (mobile/, api/), PLAN.md, App Store arama verisi

Bu belge diğer tüm mağaza belgelerinin (keywords, metadata, growth-plan) dayanağıdır. Ürün değişince önce bunu güncelle.

## 1. Uygulama özeti

| Alan | Değer |
|---|---|
| Mağaza adı (öneri, ASC'ye girildi) | EN: **somine: Save Links & Bookmarks** · TR: **somine: Link Kaydet, Hatırlat** |
| Eski ad | somine: Social Bookmark (EN) · somine: Sosyal Medya Arşivi (TR) |
| Apple ID / Bundle | 6757957749 / com.somine.app |
| Geliştirici | GSO Studio (hesap bireysel: "GOKMEN KUCUK") |
| Kategori | Birincil Productivity, ikincil Lifestyle (ASC'de kaydedildi) |
| Platform | iOS (iPhone; binary iPad'i de destekliyor, bkz. README açık soru), Android üretimde değil |
| Model | Freemium + otomatik yenilenen abonelik (haftalık/aylık/yıllık, RevenueCat, entitlement "So Mine Premium"), deneme süresi yok (bilinçli karar) |
| Durum | 1.0 Prepare for Submission, build 37 TestFlight'ta, 38 yükleniyor |
| Diller (uygulama) | Türkçe, İngilizce |

## 2. Değer önerisi

- **Problem:** İnsanlar her gün link, reel, tarif, mekân, makale kaydediyor (Instagram kaydedilenler, ekran görüntüsü, "kendime WhatsApp"), sonra bir daha bakmıyor. Kayıtlar platformlara dağılmış ve geri dönmüyor.
- **Çözüm:** Her uygulamanın Paylaş menüsünden tek yere kaydet, koleksiyonlara ayır, ve en önemlisi **kaydettiklerin sana geri gelsin**: kayıt başına hatırlatıcı, haftalık "Sana geri geldi" bildirimi, her gün bir kaydı gösteren "Günün Kaydı" widget'ı.
- **Konumlandırma cümlesi (TR):** "Kaydettiklerin kaybolmasın — sana geri gelsin."
- **Konumlandırma cümlesi (EN):** "The save-for-later app that actually brings things back."
- **Asansör konuşması:** somine, her yerden kaydettiğin link ve notları koleksiyonlarda toplar ve doğru zamanda sana hatırlatır; istersen arkadaşlarınla koleksiyon paylaşırsın.

## 3. Hedef kitle

**Birincil (TR, kama pazarı):** 18–35 yaş, iPhone kullanan, Instagram/TikTok/YouTube'da içerik biriktiren kullanıcılar. Tipik kayıtlar: "denemek istediğim tarifler", "gitmek istediğim yerler", "dinlemek istediğim", "ilham". Uygulamanın varsayılan koleksiyonları da tam bunlar (`mobile/lib/l10n/app_tr.arb` → defaultCategory*).

**İkincil (TR + global):** Pocket'ın kapanmasıyla (Mozilla, Temmuz 2025) boşta kalan "sonra okurum" kullanıcıları ve Omnivore'un (Kasım 2024) mültecileri. Bunlar daha yaşlı, daha çok makale okuyan, ödemeye daha yatkın bir kitle; ancak somine'de makale okuma modu (reader view) yok, bu kitleye dürüst vaat "kaydet + hatırlat + bul" olmalı.

**Üçüncül:** Çiftler/aileler/arkadaş grupları: ortak tarif, gezi, alışveriş koleksiyonu. Marka hikâyesi ("Önce kendi evimiz için yaptık") burada doğal.

## 4. Rakipler

| Uygulama | Güçlü | Zayıf / somine'nin açısı |
|---|---|---|
| **Pocket** (kapandı, 2025) | Devasa kurulu taban, "read later" kavramının sahibi | Artık yok. Göç eden kullanıcılar yeni ev arıyor. Metadata'da adı **kullanılamaz** (2.3.7), ama blog/Reddit/AlternativeTo'da "Pocket alternatifi" anlatısı serbest |
| **Raindrop.io** | Çok platform, web eklentisi, güçlü klasör/etiket, uygun Pro | Güç kullanıcısı odaklı, sosyal katman zayıf, hatırlatma yok, Türkçe yok |
| **Matter** | Okuma deneyimi, sesli okuma, bülten | Makale/okuma odaklı; reel/tarif/mekân kaydetmeye uygun değil |
| **Readwise Reader** | En güçlü okuma + vurgulama aracı | Pahalı (~10 $/ay), karmaşık, tüketici değil |
| **GoodLinks** | Tek seferlik ödeme, Apple-yerli, temiz | Sadece okuma listesi, paylaşım/hatırlatıcı yok |
| **Anybox** | Mac-öncelikli, güçlü yer imi | Mac güç kullanıcısı; mobil tüketici değil |
| **mymind** | Estetik, AI etiketleme, "klasörsüz" | Pahalı, AI odaklı, sosyal paylaşım yok |
| **Pinterest panoları / Instagram Kaydedilenler** | Sıfır sürtünme, platform içinde | Platformlar arası değil, hatırlatma yok, dışarı aktarılamaz |
| **Apple Notlar / kendine WhatsApp** | Zaten telefonda | Düzen yok, önizleme yok, geri gelmiyor |

Mağaza verisi (2026-10-18, iTunes Search API): ABD'de "bookmark manager / link saver / save for later / link organizer" aramalarında ilk 10'un medyan değerlendirme sayısı 6–92 → **rekabet düşük**. TR'de "link kaydet, yer imi, sonra oku, bookmark, read later" aramalarında ilk 10'un medyanı 0–3 → **neredeyse boş alan**, ama arama hacmi de düşük.

## 5. Farklılaştırıcılar (kodda doğrulandı)

1. **Resurfacing:** kayıt başına hatırlatıcı (yarın/hafta sonu hızlı seçim + tekrar: günlük, haftalık, aylık, yıllık, hafta içi, hafta sonu) · haftalık "Sana geri geldi" yerel bildirimi (Pazar, açılmamış kayıtlar; varsayılan kapalı) · "Günün Kaydı" widget'ı (small/medium).
2. **Sosyal koleksiyonlar:** kullanıcı adıyla koleksiyon paylaşımı (istek, kabul/ret) + tarayıcıda açılan herkese açık link (`somineapp.com/s/{token}`), 1.2 kontrolleri (bildir, engelle, kitaplıktan kaldır).
3. **Gizli Kasa:** Face ID/Touch ID ile kilitli koleksiyonlar; kasa içerikleri widget'a, haftalık özete ve kilit ekranı bildirimine girmez.
4. **Türkçe-yerli:** tamamen Türkçe arayüz, Türkçe karakterlere duyarlı (unaccent + trigram) yazım hatası toleranslı arama.
5. **Veri sahipliği:** JSON/CSV dışa aktarma, uygulama içi hesap silme, 30 gün Son Silinenler, takip/reklam yok.

## 6. Dürüst zayıflıklar

- Android, web uygulaması ve tarayıcı eklentisi **yok** (Pocket/Raindrop göçmenleri için büyük eksik).
- AI etiketleme / semantik arama **yok** (kod duruyor, bayrakla kapalı; metadata'da AI iddiası yapılmamalı).
- Okuma modu (makale metnini çekip okuma), çevrimdışı okuma **yok**.
- Paylaşım eklentisi yalnız link/metin kabul eder, görsel paylaşımı uygulama içinden yapılır; eklenti ana uygulamayı açar (tek dokunuşta kaydetmiyor).
- Giriş zorunlu (Apple/Google). İlk açılış sürtünmesi.
- Instagram/TikTok önizleme görselleri CDN süresi dolunca kaybolabiliyor (PLAN.md "og:image" aday işi).
- Sıfır değerlendirme, bilinmeyen marka, tek kişilik ekip.
- Widget adı ve açıklaması kodda yalnız Türkçe (`ios/SomineWidget/SomineWidget.swift:173-174`), İngilizce cihazda Türkçe görünür.
- Bildirim Ayarları'nda haftalık özet alt yazısı "özet e-postası" diyor (`app_tr.arb`/`app_en.arb` notificationSettingsWeeklyDigestSubtitle) ama özellik e-posta değil yerel bildirim. Düzeltilmeli (2.3.1 açısından küçük risk).

## 7. Hedefler (öneri, kullanıcı onayı bekliyor)

1. İlk 90 gün: TR'de 1.000 indirme, ürün sayfası dönüşümü %30+ (ASC Analytics).
2. Aktivasyon (ilk kayıt) %60+, D30 tutma %15+, hatırlatıcı kurma oranı %25+.
3. İlk 90 günde 50+ değerlendirme, ortalama 4,5+.
4. Premium dönüşümü %2–4 (aktif kullanıcı bazında).

## 8. Kaynaklar ve kısıtlar

- Ekip: tek geliştirici (GSO Studio), pazarlama bütçesi yok/çok düşük → organik + ASO + topluluk.
- Araçlar: Firebase Analytics (eventler: activation, content_add, reminder_set, paywall_view/convert, share, widget_tap, export), ASC Analytics, RevenueCat panosu, Remotion (görsel/video).
- Kısıt: ücretli anahtar kelime aracı yok; anahtar kelime puanları tahmin (bkz. keywords.md yöntem).

## 9. Pazarlar

- **Birincil:** Türkiye (tr). Not: Türkiye mağazası Apple tablosuna göre **English (U.K.) varsayılan + Turkish** dizinler. Yani en-GB yerelleştirmesi TR mağazasında ek 100 karakter anahtar kelime demek.
- **İkincil:** ABD (en-US; ABD mağazası ayrıca es-MX dahil 9 dili dizinler), diğer İngilizce mağazalar.
- **Sonraki:** bkz. growth-plan.md yerelleştirme yol haritası.
