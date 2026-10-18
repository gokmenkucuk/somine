# Ekran Görüntüsü ve Önizleme Planı

Tarih: 2026-10-18 · Üretim: daha sonra Remotion ile, Yetti'deki yapı örnek alınarak (`~/Desktop/App/yetti/yetti/marketing/video`: StoreShot bileşeni, Plus Jakarta Sans + Inter, PNG çıktı). Şimdi görsel üretilmedi.

## Gerekli boyutlar

| Cihaz sınıfı | Boyut (dikey) | Zorunlu mu | Not |
|---|---|---|---|
| iPhone 6.9" | 1320×2868 (tercih) · 1290×2796 · 1260×2736 | **Evet** (en az 1, en fazla 10) | Yetti'de 1206×2622 de kabul edildi; Remotion'da 1320×2868 üret, gerekirse küçült. Küçük iPhone boyutları buradan otomatik ölçeklenir |
| iPad 13" | 2064×2752 veya 2048×2732 | **Evet, şu anki binary ile** | Runner hedefinde `TARGETED_DEVICE_FAMILY = "1,2"` (iPad destekli). iPad için ayrı ekran görüntüsü zorunlu. **Karar gerekiyor:** ya iPad görselleri üretilecek ya da bir sonraki build'de iPhone-only'e (`1`) geçilecek. İlk yayından önce iPad desteğini kaldırmak serbest; yayından sonra kaldırılamaz |
| App Preview (opsiyonel) | 886×1920 (6.9") | Hayır | 15–30 sn, gerçek ekran kaydı tabanlı olmalı (2.3.4) |

Kurallar: gerçek uygulama ekranları (giriş/splash değil), fiyat yazma, "en iyi/1 numara" gibi doğrulanamaz iddia yok, Instagram/TikTok/YouTube logoları ve marka adı görsellerde yok (PLAN.md notu da bunu söylüyor), demo veride gerçek kişi adı/fotoğrafı yok.

## Görsel yön

- Uygulamanın kendi temaları: 1–4 **Air** (açık, nane #E8F1EF zemin, mevcut marka), 5 **Midnight** (koyu + neon), 6 **Vibe** (koyu + kırmızı ışıltı). Böylece tema çeşitliliği satış argümanı olarak görünür ve Premium temalar dürüstçe "Premium" etiketiyle gösterilir.
- Üst bantta büyük başlık (≤6 kelime), altında tek satır destek cümlesi, altta cihaz çerçevesiz, köşeleri yuvarlatılmış ekran. Yazı tipi: Yetti ile aynı aile (Plus Jakarta Sans başlık, Inter gövde) veya landing'deki Outfit/Poppins; marka tutarlılığı için **landing'deki Outfit** önerilir.
- İlk 3 görsel arama sonuçlarında görünür: hikâyeyi orada bitir (kaydet → düzenle → geri gel).

## Demo veri (her iki dilde ayrı hesap)

Koleksiyonlar: Denemek İstediğim Tarifler / Recipes to Try (8), Gitmek İstediğim Yerler / Places to Visit (6), Dinlemek İstediğim / To Listen (5), İlham / Inspiration (9), Ev / Home (4). Kayıtlar: telifsiz veya kendi çektiğin görsellerle (Unsplash lisansı uygun) tarif, kafe, sahil, mimari, podcast başlıkları. Hatırlatıcı: "Cumartesi 10:00 — Fırında mantı". Kullanıcı adları: `ayse`, `mert` (kurgusal).

## Slot planı

| # | TR başlık | EN başlık | Ekran / durum | Tema |
|---|---|---|---|---|
| 1 | Kaydettiklerin kaybolmasın | Never lose a save again | Akış (masonry), dolu, renkli önizlemeler | Air |
| 2 | Her uygulamadan kaydet | Save from any app | Safari üstünde Paylaş sayfası, somine simgesi vurgulu + yanında ekleme ekranı (koleksiyon seçimi) | Air |
| 3 | Doğru zamanda hatırlatır | Reminded at the right time | Kayıt sonrası başarı sayfası "Yarın / Hafta sonu" + üstte kilit ekranı bildirimi mock'u | Air |
| 4 | Her şey koleksiyonunda | Everything in its collection | Koleksiyonlar ekranı, emoji/ikonlu kartlar | Air |
| 5 | Arkadaşlarınla paylaş | Share collections with friends | Paylaşım sayfası "Kişiyle paylaş / Link ile paylaş" + gelen istek kartı | Midnight |
| 6 | Her gün biri geri gelir | One save comes back daily | Ana ekranda "Günün Kaydı" widget'ı (small + medium) | Air |
| 7 | Gizli Kasa, Face ID ile | Private Vault with Face ID | Kilitli kasa ekranı + Face ID simgesi, "Premium" rozeti | Vibe |
| 8 | Aradığını hemen bul | Find anything in seconds | Arama ekranı, yazım hatalı sorgu ve doğru sonuçlar | Air |

Başlık uzunlukları ≤6 kelime (hepsi 3–5). Görsel 5 ve 7'de "Premium" rozeti şart (3.1.2/2.3 açısından ücretli özelliği ücretsizmiş gibi göstermemek için).

iPad (gerekirse): aynı 1, 2, 4, 6 slotlarının iPad ekranında yeniden yerleşimi; uygulama iPad'de büyütülmüş iPhone düzeniyle çalışıyorsa önce iPad'de gerçek görünüm kontrol edilmeli (kötü görünüyorsa iPhone-only önerisi güçlenir).

## 30 sn App Preview storyboard (opsiyonel, 886×1920)

| Zaman | Görüntü | Üst yazı (TR / EN) |
|---|---|---|
| 0–3 sn | Instagram benzeri jenerik bir akışta parmak "kaydet"e basıyor, sonra ekran görüntüleri yığını (logo yok) | Kaydettin… sonra unuttun. / Saved it… then forgot it. |
| 3–9 | Safari'de tarif → Paylaş → somine → "Denemek İstediğim Tarifler" → kaydedildi | Her yerden kaydet / Save from anywhere |
| 9–14 | Başarı sayfası → "Hafta sonu" hatırlatıcısı | Hatırlatıcıyı kur / Set a reminder |
| 14–18 | Cumartesi 10:00 kilit ekranı bildirimi → dokun → kayıt açılır | Sana geri gelir / It comes back to you |
| 18–23 | Koleksiyonlar arasında kaydırma, arama | Hepsi düzenli / All in order |
| 23–27 | Koleksiyonu arkadaşa gönder, istek kabul edildi | Arkadaşınla paylaş / Share with friends |
| 27–30 | Logo + "somine" + konumlandırma cümlesi | Kaydettiklerin sana geri gelsin / Your saves, back when you need them |

Kurallar: önizleme gerçek uygulama kaydından yapılmalı (simülatör kaydı + Remotion üst yazı kabul), ilk karede poster çerçevesi otomatik seçilir, ses opsiyonel. Yetti tuzağı: `metadata:push` gibi otomasyonlar önizlemeyi silebilir; somine'de EAS yok ama ASC'de elle yönet.
