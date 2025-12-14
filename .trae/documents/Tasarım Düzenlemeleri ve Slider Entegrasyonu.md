**Tasarım Düzenlemeleri Planı**

Kullanıcı geri bildirimlerine ve görsel referansa dayanarak aşağıdaki değişiklikleri yapacağım:

1.  **Header Info Card ("Son incelediğim kategori"):**
    *   `lib/screens/home_screen.dart` dosyasındaki `HeaderInfoCard` bileşenini güncelleyeceğim.
    *   Başlık: "Son incelediğim kategori" olarak değiştirilecek.
    *   Alt başlık: "Kitaplar" (veya benzeri bir örnek kategori) ve emoji '📚' olarak güncellenecek.

2.  **Inbox Alanının Kaldırılması:**
    *   `lib/screens/home_screen.dart` dosyasından `InboxCard` bileşenini ve ilgili `SliverToBoxAdapter`'ı tamamen kaldıracağım. Kullanıcının "buna ihtiyaç yok" dediği alan burası.

3.  **Kategori Slider (Carousel) Tasarımı:**
    *   Kullanıcının "uçak ikonları" olarak belirttiği ve beğenmediği küçük `ShowcaseSection` alanını değiştireceğim.
    *   Bunun yerine, görseldeki gibi büyük kartlardan oluşan bir **Slider (Carousel)** yapısı kuracağım.
    *   Bunun için `lib/widgets/showcase_carousel.dart` adında yeni bir widget oluşturacağım (mevcut `CategoryCarousel` yapısına benzer ama `ShowcaseItem` kullanan ve daha büyük `LargeShowcaseCard` tasarımını içeren).
    *   `HomeScreen` içerisinde bu yeni slider'ı kullanacağım. Böylece kategoriler büyük, kaydırılabilir kartlar olarak görünecek.

**Dosya Değişiklikleri:**
*   `lib/screens/home_screen.dart`: `InboxCard` kaldırılacak, `HeaderInfoCard` metinleri güncellenecek, `ShowcaseSection` yerine yeni carousel eklenecek.
*   `lib/widgets/showcase_carousel.dart`: Yeni dosya oluşturulacak.
*   `lib/widgets/header_info_card.dart`: Mevcut haliyle kalabilir, sadece çağrıldığı yerdeki parametreler değişecek.

Onayınızla bu düzenlemeleri uygulamaya başlıyorum.