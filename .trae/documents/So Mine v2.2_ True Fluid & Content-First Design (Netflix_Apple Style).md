Kullanıcı şikayetlerini ve "Netflix/Apple Photos" stili modern arayüzleri analiz ettim. Mevcut kodda uyguladığım tasarımın hala fazla "kutu gibi" ve statik kaldığını, Apple Photos'un akışkan (fluid) yapısını ve Netflix'in yatay sonsuzluk hissini tam yansıtmadığını anladım.

### **Tespit Edilen Eksikler ve Yeni Plan**

1.  **Vitrin (Showcase) Alanı Çok Statik:**
    *   *Sorun:* Şu anki kartlar birbirinden çok ayrık ve "buton" gibi duruyor.
    *   *Çözüm (Apple Photos Stili):* Kartları ekranın solundan başlatalım (kenar boşluğu olmadan), daha büyük ve "Carousel" mantığında yapalım. Kullanıcı kaydırdıkça bir sonraki kartın ucu görünmeli (peek effect).
    *   *Görsel:* Sadece gradient değil, "Canlı, Büyük İkon/Görsel" odaklı, üstünde minimal metin olan dev kartlar.

2.  **Swimlane (Yatay Şeritler) "Kutu" Gibi Duruyor:**
    *   *Sorun:* Başlık ve liste çok ayrık, kartlar küçük.
    *   *Çözüm (Netflix Stili):*
        *   Başlıkları ("Tatil Planlarım") daha büyük ve kalın (`Outfit Bold 22px`) yapıp, sol kenara yaslayalım.
        *   Kartları büyütelim (Genişlik: 160px -> 200px+).
        *   Kart köşelerini daha yuvarlak (Radius 20px) yapıp, gölgeleri kaldıralım (flat ama derinlikli görsel).
        *   Görseli karta tamamen yayalım (Full bleed image), metni görselin üzerine (gradient overlay ile) veya hemen altına çok minimal şekilde koyalım.

3.  **Genel Atmosfer (Airy & Premium):**
    *   Arka planı tamamen beyaz veya çok çok açık gri (`#FAFAFA`) yapıp, *tüm* kutu gölgelerini ve sınır çizgilerini kaldıralım.
    *   İçerik ön planda olmalı, çerçeveler değil.

### **Uygulama Adımları (Revize)**

1.  **`ShowcaseSection` Revizyonu:**
    *   `PageView` kullanarak tam ekran genişliğinde kaydırılabilir, büyük "Hero" kartlar yapacağım.
    *   Kart yüksekliğini artır (220px+).

2.  **`ContentSwimlane` Revizyonu:**
    *   Kart tasarımını değiştir: Görsel odaklı, metin görselin içinde (Netflix poster mantığı) veya hemen altında.
    *   Başlık boyutunu büyüt ve hiyerarşiyi güçlendir.

3.  **Home Screen Düzeni:**
    *   Paddingleri azaltıp içeriği kenarlara daha çok yaklaştırarak "Infinity Scroll" hissi vereceğim.
    *   Header'ı daha minimal hale getireceğim.

Bu planla, "kutu kutu" görünümden kurtulup, Apple Photos'un iOS 18'deki "tek parça akış" hissine ve Netflix'in "içerik odaklı" yapısına geçeceğiz.

Onaylarsan hemen kodlamaya başlıyorum.