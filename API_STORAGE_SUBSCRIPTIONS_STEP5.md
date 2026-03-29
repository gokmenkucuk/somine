# API Storage + Subscriptions Step 5

Bu adımda storage ve subscription katmanı backend-aware hale getirildi.

## Storage

Güncellenen dosyalar:

- `lib/core/repositories/storage_repository.dart`
- `lib/core/services/storage_service.dart`

Yeni davranış:

- Backend auth açıksa dosya yüklemeleri `POST /api/storage/upload` ile yapılıyor.
- Backend auth açıksa silme işlemleri `DELETE /api/storage/{fileName}` ile yapılıyor.
- Firebase fallback korunuyor.
- Ekranların kullandığı eski `StorageService` yüzeyi korunarak arkada API desteği eklendi.

Etkilenen akışlar:

- capture ekranındaki uzak görsel kalıcılaştırma
- add content ekranındaki görsel yükleme
- not görseli yükleme
- profil görseli yükleme için altyapı

## Subscriptions

Güncellenen dosyalar:

- `lib/core/services/subscription_service.dart`
- `lib/core/providers/subscription_provider.dart`
- `lib/core/repositories/auth_repository.dart`

Yeni davranış:

- RevenueCat ürün listeleme ve satın alma cihazda kalıyor.
- Premium durumu backend auth açıksa `api/subscriptions/status` ve `api/subscriptions/verify` üzerinden backend tarafından belirleniyor.
- Login sonrası RevenueCat kullanıcı eşlemesi `setUserId` ile senkronize ediliyor.
- Logout sırasında RevenueCat oturumu da temizleniyor.

## Doğrulama

- `flutter analyze --no-pub lib/core/repositories/storage_repository.dart lib/core/services/storage_service.dart lib/core/services/subscription_service.dart lib/core/providers/subscription_provider.dart lib/core/repositories/auth_repository.dart lib/core/providers/storage_providers.dart`

Sonuç:

- ilgili dosyalar analyze temiz

## Not

Subscription tarafında satın alma işlemi halen istemci üzerinden RevenueCat SDK ile gerçekleşiyor. Bu bilinçli; bu adımda değişen kısım ürün erişim kararının backend source of truth haline gelmesi.

## Sonraki Adım

Bir sonraki mantıklı iş:

- gerçek cihaz / TestFlight smoke testi
- Firebase bağımlılığı kalan servislerin ve ekranların envanteri
- cutover checklist
