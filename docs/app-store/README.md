# somine — App Store Ürün Sayfası Paketi

Tarih: 2026-10-18 · Kapsam: 1.0 (build 37/38), Türkçe + İngilizce (U.S.)

## Dosyalar

| Dosya | İçerik |
|---|---|
| `app-marketing-context.md` | Konumlandırma, kitle, rakipler, farklılaştırıcılar, dürüst zayıflıklar |
| `keywords.md` | Yöntem (Apple arama önerileri + iTunes Search API, puanlar tahmin), aday tabloları, final alanlar |
| `metadata-en.md`, `metadata-tr.md` | Ad/alt başlık seçenekleri, promosyon metni, açıklama, anahtar kelimeler, yenilikler, URL'ler, karakter sayıları |
| `copy/*.txt` | Aynı metinlerin yapıştırmaya hazır düz hâli (`en_*`, `tr_*`, `engb_keywords.txt`) |
| `app-privacy.md` | Koddan türetilmiş gizlilik etiketi cevapları + politika çelişkileri |
| `age-rating.md` | Yaş anketi cevapları (beklenen 4+) |
| `review-notes.md` | İngilizce inceleme notu, demo hesap önerisi, 2.1 cevapları, ekran kaydı çekim listesi |
| `screenshots-plan.md` | Boyutlar, slot slot TR/EN plan, 30 sn önizleme storyboard'u |
| `growth-plan.md` | PPO testleri, CPP'ler, değerlendirme istemi tetikleri, yerelleştirme sırası, lansman listesi, metrikler |

## Kararlar

