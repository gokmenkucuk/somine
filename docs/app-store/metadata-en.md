# Mağaza Metinleri — English (U.S.)

Durum: Ad ve alt başlık **ASC'ye girildi ve kaydedildi (2026-10-18)**. Diğer alanlar ASC'ye girilemedi (tarayıcı otomasyonu izin sınırına takıldı, bkz. README); aşağıdaki metinler yapıştırmaya hazır. Düz metin kopyaları: `copy/en_*.txt`.

Karakter sayıları Python `len()` ile ölçüldü (ASC de karakter sayar, bayt değil).

## Ad seçenekleri (≤30)

| Seçenek | Uzunluk | Gerekçe |
|---|---|---|
| **somine: Save Links & Bookmarks** (önerilen, girildi) | 30 | En güçlü iki düşük rekabetli kategori ifadesi ("save links", "bookmark") başlıkta; ne yaptığını tek bakışta söylüyor |
| somine: Link Saver & Read Later | 31 | 1 karakter fazla; "somine – Link Saver, Read Later" gibi kısaltma gerekirdi |
| somine: Save for Later | 22 | Duygusal ve net, ama "bookmark" kaybolur, 8 karakter boşa |
| somine: Social Bookmark (eski) | 23 | "social bookmark" için Apple'da jenerik arama önerisi yok (yalnız uygulama adları), "social" ise inceleme ve kitle açısından yanlış beklenti (sosyal ağ) yaratıyor |

Not: İlk sürüm yayımlanmadan önce ad serbestçe değişir; yayından sonra da her sürümde değişebilir, ama ad değişikliği sıralama geçmişini sıfırlamaz, yalnız alaka sinyalini değiştirir.

## Alt başlık seçenekleri (≤30)

| Seçenek | Uzunluk | Not |
|---|---|---|
| **Read later with reminders** (önerilen, girildi) | 25 | "read later" + "reminder", farklılaştırıcıyı söylüyor |
| Saved posts that come back | 26 | Daha duygusal, anahtar kelime zayıf (A/B testi adayı, bkz. growth-plan) |
| Collect, organize, get reminded | 31 | 1 fazla |

### Promotional Text (160/170)

```
Stop losing great finds in screenshots and chats. Save any link in a few taps, sort it into collections and let somine bring it back when you finally have time.
```

Promosyon metni incelemeye girmez, istediğin zaman değiştirilebilir. Yayın haftası alternatifi: "New: Today's Pick widget brings one of your saves back every day. Add it from your Home Screen." (sürümle gelen özellikleri burada döndür).

### Description (2488/4000)

```
Saved it, then never saw it again? somine keeps the links, posts and notes you save from anywhere, and brings them back when you actually have time.

Tap Share in any app and choose somine, pick a collection, and your find is saved with a preview, ready when you are.

WHAT YOU CAN DO
• Save from anywhere: share links from Safari, social and video apps, or add notes and photos right inside somine.
• Keep it tidy: sort saves into collections like Recipes to Try or Places to Visit, mark favorites and move things around in seconds.
• Get reminded: set a reminder on any save for tomorrow, the weekend or any date you pick, and repeat it daily, weekly or monthly if you like.
• "It came back to you": an optional weekly notification brings back saves you haven't opened yet.
• Today's Pick widget: a home screen widget shows you one of your saves every day.
• Find it fast: search titles, notes and links. Small typos are forgiven.
• Share with friends: send a collection to a friend by username. Once they accept, it shows up in their library. Or create a public link anyone can open in a browser. (Premium)
• Hidden Vault: keep private collections behind Face ID or Touch ID. (Premium)
• Make it yours: Air, Midnight and Vibe themes plus alternate app icons.
• Your data stays yours: export everything as JSON or CSV, and delete your account from inside the app at any time. Deleted items wait 30 days in Recently Deleted.

Sign in with Apple or Google. somine is available in English and Turkish.

FREE AND PREMIUM
Free: up to 500 saves, 10 collections, 3 active reminders, the widget, search, the weekly digest and data export.
Premium: unlimited saves, collections and reminders; sharing collections with friends and public links; Hidden Vault; Midnight and Vibe themes; custom app icons.

SUBSCRIPTION INFORMATION
somine Premium is offered as an auto-renewing weekly, monthly or yearly subscription. Payment is charged to your Apple Account when you confirm the purchase. The subscription renews automatically unless it is cancelled at least 24 hours before the end of the current period, and renewal is charged within the 24 hours before the period ends. You can manage or cancel your subscription at any time in your App Store account settings.

Terms of Use: https://www.somineapp.com/terms?lang=en
Privacy Policy: https://www.somineapp.com/privacy?lang=en

Made at home: GSO Studio built somine for our own household first. Questions or feedback? Write to support@somineapp.com
```

İlk üç satır ("more" öncesi görünen kısım) problemi, çözümü ve nasıl çalıştığını veriyor. Abonelik paragrafı 3.1.2 için gerekli unsurları içeriyor: süre seçenekleri, otomatik yenileme, iptal penceresi (24 saat), yenileme ücretinin ne zaman alındığı, yönetim yeri, Kullanım Şartları ve Gizlilik Politikası bağlantıları. Fiyat bilinçli olarak yazılmadı (bölgeye göre değişir; mağaza zaten IAP listesinde gösteriyor).

Doğrulanan iddialar (dosya): limitler `api/src/SomineApi.Application/SubscriptionLimits.cs`, `mobile/lib/core/services/subscription_service.dart:333-337` · paylaşımın Premium olması `mobile/lib/screens/catalog_screen.dart` (_showEditCategoryOptions, `catalogSharePremiumMessage`) · tekrar seçenekleri `mobile/lib/core/models/reminder_model.dart:3` · arama alanları `api/src/SomineApi.Infrastructure/Data/ItemSearchQuery.cs:47-92` · 30 gün `recentlyDeletedInfoBanner` · widget `ios/SomineWidget/SomineWidget.swift:173` · paylaşım eklentisi yalnız link/metin `ios/somine/Info.plist` (NSExtensionActivationRule).

**Bilerek söylenmeyenler:** AI/akıllı arama, Android, web, iPad optimizasyonu, çevrimdışı okuma, ücretsiz deneme, Pocket/Instagram/TikTok markaları.

## Keywords (99/100)

```
saver,organizer,collection,folder,post,recipe,idea,inspiration,vault,note,wishlist,favorite,article
```

### What's New in This Version (137/4000)

```
Welcome to somine 1.0! Save links, posts, notes and photos from anywhere, sort them into collections and get reminded when you have time.
```

İlk sürümde ASC bu alanı göstermez; 1.0.1'den itibaren kullanılır.

## URL'ler

| Alan | Değer | Durum |
|---|---|---|
| Support URL | https://www.somineapp.com/support?lang=en | Canlı (200). **Ama canlı site eski sürüm:** `?lang=en` yok sayılıyor, sayfa Türkçe ve SSS'de yanlış bilgi var ("koleksiyon başına 5 içerik", "Gizli Kasa ücretsiz"). Repo'daki iki dilli SomineWeb deploy edilmeli. Bkz. README blokaj #1 |
| Marketing URL | https://www.somineapp.com/?lang=en | Canlı |
| Privacy Policy URL | https://www.somineapp.com/privacy?lang=en | Canlı (Türkçe döner, deploy sonrası İngilizce) |
| Copyright | 2026 Gökmen Küçük | Hesap bireysel ("GOKMEN KUCUK"). "2026 GSO Studio" da kullanılabilir (telif alanı tüzel kişilik şartı aramaz), karar kullanıcıda |
