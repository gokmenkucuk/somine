# API Auth Migration Step 1

Bu adımda mobil uygulama tamamen backend'e taşınmadı.

Ama auth geçişinin omurgası kuruldu:

- Firebase login akışı korunuyor
- login sonrası backend token exchange yapılabiliyor
- access/refresh token yerelde saklanıyor
- uygulama açıldığında Firebase user varsa backend session yenilenebiliyor
- sign out sırasında backend logout denemesi yapılıyor

## Bu adımda ne değişti

Yeni dosyalar:

- `lib/core/config/api_config.dart`
- `lib/core/models/backend_auth_session.dart`
- `lib/core/services/backend_auth_service.dart`

Güncellenen ana dosyalar:

- `lib/core/repositories/auth_repository.dart`
- `lib/core/providers/auth_providers.dart`

## Çalışma mantığı

1. Kullanıcı Google veya Apple ile Firebase'e login olur.
2. Firebase user oluşunca `getIdToken()` ile Firebase ID token alınır.
3. Bu token backend'e gönderilir:
   - `POST /api/auth/google`
   - `POST /api/auth/apple`
4. Backend access token + refresh token döner.
5. Mobil taraf bu session'ı yerelde saklar.
6. Session expire olmaya yaklaşınca refresh denenir.
7. Refresh başarısızsa Firebase token ile yeniden exchange yapılır.

## Neden bu yaklaşım seçildi

Uygulamanın mevcut UI ve onboarding akışı tamamen Firebase user stream'ine bağlı.

Bu yüzden ilk adımda:

- `AuthWrapper`
- `LoginScreen`
- onboarding yönlendirmesi

kırılmadan bırakıldı.

Yani bu branch'te auth geçişi "yan yana çalışma" modeliyle başladı.

## Konfigürasyon

Backend auth varsayılan olarak yalnızca `SOMINE_API_BASE_URL` tanımlıysa aktif olur.

Örnek:

```bash
flutter run --dart-define=SOMINE_API_BASE_URL=http://127.0.0.1:5181
```

Not:

- iOS simulator için `127.0.0.1` uygundur
- Android emulator için ileride `10.0.2.2` gerekebilir
- gerçek cihaz/TestFlight için uzak API URL'i verilmelidir

## Bu adımın sınırları

- Veri repository'leri hala Firestore kullanıyor
- token storage şu an `SharedPreferences` üzerinde
- client proof header üretimi henüz mobilde eklenmedi
- backend user id henüz veri repository'lerinde kullanılmıyor

## Sonraki adım

En mantıklı ikinci adım:

1. backend token storage'ı güvenli depoya taşımak
2. auth bootstrap durumunu UI'da görünür hale getirmek
3. ardından `users/categories/items` repository'lerini HTTP katmanına geçirmek
