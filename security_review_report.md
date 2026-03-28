# SoMine Guvenlik Inceleme Raporu

Tarih: 2026-03-16
Kapsam: Flutter istemcisi, Android/iOS proje dosyalari, yerel repo icerigi
Yontem: Statik kod incelemesi ve repository taramasi

## 1. Yonetici Ozeti

Bu inceleme uc ana basliga odaklandi:

- repoda sert kodlanmis key ve hassas veri aramasi
- mobil istemcide tersine muhendislik yuzeyi
- istemci tarafli guvenlik zafiyetleri ve veri koruma modeli

Ozet sonuc:

- Repoda private key, service account JSON, keystore, `.env` veya benzeri yuksek etkili bir gizli bilgi bulunmadi.
- Kod icerisinde Firebase istemci ayarlari ve RevenueCat public SDK key'leri gibi istemci tarafinda bulunmasi beklenen degerler yer aliyor.
- En buyuk pratik risk, bu key'lerin gorunur olmasi degil; Vault ve Premium gibi hassas davranislarin istemci tarafina guvenmesi.
- Android release sertlestirmesi zayif. Release build su anda debug signing config ile ayarli ve repoda obfuscation/minification akisina rastlanmadi.
- Firestore ve Storage security rules repo icinde bulunmadigi icin sunucu tarafi yetkilendirme dogrulanamadi. En buyuk belirsizlik bu alanda.

## 2. Inceleme Kapsami

Incelenen alanlar:

- `lib/`
- `android/`
- `ios/`
- `macos/`
- `web/`
- kok seviye config ve manifest dosyalari

Yapilan kontroller:

- hardcoded key ve credential taramasi
- Firebase, Google Sign-In ve RevenueCat konfigrasyonu incelemesi
- release build ve tersine muhendislik yuzeyi incelemesi
- Vault ve Premium ozellik kapilarinin incelenmesi
- loglama ve istemci veri akisi incelemesi

## 3. Bulgular

### Bulgu 1: Vault veri katmaninda degil, UI katmaninda korunuyor

Seviye: Yuksek

Aciklama:

Vault icerikleri biyometrik dogrulama uygulanmadan once istemciye cekiliyor. Uygulama daha sonra bu icerikleri UI tarafinda gizliyor veya gosteriyor. Bu nedenle modifiye edilmis istemci, runtime instrumentation veya hook tabanli bir mudahale ile Vault icerikleri biyometrik dogrulama olmadan okunabilir.

Kanit:

- Filtresiz katalog item stream'i: `lib/core/providers/firestore_providers.dart:106`
- Repository kullanicinin tum item'larini stream ediyor: `lib/core/repositories/item_repository.dart:334`
- Arama ekrani tum item'lari once bellege aliyor, sonra Vault filtresi uyguluyor: `lib/screens/search_screen.dart:133`
- Katalog ekrani Vault icerigini render/filter asamasinda gizliyor: `lib/screens/catalog_screen.dart:317`

Etkisi:

- Vault mevcut haliyle guclu veri korumasi olarak kabul edilmemeli.
- Tersine muhendislik yapilmis veya manipule edilmis build'ler korumali icerige erisebilir.
- Biyometrik dogrulama su an gercek bir gizlilik siniri degil, goruntuleme kapisi gorevi goruyor.

Oneri:

- Vault kontrolunu sadece UI katmaninda degil, veri katmaninda uygulayin.
- Vault verisi icin ayri ve korumali bir sorgu akisina gecin.
- Guclu gizlilik gerekiyorsa Vault icerigini istemci tarafinda sifreleyin ve anahtar erisimini secure storage + biometric gate ile koruyun.
- Vault unlock olmadan hassas verinin prefetch edilmesini engelleyin.

### Bulgu 2: Android release build debug signing config kullaniyor

Seviye: Yuksek

Aciklama:

Android `release` build type su anda debug signing config ile ayarlanmis durumda.

Kanit:

- `android/app/build.gradle.kts:33`

Etkisi:

- Release dagitiminin butunlugune operasyonel olarak zarar verir.
- Uretim build'lerine olan guveni dusurur.
- Repackage edilmis veya sahte build uretilmesini kolaylastirir.

Oneri:

- Debug signing yerine ayrica tanimlanmis bir release signing config kullanin.
- Signing bilgilerini repo disinda tutun.
- CI/CD release artefact'larini debug build'lerden ayri dogrulayin.

### Bulgu 3: Tersine muhendislik direnci zayif

Seviye: Orta

Aciklama:

Repoda release obfuscation/minification akisi gorunmuyor. `--obfuscate` / `--split-debug-info` kullanan bir build akisi bulunmadi. Android release tarafinda da ilave sertlestirme izi yok.

Kanit:

- Android release blogu yalnizca debug signing ayarli: `android/app/build.gradle.kts:33`
- Repo taramasinda release build script'i veya dokumante edilmis obfuscation akisi gorunmuyor

Etkisi:

- Dart kodu ve uygulama davranisi build cikarildiktan sonra daha kolay analiz edilir.
- Istemci tarafli entitlement ve Vault mantigi daha kolay manipule edilir.

Oneri:

- Flutter release obfuscation ve split debug info kullanin.
- Sertlestirilmis build'i varsayilan hale getiren build script'i veya dokumantasyon ekleyin.
- Uygun alanlarda Android R8/proguard sertlestirmesi dusunun.

### Bulgu 4: Premium enforcement istemci tarafinda ve bypass edilebilir

Seviye: Orta

Aciklama:

