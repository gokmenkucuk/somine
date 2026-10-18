# App Review Notes (English) + 2.1 hazırlığı

ASC → 1.0 sürümü → App Review Information. Aşağıdaki "Notes" metni yapıştırmaya hazır (3.874 karakter; ASC sınırı 4.000 — köşeli parantezleri doldururken sınırı aşma). Köşeli parantezli yerleri gönderimden önce doldur.

## Sign-in Information kararı

somine'de e-posta/şifre girişi yok; yalnız **Sign in with Apple** ve **Google**. İki seçenek:

- **A (minimum, kabul edilebilir):** "Sign-in required" kutusunu **kaldır**, notta "Sign in with Apple ile kendi Apple Kimliğinizle giriş yapın, hesap anında oluşur" de. Apple bu yaklaşımı kabul ediyor; ama inceleyen paylaşım/şikâyet akışını görmek için **ikinci bir kullanıcı** bulamaz.
- **B (önerilen, Yetti dersinden):** Bir **demo Google hesabı** aç (ör. `somine.review@gmail.com`, 2FA kapalı veya inceleme süresince yedek kodla), uygulamada onunla giriş yap, şunları hazırla: 3 koleksiyon, 10–15 kayıt, 1 kurulu hatırlatıcı, ve **ikinci bir demo hesaptan** (`somine_friend` kullanıcı adlı) bu hesaba gönderilmiş ve **kabul edilmiş** bir paylaşılan koleksiyon + bekleyen bir paylaşım isteği. Böylece inceleyen Bildir/Engelle'yi tek tıkla görür. "Sign-in required" kutusunu işaretle, kullanıcı adı/şifreyi oraya yaz (nota yazma). Hesapları ben açmadım; senin açman gerekiyor.

Google hesabında Apple incelemesi bazen "yeni cihazdan giriş" doğrulamasına takılır: hesaba bir kurtarma telefonu ekleme, ilk girişi ABD IP'siyle test etmek mümkün değilse notta "If Google asks for verification, please use Sign in with Apple instead" yaz (aşağıdaki notta var).

## Notes (yapıştır)

```
Thank you for reviewing somine.

WHAT THE APP DOES
somine lets people save links, notes and photos from anywhere (via the iOS Share Sheet or inside the app), organize them into collections, and get them back through reminders, an optional weekly "It came back to you" notification and a home screen widget. Users can share a collection with a friend by username (the friend must accept) or create a read-only public web link. The app is free with limits; somine Premium is an auto-renewable subscription (weekly, monthly, yearly) sold through In-App Purchase.

SIGN IN
The app only offers Sign in with Apple and Sign in with Google; there is no email/password account. You can sign in with your own Apple ID using Sign in with Apple: an account is created instantly and you only choose a display name and username.
We also provide a prepared Google demo account in the Sign-In Information fields. It already contains collections, a reminder and a collection shared from a second demo user, so you can test sharing, reporting and blocking. If Google asks for extra verification, please use Sign in with Apple instead.

HOW TO TEST THE MAIN FLOW
1. Tap the + button on the Feed tab to add a link, note or photo and pick a collection.
2. Share extension: in Safari, open any page, tap Share > somine (you may need to tap "More" once to enable it). somine opens with the link prefilled; choose a collection and save.
3. After saving, the success sheet offers a quick reminder (Tomorrow / Weekend). Reminders are also under Profile > My Reminders.
4. Widget: long-press the Home Screen > + > somine > "Günün Kaydı / Today's Pick".

USER-GENERATED CONTENT (Guideline 1.2)
Content from other users only appears after the user accepts a share request.
- Report / block / leave: Profile > Shared With Me > open a shared collection > "..." (top right) > Report collection (4 reasons), Block [name], or Remove from my library. The same "..." menu is on each row of Shared With Me.
- Decline and block an incoming request: Profile > Shared With Me (requests list) > Decline > Decline and block.
- Blocked users list and unblock: Profile > Shared With Me > block icon (top right).
- Reports are emailed to our moderator and reviewed within 24 hours; abusive collections and public links are removed and repeat offenders are suspended. Public web pages (somineapp.com/s/...) have a "Report this content" link.

ACCOUNT DELETION (Guideline 5.1.1(v))
Profile > Account Info > Delete Account (also at the bottom of the Profile screen). Deletion is immediate and removes all items, collections, shares and files; Sign in with Apple tokens are revoked. Users can also export their data first: Profile > Export your data (JSON or CSV).

SUBSCRIPTION (Guideline 3.1.2)
Paywall: Profile > Membership Plan card, or any Premium feature (Hidden Vault, sharing a collection, Midnight/Vibe themes, custom icons) or hitting a free limit (500 items, 10 collections, 3 active reminders). Products: somine.pro.haftalik (weekly), somine.pro.aylik (monthly), somine.pro.yillik (yearly). No free trial. The paywall shows auto-renewal terms, Restore Purchases, Terms of Use and Privacy Policy links. Purchases work with a Sandbox account; premium status is verified on our server through RevenueCat.

PERMISSIONS
Notifications are requested only when the user saves their first item or sets a reminder. Camera and Photos are requested only when adding a photo. Face ID is used only for the Hidden Vault. The location purpose string exists because the map preview of a saved place link uses MapKit; the app never requests or stores the user's location.

PUSH NOTIFICATIONS
Remote notifications (via Firebase Cloud Messaging) are sent for share requests and accepted/declined shares. Reminders and the weekly digest are local notifications.

CONTACT
[Gökmen Küçük], GSO Studio — support@somineapp.com — [phone]
```

