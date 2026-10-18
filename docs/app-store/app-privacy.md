# App Privacy ("Gizlilik Etiketi") Cevapları

Tarih: 2026-10-18 · Kaynak: kod. ASC'ye **girilmedi** (bkz. README), aşağıdaki tablo ASC → App Privacy → "Get Started / Edit" sihirbazına birebir aktarılacak şekilde hazırlandı.

## Özet

- **Takip (tracking): HAYIR.** ATT kullanılmıyor: kodda `AppTrackingTransparency`/`requestTrackingAuthorization` yok; Firebase Analytics `AnalyticsWithoutAdIdSupport` alt pod'u ile geliyor (`mobile/ios/Podfile.lock`), yani IDFA toplanmıyor. Reklam SDK'sı yok. Veri üçüncü taraflarla reklam/veri simsarlığı için paylaşılmıyor.
- **"Data Used to Track You": boş.**
- **"Data Linked to You":** Contact Info (Email, Name), User Content (Photos or Videos, Other User Content), Identifiers (User ID, Device ID), Purchases (Purchase History), Usage Data (Product Interaction), Search History, Diagnostics (Other Diagnostic Data).
- **"Data Not Linked to You":** Diagnostics (Crash Data, Performance Data).

## İncelenen SDK ve kaynaklar

