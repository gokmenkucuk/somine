## Kapsam ve Hedef

* Sadece katalog bölümünde YouTube/Instagram içeriklerinin gösterildiği kart/alanlardaki kenarlıkların (border) kalınlığını incelt.

* Renk ve stil (solid/dashed) korunur; sadece kalınlık azaltılır (≈ 1.0px).

* Layout ve responsive davranış korunur; gerekli ise padding/margin küçük düzenlemeleri yapılır.

* Placeholder’lar (ör. `${key_name}`) aynen korunur.

## Mevcut Yapı Analizi (Flutter)

* Projede CSS/Tailwind yok; sınırlar Flutter `BoxDecoration` ve `Border` ile tanımlı.

* İlgili dosyalar ve kenarlık kullanımları:

  * `lib/screens/home_screen.dart:304-305` → Vitrin/katalog kutularında seçili durumda `Border.all(color: DesignTokens.primary, width: 3)`.

  * `lib/widgets/item_card.dart:21-31` → Kart dekorasyonu (gölge/köşe yarıçapı); explicit border yok, YouTube/Instagram kaynak rozeti var (`100-113`).

  * `lib/core/design/design_tokens.dart:24` → Global border rengi: `DesignTokens.border`.

  * `lib/screens/item_detail_screen.dart:190-194` → Detay sayfası not/ayırıcı kutusunda `Border.all(color: DesignTokens.border)`.

  * `lib/screens/capture_screen.dart:346-349` → Kategori çiplerinde `Border.all(...)` (katalog filtreleriyle ilişkili olabilir).

## Uygulama Stratejisi

1. Katalog listesinde YouTube/Instagram öğelerini tespit:

   * Kaynak ikon/rozet kontrolü (`lib/widgets/item_card.dart:100-113`).
2. Seçili durumdaki katalog kutusu kenarlığını incelt:

   * `lib/screens/home_screen.dart:304-305` içindeki `Border.all(..., width: 3)` → YouTube/Instagram öğeleri için `width: 1.0`.

   * Diğer kaynaklar için mevcut davranışı koru.
3. Kart/medya konteyneri kenarlığı:

   * `item_card.dart` içinde explicit border yok; yeni border ekleme yerine mevcut kenarlıkları inceltme kapsamı uygulanır.

   * Eğer medya alanında koşullu border kullanımı varsa (okuma sırasında bir alt konteynerde), YouTube/Instagram için `width: 1.0` yap, renk `DesignTokens.border`.
4. Detay ekranı (`item_detail_screen.dart`):

   * Eğer YouTube/Instagram öğesi detayında border kullanılıyorsa, kalınlığı `1.0` yap. Diğer öğeleri etkileme.
5. Filtre çipleri (`capture_screen.dart`):

   * Katalog sosyal içeriklerle direkt görsel alan ilişkisi yoksa dokunma; sadece sosyal içerik alanlarına odaklan.
6. Renk/stil korunumu:

   * Renk: `DesignTokens.border` veya mevcut `DesignTokens.primary` kullanımına sadık kal.

   * Stil: Flutter default solid; stil değiştirme yok.

## Tasarım Bütünlüğü

* Kenarlık incelmesi sonrası görsel yoğunluk azalacağı için `padding` değerleri gözle kontrol edilir; gerekirse +1–2 px artış yapılır.

* Kart grid/spacing korunur; hiçbir hizalama veya hiyerarşi bozulmaz.

* Responsive: Farklı ekran boyutlarında (telefon/tablet) kart yoğunluğu ve grid stabil kalır.

## Test ve Doğrulama

* Katalog ekranında YouTube ve Instagram içerik kartları manuel gözle kontrol edilir.

* Seçili durumlarda kenarlık kalınlığı `1.0` olduğunun doğrulanması.

* Renk kontrastı: `DesignTokens.border` arka plan ile yeterli kontrastta.

* Etkileşim: seçme/odak/long-press gibi durumlarda görsel geribildirimler çalışıyor.

## Versiyonlama ve Akış

1. Önce her şeyi lokalde yeni bir branch’e commit et: `feature/thin-borders-catalog-social`.
2. Değişiklikleri küçük adımlarla uygula ve her mantıksal güncellemeyi ayrı commit ile kaydet.
3. Son durumda katalog sosyal içerik alanlarının sınırları inceltilmiş, diğer alanlar korunmuş olacak.

## Teslimat

* Değişen dosyalar ve satır referanslarıyla birlikte kısa değişiklik özeti.

* İsteğe bağlı ekran görüntüleri ile öncesi/sonrası karşılaştırması.