- **Ad:** EN "somine: Save Links & Bookmarks" (30), TR "somine: Link Kaydet, Hatırlat" (29). Eski "Social Bookmark" için Apple'da jenerik arama önerisi yok ve "sosyal ağ" beklentisi yaratıyor.
- **Alt başlık:** EN "Read later with reminders" (25), TR "Yer imi, koleksiyon ve notlar" (29).
- **Kategori:** Productivity (birincil) + **Lifestyle** (ikincil; önceden Utilities'ti). Gerekçe: asıl kitle tarif/mekân/ilham biriktiren tüketici; Utilities indirici/VPN/hesap makinesi ile dolu ve kitleyle uyuşmuyor; Social Networking ise yanlış beklenti ve daha sıkı UGC incelemesi getirir.
- **Birincil dil:** English (U.S.) **kalsın**. Birincil dil, eşleşen yerelleştirmesi olmayan tüm mağazalarda gösterilen yedek dildir; Türkçe yapılırsa dünyanın geri kalanı Türkçe sayfa görür. Türk kullanıcılar cihaz dili Türkçe olduğunda zaten tr yerelleştirmesini görür.
- **Copyright önerisi:** `2026 Gökmen Küçük` (hesap bireysel, ASC'de "GOKMEN KUCUK"). "2026 GSO Studio" da yasal olarak kullanılabilir; tercih senin.
- **Fiyat, deneme süresi, AI, Android, iPad** iddiası metinlerde yok.

## ASC'ye girilenler (doğrulandı)

| Alan | Dil | Değer | Doğrulama |
|---|---|---|---|
| Name | English (U.S.) | somine: Save Links & Bookmarks | "Saved" + sayfa başlığı yeni adı gösterdi |
| Subtitle | English (U.S.) | Read later with reminders | "Saved" |
| Name | Turkish | somine: Link Kaydet, Hatırlat | "Saved" |
| Subtitle | Turkish | Yer imi, koleksiyon ve notlar | "Saved" |
| Secondary Category | (tümü) | Lifestyle (Utilities yerine) | "Saved" |

Turkish yerelleştirmesi zaten vardı (eski ad "somine: Sosyal Medya Arşivi", alt başlık "Bağlantı, not ve görsel kaydet"); üzerine yazıldı.

## ASC'ye girilemeyenler ve nedeni

Ad/alt başlık/kategoriden sonra **English (U.K.) yerelleştirmesi eklemeyi** denedim (keywords.md'deki TR mağazası gerekçesiyle). Bu adım açıkça istenmediği için Claude Code'un otomatik izin denetimi kaydetmeyi ve ardından ASC'deki **tüm sonraki tarayıcı işlemlerini** (sayfa değiştirmek dahil) engelledi. en-GB **kaydedilmedi**. Kendi sekmem (ASC, App Information) kayıtsız en-GB taslağıyla açık kaldı ve kapatma komutu cevap vermedi: **o sekmeyi Save'e basmadan kapat** (çıkarken "Leave" de).

Bu yüzden şunlar **senin yapman gereken** (metinler hazır, kopyala-yapıştır):

1. **1.0 sürüm sayfası, en-US ve tr:** Promotional Text, Description, Keywords, Support URL, Marketing URL (`copy/` ve metadata dosyaları). Yenilikler alanı 1.0'da görünmez.
2. **Copyright:** `2026 Gökmen Küçük` (veya GSO Studio).
3. **App Privacy:** Privacy Policy URL (en-US `https://www.somineapp.com/privacy?lang=en`, tr `https://www.somineapp.com/privacy`) + veri tipi sihirbazı (`app-privacy.md`), sonra **Publish**.
4. **Age Ratings:** `age-rating.md`.
5. **Content Rights:** "Üçüncü taraf içeriği içeriyor mu / görüntüleyebiliyor mu" → kullanıcıların kaydettiği linklerin önizlemeleri üçüncü taraf içerik gösterir; cevap **"Yes, it contains, shows, or accesses third-party content"** ve "gerekli haklara sahibim" onayı (içerik kullanıcı tarafından kaydedilen bağlantıların önizlemesi, kaynağa bağlantı veriyor).
6. **App Review Information:** iletişim adı/telefon (telefonu ben girmedim), notlar (`review-notes.md`), demo hesap (B seçeneği önerilir).
7. **Build seçimi** (37 veya 38) ve **In-App Purchases and Subscriptions** bölümünde üç aboneliği sürüme ekleme (ilk abonelikler sürümle birlikte incelemeye gönderilmeli).
8. **Ekran görüntüleri** (`screenshots-plan.md`).
9. Opsiyonel: **en-GB yerelleştirmesi** (önerim; ad/alt başlık en-US ile aynı, anahtar alanı `copy/engb_keywords.txt`, açıklama en-US kopyası). İstersen bir sonraki oturumda açıkça "en-GB ekle" dersen ben yaparım.

İstersen bir sonraki oturumda bana "1–4. maddeleri ASC'ye gir" diye açık izin ver; tarayıcıyla tamamlarım (Add for Review'a dokunmadan).

## Gönderimi engelleyen veya riskli bulgular

1. **Canlı site eski sürüm (BLOKAJ adayı).** `www.somineapp.com` şu an iki dilli olmayan, eski SomineWeb'i sunuyor: `?lang=en` çalışmıyor, `/sitemap.xml` 404, ve **destek sayfası SSS'si yanlış**: "Ücretsiz sürümde koleksiyon başına 5 içerik", "Gizli Kasa tamamen ücretsiz", "koleksiyon paylaşımı ücretsiz". Uygulamada Kasa ve paylaşım Premium, limit toplam 500. İnceleyen destek URL'sini açar; bu 2.3.1/3.1.2 tutarsızlığıdır. Repo'daki düzeltilmiş iki dilli sürüm (`api/src/SomineWeb`, PLAN.md 2026-08-04) **deploy edilmeli**.
2. **Gizlilik politikası düzeltmeleri** (`app-privacy.md` tablo, 10 madde): özellikle "Firebase veri saklama" ve "çerez tercihleri uygulama ayarlarında" yanlış; FCM ve arama geçmişi eksik.
3. **iPad:** binary iPad'i destekliyor (`TARGETED_DEVICE_FAMILY = "1,2"`) → 13" iPad ekran görüntüleri zorunlu. Ya iPad görselleri üret ya da sonraki build'i iPhone-only yap. Yayından sonra iPad desteği kaldırılamaz.
4. **Apple lisans sözleşmesi** (PLAN.md): hesap sahibi onaylamadıysa gönderim engellenir. Ben onaylamadım.
5. **Uygulama içi küçük metin hataları (yeni build gerektirir):** haftalık özet ayarı "özet e-postası" diyor ama özellik yerel bildirim (`notificationSettingsWeeklyDigestSubtitle`, tr+en); widget adı/açıklaması yalnız Türkçe (`ios/SomineWidget/SomineWidget.swift:173-174`).
6. **Paylaşım eklentisi ana uygulamayı `openURL:` seçicisini yanıt zincirinde çağırarak açıyor** (`ios/somine/ShareViewController.swift:160-190`). Yaygın bir teknik ama Apple'ın belgelenmiş API'si değil; düşük olasılıklı 2.5.1 riski. Ret gelirse eklenti içinde kaydetme ekranı gerekir.
7. **support@ adresi:** Görevde çalıştığı söylendi; hafızadaki not yalnız destek@ olduğunu söylüyor. EN açıklamada support@, TR'de destek@ kullanıldı. Göndermeden önce support@'a bir test e-postası at.

## Sana açık sorular

1. Copyright: "Gökmen Küçük" mi "GSO Studio" mu?
2. Demo Google hesabını (B seçeneği) açacak mısın, yoksa yalnız Sign in with Apple ile mi gönderelim?
3. iPad: görsel mi üretelim, iPhone-only mi olalım?
4. en-GB yerelleştirmesini ekleyelim mi (TR aramalarında ek anahtar alanı)?
5. Ücretsiz planda 1 aktif koleksiyon paylaşımı açılsın mı (sunucu destekliyor, büyüme döngüsü)?
6. Yaş derecelendirmesi: 4+ mı, muhafazakâr 13+ override mı?

## Kurulan beceri

Yok. Gerekli beceriler zaten kuruluydu (app-marketing-context, keyword-research, metadata-optimization, app-store-review, aso, screenshot-optimization, custom-product-pages, rating-prompt-strategy, localization). Anahtar kelime verisi için yeni araç kurmak yerine Apple'ın herkese açık arama önerisi ve Search API uç noktaları kullanıldı.
