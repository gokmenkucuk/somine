# API Preferences Search History Step 6

Bu adımda arama geçmişi metadata'sı Firestore bağımlılığından çıkarıldı.

## Ne Değişti

- `PreferencesService` artık backend auth açıksa `GET/PUT /api/users/me/search-history` kullanıyor.
- Arama geçmişi yine local `SharedPreferences` içine cache ediliyor.
- `search_screen.dart` değişmeden kaldı; mevcut `get/add/remove/clear` akışı aynı servis imzalarıyla çalışıyor.
- Backend tarafında kullanıcı üzerinde `search_history_json` alanı ve ilgili endpoint'ler eklendi.
- Firebase migrator kullanıcı importunda `users/{uid}/metadata/search_history` belgesini de PostgreSQL'e taşıyor.

## Neden Bu Şekilde

- Ekran davranışını değiştirmeden son anlamlı Firebase metadata yazımını kapatmak gerekiyordu.
- Ayrı tablo yerine kullanıcı üzerinde küçük bir JSON alanı daha düşük riskli ve daha hızlı.
- Mobil tarafı yalnızca servis seviyesinde değiştirerek arama ekranını bozmadan geçiş sürdürüldü.

## Davranış

- backend açıksa:
  - geçmiş API'den okunur
  - değişiklik API'ye yazılır
  - local cache güncellenir
- backend kapalıysa:
  - yalnızca local cache kullanılır

## Sonuç

- Search metadata artık Firestore write/read blokajı değil.
- Mobilde kalan gerçek Firebase data bağımlılıkları demo seeder ve image migration helper ile sınırlı.