Premium erisim kontrolleri UI/provider katmaninda yapiliyor. Koleksiyon limiti ve premium ikon erisimi gibi kisitlar istemci state'i ve lokal kontrol akislariyla korunuyor.

Kanit:

- Provider tabanli premium kontroller: `lib/core/providers/subscription_provider.dart:118`
- Koleksiyon limiti UI akisinda kontrol ediliyor: `lib/screens/catalog_screen.dart:2858`
- Premium ikon erisimi istemci ekran mantiginda kontrol ediliyor: `lib/screens/icon_picker_screen.dart:38`

Etkisi:

- Modifiye veya instrument edilmis istemci premium kisitlarini atlatabilir.
- Is modeli acisindan kritik premium ozellikler icin mevcut model tek basina yeterli degil.

Oneri:

- Kritik entitlement kontrolunu sunucu tarafinda dogrulanan duruma tasiyin.
- Premium'a bagli veri ve aksiyonlar varsa bunlari backend tarafinda da enforce edin.
- Istemci kontrollerini guvenlik siniri degil, UX yardimi olarak gorun.

### Bulgu 5: Production log seviyesi gereksiz derecede ayrintili

Seviye: Orta

Aciklama:

Uygulama kullanici URL'lerini, metadata degerlerini ve abonelik akislarina ait debug bilgisini logluyor. RevenueCat acikca debug log seviyesinde baslatiliyor.

Kanit:

- URL ve metadata loglari: `lib/screens/add_content_screen.dart:506`
- RevenueCat debug log seviyesi: `lib/core/services/subscription_service.dart:37`

Etkisi:

- Hassas veya ozel kullanici hareketleri cihaz loglarina dusabilir.
- Debug ciktilari, troubleshooting veya ortak cihaz kullanimlarinda gereksiz bilgi sizintisi yaratir.

Oneri:

- Production build'lerde log seviyesini azaltin.
- Ayrintili loglari debug-only flag arkasina alin.
- Kullanici icerigini production loglarindan cikarin.

## 4. Hardcoded Key Incelemesi

### Repoda bulunanlar

Kaynak kontrolde bulunan degerler:

- Firebase istemci konfigrasyonu:
  - `lib/firebase_options.dart:63`
  - `ios/Runner/GoogleService-Info.plist:5`
- Google iOS OAuth client ID:
  - `lib/core/repositories/auth_repository.dart:24`
- RevenueCat public SDK key'leri:
  - `lib/core/services/subscription_service.dart:13`

### Siniflandirma

Bunlar backend secret degil, istemci tarafinda yer almasi beklenen public konfigurasyon degerleri gibi gorunuyor:

- Firebase mobile API key
- Google OAuth client ID
- RevenueCat public SDK key

Onemli not:

Bu degerlerin ilgili platformlarda dogru sekilde kisitlanmis olmasi gerekir. Ancak bir mobil uygulamanin bu degerlerin gizli kalacagina guvenmesi dogru degildir.

### Bulunmayanlar

Incelemede su tip kritik gizli bilgiler bulunmadi:

- private key
- service account credentials
- keystore
- `.env` secret
- private material iceren PEM/P12 dosyalari
- hardcoded backend admin token

## 5. En Buyuk Belirsizlik

Firestore ve Storage kurallari repo icinde bulunmadi.

Bu onemli cunku istemci dogrudan su koleksiyonlarla konusuyor:

- `users`
- `items`
- `categories`
- `collection_shares`
- `notifications`

Bu kurallar gorulmeden su konular dogrulanamaz:

- kullanicilarin yalnizca kendi dokumanlarina erisip erisemediği
- Vault verisinin sunucu tarafinda gercekten korunup korunmadigi
- notification/share dokumanlarinin uygunsuz bicimde listelenip degistirilebilip degistirilemedigi
- storage path'lerinin kullanici bazinda dogru izole edilip edilmedigi

Sonuc:

Bir sonraki en kritik guvenlik adimi Firebase security rules incelemesidir.

## 6. Risk Ozeti

### Yuksek Risk

- Vault yalnizca UI katmaninda korunuyor, veri katmaninda korunmuyor
- Android release build debug signing config kullaniyor

### Orta Risk

- Tersine muhendislik direnci zayif
- Premium kontroller istemci tarafinda ve bypass edilebilir
- Production log seviyesi fazla ayrintili

### Dusuk / Bilgilendirme

- Kod icinde public istemci key'leri var, ancak repoda yuksek etkili bir backend secret bulunmadi

## 7. Onerilen Sonraki Adimlar

Oncelik 1:

- Firestore rules'i inceleyin ve sikilastirin
- Storage rules'i inceleyin ve sikilastirin
- Vault modelini, unlock olmadan veri cekilmeyecek sekilde yeniden tasarlayin

Oncelik 2:

- Android release signing yapisini duzeltin
- Release obfuscation/hardening adimlarini ekleyin
- Production loglarini azaltin

Oncelik 3:

- Kritik premium kontrolleri backend veya server-verified entitlement modeline tasiyin
- Guvenli mobil release prosedurunu dokumante edin

## 8. Genel Degerlendirme

Repo, su an itibariyla acik bir private backend secret sizintisi gostermiyor. Ana risk mimari seviyede: hassas davranislar istemciye emanet edilmis durumda. Pratikte bu, Vault ve Premium gibi ozellikler icin gercek bir tersine muhendislik ve bypass yuzeyi olusturuyor. Bir sonraki odak noktasi sadece key taramasi degil; Firebase kurallarinin gozden gecirilmesi ve istemci sertlestirmesinin uygulanmasi olmali.
