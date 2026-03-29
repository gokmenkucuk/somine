# API Users Migration Step 2

Bu adımda `users` modülü tamamen sökülmedi, ama backend destekli hibrit modele geçirildi.

## Bu adımda ne değişti

- `UserRepository` artık backend auth aktifse `users/me` endpoint'ini kullanabiliyor
- kullanıcı okuma akışı backend + Firestore birleşik hale geldi
- kullanıcı adı müsaitlik kontrolü backend arama endpoint'i ile çalışabiliyor
- kullanıcı adı güncellemesi backend `PUT /api/users/me` üzerinden yapılabiliyor
- görünen ad güncellemesi backend `PUT /api/users/me` üzerinden yapılabiliyor
- `AccountInfoScreen` kullanıcı verisini repository üzerinden okumaya başladı

## Hibrit davranış

Backend açıkken:

- `email`
- `displayName`
- `username`
- `photoUrl`

önce backend'den alınır.

Ama şu alanlar halen Firestore'dan korunur:

- `photoBase64`
- bazı yerel onboarding/uyumluluk alanları

Bu sayede `UserAvatar` gibi mevcut ekranlar bozulmadan çalışır.

## Neden tamamen backend'e geçmedik

Çünkü profil fotoğrafı akışında halen Firestore `photoBase64` kullanılıyor ve backend `users/me` cevabı bunu henüz dönmüyor.

Yani bu adım bilinçli olarak:

- API-first
- Firestore-compatible

tasarlandı.

## Kalan user işleri

Tam `users` geçişi için sonraki iş:

1. backend `users/me` cevabına `photoBase64` eklemek veya fotoğrafı storage tabanlı tamamen yeni modele geçirmek
2. `AccountInfoScreen` içindeki doğrudan Firestore fotoğraf akışını repository/service katmanına taşımak
3. `AuthWrapper` ve `LoginScreen` içindeki onboarding kararını Firestore yerine backend user profilinden vermek
