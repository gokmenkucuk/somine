# Organik Büyüme Planı

Tarih: 2026-10-18 · Yöntem: genel ASO/CPP/değerlendirme ilkeleri (ilgili beceriler kurulu, bu oturumda yalnız app-store-review, keyword-research, metadata-optimization, app-marketing-context yüklendi) · Bütçe varsayımı: sıfır/çok düşük, tek kişi.

## 1. ASO iterasyon planı (Product Page Optimization)

PPO aynı anda en fazla 3 varyantla ikon, ekran görüntüsü ve önizlemeyi test eder (metin alanlarını test edemez; onlar sürümle değişir). Anlamlı sonuç için varyant başına birkaç bin gösterim gerekir; yayından sonraki ilk 4–6 haftada trafik düşükse test **uzun** sürer, o yüzden sıra önemli.

| Sıra | Test | Hipotez | Ne zaman |
|---|---|---|---|
| 1 | Ekran görüntüsü 1: "Kaydettiklerin kaybolmasın" (akış) **vs** "Doğru zamanda hatırlatır" (hatırlatıcı önce) | Farklılaştırıcıyı (resurfacing) öne çıkarmak dönüşümü artırır | Yayından ~2 hafta sonra |
| 2 | Air tema seti **vs** Midnight (koyu) seti | Koyu görseller arama listesinde daha çok dikkat çeker | Test 1 bitince |
| 3 | İkon: mevcut **vs** GSO paletine (#28594F/#C47755) yakın varyant | Ancak ikon alternatifleri binary'de olmalı (alternatif ikonlar zaten var, uygun olanı seç) | 2. ay |

Metin iterasyonu (sürüm başına bir değişiklik, 4 hafta ölç):
- Alt başlık B: EN "Saved posts that come back" / TR "Kaydettiğin sana geri gelsin".
- Anahtar alanı: 4 haftada ilk 50'ye girmeyen kelimeleri değiştir (keywords.md izleme listesi).
- Promosyon metni (incelemesiz): ayda bir döndür (yeni özellik, mevsim: "Ramazan tarifleri", "Yaz tatili yerleri").

## 2. Custom Product Pages fikirleri

CPP'ler kendi URL'sine gelen trafiğe farklı görsel + promosyon metni gösterir; 35'e kadar. Organik kullanımda en değerli yer: **paylaşım linkleri ve sosyal paylaşımlar**.

| CPP | Kime | İlk görsel / mesaj | Bağlantının konacağı yer |
|---|---|---|---|
| "Tarif biriktirenler" | TikTok/IG yemek içeriği kitlesi | "Denemek İstediğim Tarifler" koleksiyonu + hafta sonu hatırlatıcısı | Tarif odaklı sosyal içerik, bio linki |
| "Gezi planlayanlar" | gezi/kafe biriktirenler | "Gitmek İstediğim Yerler" + harita önizlemesi | gezi içerikleri |
| "Paylaşılan koleksiyon" | `somineapp.com/s/{token}` sayfasından gelenler | "Arkadaşın bu koleksiyonu seninle paylaştı — sen de topla" | Paylaşım sayfasındaki App Store düğmesi |
| "Read later" (EN) | Pocket'tan göç edenler | "Your new home for saved links" (rakip adı kullanmadan) | Reddit/AlternativeTo yazıları |

Ölçüm: ASC Analytics'te CPP bazında dönüşüm; ayrıca her bağlantıya kampanya parametresi `ct=` ekle (aşağıda).

## 3. Değerlendirme isteme stratejisi (SKStoreReviewController)

**Durum:** Kodda hiç yok (`in_app_review`, `requestReview`, `SKStoreReview` aranıp bulunamadı).

**Öneri (uygulanacak):**
- Paket: `in_app_review` (Flutter, `InAppReview.instance.requestReview()` → iOS'ta `SKStoreReviewController`/`AppStore.requestReview`). Apple yılda en fazla 3 kez gösterir; ne zaman göstereceğine Apple karar verir.
- **Tetik 1 (birincil, "değer anı"):** Kullanıcı bir **hatırlatıcı bildirimine veya haftalık "Sana geri geldi" bildirimine dokunup** kaydı açtığında, kayıt detayı kapandıktan sonra. Koşullar: ilk kurulumdan ≥3 gün geçmiş, toplam kayıt ≥5, son 120 günde istenmemiş, son oturumda hata/limit diyaloğu görülmemiş. Yer: bildirim açılış yolu `openItemDetail` (deeplink/bildirim kapısı) çağrısının dönüşü.
- **Tetik 2 (yedek):** Başarı sayfası (`mobile/lib/widgets/success_notification_sheet.dart`) kapandıktan sonra toplam kayıt **10, 50 veya 150**'ye ulaştığında, aynı koşullarla.
- **Asla:** paywall'dan hemen sonra, satın alma iptalinde, ilk oturumda, kasa açılışında, hata sonrası, bir düğmeye bağlı "bizi değerlendir" diyaloğuyla (Apple yerleşik istemin önüne ön-soru koymaya izin veriyor ama "memnun musun?" kapısı ile olumsuzları filtrelemek 5.6.1 riski — yapma).
- Ayarlar > Yardım ve Destek'e kalıcı "App Store'da değerlendir" satırı: `https://apps.apple.com/app/id6757957749?action=write-review`.
- Olumsuz yorumlara ASC'den 24 saat içinde Türkçe/İngilizce cevap.

## 4. Yerelleştirme yol haritası

| Sıra | Yerelleştirme | Neden | Maliyet |
|---|---|---|---|
| 1 | **en-GB (metadata)** | Türkiye mağazası en-GB'yi varsayılan dil olarak dizinler → TR aramalarına ikinci 100 karakterlik anahtar alanı (bkz. keywords.md). Ayrıca İngiltere | Çok düşük (en-US kopyası + farklı anahtar alanı) |
| 2 | **es-MX (metadata)** | ABD mağazası es-MX'i de dizinler → ABD'de ek anahtar alanı + Meksika | Düşük (metadata çevirisi; uygulama İngilizce kalsa da olur ama sayfa İspanyolca görünür, dikkat) |
| 3 | **de-DE (uygulama + metadata)** | Pocket'ın en güçlü olduğu pazarlardan, yüksek iOS payı ve ödeme isteği, "read later" kültürü | Orta (ARB çevirisi ~600 anahtar + site) |
| 4 | **pt-BR** | Büyük, sosyal içerik biriktirme davranışı güçlü | Orta |
| 5 | **ar / az** | TR'ye kültürel yakın pazarlar (Azerbaycan Türkçeyi kısmen anlar), düşük rekabet | Orta |

Kural: önce metadata yerelleştir, 4–6 hafta gösterim/indirme verisine bak, ancak talep varsa uygulamayı çevir.

## 5. Lansman kontrol listesi (gerçekçi efor)

**Yayın öncesi (bu hafta)**
- [ ] Blokajlar (README) çözüldü, build seçildi, abonelikler sürüme eklendi.
- [ ] SomineWeb iki dilli sürüm deploy, `AppStoreId=6757957749` (yayından sonra smart banner açılır).
- [ ] Demo hesaplar ve ekran kaydı hazır.
- [ ] Yayın sonrası `ReminderNotifications__Enabled=true` (PLAN.md).

**Lansman haftası (her biri 1–3 saat)**
| Kanal | Ne | Efor | Not |
|---|---|---|---|
| X/Twitter TR yazılımcı + indie çevresi | "Evde yaptık" hikâyesi, 30 sn video | 2 sa | Kişisel hesaptan, samimi ton |
| Instagram/TikTok (kendi hesap) | "Kaydedip unuttuğun tarifler" reels'i, uygulamayla çözüm | 3 sa/video | Haftada 2, Remotion şablonuyla |
| Ekşi Sözlük | "somine" başlığı (kendin reklam yazma; kullanıcıların yazmasını teşvik et) | 0,5 sa | Tanıtım entry'si kurallara aykırı olabilir |
| DonanımHaber / Technopat forumları "iOS uygulama tanıtımı" alt forumları | Tanıtım konusu | 1 sa | Kurallara uygun bölüm |
| Webrazzi / ShiftDelete / Webtekno | Kısa basın bülteni (TR yapımı, Pocket kapandı açısı) | 3 sa | Düşük olasılık, düşük maliyet |
| r/Turkey, r/KGBTR (self-promo kurallarına dikkat) | "Kendi evimiz için yaptığımız uygulama" | 1 sa | Moderasyon kuralları değişken |
| Product Hunt | EN lansman, salı-perşembe, 00:01 PT | 6–8 sa | Önceden 5–10 destekçi; Android/web eksikliği sorulacak |
| r/iOSapps, r/apple "App Saturday", r/productivity | EN tanıtım | 2 sa | Promo kodu ver (Premium için ASC Promo Codes) |
| AlternativeTo, SaaSHub | "Pocket alternatives" altında listelenme | 1 sa | Burada rakip adı serbest |

**İlk ay**
- [ ] İlk 20 kullanıcıyla kişisel görüşme / TestFlight grubundan geri bildirim.
- [ ] Değerlendirme istemi (bölüm 3) ve CPP'ler.
- [ ] Haftalık ASO raporu (anahtar kelime sıraları, dönüşüm).

## 6. Üründe zaten olan büyüme döngüleri

1. **Herkese açık koleksiyon linki** (`somineapp.com/s/{token}`): OG kartıyla WhatsApp/X'te önizleme. Yapılacak: sayfadaki App Store düğmesini kampanya linki yap: `https://apps.apple.com/app/apple-store/id6757957749?pt=<SAĞLAYICI_ID>&ct=share_page&mt=8` (sağlayıcı ID'si ASC → App Analytics → kampanya link oluşturucuda). Yayından sonra `AppStoreId` config'iyle smart banner'ı aç.
2. **Kişiyle koleksiyon paylaşımı:** alıcının uygulamaya sahip olması gerekiyor → doğal davet. Şu an yalnız Premium; büyüme için **ücretsiz planda 1 aktif paylaşım** (sunucu zaten `FreeMaxActiveShares = 1` destekliyor, uygulama Premium'a kilitliyor) açmak düşünülmeli. Ürün kararı.
3. **Arkadaşını Davet Et** (`invite_friend_screen.dart`, link `https://apps.apple.com/app/id6757957749`): linke `?ct=invite` ekle; mesaj metni şu an "Try somine! Collect everything you save in one place." — konumlandırmayla hizala: "Kaydettiklerin kaybolmasın: somine".
4. **Widget ve haftalık özet:** tutma döngüsü; haftalık özet varsayılan kapalı. Onboarding'de tek ekranla "Pazar günleri sana açmadığın kayıtları hatırlatalım mı?" sorusu tutmayı artırır (ölç).

## 7. İzlenecek metrikler

| Katman | Metrik | Kaynak | Hedef (ilk 90 gün, öneri) |
|---|---|---|---|
| Keşif | Gösterim, ürün sayfası görüntüleme, arama/göz atma payı | ASC App Analytics | Haftalık artış |
| Dönüşüm | Ürün sayfası dönüşüm oranı (TR, US ayrı) | ASC | %30+ TR |
| Arama | Takip listesindeki kelimelerin sırası | elle / ücretsiz araç | 8 kelime ilk 20'de |
| Aktivasyon | `activation` (ilk kayıt) / kayıt olan | Firebase | %60+ |
| Kanal | `content_add` source=share_ext oranı | Firebase | %40+ (eklentiyi keşfettiklerinin işareti) |
| Değer | `reminder_set` / aktif kullanıcı; bildirimden açılma | Firebase + sunucu `open_count` | %25+ |
| Tutma | D1/D7/D30 | Firebase | D30 %15+ |
| Gelir | `paywall_view` → `paywall_convert`, deneme yok | Firebase + RevenueCat | %3–5 paywall dönüşümü |
| Viral | `share` eventi, public link görüntüleme, `ct=share_page` indirmeleri | Firebase, sunucu log, ASC kampanya | K-faktörü ölç |
| İtibar | Puan, değerlendirme sayısı | ASC | 4,5+ / 50+ |
