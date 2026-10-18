# SoMine — Tek Plan

Son güncelleme: 2026-08-03
Bu, projenin **tek** plan dosyasıdır. Eski plan/migrasyon dokümanlarının tamamı silindi; tarihsel bilgiye ihtiyaç olursa kaynak koddur. Operasyonel istisnalar: `somine_api/DOCKER_HETZNER_DEPLOYMENT.md` (deploy talimatı) ve `somine_api/LOCAL_SECRETS.md` (lokal secret kurulumu) plan olmadıkları için korundu.

---

## 🎨 TASARIM + UX DENETİMİ (2026-10-17)

apple-design becerisiyle (Apple HIG) uçtan uca denetim; ~60 bulgu düzeltildi. App `c2a4961`, API `d5f0c34` (137/137, migration `UgcReportsAndBlocks`).
- **1.2 UGC:** paylaşılan koleksiyonda Bildir / Engelle / Kitaplığımdan çıkar (… menüsü), istekte "Reddet ve engelle", Engellenenler ekranı. Raporlar `content_reports` tablosunda; **24 saat içinde bakılacağı söz verildi — takip süreci gerekli.**
- Hesap silme Hesap Bilgileri'nden de çalışıyor, Apple token revoke, resmî Apple düğmesi, onboarding'de ad önden dolu.
- Paywall okunur, indirim gerçek fiyattan, satın alma hataları görünür, Premium'da abonelik yönetimi.
- InfoPlist.strings en/tr, mikrofon izni kaldırıldı; paylaşım eklentisi sadece link/metin.
- Kontrast tokenları AA, VoiceOver etiketleri, min 11pt, Hareketi Azalt; kaydetme hataları görünür, kaydedilmemiş değişiklik uyarısı, boş ekran düğmeleri, kasa açma düğmesi, tekrar kayıt uyarısı.
- Haftalık özet varsayılan kapalı; kasa içerikleri kilit ekranı bildiriminde görünmez.
- **Deploy sırası:** prod'da `somine_api/prod_v18_ugc_reports_and_blocks.sql` → yeni API imajı → build 37.
- **Açık karar:** karanlık mod sistemi takip etmiyor (Midnight Premium). Air/Vibe primary düğmelerinde beyaz yazı 3.6/3.0:1 (marka kararı).


## 🌐 SOMINEWEB İKİ DİLLİ (TR/EN) — landing + paylaşım sayfası (2026-08-04)

**Tetikleyici:** Bir önceki oturumda bırakılan "⚠️ Landing sitesinin İngilizcesi YOK" maddesi. App Store'a verilen gizlilik ve destek adresleri bu sayfalar; tek dilli olmaları hem inceleme hem de yurt dışı kullanıcı açısından sorundu.

### Seçilen mimari ve gerekçesi
- **Kısa arayüz metinleri → tek `.resx` çifti.** `Resources/SharedResource.resx` (Türkçe, **nötr**) + `SharedResource.en.resx`, `IStringLocalizer<SharedResource>` ile `_ViewImports.cshtml`'de `L` olarak enjekte edildi. **216 anahtar.** Sayfa başına ayrı resx yerine tek dosya çifti seçildi: 9 view için 18 dosya yerine 2 dosya, ve iki dil arasındaki anahtar eşitliği **tek bir yerde** denetlenebiliyor. Anahtarlar önek kuralıyla ayrılıyor (`nav.*`, `footer.*`, `index.*`, `share.*`, `support.*`, `delete.*`, `plan.*`, `layout.*`, `common.*`).
- **Uzun hukuki/uyum metinleri → dile göre ayrı Razor parçaları.** `Pages/Shared/_PrivacyBody.{tr,en}.cshtml`, `_TermsBody.{tr,en}.cshtml`, `_SupportReport.{tr,en}.cshtml`. **Gerekçe:** hukuki metin bölüm bölüm okunur ve revize edilir, cümleler birbirine bağımlıdır, içinde satır içi biçimlendirme (`<strong>`, bağlantı) vardır ve iki dilin madde yapısı zamanla meşru biçimde ayrışabilir. Anahtar anahtar bölmek hem çeviriyi hem bakımı bozardı; resx'e HTML gömmek de ayrı bir koku olurdu. Sayfaların kabuğu (başlık, "Son güncelleme" tarihi) resx'te kaldı.
- **Landing (`Index.cshtml`) resx'te bırakıldı**, parçalara bölünmedi: 490 satırlık markup'ı iki dile kopyalamak her tasarım değişikliğini iki yerde yapmayı gerektirirdi. Metinleri zaten kısa ve ayrık.

