Aşağıdaki plan `task1.md` içeriğini birebir uygular, mevcut kodla uyumlu geçişi de garanti eder.

## 1) Design Tokens: SoMineTokens’a Geçiş
- `lib/core/design/design_tokens.dart` dosyasını tamamen `SoMineTokens` ile değiştir.
- İçerik: task1’de verilen renkler, gradientler, shadow setleri, radius, spacing, aspect ratios, durations, typography sizes.
- Mevcut kodda `DesignTokens` kullanımları var. Derlemenin kırılmaması için iki opsiyon:
  - Opsiyon A (tam geçiş): Tüm dosyalardaki `DesignTokens` referanslarını `SoMineTokens` ile değiştir (Home, Login, RootShell, Splash, Showcase, Swimlane, vb.).
  - Opsiyon B (adaptör): Geçici olarak `design_tokens.dart` içinde `class DesignTokens` adında bir adapter ekleyip `SoMineTokens` alanlarına delege et, sonra kademeli refaktör.
- Tercih: Opsiyon A (tek turda tam geçiş) — task1’in “tamamen sil ve değiştir” talebine daha sadık.

## 2) App Theme: Poppins Teması
- `lib/core/design/app_theme.dart` dosyasını tamamen task1’deki Poppins temasıyla değiştir.
- `ThemeData` içerisinde `SoMineTokens` referansları kullanılır; `textTheme` Poppins olacak.
- Mevcut widget’larda doğrudan `GoogleFonts.outfit` kullanan yerleri azaltıp `Theme.of(context).textTheme` stillerine yasla (başlıklar, label vs.).
- `AppBar`, `Card`, `InputDecoration`, `ElevatedButton`, `BottomNavigationBar`, `Divider` temaları task1’deki gibi set edilir.

## 3) SoftCard Bileşeni (Yeni)
- `lib/widgets/soft_card.dart` yeni dosyasını oluştur.
- `SoftCard` ve `GradientSoftCard` komponentlerini task1’deki API ile ekle.
- Vitrin/Showcase ve bilgi kutuları gibi alanlarda bu bileşeni kullanmaya başlayacağız (bir sonraki adımlar).

## 4) ItemCard (Platform-Aware)
- `lib/widgets/item_card.dart` dosyasını task1’deki sürümle tamamen değiştir.
- `getAspectRatioForPlatform` ve `getPlatformIcon` ile Pinterest/Instagram/YouTube gibi kaynaklara göre görsel oranlarını ayarla.
- Görsel yükleme/placeholder/loading davranışı task1’deki gibi uygulanır.

## 5) Kod Tabanı Uyumlandırma
- `SoMineTokens`’a geçiş sonrası:
  - `HomeHeader`, `ShowcaseSection`, `ContentSwimlane`, `RootShell`, `LoginScreen`, `SplashScreen` dahil tüm dosyalarda `DesignTokens` → `SoMineTokens` refaktörü.
  - `Outfit` doğrudan kullanımları mümkün olduğunca `textTheme` ile değiştirilir; Poppins teması üzerinden stil verilir.
- `Showcase` ve bölüm kartlarında `SoftCard` (ve gerekirse `GradientSoftCard`) kullanımıyla referanstaki beyaz kart stilini netleştir.

## 6) Doğrulama ve Test
- iOS Simülatörde derleme ve çalıştırma.
- Kart aspect ratio’ları: Pinterest (3:4), Instagram (1:1), YouTube (16:9) örnek veriyle doğrula.
- Temada Poppins ve renk/doku tutarlılığını kontrol et.
- Splash: Logo geçişinden etkilenmez; yalnızca tema arka planıyle tutarlılık kontrolü.

## 7) Teslim
- Tüm değişiklikleri tek commit dizisi olarak hazırlayıp (kullanıcı isterse) commit edilmeye hazır hale getir.

Onayladığında bu adımları uygulayıp yeniden çalıştırarak görsel ve davranışsal doğrulamayı gerçekleştireceğim.