| Kaynak | Dosya | Topladığı |
|---|---|---|
| Firebase Auth (Apple + Google ile giriş) | `mobile/pubspec.yaml` firebase_auth, sign_in_with_apple, google_sign_in; Pod GoogleSignIn 8.0, AppAuth, GTMAppAuth | E-posta, ad, profil fotoğrafı URL'si, Firebase UID |
| Firebase Analytics (IDFA'sız) | `mobile/lib/core/services/analytics_service.dart` | Eventler: login, sign_up, activation, content_add(type, source), reminder_set, paywall_view/convert(product_id), share, widget_tap, export, screen_view. Uygulama örnek kimliği (app instance ID). `setUserId` **çağrılmıyor** → Firebase tarafında kullanıcıya bağlanmıyor |
| Firebase Crashlytics (+ FirebaseSessions) | `mobile/lib/main.dart:71-123` | Çökme kaydı, yığın izi, cihaz modeli, OS sürümü, kurulum UUID'si. `setUserIdentifier` **yok** → bağlanmıyor |
| Firebase Messaging (FCM) | pubspec firebase_messaging; API `DeviceToken` (Token, Platform, Locale, UserId) `api/src/SomineApi.Domain/Entities/DeviceToken.cs` | Push token, kullanıcıya bağlı |
| RevenueCat (purchases_flutter) | `mobile/lib/core/services/subscription_service.dart` (`Purchases.logIn(firebaseUid)`) | Satın alma geçmişi, app user ID = Firebase UID |
| somine API (kendi sunucu, Hetzner) | `api/src/SomineApi.Domain/Entities/*.cs` | Aşağıda |
| local_auth (Face ID) | Gizli Kasa | Biyometrik veri **cihazdan çıkmaz**, toplanmaz |
| image_picker / kamera | profil fotoğrafı, görsel içerik | Yüklenen görsel sunucuda saklanır (User Content) |
| apple_maps_flutter | kaydedilen konum linkinin harita önizlemesi | Kullanıcının konumu **toplanmaz**; konum izni metni yalnız harita gösterimi için (`Info.plist` NSLocationWhenInUseUsageDescription) |
| flutter_local_notifications | hatırlatıcı + haftalık özet | Cihazda yerel |
| home_widget | Günün Kaydı widget'ı | App Group içinde yerel |

Sunucunun sakladıkları (somine API, PostgreSQL):
- `User`: FirebaseUid, Email, DisplayName, Username, PhotoUrl, PhotoBase64, **SearchHistoryJson** (son 10 arama, `mobile/lib/core/services/preferences_service.dart:26-66`), TimeZoneId, PremiumExpiresAtUtc.
- `Item`: Url, Note, ImageUrl, OG başlık/açıklama/görsel, favori, silinme, **LastOpenedAt, OpenCount** (açılma takibi → resurfacing).
- `Category`, `CollectionShare`, `UserBlock`, `ContentReport`, `Reminder`, `Notification`, `UploadedFile`.
- `AuthSession`: refresh token özeti, cihaz adı, User-Agent, **IP adresi**.
- `RequestLog` / `ExceptionLog`: yol, durum kodu, süre, **IP adresi, User-Agent, UserId** (gövde loglanmıyor; PLAN.md güvenlik denetimi).

## ASC sihirbazı cevapları

"Do you or your third-party partners collect data from this app?" → **Yes**

| Veri tipi (ASC adı) | Toplanıyor | Kullanıcıya bağlı | Takip | Amaçlar | Kaynak |
|---|---|---|---|---|---|
| Contact Info → **Email Address** | Evet | Evet | Hayır | App Functionality | Apple/Google girişi, `User.Email` |
| Contact Info → **Name** | Evet | Evet | Hayır | App Functionality | `User.DisplayName`, `Username` (paylaşımda diğer kullanıcılara görünür) |
| User Content → **Photos or Videos** | Evet | Evet | Hayır | App Functionality | profil fotoğrafı, görsel içerik (`UploadedFile`, `PhotoBase64`) |
| User Content → **Other User Content** | Evet | Evet | Hayır | App Functionality | linkler, notlar, koleksiyonlar, hatırlatıcılar, şikâyet kayıtları |
| Identifiers → **User ID** | Evet | Evet | Hayır | App Functionality | Firebase UID, RevenueCat app user ID |
| Identifiers → **Device ID** | Evet | Evet | Hayır | App Functionality, Analytics | FCM push token (kullanıcıya bağlı), Firebase app instance/installation ID |
| Purchases → **Purchase History** | Evet | Evet | Hayır | App Functionality | RevenueCat + sunucu premium anlık görüntüsü |
| Usage Data → **Product Interaction** | Evet | Evet | Hayır | Analytics, App Functionality | Firebase Analytics eventleri (bağlı değil) + sunucuda içerik açılma sayısı/zamanı (bağlı) → en katı cevap "bağlı" |
| **Search History** | Evet | Evet | Hayır | App Functionality | son 10 arama sunucuda (`SearchHistoryJson`) |
| Diagnostics → **Crash Data** | Evet | Hayır | Hayır | App Functionality | Crashlytics |
| Diagnostics → **Performance Data** | Evet | Hayır | Hayır | App Functionality | FirebaseSessions (Crashlytics oturum verisi) — muhafazakâr işaretleme |
| Diagnostics → **Other Diagnostic Data** | Evet | Evet | Hayır | App Functionality | sunucu istek/hata logları (UserId, IP, User-Agent) |

**Toplanmayanlar (işaretleme):** Health & Fitness, Financial Info, Location (Precise/Coarse), Sensitive Info, Contacts, Emails or Text Messages, Audio Data, Gameplay Content, Customer Support (destek e-postayla, uygulama dışı), Browsing History (kayıtlar kullanıcının bilinçli kaydettiği içerik, tarama geçmişi değil), Advertising Data, Other Data Types, Phone Number, Physical Address, Other User Contact Info.

Not: IP adresi Apple'ın ayrı bir veri tipi değildir; konum türetmek için kullanılmadığı sürece "Coarse Location" işaretlenmez. Sunucuda IP'den konum çıkarılmıyor.

## Kod ile gizlilik politikası arasındaki çelişkiler (DÜZELTİLMELİ)

Canlı politika: https://www.somineapp.com/privacy (2 Ağustos 2026 tarihli, yalnız Türkçe; repo'daki `api/src/SomineWeb/Pages/Shared/_PrivacyBody.{tr,en}.cshtml` aynı içerikte).

| # | Politikada | Kodda gerçek | Öneri |
|---|---|---|---|
| 1 | "Firebase: kullanıcı kimlik doğrulama, **veri saklama**…" | İçerik Firebase'de değil, kendi sunucumuzda (PostgreSQL, Hetzner, AB; veri merkezi konumunu doğrula). Firebase yalnız Auth, Analytics, Crashlytics, Messaging | Firebase maddesini "kimlik doğrulama, analiz, çökme raporu ve bildirim iletimi" yap; ayrı madde: "İçerikleriniz Avrupa Birliği'ndeki (Hetzner) kendi sunucularımızda saklanır" |
| 2 | Firebase Cloud Messaging **anılmıyor** | Push bildirimleri FCM ile, cihaz token'ı sunucuda saklanıyor | Madde ekle |
| 3 | "Uygulama ayarlarınızdan **çerez tercihlerinizi** yönetebilirsiniz" | Uygulamada çerez ayarı yok | Cümleyi kaldır (yanlış beyan, 5.1.1 riski) |
| 4 | Arama geçmişi anılmıyor | Son 10 arama sunucuda | "Kullanım verileri" maddesine ekle |
| 5 | Sunucu logları (IP, User-Agent) açıkça anılmıyor | RequestLog/AuthSession IP saklıyor, saklama süresi tanımsız (PLAN.md: "request_logs retention" açık iş) | "Güvenlik ve hata ayıklama için IP ve cihaz bilgisi X gün saklanır" + gerçekten X günlük temizlik işi |
| 6 | "Apple App Store / **Google Play**" | Android yayında değil | Zararsız ama "Google Play" ifadesini kaldır veya "ileride" diye belirt |
| 7 | İçerik şikâyetleri anılmıyor | Şikâyetler saklanıyor ve moderatöre e-postayla gidiyor | "Şikâyet ettiğinizde içerik ve hesap bilgisi incelenmek üzere saklanır" |
| 8 | Paylaşımda görünen bilgiler anılmıyor | Koleksiyon paylaşımında görünen ad/kullanıcı adı karşı tarafa, herkese açık linkte görünen ad herkese görünür | Ekle |
| 9 | Veri sorumlusu kimliği yok (KVKK) | — | "Veri sorumlusu: Gökmen Küçük (GSO Studio), iletişim: destek@somineapp.com" ekle |
| 10 | Canlı site `?lang=en` desteklemiyor | Repo'daki iki dilli sürüm deploy edilmemiş | SomineWeb yeni imajını deploy et (README blokaj #1) |

Ayrıca `mobile/ios/Runner/PrivacyInfo.xcprivacy` toplanan veri tipleri listesinde yalnız Email, Name, OtherUserContent, PhotosOrVideos var; **Search History, User ID, Purchase History, Product Interaction** eksik. Apple bu dosyayı etiketle birebir karşılaştırmıyor (SDK'ların kendi manifestleri ayrı), ama tutarlılık için bir sonraki build'de eklenmesi önerilir.
