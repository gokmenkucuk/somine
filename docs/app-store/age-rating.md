# Yaş Derecelendirmesi Anketi

Tarih: 2026-10-18 · ASC'ye **girilmedi** (bkz. README). ASC → App Information → Age Ratings → Edit. Apple'ın 2025'te güncellenen anketi (4+, 9+, 13+, 16+, 18+) esas alındı.

## Cevaplar

### İçerik (hepsi "None")
| Soru | Cevap | Gerekçe |
|---|---|---|
| Cartoon or Fantasy Violence | None | Uygulama içeriği yok; kullanıcının kendi kayıtları |
| Realistic Violence | None | |
| Prolonged Graphic or Sadistic Realistic Violence | None | |
| Profanity or Crude Humor | None | |
| Mature or Suggestive Themes | None | |
| Horror/Fear Themes | None | |
| Medical or Treatment Information | None | |
| Alcohol, Tobacco, or Drug Use or References | None | |
| Sexual Content or Nudity | None | |
| Graphic Sexual Content and Nudity | None | |
| Simulated Gambling | None | |
| Contests | None | |
| Guns or Other Weapons | None | |

### Yetenekler / özellikler
| Soru | Cevap | Gerekçe (kod) |
|---|---|---|
| **Unrestricted Web Access** | **No** | Kaydedilen linkler uygulama içinde değil **harici olarak** (Safari veya kaynak uygulama) açılıyor: `LaunchMode.externalApplication` 5 çağrı yeri. Uygulama içi tarayıcı (`LaunchMode.inAppBrowserView`, `mobile/lib/core/utils/open_in_app_link.dart`) yalnız kendi gizlilik/şartlar/destek sayfalarımız için. `webview_flutter` yok. YouTube oynatıcı yalnız kaydedilen videoyu gömülü oynatıyor (gezinme yok) |
| **User-Generated Content** | **Yes** | Kullanıcılar koleksiyonlarını birbirine gönderebiliyor ve herkese açık link oluşturabiliyor. Karşılıkları: bildir (4 sebep), engelle, kitaplıktan kaldır, isteği reddet ve engelle, Engellenenler ekranı, 24 saat içinde inceleme taahhüdü (`share_moderation_sheets.dart`, `blocked_users_screen.dart`, `ContentReport`) |
| Messaging and Chat | No | Kullanıcılar arası mesajlaşma yok; yalnız koleksiyon paylaşım isteği |
| Advertising | No | Reklam SDK'sı yok |
| Age Assurance / Parental Controls | No | |
| Loot boxes / paid random items | No | |
| Health or wellness topics | No | |

### Diğer
| Soru | Cevap |
|---|---|
| Made for Kids | No |
| Age Rating Override | Yok (hesaplanan değer kullanılsın) |

## Beklenen sonuç

İçerik sorularının tamamı "None" ve web erişimi "No" olduğu için beklenen genel derecelendirme **4+**. "User-Generated Content: Yes" bazı bölgelerde (ör. Brezilya, Avustralya, Kore'nin kendi sistemleri) farklı bir eşleme üretebilir; ASC kaydettikten sonra her bölge için sonucu gösterir, onu kontrol et.

**Alternatif değerlendirme (kullanıcı kararı):** Herkese açık link ve paylaşılan koleksiyonlarda üçüncü kişilerin linkleri görülebildiği için muhafazakâr bir yaklaşım derecelendirmeyi 13+'ya override etmek olabilir. Önerim **4+ bırakmak**: içerik kullanıcının kendi seçtiği arkadaşlarından, istek kabul edilmeden görünmüyor ve engelleme/şikâyet var. Gizlilik politikası "13 yaş altından bilerek veri toplamaz" diyor; bu App Store derecelendirmesiyle çelişmez ama ileride Kids kategorisine girilmemeli.
