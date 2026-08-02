# SomineWidget — Xcode Kurulum Talimatı (tek seferlik GUI adımı)

Widget'ın tüm kodu hazır (`SomineWidget.swift`, `SomineWidgetBundle.swift`,
`Info.plist` bu klasörde). Flutter tarafı (`home_widget` paketi,
`WidgetDataService`, deep link işleme) tamamlandı. Eksik olan TEK şey:
Xcode projesine Widget Extension **target**'ının eklenmesi. pbxproj'u elle
düzenlemek riskli olduğu için bu adım Xcode GUI ile yapılmalı.

Süre: ~5 dakika.

## 1. Projeyi aç

```
open ios/Runner.xcworkspace
```

(`.xcodeproj` değil, **`.xcworkspace`** — CocoaPods kullanılıyor.)

## 2. Widget Extension target'ı oluştur

1. Xcode menüsü: **File > New > Target...**
2. Şablon listesinden **Widget Extension** seç → Next.
3. Ayarlar:
   - **Product Name:** `SomineWidget` (birebir bu ad — Flutter tarafındaki
     `updateWidget(iOSName: 'SomineWidget')` çağrısı bu ada bağlı)
   - **Team:** Runner ile aynı takım
   - **Bundle Identifier:** otomatik `com.somine.app.SomineWidget` olmalı
   - **Include Live Activity:** KAPALI (işaretleme)
   - **Include Configuration App Intent** (veya "Include Configuration
     Intent"): KAPALI (işaretleme)
   - **Project / Embed in Application:** Runner
4. Finish → çıkan **"Activate 'SomineWidget' scheme?"** sorusuna **Activate**.

## 3. Sihirbazın ürettiği dosyaları bizimkilerle değiştir

Sihirbaz `SomineWidget/` grubunda kendi şablon dosyalarını üretir
(`SomineWidget.swift`, `SomineWidgetBundle.swift`, varsa `Assets.xcassets`).
Bizim hazır dosyalarımız da diskte AYNI klasörde (`ios/SomineWidget/`) durduğu
için iki olasılık var:

**Olasılık A — Xcode aynı klasörü kullandıysa (dosya çakışması sorarsa):**
Sihirbaz dosya yazarken "replace/overwrite" sorarsa **bizim dosyaların
üzerine YAZDIRMA** (Keep/Don't overwrite). Sihirbaz farklı içerik ürettiyse
Finder'da kontrol et: `ios/SomineWidget/SomineWidget.swift` dosyasının başında
`SomineAirColors` enum'u olmalı. Yoksa git ile geri al:
`git checkout -- ios/SomineWidget/SomineWidget.swift ios/SomineWidget/SomineWidgetBundle.swift ios/SomineWidget/Info.plist`

**Olasılık B — Xcode ayrı bir klasör oluşturduysa:**
1. Xcode'daki `SomineWidget` grubunda sihirbazın ürettiği
   `SomineWidget.swift` ve `SomineWidgetBundle.swift` dosyalarını sil
   (**Move to Trash**).
2. Sağ tık `SomineWidget` grubu → **Add Files to "Runner"...** →
   `ios/SomineWidget/SomineWidget.swift` ve
   `ios/SomineWidget/SomineWidgetBundle.swift` seç.
3. Ekleme diyaloğunda **Target Membership: yalnız `SomineWidget`** işaretli
   olsun (Runner işaretli OLMASIN).
4. Sihirbazın ürettiği Info.plist yerine bizimkini kullanmak için: target
   **SomineWidget > Build Settings > Info.plist File** değerini
   `SomineWidget/Info.plist` yap (bizim dosya standart
   `com.apple.widgetkit-extension` NSExtension içeriyor; sihirbazınki de
   genelde aynıdır — bu adım çoğu zaman gereksizdir, fark varsa uygula).

Not: `Assets.xcassets` (sihirbaz ürettiyse) kalabilir, zararı yok.

## 4. App Group ekle

1. Target **SomineWidget** → **Signing & Capabilities** sekmesi.
2. **+ Capability** → **App Groups**.
3. Listeden **`group.com.somine.app`** işaretle (Runner ve share
   extension'da zaten tanımlı olan grup — YENİ grup oluşturma).

## 5. Deployment target uyumu

Target **SomineWidget > General > Minimum Deployments** değerini Runner
target'ınınkiyle AYNI yap (Runner > General'de görünen değer). Widget kodu
iOS 17 öncesini `#available` ile ele alıyor; alt sınır 14.0'ın altına inmesin.

## 6. Doğrulama

Terminalde:

```
cd /Users/gokmenkucuk/Desktop/App/SoMine/somine_app
flutter build ios --no-codesign --debug
```

Build başarılıysa simülatörde/telefonda çalıştır, ana ekrana küçük veya orta
boy **SoMine — Günün Kaydı** widget'ını ekle. Uygulamayı bir kez aç (widget
verisi açılışta yazılır), widget'ta bir kayıt başlığı görünmeli. Widget'a
dokununca uygulama açılıp ilgili kaydın detayı gelmeli.

## Sorun giderme

- **Widget "Bugünlük bir kayıt yok" diyor:** Uygulamayı bir kez açıp kapat
  (veri açılışta ve her yeni kayıtta yazılır). App Group'un widget target'ına
  eklendiğinden emin ol (Adım 4).
- **Tıklama uygulamayı açıyor ama detay gelmiyor:** Runner Info.plist'te
  `somine` URL scheme'i olmalı (bu hazırlıkta eklendi); temiz build al.
- **Pod hatası:** `cd ios && pod install` sonrası tekrar dene.