## App Review Information alanları

| Alan | Değer | Durum |
|---|---|---|
| First / Last name | Gökmen / Küçük | ASC'de dolu mu kontrol et |
| Phone | — | **Senin girmen gerekiyor** (uydurulmadı) |
| Email | support@somineapp.com (veya kişisel) | |
| Sign-in required | B seçeneğinde işaretli + demo hesap | Hesap senin tarafından açılmalı |
| Attachment | Opsiyonel: aşağıdaki ekran kaydı (2.1'i önler) | |

## 2.1 "Information Needed" için hazır cevaplar (Yetti'de gelen 6 soru)

1. **What is the purpose of your app?** somine is a save-for-later app. Users save links, notes and photos from any app through the iOS Share Sheet, organize them into collections and get them back through reminders, a weekly local notification and a widget. Optional sharing lets friends exchange collections.
2. **Who is the target audience?** Adults and teens in Turkey and English-speaking countries who save recipes, places, videos and articles from social and web apps and want them in one place.
3. **Account / login steps?** Sign in with Apple or Google; no other account type. Demo Google account is in Sign-In Information. Account deletion: Profile > Account Info > Delete Account.
4. **External services?** Our own API (api.somineapp.com, hosted by us) stores user content. Firebase is used for authentication, analytics (no advertising ID) and crash reports, Firebase Cloud Messaging for push, RevenueCat to validate App Store subscriptions. No ads, no tracking.
5. **Regional differences?** None. The app is localized in English and Turkish and behaves the same in every storefront.
6. **Regulated industry / licenses?** Not applicable. The app does not deal with finance, health, gambling or other regulated content.
7. **Paid content?** somine Premium auto-renewable subscription through In-App Purchase only; no external payments or links to purchase.

## Ekran kaydı çekim listesi (fiziksel iPhone, ~4–6 dk, Ayarlar > Denetim Merkezi > Ekran Kaydı)

Kayıttan önce: Rahatsız Etme açık, demo hesap hazır, Safari'de bir tarif sayfası açık, ikinci demo hesaptan bir paylaşım isteği bekliyor.

1. (0:00) Uygulamayı ilk kez aç → Sign in with Apple → ad ve kullanıcı adı → varsayılan koleksiyonlar.
2. (0:40) Safari'de sayfa → Paylaş → somine → koleksiyon seç → kaydet → başarı sayfasında "Yarın" hatırlatıcısı → bildirim izni istemi.
3. (1:30) Akış'ta karta dokun, detay, favori, başka koleksiyona taşı. Ara sekmesinde yazım hatalı arama ("tarfi" → tarif sonuçları).
4. (2:10) Profil > Hatırlatıcılarım. Ana ekrana widget ekle.
5. (2:40) Koleksiyonlar > bir koleksiyon > ... > Koleksiyonu Paylaş → Kişiyle / Link ile (paywall'ın açıldığını göster, Restore ve şartlar linklerini göster, sandbox ile satın al).
6. (3:30) Profil > Benimle Paylaşılanlar → isteği kabul et → koleksiyonu aç → ... → Koleksiyonu bildir (sebep seç) → Engelle → Engellenenler listesi → engeli kaldır.
7. (4:30) Gizli Kasa: koleksiyonu kasaya taşı → Face ID ile aç.
8. (5:00) Profil > Verilerini dışa aktar (CSV) → Hesap Bilgileri > Hesabı Sil (onay ekranını göster, istersen gerçekten sil ve giriş ekranına dönüşü göster).

Kayıt 10 MB'yi geçerse tarayıcı aracı yükleyemez (Yetti notu); ASC'ye elle yükle veya Reply to App Review ekine koy.