### Dil çözümleme (`Program.cs`)
`RequestLocalization` sağlayıcı sırası — **bilinçli**:
1. `?lang=en|tr` (açık seçim, her şeyi ezer) · 2. **`OgScraperCultureProvider`** (yeni) · 3. çerez · 4. `Accept-Language` · 5. varsayılan **tr**.
- Çerezi kimse yazmıyordu; `UseRequestLocalization` sonrasına küçük bir middleware konuldu, `?lang=` görünce `.AspNetCore.Culture` çerezini 1 yıllığına yazıyor → **seçim kalıcı**.
- **🔑 OG kazıyıcı çözümü:** `facebookexternalhit`, `Twitterbot`, `WhatsApp`, `Telegram`, `Slack`, `Discord`, `LinkedIn`, `Pinterest`, `Applebot`, `Googlebot` vb. 30 token için — açık `?lang=` yoksa — dil **tr'ye sabitleniyor**. Sebep: bu botların çoğu `Accept-Language` göndermez, gönderenlerin başlığı da paylaşanla veya linki açacak kişiyle ilgisizdir (sunucu konumuna göre `en-US` gelebilir). Sabitleme sayesinde kartın dili **deterministik** ve sayfanın gerçek diliyle **her zaman aynı**. `?lang=en` ile paylaşan biri isterse İngilizce kart alır (kaçış yolu).
- OG etiketleri artık aktif kültürden üretiliyor (`ShareModel`'e `IStringLocalizer` enjekte edildi), `og:locale` + `og:locale:alternate` doğru yazılıyor.

### SEO
- `<html lang>` dinamik (her iki layout).
- Her dil sürümü **kendi canonical adresine** sahip (`/privacy?lang=en`), `hreflang="tr"|"en"|"x-default"` alternatifleri eklendi; `x-default` dil pazarlığı yapan parametresiz adres.
- **`/sitemap.xml` yeni** — `robots.txt` yıllardır ona işaret ediyordu ama **dosya hiç yoktu (404)**. `Program.cs`'te minimal endpoint, 5 sayfa × 2 dil = 10 `<loc>`, her birinde `xhtml:link` alternatifleri.
- **`/s/{token}` üzerindeki `noindex` korundu** (iki dilde de teyitli) ve o sayfada canonical/hreflang **bilinçli olarak yayınlanmıyor** (`ViewData["SuppressAlternates"]`).

### Dil değiştirici
Navbar (masaüstü + mobil), mobil menü paneli ve footer'da sade **TR/EN** hap düğmesi (`_LanguageSwitcher.cshtml`, 4 varyant: transparent/solid/menu/footer). Mevcut tasarım diline yaslanıyor — `#688E8B`, `rounded-full`, aynı tipografi; **yeni renk/tipografi getirilmedi**. Bağlantılar geçerli yolu ve sorgu dizesini koruyor (`/support?foo=1&lang=en` teyitli).

### Yol boyunca düzeltilen gerçek hatalar (kapsam dışıydı, ama yanlış bilgiyi İngilizceye kopyalamak olmazdı)
- **`Index.cshtml` premium tablosu üç yerde yanlıştı:** "Koleksiyon başına 5 içerik" → gerçekte **toplam 500** · **Gizli Kasa ücretsiz görünüyordu** → Premium (`catalog_screen.dart:1491`) · hatırlatıcı limiti hiç yoktu → **3 aktif hatırlatıcı** eklendi. Ayrıca özellik kartlarındaki "Gizli Kasa… tamamen ücretsiz" ve "tüm temalar ücretsiz" ifadeleri düzeltildi (ikincisi aynı sayfadaki Temalar bölümüyle **kendi içinde çelişiyordu**). Kaynak: `SubscriptionLimits.cs` + `subscription_service.dart:270-275`.
- `Terms.cshtml` ücretsiz plan kutusu "Sınırlı sayıda koleksiyon" → **"10 koleksiyon, toplam 500 içerik"**; iki dile de UGC/şikâyet maddesi eklendi (Madde 2).
- `_Layout.cshtml` (Error sayfası) **"SoMine" → "Somine"** ve `lang` dinamik. Sitede artık hiç "SoMine"/"So Mine" yok (curl ile teyitli).

### Destek sayfası kararı
- **EN sürümde ayrı "In English" paragrafı kaldırıldı** — sayfanın tamamı zaten İngilizce.
- **TR sürümde bilinçli olarak BIRAKILDI** (+ "Read this page in English" bağlantısı eklendi). Gerekçe: App Store'a verilen destek adresi bu sayfa; inceleyen kişi `Accept-Language` göndermeyen bir araçla ya da doğrudan bağlantıyla Türkçe sürüme düşerse şikâyet mekanizmasını yine de okuyabilsin. Maliyeti bir paragraf, karşılığı bir ret riskinin kapanması.
- `id="icerik-bildirimi"` çapası **iki dilde de aynı** bırakıldı (paylaşım sayfası ve dışarıya verilmiş adresler ona işaret ediyor).
- FAQ iki dilde de uygulamanın gerçeğiyle uyumlu (10 koleksiyon / 500 içerik / 3 hatırlatıcı; Gizli Kasa + koleksiyon paylaşımı Premium).

### Uygulama ↔ paylaşım bağlantısı
- **KARAR: paylaşılan URL'e dil parametresi EKLENMEDİ.** `publicLinkUrlFromToken` değişmedi. Gerekçe: bağlantıyı **açan** kişinin dili önemli, paylaşanın değil; otomatik algılama bunu zaten çözüyor ve URL temiz kalıyor. `?lang=` manuel geçiş için çalışıyor (teyitli), bot tarafı da yukarıdaki sağlayıcıyla deterministik.
- **Paylaşım akışında kalan Türkçe temizlendi.** `share_repository.dart`'taki `throw Exception('Kullanıcı bulunamadı')` / `'Bu koleksiyon zaten bu kişiyle paylaşılmış'` / `'Paylaşım isteği oluşturulamadı'` üçlüsü, `catalog_screen`'deki `_userFacingErrorMessage` tarafından **aynen** ekrana basılıyordu → İngilizce cihazda Türkçe hata. `AppException`'a **dilden bağımsız `code` alanı** eklendi (`AppErrorCodes`), `FailureMapper` kodu l10n'a çeviriyor, `_userFacingErrorMessage` silindi. Kullanıcı aramasındaki iki `errorMessage = e.toString()` de `FailureMapper.toUserMessage(e, l10n)` oldu.
- **3 yeni ARB anahtarı** (TR+EN): `shareCreateUserNotFound`, `shareCreateAlreadyShared`, `shareCreateFailed` → **564/564 eşit**, sıra da aynı.

### Doğrulama
- `dotnet build SomineApi.slnx` → **0 hata** · `dotnet test SomineApi.slnx` → **131/131**
- `flutter analyze` → **0 hata** · `flutter test` → **30/30** · ARB **564/564 eşit**
- Lokal (5135) curl: `/`, `/privacy`, `/terms`, `/support`, `/delete-account` iki dilde de **200**, `/s/xxx` iki dilde de **404**; `<html lang>` doğru; İngilizce sayfalarda **hiç Türkçe karakter yok**; ham resx anahtarı sızmıyor; `noindex` iki dilde de yerinde; `og:locale` sayfanın diliyle birebir.
- Dil zinciri 14 senaryoyla test edildi (başlıksız→tr, `de-DE`→tr, `?lang=fr`→zincire düşer, çerez ezer, bot+`en-US`→tr, bot+`?lang=en`→en).

### ⏳ Deploy bekleyen
- **Yeni SomineWeb imajı** (iki dilli site). Önceki oturumdan kalan destek+paylaşım sayfası değişiklikleri de bu imajın içinde.
- **Yeni API imajı** (bildirim `Data` alanları) — önceki oturumdan bekliyor.
- **Mobil: yeni build gerekli** (paylaşım hatası çevirileri build 36'da YOK). Bu oturumda **IPA alınmadı**.
- Hiçbir değişiklik **commit edilmedi**.

### 👀 İnsan gözü gerekiyor
- **Çeviri tonu:** İngilizce pazarlama metinleri (hero, özellikler, temalar, premium) makine değil elle yazıldı ama **anadili İngilizce olan biri okumadı**. Özellikle hero başlığı ("Everything You Love, in One Place") ve tema etiketleri gözden geçirilmeli.
- **Hukuki metin:** Gizlilik ve Şartların İngilizcesi anlam kaybı olmadan çevrildi, KVKK çerçevesi korundu (GDPR iddiası **uydurulmadı**, uygulanacak hukuk Türkiye). Yine de **bir hukukçunun onayı önerilir** — özellikle "Governing Law" ve "Limitation of Liability" bölümleri.
- Sitenin **görsel** kontrolü tarayıcıda yapılmadı (yalnız curl ile HTML doğrulandı); dil değiştiricinin mobil menüdeki yerleşimi göz kararı onaylanmalı.

---

## 🌍 UGC BİLDİRİM MEKANİZMASI + TAM İNGİLİZCE (2026-08-03)

**Tetikleyici:** App Store 1.2 (kullanıcı üretimi içerik) maddesi — Apple dört şey istiyor: içerik filtreleme, şikâyet mekanizması, taciz eden kullanıcıyı engelleme, yayımlanmış iletişim bilgisi. Elimizde kısmi karşılıklar vardı, **şikâyet mekanizması yoktu**.

- **🔴 Doğrulanan delik:** `somineapp.com`'un **MX kaydı yok** (Cloudflare DoH ile teyitli) → destek sayfasında ve uygulamada yayımlanan `support@somineapp.com` adresine mail **ulaşmıyordu**; destek sayfasındaki form da `action="mailto:"` (Chrome sessizce yutuyor). Yani "yayımlanmış iletişim bilgisi" ayağı fiilen karşılanmıyordu. **Kullanıcı Cloudflare Email Routing ile `support@` ve `abuse@` yönlendirmesini açıyor.**
- **Destek sayfası (`Support.cshtml`) ✅:** `id="icerik-bildirimi"` çapalı **İçerik bildirimi** bölümü — ne bildirilir, nereye (`abuse@somineapp.com`, konu satırı hazır), mesajda ne olmalı, **24 saat içinde değerlendirme** taahhüdü, ihlalde link iptali + içerik kaldırma + tekrarda hesap askıya alma, uygulama içi karşılıklar (isteği reddet / paylaşımı kaldır / linki iptal et) ve inceleyen için **İngilizce paragraf**. Form artık JS ile gerçek bir mailto taslağı kuruyor.
- **FAQ'daki 3 yanlış bilgi düzeltildi (ret riskiydi):** "koleksiyon başına 5 içerik" → **500 içerik / 10 koleksiyon / 3 hatırlatıcı** (`SubscriptionLimits` ile birebir) · "Gizli Kasa ücretsiz" → **Premium** · "koleksiyon paylaşımı ücretsiz" → **Premium**. +3 yeni SSS (hatırlatıcılar, uygunsuz içerik, hesap silme).
- **Paylaşım sayfası (`Share.cshtml`) ✅:** CTA altına "Bu içeriği bildir" — mailto konusu/gövdesi **şikâyet edilen sayfanın adresiyle önceden dolu**, yanında `/support#icerik-bildirimi` bağlantısı. Dışa açık tek yüzey kapandı.
- **Sonraki sürüm işi (karar):** uygulama içine "Paylaşımı bildir" + "Bu kullanıcıdan paylaşım alma". 1.0 için mevcut üçlü savunulabilir.

**Tam İngilizce turu (build 36):** ARB zaten 530/530 çeviriliydi ama **sabit Türkçe metinler** vardı.
- 31 yeni ARB anahtarı (TR+EN, **561/561 eşit**): paywall plan adları/açıklamaları · Bugün/Yarın · harita-tarayıcı "…'da Aç" varyantları · Düzenle · telif uyarısı · hatırlatıcı saat etiketleri · varsayılan koleksiyon adları · bildirim metinleri.
- **`timeago` sabit `'tr'`'den kurtuldu** → `formatRelativeTime(context, …)` aktif dile bakıyor (4 çağrı yeri). `initializeDateFormatting` iki dil için de yapılıyor.
- **Elle yazılmış ay kısaltması dizileri silindi** → `formatShortDate` (intl `DateFormat.MMMd/yMMMd`, locale duyarlı; EN "Aug 5", TR "5 Ağu").
- **`Info.plist` → `CFBundleLocalizations = [tr, en]`** (yoktu; App Store "Diller" alanı binary'den türüyor). IPA içinde doğrulandı.
- **Varsayılan koleksiyonlar artık kullanıcının dilinde oluşuyor** (`defaultCategories` adları dışarıdan alıyor; onboarding eşleştirmesi ad yerine **order** ile).
- **`'Hızlı'` mantık anahtarı korundu** ama tek yerde tanımlandı (`kQuickCategoryKey`) ve **gösterildiği tek yerde** (detay sheet'i) `categoryDisplayName` ile çevriliyor → EN'de "Quick".
- **Bildirim metinleri:** yerel bildirim başlıkları `appL10n` ile (servis katmanında context yok) · sunucudan gelen Türkçe bildirimler istemcide yeniden yazılıyor (`NotificationDisplay`) — API bildirim `Data`'sına **`fromUserName`/`categoryName`** eklendi, Title/Message Türkçe **bilinçli olarak korundu** (eski istemciler bozulmasın; alan yoksa sunucu metnine düşülüyor).
- **Ölü dosya temizliği:** `capture_screen.dart` (482 satır) ve `demo_mock_data.dart` — ikisi de **0 referans**.
- **Doğrulama:** `flutter analyze` **0 hata** · `flutter test` **30/30** · `dotnet test` **131/131** · `flutter build ipa` ✓ → **build 36**, `Somine.ipa` (67 MB), her iki uzantı ve `CFBundleLocalizations` IPA içinde teyitli.

**⏳ Deploy bekleyen:** yeni **SomineWeb imajı** (destek + paylaşım sayfası) ve yeni **API imajı** (bildirim `Data` alanları). Build 36 TestFlight'a yüklenmeli.

**~~⚠️ Landing sitesinin İngilizcesi YOK~~ → ✅ ÇÖZÜLDÜ (2026-08-04):** somineapp.com artık iki dilli (TR/EN). Ayrıntı için en üstteki "SOMINEWEB İKİ DİLLİ" bölümüne bak.

---

## 🔖 GÜNCEL DURUM (2026-08-02 gece)

Bu blok her oturum sonunda güncellenir. Ayrıntılı tarihli kayıt aşağıda ("Günlük" bölümleri).

### 🟢 Canlıda (prod)
- **API `gokmenkucuk/somineapi:prod_v14`** — auth 23505 yarış koruması · açılma takibi (`items/{id}/opened`) · JSON/CSV export · trigram (pg_trgm) arama · kategori public link · hatırlatıcı bildirim altyapısı [**bayrak KAPALI**] · kullanıcı saat dilimi · RepeatFrequency enum düzeltmesi + kendini onaran `MapToDto`. Probe'larla doğrulandı (auth 401, uçlar mevcut).
- **Web `gokmenkucuk/somine-share:v5`** — paylaşım sayfası landing tasarımına taşındı · OG kartları + koşullu smart banner (`AppStoreId` boş) · `Api__BaseUrl` imaja gömülü (appsettings.Production.json) · marka yazımı "Somine" tekleşti.
- **DB (uygulanan SQL'ler):** v12-part1 (açılma kolonları) · v13 (trigram) · v14 (kategori public link) · v15 (saat dilimi + reminder indeksi) · v16 (enum veri düzeltmesi). **part2-embeddings UYGULANMADI** (pgvector iptal, semantik arama pasif).

### 📄 App Store denetim raporu (canlı belge)
Adres: **https://claude.ai/code/artifact/6d9982d3-ad85-48b7-8130-7c40cd3c07e4** — kapatılan denetim maddeleri, güvenlik turu, gönderim sırası ve App Store Connect'te kullanıcıyı bekleyenler (hazır inceleme notu metni dahil). Kullanıcı istediğinde güncellenip aynı adrese yeniden yayınlanır (dosya: `scratchpad/appstore-denetim.html`).

### 🟡 Mobilde hazır, TestFlight bekliyor
TestFlight'taki son sürüm **build 33** — aşağıdaki bugünkü mobil işleri İÇERMİYOR. Yeni build (34) gerekli:
Hatırlatıcılarım ekranı · reminder bildirim tipi + `unknown` fallback · saat dilimi gönderimi · Link ile paylaş · dışa aktarma UI · widget · abonelik üçlü düzeltmesi (RevenueCat kimlik + backend fallback + oto-restore) · App Store uygunluk düzeltmeleri (paywall dürüstlüğü, kullanılmayan izinler, privacy manifest, launch screen) · tasarım turları (divider/danger token'ları, 31 clipBehavior, üst butonlar → `CircleIconButton`, masonry oran önbelleği, shimmer, görünüm-modu çift zemin). Son build telefonda + simülatörde çalışıyor.

### 🧾 Kapanış turu (2026-08-02 gece) — son eklenenler
- **Marka yazımı tekleşti:** Uygulamadaki tüm kullanıcıya görünen "So Mine" → **"Somine"** (Yardım&Destek SSS, davet metinleri, ayarlar sürüm satırı, destek e-posta konusu, sistem başlığı, ARB TR+EN). **DOKUNULMADI:** `subscription_service.dart`'taki `"So Mine Premium"` — o bir metin değil, RevenueCat panelinde tanımlı **entitlement kimliği**; değiştirmek premium tespitini komple bozardı.
- **Konum izni GERİ eklendi** (`ITMS-90683`): Apple yükleme sonrası uyardı. Sebep: bizim kodumuz konum istemiyor ama bağlı SDK (`apple_maps_flutter` → MapKit/CoreLocation) API'ye referans veriyor; Apple **binary'yi** tarıyor, Dart kodunu değil. Metin dürüst tutuldu: "Kaydettiğiniz konum bağlantılarını harita önizlemesinde göstermek için kullanılır." (Harita gerçekten yalnız kaydedilen koordinatı gösteriyor, kullanıcı konumu hiç istenmiyor.) → **build 35**. `NSLocalNetworkUsageDescription` geri EKLENMEDİ (Apple şikâyet etmedi).
- **Gizlilik politikası güncellendi** (`Privacy.cshtml`): **Firebase Analytics** + **Firebase Crashlytics** maddeleri eklendi (bugüne kadar hiç anılmıyordu — App Privacy anketiyle tutarsızlık ret sebebi olabilirdi) · uygulama içi **dışa aktarma ve hesap silme** hakkı yazıldı · tarih 2 Ağustos'a alındı · IDFA/reklam takibi yapılmadığı açıkça belirtildi.
- **Paylaşım sayfası görsel yer tutucusu:** Dış kaynaklı görseller (Instagram CDN) hotlink engeli veya **süresi dolmuş adres** yüzünden yüklenemiyordu → kırık resim ikonu çıkıyordu. Artık yer tutucu her zaman altta duruyor, görsel yüklenemezse `onerror` ile kendini kaldırıyor. Yer tutucu **tek renk ve tipografik** (nane gradyan + soluk sage ikon + platform adı kapitallerle) — kullanıcı kararı: renkli platform logoları sayfanın sade dilini bozuyor. **NOT: Bu sorunu GİZLİYOR, çözmüyor** — görsel hâlâ gelmiyor. Gerçek çözüm: kaydederken görseli kendi depomuza indirmek (aday iş, aşağıda).
- **`prod_v17` uygulanmamıştı → prod 500:** Deploy sonrası `GET /api/items` 500 döndü; sebep `og_image_width/height` kolonlarının eksikliğiydi (sabahki `premium_checked_at_utc` senaryosunun aynısı). Kullanıcı SQL'i uygulayınca düzeldi. **Ders tekrar: şema HER ZAMAN imajdan önce ve tam olarak gitmeli.**
- **API key rotasyonu iptal** (ayrıntı aşağıda) — prod'da katman zaten kapalıymış.

### 🖼️ ADAY İŞ: og:image'ları kendi depomuzda saklamak
Paylaşım sayfasındaki görsellerin gerçekten görünmesi için tek kalıcı çözüm: içerik kaydedilirken OG görselini bir kez indirip kendi depomuza yazmak. Instagram/TikTok CDN adresleri **süreli** olduğu için proxy'lemek yetmez (adres ölüyor). Sunucuda mevcut Channel-kuyruk kalıbı (`EmbeddingBackgroundService`) bunun için kopyalanabilir. Depolama büyümesi ve indirme hata yönetimi düşünülmeli. **Kullanıcı kararı: App Store gönderimi sonrasına bırakıldı.**

### 🔴 Sıradaki adımlar (öncelik sırası)
1. **Kullanıcı testi:** masonry kaydırma + edit sheet aşağı-sürükleme kapanışı (ajanlar test edemedi).
2. **Güvenlik sıkılaştırması ✅ uygulandı** (bkz. 🔐 bölümü) — API kod hazır (deploy bekliyor), mobil telefonda test edilebilir.
3. **API yeni imaj (prod_v15)** — güvenlik başlıkları + search rate limit + public-file exact-match içeriyor. Derlenip deploy edilecek.
4. **Build 34 → TestFlight** (sürüm artır → IPA → Organizer). API key ESKİ/çalışan (`a148c8a4…`) ile derlenir. İçerir: bugünkü tüm mobil işler + güvenlik sıkılaştırmaları + ölü dosya temizliği.
5. **Build 34 yayıldıktan SONRA** sunucu `.env`: `ReminderNotifications__Enabled=true` (erken açılırsa eski sürümler "reminder" tipini paylaşım isteği sanar).

### ✅ Bu oturumda ek olarak biten
- Ölü dosyalar silindi: `edit_content_screen.dart` + `item_detail_screen.dart` (0 referans; 22 eski DesignTokens kullanımı da gitti).

### ⏳ Karar/ileri iş (aciliyet yok)
- Haftalık plan yapısı (kullanıcı kararı; trial İPTAL — kullanıcı kredi kartı zorlamayı istemiyor)
- `AppStoreId` config (App Store yayını sonrası → smart banner açılır)
- ~~API key rotasyonu~~ **İPTAL — gerek yok (2026-08-02 doğrulandı).** Prod `.env`'de `ApiKey__Key`/`ApiKey__Enabled` YOK → `appsettings.json` varsayılanı geçerli → `Enabled: false` → **API key kontrolü prod'da hiç çalışmıyor.** Kanıt: anahtar katmanı aktif olsa başlıksız istek düz metin `Unauthorized` gövdesi dönerdi; canlı test **boş gövde** döndü (istek katmanı geçip JWT'de reddedildi). Dolayısıyla ortada zorlanan bir anahtar yok, rotasyon anlamsız ve build/sunucu eşzamanlılık kısıtı da **geçersiz** — build 34 istenen an yüklenebilir, build 33 çalışmaya devam eder.
  **Karar: katman kapalı kalsın.** Anahtar zaten binary'den çıkarılabiliyor (gerçek saldırganı durdurmuyor), buna karşılık açık olması her mobil sürümde sunucu-uygulama anahtar eşleşmesi zorunluluğu getirir; eşleşmezse TÜM kullanıcıların uygulaması çalışmaz. Sağladığı korumaya kıyasla operasyonel riski büyük. Gerçek korumalar yerinde: JWT + sunucu tarafı sahiplik kontrolleri + hız sınırları + güvenlik başlıkları.
  (Not: build 34 yeni anahtarla derlendi — kontrol kapalı olduğu için etkisiz, sorun değil.)
- og:image boyutlarını backend'de sakla (masonry ilk-görüntüleme 10.9px'i sıfırlar; şu an gerek yok)
- **somine_api GitHub yedeği YOK** (hâlâ yalnız bu makinede — risk!)
- request_logs retention temizliği · dotnet paket güvenlik uyarıları (NU1903)
- RepeatFrequency enum: mobil-sunucu artık hizalı ama kalıcı temizlik için mobil `repeat.index` yerine isim gönderebilir (opsiyonel)

---

## 🗄️ VAULT SUNUCU AYRIMI + OG:IMAGE BOYUTLARI (2026-08-02, kapanış turu)

### Vault sunucu tarafı ayrımı ✅ (API 131/131 · App 30/30)
**Yapılan:** Vault kategorisindeki item'lar artık `GET /api/items`, `/search`, `/favorites`, `/deleted` uçlarından **varsayılan olarak dönmüyor**; `includeVault=true` ile açıkça isteniyor. Ayrı uç yerine query parametresi seçildi (5 farklı liste şekli — sayfalama, trigram/semantik sıralama, platform filtreleri — tekrarlanmasın diye). **Sunucu tarafı ek yetki kontrolü BİLİNÇLİ OLARAK EKLENMEDİ** ve koda yorumla yazıldı: biyometrik sunucuya kanıtlanamaz, oraya sahte bir güvenlik kontrolü koymak ileride "burası korumalı" yanılgısı yaratırdı. Parametre bir niyet beyanıdır, güvenlik sınırı değil.
**Bozulmadığı tek tek doğrulananlar:** kota sayacı (vault item'ları hâlâ 500 limitine sayılıyor — test: 499 vault item'la 500. reddediliyor) · kategori listesi (vault kategorileri `isVault: true` ile dönmeye devam) · export (vault dahil, kullanıcının bilinçli kendi verisi talebi) · public shares (dokunulmadı) · client-side filtreler (defense-in-depth olarak KORUNDU, yalnız istekler açık-parametreli hale geldi).
**Sayaç kazanımı:** `getItemCount` eskiden **tüm item'ları indirip** `.length` alıyordu; vault hariç tutulunca sayı sunucunun 500 kontrolünden sapacaktı. Yeni `GET /api/items/count` ucu eklendi — tek sayı döner (vault dahil), istemci/sunucu tutarlı ve sayaç dramatik biçimde ucuzladı.
**Kullanıcıya görünür davranış değişiklikleri (bilinçli):** (1) Feed'de vault kategori chip'leri artık her zaman görünüyor — aksi halde kilitli vault feed'den ulaşılamaz hale gelirdi; yan fayda: chip varlığı artık vault'un dolu olup olmadığını sızdırmıyor. (2) Kilitliyken vault item'ına kurulu hatırlatıcı, başlığı sızdırmamak için "içerik bulunamadı" etiketiyle görünüyor. (3) Kilitli katalog kartları artık gerçek sayı yerine 0 gösteriyor (bu bir sızıntı düzeltmesi). (4) **iOS ana ekran widget'ı ve haftalık özet artık vault item'larından beslenmiyor** — kod tabanındaki en ciddi sızıntı buydu. (5) `GET /api/items/{id}` bilinçli açık bırakıldı (bildirim/deeplink akışının kendi fail-closed vault kapısı var).
**Bu değişikliğin GERÇEKTEN engellediği:** Vault verisi normal kullanımda cihaza hiç inmiyor — disk önbelleği, bellek dökümü, arka plan anlık görüntüsü, widget ve bildirimler temiz. Çalınmış ama kilitli telefondan vault hakkında hiçbir şey çıkmıyor. Yeniden paketleme çıtası "tek `.where()` satırını sil"den "API sözleşmesini anla ve birden çok çağrıya parametre ekle"ye yükseldi.
**Engellemediği:** Geçerli access token'a sahip biri (değiştirilmiş build çalıştıran kullanıcı dahil) `includeVault=true` gönderip her şeyi alabilir. Export'ta vault hâlâ var, `GET /api/items/{id}` ile id bilinen item tek tek çekilebilir, vault kategori ADLARI listeleniyor ve sunucu düz metni her an okuyabiliyor. **Bu bir maruziyet azaltması, güvenlik sınırı değil** — sınır ancak sunucunun anahtarı hiç görmediği client-side şifrelemeyle kurulur (ayrı proje).

### og:image boyutları sunucuda ✅
`items.og_image_width/height` (migration `20260802144654_AddOgImageDimensions`, prod SQL `prod_v17_og_image_dimensions.sql`, pgvector temiz). OG metadata **istemcide** çekildiği için boyutu da istemci gönderiyor — sunucu görsel indirmiyor, yalnız `0 < değer <= 20000` aralığını saklıyor. Ölçüm URL'e bağlı (geç gelen sonuç başka görselin oranını bozmuyor). Oran çözümleme sırası: **(a) sunucu boyutu → (b) yerel önbellek → (c) 16:9**; sunucudan oran gelince ölçüm hiç başlatılmıyor. Yerel önbellek korundu (boyutsuz eski kayıtlar için). **Kazanım:** yerel önbellek yalnız o cihazda geçerliydi; artık yeni telefon/yeniden kurulumda da ilk saniyeden doğru oran.

## 🔐 GÜVENLİK DENETİMİ + SIKILAŞTIRMA (2026-08-02)

İki paralel tersine-mühendislik analizi (API + mobil, GPT 5.5 köprüsü) + orkestratör doğrulaması. **Önemli:** Ajanların "prod config göremedim → KRİTİK" bulgularının çoğu doğrulamayla düştü.

### ✅ Uygulandı (net kazanımlar, davranış bozmadan)
**API (kod hazır, DEPLOY BEKLİYOR — yeni imaj gerekir):**
- Güvenlik başlıkları middleware'i: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Content-Security-Policy: default-src 'none'` + prod'da `UseHsts()`.
- `GET /api/items/search` için `"search"` rate limit policy'si (kullanıcı başına 30/dk) — global 300/dk'ya ek, trigram DB yükü koruması.
- `PublicSharesController` görsel proxy: `Contains` substring → yol-segmenti tam eşleşme (yanlış-pozitif/manipülasyon kapatıldı).
- Loglama denetimi: **temiz çıktı** — `RequestBodyPreview` hep null, auth body'si (idToken/refreshToken) hiç loglanmıyor, query maskeleme listesi zaten kapsamlı.
- 118/118 test.

**Mobil (uygulandı, telefonda test edilebilir):**
- **Deeplink vault bypass guard:** `openItemDetail` artık vault kategorideki item'ı açmadan önce biometric unlock istiyor — 4 giriş noktasının hepsi (bildirim tap, widget `somine://`, reminder bildirimi, bildirimler ekranı) tek kapıdan geçiyor.
- **Token'lar Keychain'e:** backend session (access+refresh) SharedPreferences düz metin → `flutter_secure_storage` (iOS `first_unlock_this_device`, yedeğe gitmez). Migration: eski prefs → Keychain, sonra plaintext sil (başarısızsa Firebase ile yeni exchange, risk düşük).
- **Deeplink itemId doğrulama:** `^[A-Za-z0-9_-]{1,128}$` — path traversal/reserved karakter reddi.
- **Prod log hijyeni:** response body/uid/email basan debugPrint'ler `kDebugMode` guard'ına alındı (release'de status+endpoint alias yeter). `flutter_secure_storage ^9.2.2` eklendi. 24/24 test.

### 🔍 Orkestratör incelemesi — ajan işinde bulunan 3 kusur (düzeltildi)
Ajan raporlarına güvenilmeyip kod okundu; üç gerçek sorun çıktı:
1. **🔴 Vault guard FAIL-OPEN'dı.** Kontrol `itemCategory?.isVault == true` şeklindeydi; `itemCategory` üç durumda null kalıyordu (userId yok · **kategori isteği hata verirse** — catch'te yutuluyordu · kategori listede bulunamazsa). Üçünde de guard atlanıp **vault item'ı kilitsiz açılıyordu** — yani kategori isteğini düşüren bir saldırgan (veya sıradan bir ağ hatası) kilidi devre dışı bırakabiliyordu. **Düzeltme:** `vaultStatusResolved` bayrağı eklendi; vault durumu KESİN belirlenemezse kilit isteniyor (fail-closed). Kategorisiz item vault olamayacağı için o yol hızlı geçiyor.
2. **🟠 `saveSession` korumasızdı.** Keychain yazması SharedPreferences'ın aksine başarısız olabilir; hata tüm `ensureSession` akışını kırardı (üretimde "bazen giriş yapılamıyor" olarak görünür, teşhisi zor). try/catch'e alındı — kalıcılık kaybı oturumu kırmıyor, sonraki açılışta Firebase token'ıyla yeniden exchange ediliyor.
3. **🟡 Arama rate limit'i fazla katıydı (30/dk).** Sonsuz kaydırmada her sayfa bir istek olduğu için meşru power-user 429 yiyebilirdi; üstelik asıl tehdit (OpenAI maliyeti) semantik arama iptal edildiği için yok. **60/dk**'ya çıkarıldı.

Doğrulanan ve dokunulmayanlar: `_ensureVaultUnlocked` zaten fail-closed · Keychain migration doğru (düz metin kopya siliniyor) · public-file exact-match doğru (prod'daki gerçek URL biçimi `.../api/storage/{ad}`, sorgu parametresi yok — meşru görseller kırılmıyor) · güvenlik başlıkları `await next()` öncesi yazılıyor (doğru) · HSTS yalnız prod'da.

### ✅ Doğrulamayla DÜŞEN bulgular (ajan abartısı)
- "Secret'lar imaja gömülü = kritik" → YANLIŞ: Dockerfile yalnız kaynak kopyalıyor; firebase-admin.json runtime volume, secret'lar `env_file`. Zaten önerilen yöntem.
- "Premium enforce edilmiyor = kritik" → YANLIŞ: `ItemsController:124` `IsPremiumForEnforcementAsync` + `FreeMaxItems` ile enforce ediyor. Client patch yalnız UX.
- IDOR/SQL-injection → temiz (tüm controller'larda userId filtresi; trigram parametreli + escape'li).

### ⏳ Kullanıcı kararları (2026-08-02)
- **Vault mimarisi → AYRI İŞ olarak planlandı** (kullanıcı kararı). Sorun: vault verisi `/api/items` ile cihaza iniyor, FaceID sadece UI kapısı; repackaging ile atlanabilir. Deeplink guard yüzeysel bypass'ı kapattı ama **kök çözüm:** backend'de ayrı vault ucu + ikinci server-side unlock challenge + client-side envelope encryption (anahtar Keychain+biometric). TestFlight'ı bekletmeden ayrı çalışma.
- **Sertifika pinning → ERTELENDİ** (kullanıcı kararı). API zaten HTTPS+JWT+server-side yetki ile korunuyor; yanlış pinning cert rotasyonunda uygulamayı kırar. İleride rotasyon planıyla.
- **Prod .env kontrolü → SONRAYA** (kullanıcı kararı). Kullanıcı sunucusunda doğrulamalı: `Jwt__Secret` güçlü rastgele mi (CHANGE_ME değil), `ClientRequestSecurity__Enabled` prod'da `true` mu, Firebase/RevenueCat anahtarları gerçek mi. (`.env.production.example`'da hepsi env override edilebilir — kod hazır, değer kullanıcıda.)

### Aday ileri işler (güvenlik)
App Check/App Attest (Firebase) · vault görsel disk-cache şifreleme · screenshot/screen-record koruması (vault ekranı) · share extension App Group TTL/temizlik · NU1903 paket açıkları (`dotnet list package --vulnerable`).

---

## 🔖 Kaldığımız Nokta (2026-10-17) — YAYINA HAZIRLIK

### Uçtan uca durum (2026-10-17 denetimi)
- **Prod:** `somineapi:prod_v15` + `somine-share:v7` ayakta (somineapp.com, privacy/terms/support/delete-account 200, /api/export 401). `ReminderNotifications__Enabled` hâlâ KAPALI (yeni sürüm yayına girince açılacak).
- **ASC (App ID 6757957749, "Somine: Social Bookmark"):** 1.0 Prepare for Submission. Abonelik grubu "So Mine Premium Plans" (haftalık/aylık/yıllık) Ready for Review. EKSİK: açıklama/anahtar kelime/tanıtım metni/destek URL/telif, ekran görüntüsü 0/10, önizleme 0/3, App Privacy anketi + gizlilik URL'si, yaş derecelendirmesi, içerik hakları, build seçimi, review notları. Apple Developer Program License Agreement güncellendi — hesap sahibi onaylamalı (gönderimi engeller). TestFlight build 32–35 ~2026-10-31'de süresi doluyor.

### Kod düzenlemesi (2026-10-17) ✅
- Commit'siz kalan iş commit'lendi: app `71cd491` (TR/EN yardımcıları, build 36), api `07fdc22` (SomineWeb EN).
- **app `5e39a43`:** bildirim izni açılışta istenmiyor → ilk içerik kaydında (success sheet) ve hatırlatıcı kurulurken/düzenlenirken · paywall planları yüklenemezse sahte fiyat + "Satın alma yakında" yerine lokalize "planlar yüklenemedi" + Tekrar Dene (3.1.1/2.1 riski) · ~1.100 satır ölü kod silindi. analyze 0 uyarı · 30/30 test · iOS release build ✓. GitHub: `feature/api-auth-migration` (ilk kez push edildi; master'a merge kullanıcı kararı).
- **api `bbe819a`:** zafiyetli transitif paketler sabitlendi (Pkcs/Xml 10.0.13, Microsoft.OpenApi 2.7.5, SQLitePCLRaw 2.1.14) → `dotnet list package --vulnerable` temiz · 131/131 test. Prod'a yeni imajla çıkmalı. **somine_api'nin hâlâ uzak reposu yok.**
- Konum izin metni bilinçli olarak KALDI: `apple_maps_flutter` CLLocationManager'a bağlanıyor, metin silinirse ITMS-90683.

### Sıradaki
1. Kullanıcı: Apple lisans sözleşmesini onayla; somine_api için GitHub private repo aç.
2. Build 36 → TestFlight; sürüme bağla.
3. Mağaza metinleri (TR+EN), App Privacy, yaş derecelendirmesi, review notları.
4. Remotion ile ekran görüntüleri + 30 sn önizleme + başlık görseli (Yetti'deki marketing/video yapısı örnek).
5. Gönderim; yayın sonrası `ReminderNotifications__Enabled=true`.

## 🔖 Kaldığımız Nokta (2026-08-01)

### 🚀 UYGULAMA BAŞLADI: Faz A ✅ tamamlandı (2026-08-01, orkestrasyonla)
- **A1 (app) ✅:** `ExponentialBackoff` utility (+6 unit test) · `BackendAuthService` singleton + in-flight dedup + devre kesici (5 hata → 60sn→10dk cooldown) · refresh hatası artık exchange'e düşmüyor (retryable sınıflandırma) · `streamUser` backoff'lu · reminder poll 2sn→10sn+backoff. `flutter analyze` 0 hata, `flutter test` 14/14 (orkestratör tarafından da doğrulandı).
- **A2 (api) ✅:** `GetOrCreateUserAsync` ortak helper + `DbUpdateException` recovery (23505 yarışı — kaybeden istek kazananın satırını kullanır) · fake `IFirebaseAuthService` + `SaveChangesHookInterceptor` test altyapısı · 3 yeni entegrasyon testi (ardışık/paralel/deterministik yarış). `dotnet test` 39/39 (orkestratör doğruladı). **Deploy notu:** Bu düzeltme prod'a yeni imajla çıkmalı.
- **B (app) ✅:** `firebase_analytics ^11.3.3` (IDFA'sız — `$FirebaseAnalyticsWithoutAdIdSupport`, ATT prompt yok) · tipli `AnalyticsService` (singleton + Riverpod provider) · 8 event bağlandı (login/sign_up ayrımlı, content_add+activation, reminder_set, paywall_view/convert — PaywallScreen'e source parametresi, share, screen_view observer+manuel sheet'ler). analyze 0 hata · 14/14 test · iOS debug build ✓ (orkestratör doğruladı).
- **C0 backend (api) ✅:** `items.last_opened_at`+`open_count` (migration `20260801131323_AddItemOpenTracking`, temiz) · `POST /api/items/{id}/opened` · 8 ItemDto projeksiyonu güncellendi · 42/42 test. Yan kazanım: eski elle-migration'dan kalan `exception_logs` FK model-drift'i konfigürasyona `SetNull` eklenerek kapatıldı (sıfır DB değişikliği).
- **D backend (api) ✅:** pgvector spike başarılı (SQLite testlerde `ItemEmbedding` provider-koşullu map dışı) · `item_embeddings` tablosu + HNSW cosine index (migration `20260801132038_AddItemEmbeddings`, temiz) · `OpenAiEmbeddingService` (text-embedding-3-small, 512, ApiKey yoksa kapalı→keyword fallback) · embedding kuyruk+background service · search'e `mode=semantic` + `categoryId/excludeCategoryIds/platform` sunucu filtreleri · 48/48 test (orkestratör doğruladı). **Oto-etiket atlandı** — API'de tag sistemi yok (doğrulandı). Backfill ayrı iş olarak açık. **Deploy ön koşulu: pgvector'lü Postgres imajı** (compose'da `postgres:17` → ör. `pgvector/pgvector:pg17`; prod PG 18 → `pgvector/pgvector:pg18`) + `Embedding__ApiKey` env (verilene dek özellik kapalı, güvenli).
- **C client (app) ✅:** C0-client: `ItemModel.lastOpenedAt` + `markOpened` (detay sheet initState'te, tüm açılış yolları tek noktadan) · C1: pop sözleşmesi `AddContentResult`'a geçti (3 pop noktası + 4 çağıran uyarlandı), success sheet'te "Yarın/Hafta sonu" hızlı hatırlatıcı (limit kontrollü, analytics'li) · C2: `WeeklyDigestService` (`notification_weekly` toggle'ına bağlı, `lastOpenedAt==null` adaylardan Pazar 19:00 idempotent lokal bildirim, id 900001) · `NotificationService` JSON payload'a geçti (eski düz-string fallback'li) · 9 yeni ARB anahtarı · `resurfacing_dates` + 10 unit test. analyze 0 hata · 24/24 test (orkestratör doğruladı).
- **F backend (api+web) ✅:** Share sayfasına OG meta seti (og:title/description/image/url + twitter:card; 404'te nötr, noindex korundu) + koşullu `apple-itunes-app` smart banner (`AppStoreId` config, boşsa render edilmez — gerçek App Store ID'si girilmeli) · `GET /api/export?format=json|csv` (auth + kullanıcı başına 5/saat rate limit, streaming, RFC4180) · 5 yeni test → 53/53 (orkestratör doğruladı).
- **D+F client (app) ✅:** Arama ekranına "Akıllı" (semantik) toggle chip'i — varsayılan kapalı, keyword davranışı birebir korunur; semantik modda sunucu sıralaması esas (5-sayfa doldurma + client post-filtre kapalı, vault/platform filtreleri sunucuya) · ölü `searchResultsProvider` silindi · profil ekranına "Verilerini dışa aktar" (JSON/CSV → share sheet; NOT: `settings_screen.dart` ölü kod çıktı, satır canlı yüzey olan profile eklendi) · `logExport` eventi · 6 yeni ARB anahtarı. analyze 0 hata · 24/24 (orkestratör doğruladı).
- **E hazırlık (app) ✅:** `home_widget ^0.9.2+1` · `ios/SomineWidget/` Swift dosyaları (air teması renkleriyle small+medium widget, `.after(gece yarısı)` timeline, `somine://item/<id>?homeWidget` tap) · `widget_data_service.dart` (günün kaydı: `lastOpenedAt==null` adaylardan tarih-tohumlu deterministik; açılış + kayıt sonrası güncelleme) · Runner Info.plist'e `somine` scheme · `NotificationService.openItemDetail` ortak kalıbı + `widget_tap` eventi · Podfile platform 13.0→14.0 (home_widget gereği; post_install zaten 14.0 dayatıyordu, davranışça nötr). analyze 0 hata · 24/24 · iOS build ✓ (orkestratör doğruladı).
- **E kapanış ✅ (2026-08-01 akşam):** Kullanıcı Xcode'da SomineWidget target'ını ekledi (sihirbaz şablon dosyaları bizim Swift dosyalarının üzerine yazmıştı — Fable içerikleri yeniden yazdı, Live Activity/Control/AppIntent şablonlarını sildi; target Xcode 16 klasör-senkronize grup olduğundan dosya bağlama gerekmedi). Fable ayrıca pbxproj'da 3 widget config'ine `CODE_SIGN_ENTITLEMENTS` (App Group `group.com.somine.app` entitlements dosyası oluşturuldu) ekledi ve widget deployment target'ını 26.2→17.0'a indirdi. Doğrulama: `flutter build ios --no-codesign --debug` ✓ — `SomineWidgetExtension.appex` Runner'a gömülü (`com.apple.widgetkit-extension`). **Faz A→F kod tarafı TAMAMEN bitti.**
### 🐛 DÜZELTME (2026-08-01): Haftalık özet varsayılanı KAPALI'ydı → AÇIK yapıldı
Simülatör logunda yakalandı (`[WeeklyDigest] Toggle off — digest cancelled`): `notification_weekly` varsayılanı `false`'du, yani resurfacing (ürünün ana vaadi) opt-in kalıyordu — pratikte hiç çalışmazdı. İki yerde varsayılan `true` yapıldı: `notification_settings_screen.dart:34` ve `weekly_digest_service.dart` (ikisi senkron olmalı). Kullanıcı isterse ayarlardan kapatabilir. Ayrıca doğrulandı: `[WidgetData] Widget synced` — widget veri akışı çalışıyor.

### ⏰ HATIRLATICI GÖRÜNÜRLÜĞÜ (2026-08-02) — Faz 1 ✅ · Faz 2 backend ✅
Plan: `~/.claude/plans/tingly-toasting-hippo.md`. Tetikleyici: kullanıcı "hatırlatıcılar bildirimlere düşmüyor" dedi → iOS banner çalışıyor ama kaçırılırsa hatırlatıcı iz bırakmıyordu; listeleyen ekran yoktu, uygulama içi bildirim listesi yalnız paylaşım bildirimlerini taşıyor.
- **Faz 1 (app) ✅:** `my_reminders_screen.dart` — Yaklaşan/Geçmiş/Tümü filtreleri (search chip stili), içerik başlığı + tarih + tekrar rozeti, dokun→içerik detayı, menü/kaydır→düzenle-sil, çekme-yenile, yetim hatırlatıcı (içeriği silinmiş) desteği. `reminder_providers.dart` — `remindersWithItemsProvider` (FutureProvider; hatırlatıcı+item eşleştirmesi tek seferde, `getItem()` ile 1+N istek yerine). Profil→İçerik grubunun başına menü satırı. 14 yeni ARB anahtarı (TR+EN). Silme HER ZAMAN `ReminderSchedulerService.cancelReminder` üzerinden (repository doğrudan çağrılırsa bildirim iptal edilmez, `hasReminder` bayrağı kalır). **Aktif/pasif switch'i bilinçli olarak YOK** — `toggleReminder` bildirimleri güncellemiyor, bozuk yolu UI'a açmak yanlış olurdu. analyze 0 hata · 24/24 · release build ✓ · telefona kuruldu.
- **Faz 2 backend (api) ✅ — 99/99 test:** Ajan plandaki `NextTriggerAtUtc` önerisini **gerekçelendirerek reddetti** ve `User.TimeZoneId` (Option B) seçti: backfill zaten bir saat dilimi varsaymayı gerektiriyor, o varsayımı script'e gömmek yerine veri olarak saklamak doğru; ayrıca Option A sunucunun doğruluğunu istemci sürümüne rehin bırakıyordu (mobil bu alanı bugün göndermiyor → kimse güncellemeden hatırlatıcı tetiklenmezdi). `ReminderNotificationBackgroundService` (PeriodicTimer, `Enabled`/`PollInterval`/`CatchUpWindow` bayrakları) vakti gelen hatırlatıcı için `notifications` kaydı üretip SignalR yayınlıyor; transaction içinde claim + `LastTriggered`. Migration `20260802101050_AddReminderNotifications` (users.time_zone_id + reminders indeksi, vector sızıntısı yok). Prod SQL: **`prod_v15_reminder_notifications.sql`**. Atıl `NotificationType` enum'u silindi → `NotificationTypes` sabitleri. `CatchUpWindow` (24 sa) özellik açılınca eski hatırlatıcıların toplu bildirim yağdırmasını engelliyor.
- **⚠️ Ajanın bulduğu MEVCUT hata (henüz düzeltilmedi):** `RepeatFrequency` enum sırası mobil ile sunucuda farklı (mobil `customMinutes(7), customDays(8)`; sunucu `CustomDays(7), CustomMinutes(8)`) ve mobil `repeat.index`'i int olarak gönderiyor → "15 dakikada bir" DB'ye `CustomDays` olarak yazılıyor. Mobil-sunucu gidiş-dönüşü kendi içinde tutarlı olduğu için ajan sunucu enum'unu DEĞİŞTİRMEDİ (değiştirse mobili bozardı); `ReminderSchedule.EffectiveRepeatType` hangi custom alanın dolu olduğuna bakarak telafi ediyor. Kalıcı düzeltme ayrı iş: enum sırasını hizala + tek seferlik veri düzeltme SQL'i.
- **Faz 2 mobil ayağı ✅:** `NotificationType` += `reminder` + **`unknown`** (bilinmeyen tip artık paylaşım isteği sanılmıyor; `fromApi` fallback'i nötr) · 3 exhaustive switch güncellendi (`main.dart` yönlendirme → `NotificationService.openItemDetail(data['itemId'])`, `notifications_screen` ikon/renk + tap, `in_app_notification_banner` görünüm) · `UserRepository.syncTimeZone()` — `flutter_native_timezone` ile IANA kimliğini `PUT /api/users/me`'ye gönderiyor, değişmediyse istek atmıyor (SharedPreferences bayrağı), açılışta `main.dart`'ta unawaited · `ReminderModel` += `lastTriggered` + `nextTriggerAtUtc` parse (yalnız okunur). analyze 0 hata · 24/24 · release build ✓.
- **⏳ Faz 2 deploy (KULLANICIDA):** `prod_v15_reminder_notifications.sql` + yeni API imajı. **Sıra önemli:** mobil sürüm kullanıcılara ulaşmadan sunucudaki `ReminderNotification:Enabled` açılırsa eski istemciler "reminder" tipini tanımaz (bu sürümde `unknown`a düşer, zararsız; ama daha eski TestFlight build'leri paylaşım isteği sanar). Güvenli yol: önce mobil sürümü yay, sonra bayrağı aç.
- **⏳ ESKİ SIRA (referans):** `NotificationType`'a `reminder` + 3 exhaustive switch (`main.dart:298`, `notifications_screen.dart:167`, `in_app_notification_banner.dart:351`) · `fromApi`'deki `orElse: shareRequest` → nötr `unknown` (aksi halde eski sürümler "reminder" tipini paylaşım isteği sanıp yanlış ekrana gider) · `PUT /api/users/me`'ye `timeZoneId` gönderimi (yoksa çok bölgeli kullanıcı yanlış saatte tetiklenir; TR için sunucu varsayılanı doğru) · `ReminderDto`'daki yeni `lastTriggered`/`nextTriggerAtUtc` alanlarını parse.

### 🚀 DEPLOY (2026-08-02): `somineapi:prod_v14` CANLIDA ✅
`prod_v15_reminder_notifications.sql` + `prod_v16_fix_repeat_frequency.sql` uygulandı, imaj deploy edildi. **Doğrulama (Fable, lokalden probe):** `/health` Healthy · `auth/refresh` geçersiz token → **401** (500 değil — bu, `users.time_zone_id` kolonunun var olduğunun kesin kanıtı; eksik olsaydı sabahki `premium_checked_at_utc` senaryosu tekrarlanırdı) · `auth/google` → 401 · `/api/users/me`, `/api/reminders`, `/api/export` → 401 (uçlar mevcut).
İçindekiler: hatırlatıcı bildirim altyapısı (**bayrak KAPALI**), kullanıcı saat dilimi, RepeatFrequency enum düzeltmesi + `MapToDto` kendini onaran tip dönüşümü.
**⏳ AÇILMAYI BEKLEYEN BAYRAK:** `ReminderNotifications__Enabled=true` sunucu `.env`'ine **yalnızca yeni mobil sürüm (build 34+) TestFlight/App Store'da yayına girdikten SONRA** eklenmeli. Erken açılırsa eski mobil sürümler "reminder" tipini paylaşım isteği sanıp yanlış ekrana yönlendirir. (Varsayılan bilinçli olarak `false` yapıldı — bkz. appsettings.json'daki açıklama.)

### 🔢 DÜZELTME (2026-08-02): RepeatFrequency enum sırası uyumsuzluğu ✅
**Hata:** Mobil `…weekends(6), customMinutes(7), customDays(8)`, sunucu `…Weekends(6), CustomDays(7), CustomMinutes(8)` — 7 ve 8 ters. Mobil `repeat.index`'i **int** gönderdiği için "15 dakikada bir" DB'ye `CustomDays` olarak yazılıyordu. Mobil geri okurken aynı ters eşlemeyi yaptığından kullanıcı fark etmiyordu (yanlış+yanlış=doğru görünüyor), ama DB verisi semantik olarak yanlıştı ve Faz 2 tetikleyicisi bu veriyi gerçekten kullanmaya başlamıştı.
**Doğrulanan dayanaklar:** `repeat_type` DB'de **string** (`HasConversion<string>()`) → enum sırasını değiştirmek saklanan metni etkilemiyor, yalnız JSON int↔member eşlemesini düzeltiyor · `ReminderDto.RepeatType` mobile **int** gidiyor (JsonStringEnumConverter yok) · enum sırasına bağlı başka hiçbir yer yok (cast/karşılaştırma/GetValues yok; migrator isimden ayrıştırıyor).
**Çözüm:** Sunucu enum'u mobile hizalandı (`CustomMinutes=7, CustomDays=8`), değerler **açıkça sabitlendi** + wire-contract notu eklendi. **Mobil tek satır değişmedi** → yayındaki tüm sürümler (TestFlight dahil) anında düzeldi. Yan fayda: migrator'ın isimden doğru yazdığı kayıtlar artık mobilde de doğru görünüyor. `EffectiveRepeatType` güvenlik ağı olarak KALDI (yorumu güncellendi). 19 yeni wire-contract testi → **118/118**.
**Fable eki:** `RemindersController.MapToDto` artık ham `RepeatType` yerine `schedule.EffectiveRepeatType` dönüyor → imaj ile veri düzeltmesi arasındaki pencerede mobil doğru tipi görür ve kullanıcı kaydı düzenlerse doğru değer geri yazılır (kendini onaran). Deploy sırası artık önemsiz. Build 0 hata · 118/118.
**Veri düzeltmesi:** `prod_v16_fix_repeat_frequency.sql` — şema değişikliği YOK, migration kaydı YOK, tek atomik `UPDATE ... CASE` (iki ayrı UPDATE'in birbirini geri çevirmesini önlemek için). Ölçüt `COALESCE(x,0) > 0` (çalışma zamanı mantığıyla birebir). Belirsiz satırlara (iki alan dolu/ikisi boş) dokunulmuyor. Dosyanın başında **etkilenen kayıt sayım sorgusu** yorum olarak var — çalıştırmadan önce ne kadar veriye dokunulacağı görülebilir.

### 🔘 DETAY/DÜZENLEME ÜST BUTONLARI (2026-08-02) ✅
**Şikâyet:** "Detay ve düzenleme sayfasında üst kısımdaki butonlar uygulamanın standardına uymuyor, beni rahatsız eden bir durum var."
**Kritik keşif:** Fable'ın ilk teşhisi (SliverAppBar/siyah daireler) **iki ÖLÜ dosyaya** dayanıyordu — `ItemDetailScreen` ve `EditContentScreen` sınıflarına hiçbir yerden referans yok (grep 0 sonuç, teyitli). Gerçek ekranlar: detay = `item_detail_bottom_sheet.dart` (modal sheet), düzenleme = `add_content_screen.dart` `editItem` modunda. Ajan varsayımı simülatörde doğrulamaya çalışıp çürüttü ve gerçek ekranları buldu.
**Gerçek rahatsızlık:** İki ekranın butonları AYNI konum ve boyutta ama FARKLI malzemeden — detayda `surfaceWhite` %85 + BackdropFilter blur + `PhosphorIconsBold` + turkuaz ikonlar; düzenlemede opak `surfaceWhite` + `PhosphorIconsLight` + nötr `headline`. Buton yerinden kıpırdamadığı için geçişte "bir şey değişti ama ne?" hissi veriyordu.
**Çözüm:** Ortak `lib/widgets/circle_icon_button.dart` — düzenleme ekranı standardının birebir kopyası. **4 ayrı kopya tek widget'a indirildi** (edit_content, add_content, item_detail_bottom_sheet, item_detail_screen). Glassmorphism kaldırıldı, ikonlar Light + nötr. Görsel karşılaştırma ekran görüntüleriyle teyitli. analyze 0 hata · 24/24 · release build ✓.
**Sapma notu:** Ajan iki dosyada yanlışlıkla `dart format` çalıştırdı (alakasız satırlar yeniden biçimlendi; davranış aynı, git olmadığı için geri alınamadı). Sonraki ajanlara "dart format çalıştırma" talimatı eklendi.

### 🖼️ MASONRY GÖRSEL SIÇRAMASI + YAN BULGULAR (2026-08-02) ✅
**Şikâyet:** "Masonry görünümde görseller fit olana kadar önce geniş oluyor, beyaz zemin, sonra orijinal oranına geçiyor."
**Kök neden:** Yer tutucu `AspectRatio(1.0)` (kare), gerçek görsel `BoxFit.fitWidth` + doğal yükseklik → kutu yeniden yerleşiyordu.
**Çözüm:** Kalıcı oran önbelleği (`image_aspect_ratio_cache.dart`, URL→oran, bellek + SharedPreferences, `main()`'de ilk kare öncesi **senkron** yüklenir) + ortak `masonry_image.dart` (ana sayfa ve katalog tek mantığı paylaşıyor). Yer tutucu ve görsel artık aynı `AspectRatio` kutusunu paylaşıyor.
**Ölçümle kanıt (175px şerit):** sıçrama **87.5px → soğuk önbellekte 10.9px → sıcak önbellekte 0px**.
**Varsayılan oran veriyle seçildi:** Ajan gerçek kütüphaneden 33 örnek ölçtü (24× 16:9, 5× 4:3, 4× 9:16) → **16:9**. Benim önerdiğim 4:5 bu veride en kötü seçenekti (ortalama 112px sıçrama) — ölçüm tahmini çürüttü. `AnimatedSize` denendi ve kaldırıldı (önbellek doluyken tetiklenmiyor, şerit yeniden yerleşim riski taşıyordu).
**Yolda bulunan 3 gerçek hata (brief'te yoktu):**
1. **ÇÖKME:** `_buildSkeletonCard` `Column` içinde `Expanded` kullanıyor; kare ızgarada `childAspectRatio` sınırlıyor ama masonry/feed'de yükseklik sınırsız → "unbounded height" assert'i. Masonry açılış modu yapılınca uygulama gerçekten çöküyordu. `bounded` parametresiyle düzeltildi (6 çağrı yeri).
2. **Ölçüm yarış durumu:** Masonry kartları geri dönüştürüldüğü için ertelenmiş ölçüm bir görselin oranını başka URL'ye yazabiliyordu → ölçüm URL'ye bağlandı, önbellek anahtarı v2'ye çekildi.
3. **Edit ekranı sunum hatası:** `AddContentScreen` saydam `DraggableScrollableSheet` kökü ile yazılmış (ekleme akışı `showModalBottomSheet` ile açıyor) ama **edit akışı opak `MaterialPageRoute` ile push ediyordu** → aşağı sürükleyince beyaz kutu boşlukta kayıyor ve hiç kapanmıyordu. `_openEditScreen` ekleme akışıyla aynı sunuma çevrildi. **Cihazda sürükleyerek teyit edilmedi — kullanıcı doğrulaması bekliyor.**
**Shimmer düzeltmesi:** `_ImageShimmerPlaceholder` sabit `Colors.grey.shade200/100`, katalogdaki yer tutucu sabit `grey[100]/[300]` ve shimmer'sızdı → koyu/vibe temada parlak beyaz blok (kullanıcının gördüğü "beyaz zemin" buydu). Tek `image_shimmer_placeholder.dart`'a çıkarıldı, renk kart yüzeyinden türetiliyor.
**Öneri (kapsam dışı):** `somine_api` og:image çekerken genişlik/yükseklik de saklarsa ilk görüntülemedeki 10.9px de sıfırlanır, istemci hiç ölçüm yapmaz.
analyze 48/0-hata · 24/24 · release build ✓ · `dart format` çalıştırılmadı · geçici harness'ler geri alındı (grep ile teyitli).

### 🎨 TASARIM DİLİ DENETİMİ (2026-08-02) ✅
`divider` + `danger` semantik token'ları 3 temaya bağlandı · 31 `clipBehavior` · 13 `Divider` · 90 ham renk · 4 `isScrollControlled` · `reminder_picker` tamamen l10n'a (ARB 499→516) · **görünüm modu butonlarındaki çift zemin giderildi** (AnimatedContainer→Container, zemin anlık değişiyor; ikon rengi TweenAnimationBuilder ile animasyonlu). analyze 48/0-hata · 24/24 · release build ✓.
**Dürüst bulgu:** Ajan kullanıcının tarif ettiği köşe artefaktını simülatörde A/B piksel testiyle **yeniden ÜRETEMEDİ** — köşe profili her iki durumda da kusursuz çeyrek daire, hale/soluk kare yok. `clipBehavior` eksikliği kanıtlanmış kök neden DEĞİL; düzeltmeler koruyucu olarak bırakıldı. Artefakt tekrar görülürse ekran görüntüsü + hangi sheet/tema bilgisi gerekiyor.
**Dokunulmayanlar (gerekçeli):** marka/durum renkleri (platform kırmızıları, paylaşım durum üçlüsü), shimmer/placeholder grileri (yüzey dolgusu, hairline değil), sheet başlık fontu (Outfit), köşe yarıçapları (24/28/32), `'Hızlı'` kategori adı (10 yerde mantık string'i).

### 🍏 APP STORE UYGUNLUK DENETİMİ (2026-08-02) — bulgular giderildi
Apple politikalarına göre tam denetim yapıldı (sunum: `~/.claude` dışı, artifact olarak paylaşıldı). **Gönderimi engelleyen eksik yoktu**; 3 madde düzeltildi, 2 cila yapıldı:
- **✅ Paywall dürüstlüğü (Kılavuz 3.1.2/2.3.1 riski):** "Akıllı Arama" ve "Hızlı Widget Ekleme" premium listesinden ÇIKARILDI — ikisi de fiilen premium'a kilitli değildi (arama herkeste iyileştirildi, widget herkese açık). Kalan 4 özellik gerçekten kilitli (sınırsız içerik, gizli kasa, temalar, özel ikonlar) — doğrulandı.
- **✅ Kullanılmayan izinler (5.1.1):** `NSLocationWhenInUseUsageDescription` + `NSLocalNetworkUsageDescription` kaldırıldı (kodda konum API'si hiç çağrılmıyor — doğrulandı). Kamera/galeri/mikrofon/Face ID kaldı, karşılıkları üründe var.
- **✅ Privacy manifest (ITMS-91053):** `PrivacyInfo.xcprivacy` 3 hedefe eklendi — Runner (pbxproj'a elle), SomineWidget ve somine (klasör-senkronize gruplar). UserDefaults erişimi `CA92.1` (aynı app group) gerekçesiyle bildirildi; ana uygulamada ayrıca toplanan veri tipleri (e-posta, ad, kullanıcı içeriği, foto/video — hepsi App Functionality, tracking=false). Derlenmiş .app içinde üç konumda da doğrulandı.
- **✅ Açılış ekranı:** Boş 68 baytlık yer tutucular gerçek logoyla değiştirildi (180/360/540 px) + storyboard arka planı marka nane tonuna (#E8F1EF) çekildi. Artık açılışta beyaz boşluk yerine markalı ekran.
- **✅ Marka yazımı tekleşti:** `Share.cshtml.cs`'deki "SoMine" → **"Somine"** (App Store Connect'teki isim). Site, uygulama ve paylaşım önizlemeleri artık aynı yazımı kullanıyor. → SomineWeb imajı yenilenmeli (v6).

**Kullanıcı kararları:** Deneme süresi (trial) EKLENMEYECEK — kredi kartı isteyip iptal unutturmaya oynamak ürünün güven konumlandırmasına ters (kullanıcı kararı, plandaki trial önerisi İPTAL). Haftalık plan konusu hâlâ açık.

**App Store Connect'te kullanıcıda kalanlar:** demo hesap (App Review Notes — reviewer yalnız Google/Apple ile girebiliyor, en sık ret sebebi), App Privacy anketi (Firebase Analytics+Crashlytics), abonelik grubu + yerelleştirilmiş adlar + IAP review ekran görüntüsü, mağaza sayfası (ekran görüntülerinde 3. parti platform logolarına dikkat).

### 📦 TESTFLIGHT (2026-08-02): build 33 — GÜNCEL PAKET
`1.0.0+33` · `build/ios/ipa/Somine.ipa` (64 MB) · arşiv `build/ios/archive/Runner.xcarchive` · her iki uzantı doğrulandı (`SomineWidgetExtension.appex` + `somine.appex`) · analyze 0 hata · 24/24 test. **Build 32'ye göre farkı:** abonelik zincirindeki üç düzeltme (RevenueCat kimlik tanıtımı her açılışta · giriş akışında adım izolasyonu · kimlik başına bir kez otomatik restore). Build 32 YÜKLENMEDİ, bunun yerine 33 gönderiliyor. API key yine eski/çalışan key (`a148c8a4…`), rotasyon yapılmadı.

<details><summary>Arşiv: build 32 notları</summary>

### 📦 TESTFLIGHT (2026-08-02): build 32 hazırlandı
- `pubspec.yaml` 1.0.0+31 → **1.0.0+32** · `flutter build ipa --release --export-method app-store` · **`build/ios/ipa/Somine.ipa` (64 MB)** · arşiv: `build/ios/archive/Runner.xcarchive`. IPA içinde her iki uzantı da doğrulandı: `SomineWidgetExtension.appex` (yeni widget) + `somine.appex` (share extension). Yükleme yöntemi: Xcode Organizer (kullanıcı).
- **API KEY KARARI:** Build, hâlâ ÇALIŞAN eski prod key'iyle (`a148c8a4…`) derlendi. `LOCAL_SECRETS.md`'deki rotasyon (`2471d1e4…`) YAPILMADI — yeni key'le derlenip sunucu env'i (`ApiKey__Key`) aynı anda güncellenmezse TestFlight build'i hiç çalışmaz. Rotasyon ayrı ve eşzamanlı bir adım olarak planlanmalı.
- **Bilinen uyarı:** Launch image hâlâ varsayılan yer tutucu (flutter build uyarısı) — App Store yayını öncesi değiştirilmeli, TestFlight'ı engellemez.
- **TestFlight'ta doğrulanacak:** (1) Abonelik/premium durumu — bugünkü "premium değilsiniz" sorunu geliştirme build'inin sandbox StoreKit ortamından kaynaklanıyor olabilir, üretim ortamında test şart. (2) Google login. (3) Link ile paylaş. (4) Widget. (5) Dışa aktarma.

</details>

### ♻️ İYİLEŞTİRME (2026-08-02): Otomatik satın alma geri yükleme
Kullanıcı sorusu: "yeniden login olan/satın alması olan kullanıcı için açılışta otomatik kontrol edilse olmaz mı?" — haklı, eklendi. `subscription_service.dart` → `_autoRestoreIfNeeded()`: entitlement boşsa ve bu Firebase kimliği için daha önce denenmemişse **bir kez** `Purchases.restorePurchases()` çağırıyor (SharedPreferences `rc_auto_restore_<uid>` bayrağı). Hem açılışta (`_doInitialize`) hem taze girişte (`setUserId`) devrede. Her açılışta değil kimlik başına bir kez — Apple tarafında gereksiz istek/istem doğurmasın diye. Böylece yeni cihaz / yeniden giriş / kesintiye uğramış giriş akışında kullanıcı "Satın alımları geri yükle"ye basmak zorunda kalmıyor.

### 🎯 KÖK NEDEN (2026-08-02): Kullanıcı RevenueCat'e HİÇ kaydedilmemiş
RevenueCat panelinde 40 müşteri var ama kullanıcının kimliği (`a8AQaSJ8OJVY7ES39EpvjMZ5iSA3`) **yok**. Yani sorun makbuz doğrulaması ya da sunucu anahtarı değil, bir önceki halka: `Purchases.logIn(uid)` hiç çağrılmamış.
**Zincir:** `auth_repository.signInWithGoogle` içinde sıra `_handleUserLogin()` → `_syncSubscriptionAfterLogin()`. Sabahki 500 hatası (auth yarışı) ilk çağrıyı fırlattı → ikinci satır hiç çalışmadı → RevenueCat kullanıcıyı hiç görmedi. Oturum kalıcı olduğu için giriş akışı bir daha çalışmadı; sorun kalıcılaştı. (Aynı sebeple `premium_expires_at_utc` dört kullanıcıda da NULL.)
**Düzeltmeler (2 yerde):**
1. `subscription_service.dart` → `_identifyCurrentUserSafely()`: her açılışta, oturum açıksa `Purchases.logIn(currentUser.uid)` çağrılıyor. Kendini onaran davranış — giriş akışı ne olursa olsun kullanıcı RevenueCat'te oluşur.
2. `auth_repository.dart` (Google + Apple): `_handleUserLogin` artık kendi try/catch'inde — bir adımın hatası abonelik ve backend oturum senkronunu KESMİYOR.
`flutter analyze` 0 hata · 24/24 test.

### 🐛 DÜZELTME (2026-08-02): Premium abone "premium değilsiniz" görüyordu
Kullanıcı telefonda yakaladı: abone olmasına rağmen "Koleksiyon Paylaş" → "premium abonesi değilsiniz"; paywall'a girince "zaten abonelisiniz, yönet" çıkıyordu. **Kök neden:** `SubscriptionService._doInitialize` ve `setUserId` içinde `Purchases.getCustomerInfo()` hata verdiğinde (telefonda gerçekten veriyordu: `Rejecting receipt (7934) UNKNOWN_BACKEND_ERROR` — sandbox/dev build makbuz doğrulaması) aynı try bloğundaki `_refreshBackendStatus()` HİÇ çalışmıyordu → `_backendTier` `starter` kalıyordu → `isPremium` false. Paywall ise RevenueCat'in kendi durumunu okuduğu için "zaten abone" diyordu; çelişki buradan.
**Düzeltme:** RevenueCat çağrıları kendi try/catch'ine alındı; `_refreshBackendStatus` artık `finally` içinde, SDK patlasa da her koşulda çalışıyor (premium gerçeği sunucuda, SDK ikincil kaynak). `flutter analyze` temiz · 24/24 test · telefona kuruldu.

### 🔕 KARAR (2026-08-01): Semantik arama PASİFİZE EDİLDİ
Kullanıcı kararı: OpenAI embedding'i **ücretli/dış bağımlılık** olduğu için kullanılmayacak. Ayrıca prod Postgres'te pgvector binary'si YOK (`extension "vector" is not available` — doğrulandı), yani `AddItemEmbeddings` migration'ı prod'a uygulanamıyor/uygulanmayacak.
- **App:** `ApiConfig.semanticSearchEnabled = false` (tek satır bayrak) → arama ekranındaki "Akıllı" chip'i gizli. Kod duruyor, geri açmak tek satır.
- **API:** Embedding zaten `Embedding__ApiKey` verilmedikçe kapalı; `mode=semantic` gelse bile keyword'e düşüyor. Hiçbir veri dışarı gitmiyor.
- **DB:** `prod_v12_part1_opentracking.sql` prod'a UYGULANDI ✅ (items.last_opened_at + open_count). `prod_v12_part2_embeddings.sql` UYGULANMADI (pgvector yok — gerek de yok).
- **⚠️ Bunun sonucu:** `Database__ApplyMigrationsOnStartup=true` bayrağı **eklenmemeli** — container açılışta `AddItemEmbeddings`'i uygulamaya çalışır, pgvector olmadığı için ayağa kalkmaz. Migration'lar elle uygulanmaya devam (part1 gibi).
- **Açık ürün kararı:** Paywall'daki `paywallFeatureSmartSearch` ("Akıllı Arama") vaadi hâlâ karşılıksız. Seçenekler: (a) metni sadeleştir/çıkar, (b) ileride kendi sunucusunda çalışan embedding modeli (veri dışarı çıkmaz, `IEmbeddingService` arayüzü hazır), (c) pg_trgm/full-text ile ucuz iyileştirme (dış bağımlılık yok — prod'da `pg_trgm` mevcut mu kontrol edilmeli).

### ✨ EK İŞ (2026-08-01 akşam): "Link ile paylaş" — koleksiyondan doğrudan public link
**Tespit:** Public link YALNIZ bir `CollectionShare` üzerinden üretilebiliyordu → kullanıcı kendi koleksiyonunun web linkini almak için önce birine paylaşım isteği göndermek zorundaydı. Giriş noktası da Profil→Paylaşımlarım'da gömülüydü. Faz F'de eklenen OG kartlarını da işlevsiz bırakıyordu (kimse link üretemiyorsa kart kimseye ulaşmaz).
- **Backend ✅:** Token `Category` entity'sine taşındı (yaklaşım C; `CollectionShare`/`ShareDto`/incoming-outgoing/kota sayacı HİÇ değişmedi — ajan, önerilen "ToUserId nullable" yaklaşımını gerekçelendirerek reddetti, GPT 5.5'e de doğrulattı). `POST/DELETE /api/categories/{id}/public-link` · `CategoryDto.publicLinkToken` (yalnız sahibe) · `PublicSharesController`'da tek resolver iki kaynağı çözüyor, SomineWeb sayfası ve DTO değişmedi. Migration `20260801205249_AddCategoryPublicLink` (2 nullable kolon + unique index, drift/vector yok). **69/69 test.**
  - Yan kazanım (güvenlik): Kategori sonradan vault yapılırsa public link iptal ediliyor; resolver vault'u her iki kaynakta reddediyor — **paylaşılan kategori sonradan vault yapılsa bile eski linkin çalışmaya devam ettiği mevcut sızıntı kapandı.**
  - Not: Public link ücretsiz planda serbest (mevcut share public-link ucuyla tutarlı); kısıtlanması istenirse ürün kararı.
- **App ✅:** Koleksiyon → "Koleksiyonu Paylaş" → yeni sheet: **"Kişiyle paylaş"** / **"Link ile paylaş"** (+ altyazı *"Linki olan herkes bu koleksiyonu görüntüleyebilir"*). Link varsa: Kopyala / Yeniden Paylaş / İptal Et. Vault'ta seçenek görünmez. Backend deploy edilmeden 404 → lokalize "şu anda kullanılamıyor" mesajı (çökme yok). analyze 0 hata · 24/24 test.

### ⏳ TOPLU DEPLOY PLANI (karar: hepsi tek seferde)
**Neden gerekli:** `GET /api/export` ve `POST /api/items/{id}/opened` prod'da **404** (doğrulandı) — kod yazıldı ama eski imaj çalışıyor. Uygulamadaki "Dışa aktar" bu yüzden çalışmıyor.

**Sıra ÖNEMLİ — önce SQL, sonra imaj** (bu sırada kesinti olmaz; eski imaj yeni şemayla sorunsuz çalışır, fazladan index zarar vermez):
1. **pgAdmin:** `prod_v13_trgm_search.sql` (pg_trgm + unaccent + GIN index'ler). NOT: `prod_v12_part1_opentracking.sql` zaten uygulandı ✅; `part2_embeddings` UYGULANMAYACAK (pgvector yok, özellik iptal).
2. **Fable:** `gokmenkucuk/somineapi:prod_v12` + `gokmenkucuk/somine-share:v3` imajlarını linux/amd64 derleyip tar'a alır.
3. **Kullanıcı:** `scp` ile sunucuya → `docker load -i` → `SOMINE_API_IMAGE=gokmenkucuk/somineapi:prod_v12 docker compose -f docker-compose.server.yml up -d`.
4. **Fable:** lokalden probe — `/health`, geçersiz token 401, `GET /api/export` 401 (404 değil), arama.

**Deploy'da çıkanlar:** auth 23505 yarış koruması · `POST /api/items/{id}/opened` · `GET /api/export` (JSON/CSV) · trigram araması · Share OG kartları + smart banner.

**Config notları:** `AppStoreId` — uygulama App Store'da yayında değilse boş kalır (banner kapalı, sorun değil). `Embedding__ApiKey` VERİLMEYECEK (semantik arama iptal). `Database__ApplyMigrationsOnStartup` **eklenmeyecek** — AddItemEmbeddings migration'ı repoda duruyor ve pgvector olmadığı için container açılışta patlar; migration'lar elle uygulanmaya devam.

### 🔍 TEŞHİS EDİLDİ (2026-08-01, öğleden sonra): Gerçek-token login 500 = check-then-insert yarışı
Simülatörde prod'a karşı gerçek Google login denendi → `POST /api/auth/google` **500**. `exception_logs` ile kök neden kesinleştirildi:
- **`DbUpdateException` → `23505 duplicate key ... IX_users_firebase_uid`**: Uygulama (backoff'suz retry) aynı anda birden fazla login isteği atmış; ikisi de kullanıcıyı bulamayıp INSERT'e gitmiş — biri 11:53:10.148'de satırı yazdı, diğeri 11:53:10.204'te unique ihlaliyle 500 aldı. Migration/şema sorunu DEĞİL (`users` ve `auth_sessions` prod şeması EF modeliyle birebir doğrulandı; prod'da v11 kodu çalışıyor — endpoint probe'larıyla teyitli).
- Kullanıcı satırı (`a8AQaSJ8OJVY7ES39EpvjMZ5iSA3`) artık DB'de → sonraki login lookup'ta bulur, INSERT'e girmez; tekrar deneme başarılı olmalı (teyit bekliyor).
- **Yan bulgu 1:** Prod `users`'ta aynı e-postayla (kucuk.gokmen52@gmail.com) **4 satır** var — farklı Firebase uid'leri (`8w7Cmrk…`/ozy, `bPrjUe2…`/gokmen_kucuk_1, `iI8vEIo…`/gokmenkucuk, `a8AQaSJ…`/username boş). Eski satırlarda veri bölünmüş olabilir; temizlik/birleştirme kararı kullanıcıda.
- **Yan bulgu 2 (app çökmesi):** Login 500 alınca app `Purchases has not been configured` fatal'ıyla çöktü (`subscription_service.dart` — configure edilmeden Purchases çağrısı, login-hata yolunda). Düzeltilmeli.
- **Kalıcı düzeltme adayları:** (a) Backend: `LoginWithGoogle`/`LoginWithApple`'da INSERT'i 23505'e karşı koru — DbUpdateException'da uid ile yeniden sorgula (veya upsert). (b) App: auth retry'ye backoff + devre kesici (zaten açık madde). (c) App: RevenueCat çağrılarını configure-guard'la.

### ✅ ÇÖZÜLDÜ (2026-08-01): Prod auth 500 — eksik migration'lar elle uygulandı
Kök neden doğrulandı ve giderildi. Bu oturumda yapılanlar:
- **Migration SQL prod DB'de çalıştırıldı** (kullanıcı, sunucuda): `prod_migration_fix.sql` (idempotent) → eksik `AddUserPremiumSnapshot` (`users.premium_expires_at_utc`, `users.premium_checked_at_utc`) + `AddPublicShareLink` (`collection_shares.public_link_token`/`_created_at_utc` + unique index) uygulandı. `somine-api` container restart edildi.
- **Doğrulama (lokalden prod'a probe, 2026-08-01):**
  - `POST /api/auth/refresh` geçersiz token → **401** `{"error":"Invalid refresh token"}` (önceden 500'dü) ✅
  - `POST /api/auth/google` geçersiz token → **401** `{"error":"Invalid identity token."}` ✅
  - `GET /health` → `Healthy` ✅
  - Yani `AuthController.cs:104`'teki `Include(s => s.User)` sorgusu artık eksik kolona çarpmıyor; landing-döngüsünü besleyen 500 kaynağı kapandı.
- **Kalan doğrulama (kullanıcıda):** Telefonda gerçek Google login testi — `flutter run --profile -d <iphone> --dart-define=SOMINE_API_KEY=a148c8a4a82faab8fb7743d5903fe7128fa405a17b8e257942d7ecbd3035b92a`. (Firebase kotası aşıldıysa soğuma gerekebilir.) Landing girip-çıkma döngüsünün bittiği telefonda teyit edilmeli.

### ⏳ AÇIK TAKİP: Kalıcı düzeltmeler
1. **Startup migration bayrağı** — sunucu `somine_api/.env`'ine `Database__ApplyMigrationsOnStartup=true` eklenmeli (compose `env_file: .env`). Bu olmadan hiçbir deploy migration'ı otomatik uygulamıyor; bu oturumdaki elle SQL geçici bir onarımdı. **Bayrak eklendi mi teyit bekliyor.** (`Program.cs:181-186` bu bayrağa bakıyor.)
2. **App-tarafı devre kesici** — auth retry'ye exponential backoff + 429/`quota-exceeded`'de devre kesici (`lib/core/services/backend_auth_service.dart` + `lib/core/repositories/user_repository.dart:138`). Geçici bir 500'ün kendini DoS'a çevirmesini engeller. Henüz yapılmadı.
3. **Image tag teyidi** — sunucuda `docker inspect somine-api --format '{{.Config.Image}}'` ile çalışan imajın `prod_v11` olduğu doğrulanabilir (fonksiyonel olarak DB fix yeterliydi; imaj teyidi opsiyonel).

<details><summary>Arşiv: kök neden analizi (çözüldü, referans için)</summary>

### 🔴 (ARŞİV) AÇIK KRİTİK: Prod'da Google login çalışmıyor — token exchange 500 (migration eksik)
Fiziksel telefonda prod'a karşı (profile build, prod key `a148c8a4…`) test edildi. Belirti: **uygulama sürekli landing/login'e girip çıkıyor**. Kök neden **lokalde yaşadığımızın aynısı**:
- Prod `POST /api/auth/refresh` ve `/api/auth/google` (exchange Firebase token) → **500 server error**. Neredeyse kesin sebep: prod DB'de `AddUserPremiumSnapshot` migration'ı YOK → `column premium_checked_at_utc does not exist` (lokalde birebir bu hataydı, kolonları elle ekleyince düzeldi).
- Prod'a **v10/v11 hiç deploy edilmedi**; hâlâ eski imaj/şema çalışıyor.
- İkincil sonuç: app'in auth retry'sinde **backoff/circuit-breaker yok** → 500'ü saniyede onlarca kez tekrar deniyor, prod rate-limit'ini (429) VE Firebase Auth kotasını (`firebase_auth/quota-exceeded`) tetikliyor → kendini besleyen döngü = landing girip çıkma. (Kaynak: `lib/core/services/backend_auth_service.dart` + `lib/core/repositories/user_repository.dart:138 streamUser`.)

**GÜNCELLEME (2026-07-12, deploy sonrası):** `prod_v11` kullanıcı tarafından deploy edildi ama 500 sürüyor (probe: geçersiz token'la `POST /api/auth/refresh` → 500; 401 dönmeliydi — sorgu `AuthController.cs:104`'te `Include(s => s.User)` ile eksik premium kolonlarına çarpıyor). **Asıl kök neden bulundu:** `Database:ApplyMigrationsOnStartup` bayrağı hiçbir yerde tanımlı değil (appsettings*.json, docker-compose*.yml, .env tarandı) → varsayılan `false` → `Program.cs:181-186`'daki `Database.Migrate()` **hiç çalışmıyor**. "v11 açılışta migration'ı otomatik uygular" varsayımı yanlıştı; imaj değil, bayrak eksikti.

**ÇÖZÜM (sırayla):**
1. **`somine_api/prod_migration_fix.sql`'i prod DB'de çalıştır** (idempotent, `dotnet ef migrations script --idempotent` çıktısı; yalnız eksik `AddUserPremiumSnapshot` + `AddPublicShareLink`'i uygular). Sunucuda: `docker exec -i <postgres_container> psql -U admin -d somine_db < prod_migration_fix.sql` sonra `docker restart somine-api`. SSH bu ortamdan hâlâ yetkisiz; çalıştırma kullanıcıda. (Prod PG 18, DB `somine_db`, user `admin`, `postgresql_default` network.)
2. **Kalıcı düzeltme:** sunucu `.env`'ine `Database__ApplyMigrationsOnStartup=true` ekle (compose `env_file: .env` kullanıyor; tek instance, güvenli) → gelecek deploy'larda migration otomatik uygulanır.
3. Doğrulama: geçersiz token'la `POST /api/auth/refresh` artık **401** dönmeli (500 değil). Sonra telefonda test: `flutter run --profile -d <iphone> --dart-define=SOMINE_API_KEY=a148c8a4a82faab8fb7743d5903fe7128fa405a17b8e257942d7ecbd3035b92a`. (Not: Firebase kotası aştıysa bir süre soğuması gerekebilir.)
4. (Opsiyonel ama önerilir) App'te auth retry'ye exponential backoff + 429/quota'da devre kesici ekle ki geçici bir 500 kendini DoS'a çevirmesin.

</details>

### ✅ Bu oturumda biten
- **Landing → SomineWeb birleştirme**: Next.js landing bire bir Razor'a taşındı (Index + privacy/terms/support/delete-account + navbar/footer + Tailwind v4 + swiper + JS). SomineWeb artık hem landing hem `/s/{token}`. Lokal doğrulandı (5135). Detay: aşağıdaki 2026-07-05 günlüğü.
- **Docker imajları (linux/amd64) hazır**: `gokmenkucuk/somineapi:prod_v11` (`somine-api-prod_v11.tar`, 98MB) + `gokmenkucuk/somine-share:v2` (`somine-share-v2.tar`, 138MB, landing dahil). Lokal store'da + tar olarak `somine_api/` kökünde. Docker Hub'a **push edilmedi** (tar+scp akışı). Eski `somine-web:latest_v5` ve eski tarlar temizlendi.
- **Lokal ortam çalışır durumda**: API `http://localhost:5280` (lokal DB'ye `AddUserPremiumSnapshot` elle uygulandı), SomineWeb `http://localhost:5135`. Lokalde Google login + kullanıcı oluşturma başarılı (simülatörde doğrulandı).

### ⚠️ Yerel commit durumu
- `somine_api` working tree'de **26 dosya commit'siz** (landing taşıması + docker config). `somine_api` reposunun **remote'u yok** (yalnız bu makinede). Commit/push yapılmadı.
- `PLAN.md` / `CLAUDE.md` `SoMine/` kökünde, git dışı.

---

## Ürün Özeti

SoMine: link/not/görsel kaydetme ve koleksiyonlama uygulaması (Flutter, iOS-öncelikli) + .NET 10 / PostgreSQL API (`api.somineapp.com`, Hetzner/Docker). Konumlandırma hedefi: **"Kaydettiklerin kaybolmasın — sana geri gelsin"** (hatırlatıcı odaklı).

## Ürün Stratejisi ve Yol Haritası (2026-08-01 analizi — Fable)

> Uygulama kuralı: Aşağıdaki tüm işler **mevcut tasarım çizgisi bozulmadan** yapılır — yeni ekran dili, renk paleti veya bileşen stili icat edilmez; var olan bileşenler ve görsel dil yeniden kullanılır.

**Konumlandırma tezi:** Kategorinin çözülmemiş problemi depolama değil **resurfacing** — "kaydedilenlerin %90'ına bir daha bakılmıyor". SoMine'ın "Kaydettiklerin kaybolmasın — sana geri gelsin" vaadi doğru açı; ama bugün hatırlatıcı manuel olduğu için vaat henüz üründe gerçekleşmiyor.

**Pazar değerlendirmesi (özet):** Yatay "her şeyi kaydet" olarak küresel pazar zor (Pinterest, platform-içi kaydetler, "kendine WhatsApp" alışkanlığı). Gerçekçi yol **kama stratejisi**: TR iOS kullanıcısı, IG/TikTok reel biriktiricileri. Rüzgâr: Pocket'ın 2025 kapanışı + sosyal koleksiyonların büyüme döngüsü + yerel rakipsizlik. Tutma koşulu: resurfacing'in D30 retention'ı ölçülür şekilde artırdığının kanıtlanması. Dikkat: AI otomatik etiketleme/semantik arama 2026'da kategori standardı; paywall'daki "Akıllı Arama" vaadi gerçek değil (güven + App Store riski).

**Güçlü:** resurfacing konumlandırması, sosyal katman (koleksiyon paylaşımı + public link = viral döngü), sağlam teknik temel (kendi backend, SignalR, share extension, sunucu taraflı limitler, TR/EN), disiplinli freemium (500/10/3/1), TR pazarı avantajı.
**Zayıf:** "Akıllı Arama" satılıyor ama yok · sıfır ürün metriği · resurfacing manuel · tek platform (Android üretim dışı, web yok) · ilk oturum kırılganlığı (auth yarışı/backoff — kısmen düzeltildi) · operasyonel tek-kişi riski (API repo yedeği yok).

> **UYGULAMA PLANI ONAYLANDI (2026-08-01):** Aşağıdaki yol haritasının faz-faz uygulama planı (Faz A→F: sağlamlık, Firebase Analytics, resurfacing v1, pgvector semantik arama, iOS widget, OG/export) kullanıcı tarafından onaylandı. Tam plan: `~/.claude/plans/tingly-toasting-hippo.md`. Uygulayıcı: **Opus** (sonraki oturumlar). Sıra: A → B → C (C0 → C2); D ve F bağımsız; E, C0'a bağımlı. Her faz sonunda doğrulama (flutter analyze/test + dotnet build/test + simülatör smoke) ve bu dosyada durum güncellemesi zorunlu. Kesin kural: mevcut tasarım çizgisi bozulmaz.

### Öncelikli yol haritası

**P0 — Ölçüm + sağlamlık (~1 hafta):**
1. Analitik eventleri: aktivasyon hunisi, D1/D7/D30, hatırlatıcı kurulum/açılma oranı, paywall görüntüleme→dönüşüm. (Bugün hiçbir metrik ölçülmüyor.)
2. Auth backoff + devre kesici (app) ve `LoginWithGoogle`/`LoginWithApple`'da 23505 yarış koruması (backend) — ilk oturum asla çökmemeli.

**P0 — Vaadi gerçek yap (~2-3 hafta):**
3. Proaktif resurfacing v1: haftalık "Sana geri geldi" bildirimi (hiç açılmamış son kayıtlardan 3-5 içerik) + kayıt sonrası tek dokunuşla "Hafta sonu hatırlat" hızlı seçimi. Mevcut bildirim altyapısı ve success sheet üzerine kurulur; yeni ekran gerekmez.

**P1 — Kategori standardını yakala (~3-4 hafta):**
4. Embedding tabanlı semantik arama + otomatik etiket önerisi (API tarafında; paywall'daki "Akıllı Arama" vaadini gerçeğe çevirir).
5. Ana ekran widget'ı (paywall'da zaten vaat ediliyor): widget'ta "günün kaydı" — resurfacing ile doğal uyumlu.

**P2 — Döngüleri tamamla:**
6. Public koleksiyon sayfalarını büyüme varlığına çevir: OG kartları + "SoMine'de aç" App Store yönlendirmesi (SomineWeb altyapısı hazır).
7. JSON/CSV dışa aktarma (güven) → sonra Android üretimi ve web clipper.

## Doğrulanmış Mevcut Durum (2026-07-04 kod denetimi)

- **Firestore'dan tam çıkış tamamlandı.** Ürün verisi yalnızca PostgreSQL'de; Firebase yalnızca Auth (Google+Apple) ve Crashlytics için. `cloud_firestore` ve `firebase_storage` pubspec'te yok.
- Apple + Google Sign-In çalışıyor; iOS Share Extension mevcut; SignalR (items/categories/notifications hub'ları) gerçek; RevenueCat doğrulaması sunucu tarafında.
- Paylaşılan koleksiyon akışı yeni endpoint'lerle onarıldı: `GET /api/shares/{id}/items`, copy yetkisi, storage paylaşım erişimi.
- Hesap silme: `DELETE /api/users/me` tüm veriyi temizliyor (eski `DELETE /api/auth/account` bozuk ve ölü — kaldırılacak, bkz. Faz 0).
- Doğrulama: flutter analyze 0 hata · flutter test 8/8 · dotnet test 10/10 · iOS build ✓ (126.8MB).
- **Android üretim dışı** (debug imza, test RevenueCat key'i) — bilinçli olarak kapsam dışı; lokalizasyondan sonra ele alınacak.

---

## Değişiklik Günlüğü — 2026-07-05 (landing → SomineWeb birleştirme)

**Karar değişikliği (Faz 4 hibrit mimarisi GEÇERSİZ):** Next.js `somine_web_landing` artık ayrı bir container'da tutulmuyor. Tüm landing (ana sayfa + privacy + terms + support + delete-account) `SomineWeb` (Razor Pages) içine **bire bir taşındı**; tek .NET servisi hem landing'i (`/`) hem public paylaşım sayfalarını (`/s/{token}`) sunuyor. Caddy `/s/*` ayrıştırması ARTIK GEREKMİYOR.

Uygulama detayı:
- Styling: Tailwind CSS v4 korundu (`SomineWeb/package.json` + `Styles/landing.input.css` → `wwwroot/css/landing.css`, çıktı commit'li; node yalnızca dev-time, Docker build node gerektirmez). Swiper `wwwroot/lib/swiper` altında vendor'landı. Fontlar Google Fonts `<link>` (Outfit/Poppins).
- framer-motion animasyonları → CSS scroll-reveal (`IntersectionObserver`, `wwwroot/js/landing.js`); infinite/keyframe animasyonlar `landing.input.css`'te korundu. Swiper carousel, mobil menü, navbar scroll-state, hero platform-ikon rotasyonu, scroll-to-top hepsi vanilla JS.
- Ayrı `_LandingLayout.cshtml` (font+GA+Tailwind+JS) + `_Navbar`/`_Footer` partial'ları. **Share (`/s/{token}`) sayfası dokunulmadı** — hâlâ eski `_Layout` + `site.css` dünyasında, izole.
- Doğrulama: `dotnet build` 0 hata/0 uyarı · tüm rotalar 200 (`/`,`/privacy`,`/terms`,`/support`,`/delete-account`), `/s/{gecersiz}` 404 · headless ekran görüntüleriyle hero + alt sayfa görsel teyit (navbar home'da şeffaf, alt sayfada açık).
- **Kalan:** `somine_web_landing` klasörü artık ölü (kullanıcı silme kararı bekliyor). SomineWeb Docker imajı `landing.css`+`lib/swiper` commit'li olduğundan node'suz derlenebilir; yeni imaj build+deploy edilmeli.

---

## Değişiklik Günlüğü — 2026-07-04/05 (tek çalışma bloğu)

Tek oturumda Faz 0–5'in tamamı bitirildi. Aşağıda tüm commit'ler ve kapanış doğrulaması.

**somine_app (dal `feature/api-auth-migration`, GitHub'da):**
| Commit | İş |
|---|---|
| `78f602d` | Faz 1: Firestore'dan tam çıkış + paylaşım endpoint'lerine bağlanma + güvenlik hijyeni |
| `d255bb4` | Faz 2 client: toplam-500 limit modeli + hatırlatıcı/paylaşım limitleri + taşıma akışı düzeltmesi |
| `daa613d` | Faz 3: hatırlatıcı tüm içerik tiplerinde (detay ekranı + kart rozeti + 3-limit) |
| `4f191b3` | Faz 5 aşama 1: l10n altyapısı + çekirdek ekranlar TR/EN |
| `1330ae5` | Faz 5 aşama 2: ana ekranlar TR/EN |
| `3e7e380` | Faz 5 aşama 3: kalan ekran+widget TR/EN (487 key) |
| `e502a50` | Faz 4 mobil: public link UI (Paylaş/Kopyala/Yenile/İptal) |

**somine_api (git yalnızca bu makinede — GitHub yedeği bekliyor):**
| Commit | İş |
|---|---|
| ilk commit'ler | Faz 0: git init + .gitignore + rate limiting + CORS + ölü endpoint temizliği |
| `4d4bb6d` | Faz 2 backend: CachedSubscriptionService + limit guard'ları (create/copy/restore/reaktivasyon) |
| `0bc9965` | Controller integration testleri (WebApplicationFactory + SQLite) |
| `b013eb1` | Faz 4: public paylaşım linki (128-bit token) + SomineWeb `/s/{token}` Razor sayfası |
| `096a489` | Outgoing ShareDto'ya PublicLinkToken (mobil rozet) |
| `3c3deea` | SomineWeb Dockerfile |

**somine_web_landing (git yalnızca bu makinede):** Docker imajından kurtarıldı (Next.js, mint tema), tasarımına dokunulmadı — hibrit mimaride kendi container'ında kalıyor.

**Kapanış doğrulaması (2026-07-05):** API `dotnet build` 0 hata + `dotnet test` 36/36 · App `flutter analyze` 0 hata (48 baseline) + `flutter test` 8/8 + `flutter build ios --no-codesign` ✓ (126.9MB) · Deploy imajları: `somineapi:prod_v10` + `somine-share:v1` (tar'lar hazır, v9 silindi).

**Çalışma yöntemi notu:** Çoklu-model orkestrasyonla yürütüldü (Fable orkestratör; Sonnet/GLM/Codex/Opus işçiler). Kota dolumları nedeniyle işler birden çok kez el değiştirdi ama devir zinciriyle yarım iş kaybedilmedi. Ders: hacimli işler (l10n gibi) bundan sonra dosya-bazlı küçük paketlere bölünecek.

---

## FAZ 0 — Güvence ve Hijyen ✅ TAMAMLANDI (2026-07-04)

Yapılanlar: somine_api git'e alındı (initial commit) · app working tree commit'lendi ve GitHub'a push'landı (`feature/api-auth-migration`) · 8 adet .tar silindi · API key default'u koddan çıkarıldı, yeni key üretilip `appsettings.Local.json` + `LOCAL_SECRETS.md`'ye yazıldı (prod rotasyonu mobil release ile birlikte — eski TestFlight build'leri eski key'i gömülü taşıyor!) · bozuk `DELETE /api/auth/account` kaldırıldı · rate limiting eklendi (300/dk kullanıcı-IP, auth uçları 10/dk) · CORS any-origin fallback kapatıldı.

Ek kazanım: `somine_web_landing` kaynağı kurtarıldı — Docker imajı `somine-web:latest_v5` ile doğrulanıp `~/Downloads/somine-landing`'den projeye taşındı (Next.js + Tailwind + shadcn; kendi git geçmişiyle). Sayfalar: ana + privacy + terms + support + delete-account.

Not: Hetzner'a SSH bu ortamdan yetkisiz (publickey denied) — sunucu deploy adımları kullanıcıya kalır; imaj lokalde hazırlanacak.

⚠️ Yedekleme boşluğu: `somine_app` GitHub'da (`gokmenkucuk/somine`, dal `feature/api-auth-migration`) ✓ ama **somine_api ve somine_web_landing commit'leri yalnızca bu makinede** (remote yok, gh CLI kurulu değil). İlk fırsatta GitHub'da iki private repo aç ve push'la:
```bash
# github.com/new'dan somine-api ve somine-web-landing (private) oluşturduktan sonra:
cd somine_api && git remote add origin https://github.com/gokmenkucuk/somine-api.git && git push -u origin master
cd ../somine_web_landing && git remote add origin https://github.com/gokmenkucuk/somine-web-landing.git && git push -u origin master
```

## FAZ 0 (orijinal madde listesi — arşiv)

1. `somine_api`'yi git'e al (hiç versiyon kontrolü yok)
2. `somine_app`'te `feature/api-auth-migration` working tree'sini commit'le (73 dosya / ~8.900 satır commit'siz)
3. API key rotasyonu: `api_config.dart:11` default'unu boşalt, `--dart-define=SOMINE_API_KEY=...` ile ver, sunucuda eski key'i geçersiz kıl
4. `somine_api` kökündeki 8 adet `somine-api-prod*.tar` dosyasını sil, `.gitignore`'a ekle
5. `DELETE /api/auth/account` endpoint'ini kaldır (çağıranı yok; `collection_shares` Restrict FK'sında patlıyor)
6. Rate limiting ekle (yok) + CORS any-origin fallback'ini kapat

**Çıkış:** İki proje de git'te, secret'lar env'de, ölü endpoint yok.

## FAZ 1 — Firestore'dan Tam Çıkış ✅ TAMAMLANDI (2026-07-04)

Kalan iki adım:
- [ ] Backend'i yeni imajla deploy et (yeni endpoint'ler: shares/{id}/items, users/me DELETE, PhotoBase64, ClearPhoto — **mobil yeni sürüm bunlarsız çalışmaz, birlikte çıkmalı**)
- [ ] Cihazda smoke test (aşağıdaki checklist)

## FAZ 2 — Monetizasyon ✅ LİMİT MODELİ TAMAMLANDI (2026-07-04) / FİYATLANDIRMA KULLANICIDA

Uygulanan: client'ta toplam-500 modeli + 450 uyarısı + canCreateReminder/canCreateShare (Sonnet); catalog taşıma akışları limitsiz — taşıma toplamı değiştirmez (GLM 5.2); backend'de CachedSubscriptionService (IMemoryCache + premium snapshot + fail-open) ve create/copy/restore/reaktivasyon guard'ları (tasarım: GPT+GLM konseyi, review+fix: Codex). App `d255bb4`, API `4d4bb6d`.

⚠️ Migration yönetişimi (Codex bulgusu): Repo'daki attribute'suz 3 eski migration EF'e görünmüyor — prod şemasının bir kısmı elle SQL ile yönetilmiş. Bundan sonra şema değişikliği YALNIZCA `dotnet ef migrations add` ile yapılmalı; elle migration yazma bırakıldı. Yeni AddUserPremiumSnapshot migration'ı Designer.cs ile discoverable ve deploy'da otomatik uygulanacak.

KALAN (kullanıcı kararı): paywall fiyat/plan yapısı (haftalık planın kaldırılması + trial önerisi bekliyor).

### Orijinal Faz 2 tanımı (arşiv)

Starter (ücretsiz) yeni model — **karar verildi**:

| Özellik | Starter | Premium |
|---|---|---|
| Toplam içerik | **500** | Sınırsız |
| Koleksiyon | 10 | Sınırsız |
| Aktif hatırlatıcı | 3 | Sınırsız |
| Aktif paylaşım | 1 | Sınırsız |
| Gizli Kasa / Tema / Özel ikon | ❌ | ✅ |

- `subscription_service.dart`: koleksiyon-başı-5 limiti kalkar → toplam 500 sayacı + `canCreateReminder()` + `canCreateShare()`
- **Backend'de de enforce et** (şu an hiç yok — client bypass edilebilir): ItemsController create + SharesController create + RemindersController create'te tier kontrolü
- Paywall: haftalık plan kalkar; Aylık ₺79,99 + Yıllık ₺699,99 (kartta "ayda ₺58") + RevenueCat 7 gün trial
- 450 içerikte yumuşak uyarı, "487/500" sayacı
- **Bu fazla birlikte:** ItemsController/SharesController için ilk integration testleri (WebApplicationFactory) — limit mantığı test altında doğsun

## FAZ 3 — İçerik Bazlı Hatırlatıcı + Konumlandırma (2-3 gün)

Altyapı komple hazır (repository, scheduler, picker, RemindersController). İş, UI kilidini açmak:
- `add_content_screen.dart:1368` `if (!_isNoteMode) return;` koşulunu kaldır; `_buildReminderPicker()`'ı (satır ~2387) yalnızca not modunda değil tüm içerik tiplerinde göster
- Kayıt sonrası başarı sheet'ine hızlı seçim: "Yarın / Hafta sonu / Gelecek hafta / Özel"
- Item detayına hatırlatıcı ekle/düzenle/sil girişi; kartlarda `reminder_indicator`
- Starter 3 aktif hatırlatıcı limiti (Faz 2 ile entegre)
- Onboarding + App Store metadata: "Kaydettiklerin kaybolmasın — sana geri gelsin"

## FAZ 4 — Public Paylaşım Linki ✅ TAMAMLANDI (mobil dahil, 2026-07-05) — ~~HİBRİT MİMARİ~~ (GÜNCELLENDİ)

> ⚠️ 2026-07-05 güncelleme: Aşağıdaki hibrit mimari kararı GEÇERSİZ. Next.js landing SomineWeb'e bire bir taşındı (bkz. üstteki "landing → SomineWeb birleştirme" günlüğü). Caddy `/s/*` ayrıştırması gerekmiyor; tek servis her ikisini sunuyor.

Kararlar: (1) Güvenli link altyapısı .NET'te olacak; (2) ~~**landing tasarımı dokunulmaz** — Next.js landing (mint tema) olduğu gibi kalır, kendi container'ında.~~ (2 no'lu karar iptal — landing .NET/Razor'a taşındı.)

Mimari: `SomineWeb` (Razor Pages, somine_api solution'ında) YALNIZCA `/s/{token}` paylaşım sayfalarını sunar; Caddy `/s/*` → SomineWeb, diğer her şey → Next.js landing container'ı. Landing'e tek satır dokunulmaz.

Güvenlik tasarımı: paylaşım başına 128-bit kriptografik token (base64url ~22kr), yalnızca sahibi açar/iptal eder/yeniler, vault koleksiyonlarına açılamaz, `GET /public/shares/{token}` IP başına 30/dk rate limit + API-key muafiyeti, yanıtta kişisel veri yok (yalnızca görünen ad), share sayfası noindex, iptal edilen token nötr 404.

Uygulanan: backend token entity + migration + create/delete/get public-link endpoint'leri + SomineWeb `/s/{token}` Razor sayfası + integration testleri (API `b013eb1`). Mobil UI: `my_shares`'te Linki Paylaş / Kopyala / Yenile / İptal aksiyonları (App `e502a50`). Outgoing `ShareDto`'ya `PublicLinkToken` eklendi ki mobil link rozeti çalışsın; alıcıya (incoming) token sızdırılmaz (API `096a489`). SomineWeb için ayrı Dockerfile eklendi (API `3c3deea`). Kalan: yalnızca Caddy `/s/*` yönlendirmesi + deploy (bkz. Ek C — kullanıcıda).

### Orijinal Faz 4 tanımı (arşiv)

- Backend: `GET /public/shares/{slug}` (tahmin edilemez token'lı slug, rate limit'li; paylaşım kapanınca link ölür)
- `somine_web_landing` (şu an boş): landing ana sayfa (değer önerisi + App Store butonu; privacy/terms zaten canlı) + salt-okunur koleksiyon görünümü + "SoMine'de aç"
- Orta vadede: shares için SignalR hub'ı (şu an mobilde 2 sn'lik polling var — yük ve pil maliyeti)

## FAZ 5 — İngilizce Lokalizasyon ✅ TAMAMLANDI (2026-07-05)

**Aşama 1 ✅ (commit `4f191b3`):** gen-l10n altyapısı kuruldu (l10n.yaml, `lib/l10n/app_tr.arb` şablon + `app_en.arb`, cihaz diline göre tr/en). Taşınan: login, settings, profile, paywall (fiyat string'leri bilinçli hariç), limit_reached_dialog, failure_mapper.

**Aşama 2 ✅ (commit `1330ae5`):** Ana ekranların Türkçe UI string'leri ARB'ye taşındı: `home_screen`, `item_feed_screen`, `catalog_screen`, `add_content_screen`, `search_screen`, `item_detail_screen`. Limit/hatırlatıcı metinleri ortak key'le; marka/URL/log taşınmadı.

**Aşama 3 ✅ (commit `3e7e380`):** Kalan ekranlar (paylaşım/bildirim/onboarding/yardım vb.) + widget'lar taşındı. Toplam 487 key, TR + EN eksiksiz. Fiyat/paywall string'lerine bilinçli olarak dokunulmadı.

### Orijinal Faz 5 tanımı (arşiv)

- ARB tabanlı l10n (`app_tr.arb`, `app_en.arb`); ~30 ekran hard-coded Türkçe metin taşınacak
- Bilinçli olarak en sonda: Faz 2-3 metinlere dokunuyor, iki kez çeviri yapılmasın
- App Store metadata EN; cihaz diline göre otomatik dil

✅ Ek kapanış (2026-07-04): Controller integration testleri kuruldu (`0bc9965`, Codex) — WebApplicationFactory + SQLite, limit 403'leri + paylaşım yetkisi senaryoları, 31/31. NOT: prod_v9.tar bu commit'ten ÖNCE derlendi; test-only değişiklik olduğu için imaj güncel sayılır.

## Kullanıcıya Kalanlar (kapanış — 2026-07-05)

Kod tarafındaki fazların tamamı (Faz 0–5) bitti ve doğrulandı. Aşağıdakiler yalnızca kullanıcı kararı / makine-dışı erişim gerektirdiği için sende:

1. **Fiyatlandırma kararı** — Paywall plan/fiyat yapısı (haftalık planın kaldırılması + trial önerisi) hâlâ senin kararında. Kod bu karara hazır; yalnızca metin/RevenueCat ürün yapılandırması gerekir. (Ben paywall/fiyat metinlerine hiç dokunmadım.)
2. **Deploy (prod_v11 + somine-share:v2)** — `somine-api-prod_v11.tar` (98MB, linux/amd64) ve `somine-share-v2.tar` (138MB, linux/amd64, landing DAHİL) hazır (`somine_api/` kökünde). Ek C'deki adımlarla Hetzner'a yükle. **Caddy `/s/*` ayrıştırması ARTIK GEREKMİYOR** — somine-share:v2 hem landing'i hem `/s/{token}`'i sunuyor; Caddy her şeyi somine-share'e proxy'ler, Next.js landing container'ı emekliye ayrılır. (Hetzner'a SSH bu ortamdan yetkisiz olduğu için deploy sende.)
3. **GitHub yedeği** — `somine-api` ve `somine-web-landing` private repolarını GitHub'da aç ve push'la (bkz. Faz 0'daki komutlar). Şu an bu iki repo yalnızca bu makinede; `somine_app` zaten GitHub'da.
4. **Cihazda smoke test** — Yeni imaj deploy edildikten sonra Ek B checklist'ini gerçek cihazda koştur (özellikle paylaşım + public link akışı + hatırlatıcı).
5. **API key rotasyonu** — Yeni mobil sürüm TestFlight'a çıkarken yap: sunucu env `ApiKey__Key=<yeni key>` + mobil build `--dart-define=SOMINE_API_KEY=<aynı key>`. Deploy tek başına key'i değiştirmez (mevcut TestFlight build'leri eski key'i gömülü taşıyor).

## Faz Sonrası Aday İşler (sıralanmadı)
- dotnet build'de 6 paket güvenlik uyarısı var (transitif bağımlılıklar) — `dotnet list package --vulnerable` ile dök ve güncelle

- JSON/CSV dışa aktarma ("verin senindir" güveni)
- Ana ekran widget'ı (paywall'da vaat ediliyor)
- Ölü kod temizliği: `capture_screen.dart` (hiç çağrılmıyor), item_feed'deki kullanılmayan builder'lar (75 analyze uyarısı)
- Analitik eventleri (paywall dönüşümü, D1/D7, hatırlatıcı oranı) — bugün hiçbir ürün metriği ölçülmüyor
- Android'i üretime hazırlama (imza, RevenueCat prod key, SHA kaydı)
- Semantik arama (paywall'daki "Akıllı Arama" vaadini gerçek yapmak)

---

## Ek A — Lokal Çalıştırma

```bash
# API (lokal)
cd somine_api && dotnet run --project src/SomineApi.WebApi   # LOCAL_SECRETS.md'ye göre appsettings.Local.json gerekir

# Mobil, lokal API'ye karşı (key: somine_api/LOCAL_SECRETS.md → "API Key Rotasyonu")
cd somine_app && flutter run \
  --dart-define=SOMINE_API_BASE_URL=http://127.0.0.1:5181 \
  --dart-define=SOMINE_API_KEY=<LOCAL_SECRETS.md'deki yeni key>

# Mobil, prod API'ye karşı (deploy'a kadar ESKİ prod key kullanılır)
flutter run --dart-define=SOMINE_API_KEY=<prod key>

# NOT: API key artık koda gömülü değil; dart-define verilmezse app key header'ı göndermez ve API reddeder.
```

## Ek B — Cihaz Smoke Test Checklist (Faz 1 kapanışı için)

1. **Auth:** açılış, mevcut oturum, Google ve Apple login, logout
2. **Profil:** isim/kullanıcı adı değiştirme, fotoğraf yükleme + temizleme (yeni: API'de)
3. **Kategoriler:** oluştur/yeniden adlandır/ikon/sırala/sil
4. **İçerik:** link + not + görsel ekle, düzenle, favori, taşı, sil → son silinenler → geri al → kalıcı sil
5. **Paylaşım (kritik — yeni onarıldı):** istek gönder/kabul/reddet, paylaşılan koleksiyonu aç (içerik + görseller gelmeli), koleksiyona kopyala, yeni koleksiyon oluşturarak kopyala, paylaşımı iptal et
6. **Bildirimler:** liste, okundu, tümünü okundu, sil; bildirime dokununca doğru ekran
7. **Hatırlatıcı:** not içeriğinde kur, bildirim gelsin, iptal et
8. **Abonelik:** paywall açılıyor, restore çalışıyor, premium durumu backend'den okunuyor
9. **Hesap silme:** tüm veri + dosyalar gidiyor, tekrar kayıt olunabiliyor
10. **Regresyon:** uçak modunda anlamlı hata mesajları; oturum yenileme (15 dk+ açık bırak)

## Ek C — Deploy: prod_v11 + somine-share:v2 HAZIR (2026-07-06) — tek adım sende

İki imaj `somine_api/` kökünde hazır (ikisi de **linux/amd64**, `--load` ile lokal Docker store'da da mevcut):
- `somine-api-prod_v11.tar` (98MB) → `gokmenkucuk/somineapi:prod_v11`. İçerik: Firestore-sonrası tüm endpoint'ler + rate limiting + limit enforcement + public paylaşım linki endpoint'leri (`GET /public/shares/{token}`, share `public-link` create/delete) + outgoing ShareDto'da PublicLinkToken + AddUserPremiumSnapshot migration'ı (açılışta otomatik uygulanır). (Kod prod_v10 ile aynı; sürüm artışı için temiz yeniden derleme.)
- `somine-share-v2.tar` (138MB) → `gokmenkucuk/somine-share:v2`. İçerik: SomineWeb (Razor Pages) — artık **hem landing (`/`, `/privacy`, `/terms`, `/support`, `/delete-account`) HEM public paylaşım sayfası (`/s/{token}`)**, port 8080. Tailwind CSS `wwwroot/css/landing.css` olarak commit'li (imaj node gerektirmez). `Api:BaseUrl` env'i API container'ına işaret etmeli.

```bash
# 1. İki tar'ı da sunucuya taşı
scp /Users/gokmenkucuk/Desktop/App/SoMine/somine_api/somine-api-prod_v11.tar root@46.224.146.102:/opt/somine/
scp /Users/gokmenkucuk/Desktop/App/SoMine/somine_api/somine-share-v2.tar root@46.224.146.102:/opt/somine/

# 2. Sunucuda yükle ve geçir
ssh root@46.224.146.102
cd /opt/somine
docker load -i somine-api-prod_v11.tar
docker load -i somine-share-v2.tar
SOMINE_API_IMAGE=gokmenkucuk/somineapi:prod_v11 docker compose -f docker-compose.server.yml up -d
docker compose -f docker-compose.server.yml logs -f somine-api   # "Applying migration" + Healthy görmelisin

# 3. Sağlık kontrolü
curl https://api.somineapp.com/health
```

### SomineWeb (somine-share) servisi + Caddy yönlendirmesi

`docker-compose.server.yml`'e somine-share servisini ekle (API ile aynı ağda), örnek:

```yaml
  somine-share:
    image: gokmenkucuk/somine-share:v2
    restart: unless-stopped
    environment:
      - Api__BaseUrl=http://somine-api:8080      # API container adına göre
    networks:
      - somine
```

Caddy: **artık `/s/*` ayrıştırması yok** — somine-share:v2 hem landing'i hem paylaşım sayfasını sunduğu için her şey ona proxy'lenir. Eski Next.js landing container'ı (`somine-landing`) emekliye ayrılabilir:

```caddy
somineapp.com {
    reverse_proxy somine-share:8080
}
```

ÖNEMLİ: Bu deploy API key'i DEĞİŞTİRMEZ — eski key geçerli kalır (mevcut TestFlight build'leri eski key'i gömülü taşıyor). Key rotasyonu, yeni mobil sürüm TestFlight'a çıkarken yapılacak: sunucu env'inde `ApiKey__Key=<LOCAL_SECRETS.md'deki yeni key>` + mobil build `--dart-define=SOMINE_API_KEY=<aynı key>`.

Geriye dönüş: `SOMINE_API_IMAGE=gokmenkucuk/somineapi:prod_v9 docker compose -f docker-compose.server.yml up -d` (migration geri alınmaz ama eski imaj yeni kolonları bilmediği için sorun çıkarmaz — kolonlar nullable). NOT: v9 tar'ı bu kapanışta silindi; gerekirse `gokmenkucuk/somineapi:prod_v9` imajı sunucuda hâlâ yüklüyse kullanılabilir.
