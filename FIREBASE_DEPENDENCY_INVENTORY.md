# Firebase Dependency Inventory

Bu dosya mobil uygulamada Firebase bağımlılığının son durumunu çıkarır.

## Durum Özeti

Backend-aware hale gelen ana veri modülleri:

- auth
- users
- categories
- items
- shares
- notifications
- reminders
- storage
- subscriptions

Bu modüller backend auth açıksa API'ye gidiyor, aksi durumda Firebase fallback ile çalışıyor.

## Hâlâ Kabul Edilen Geçiş Bağımlılıkları

Bunlar cutover öncesi kabul edilebilir:

- `lib/core/repositories/auth_repository.dart`
- `lib/core/services/backend_auth_service.dart`
- `lib/main.dart`

Sebep:

- Google / Apple login sonrası geçici olarak Firebase Auth köprü kimlik sağlayıcı olarak kullanılıyor.
- Nihai aşamada bu bağımlılık da sökülecek.

## Bu Turda Kapatılan Son Metadata Bağımlılığı

### Arama geçmişi metadata'sı

- `lib/core/services/preferences_service.dart`
- `lib/screens/search_screen.dart`

Önce:

- arama geçmişi `users/{uid}/metadata/search_history` altında Firestore'a yazılıyordu

Şimdi:

- backend auth açıksa `/api/users/me/search-history` kullanılıyor
- aynı veri local `SharedPreferences` içinde cache ediliyor
- backend kapalıysa yalnızca local cache ile çalışıyor

## Hâlâ Doğrudan Firebase Data Katmanına Bağlı Kalanlar

### 1. Demo veri üretimi

- `lib/core/utils/demo_seeder.dart`

Durum:

- doğrudan Firestore batch yazıyor

Öncelik:

- orta

Öneri:

- eğer demo seed hâlâ kullanılacaksa repository üzerinden yeniden yazılmalı
- kullanılmıyorsa geçiş sonunda kaldırılmalı

### 2. Eski görsel migration yardımcı servisi

- `lib/core/services/image_migration_service.dart`

Durum:

- doğrudan Firestore item kayıtlarını tarıyor ve güncelliyor

Öncelik:

- düşük

Öneri:

- tek seferlik yardımcı araç olarak bırakılabilir
- ya da backend migrator/smoke araçlarına taşınabilir

## Bu Turda Kapatılan Kritik Kalanlardan Biri

- `lib/screens/account_info_screen.dart`

Önce:

- profil fotoğrafı doğrudan Firestore'a yazılıyordu

Şimdi:

- `UserRepository` üzerinden gidiyor
- backend auth açıksa backend'e, sonra local mirror'a yazıyor

## FirebaseAuth Referansları

Aşağıdaki ekranlarda `FirebaseAuth.instance.currentUser` okunuyor:

- `lib/screens/add_content_screen.dart`
- `lib/screens/catalog_screen.dart`
- `lib/screens/edit_content_screen.dart`
- `lib/screens/search_screen.dart`
- `lib/screens/account_info_screen.dart`

Değerlendirme:

- bunların çoğu yalnızca aktif kullanıcı uid'si almak için kullanılıyor
- bu, tam auth cutover yapılana kadar geçici olarak kabul edilebilir

## RevenueCat Bağımlılığı

- `lib/core/services/subscription_service.dart`
- `lib/core/providers/subscription_provider.dart`
- `lib/screens/paywall_screen.dart`

Değerlendirme:

- satın alma işlemi hâlâ cihazdaki RevenueCat SDK ile yapılıyor
- ama premium erişim kararı backend status/verify ile destekleniyor
- bu, mevcut geçiş planıyla uyumlu

## Cutover Öncesi Kalan Gerçek Blokajlar

1. demo seeder'ın Firestore'a direkt yazması
2. image migration helper'ın Firestore'a direkt yazması
3. nihai auth cutover yapılmadığı için Firebase Auth köprüsünün hâlâ açık olması

## Hedef Son Durum

- veri CRUD tamamen backend API
- metadata backend API
- storage backend API
- subscription durumu backend source of truth
- Firebase Auth köprüsü kaldırılmış
- Firestore ve Firebase Storage bağımlılıkları temizlenmiş
