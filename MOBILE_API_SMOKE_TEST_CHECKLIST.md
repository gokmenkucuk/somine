# Mobile API Smoke Test Checklist

Bu checklist backend-aware mobil geçişin cihaz üzerinde doğrulanması içindir.

## Ön Koşullar

- backend ayakta olmalı
- mobil uygulama backend URL ile çalıştırılmalı

Örnek:

```bash
flutter run --dart-define=SOMINE_API_BASE_URL=http://127.0.0.1:5181
```

## 1. Auth

- uygulama açılıyor
- mevcut oturum varsa ana akış bozulmadan açılıyor
- Google login başarılı
- Apple login başarılı
- login sonrası backend session oluşuyor
- uygulamayı kapatıp açınca session yenileniyor
- logout sonrası uygulama temiz çıkış yapıyor

Beklenen:

- kullanıcı giriş yapabiliyor
- login sonrası veri ekranları boş 401/403 hatası vermiyor

## 2. User Profile

- profil ekranı açılıyor
- display name güncellenebiliyor
- username güncellenebiliyor
- profil fotoğrafı seçilebiliyor
- profil fotoğrafı kaldırılabiliyor

Beklenen:

- ekran kapanıp açıldığında yeni profil bilgileri korunuyor

## 3. Categories

- kategori listesi geliyor
- yeni kategori oluşturulabiliyor
- kategori düzenlenebiliyor
- kategori sırası değiştirilebiliyor
- kategori silinebiliyor

Beklenen:

- sıra ve görünüm uygulamayı yeniden açınca korunuyor

## 4. Items

- item listesi geliyor
- yeni link kaydı eklenebiliyor
- yeni not kaydı eklenebiliyor
- item favori yapılabiliyor
- item başka kategoriye taşınabiliyor
- item kategorisiz yapılabiliyor
- item silinince Recently Deleted'a düşüyor
- item restore edilebiliyor
- item permanent delete çalışıyor
- arama sonuçları geliyor
- favorites ekranı doğru doluyor

Beklenen:

- kategori değişimleri ve reorder bozulmuyor
- search geçmişi arama ekranında görünüyor
- geçmişten bir terim silinebiliyor
- tüm geçmiş temizlenebiliyor

Beklenen:

- arama geçmişi uygulamayı kapatıp açınca korunuyor
- backend auth açıksa yeni geçmiş `/api/users/me/search-history` üzerinden geliyor

## 5. Shares

- kullanıcı arama çalışıyor
- koleksiyon paylaşımı oluşturulabiliyor
- incoming share listesi geliyor
- share accept çalışıyor
- share reject çalışıyor
- outgoing share revoke çalışıyor
- shared collection görüntülenebiliyor
- shared collection kopyalanabiliyor

Beklenen:

- kabul/reddet sonrası ilgili listeler anlık ya da kısa polling gecikmesiyle güncelleniyor

## 6. Notifications

- bildirim listesi geliyor
- share request bildirimi görünüyor
- mark as read çalışıyor
- mark all as read çalışıyor
- notification delete çalışıyor

## 7. Reminders

- item için reminder oluşturulabiliyor
- mevcut reminder okunabiliyor
- reminder update çalışıyor
- reminder pasif/aktif yapılabiliyor
- reminder silinebiliyor

Beklenen:

- reminder ekranları eski Firestore akışına düşmeden çalışıyor

## 8. Storage

- uzaktaki görsel URL'si kalıcılaştırılabiliyor
- not içine eklenen görsel yüklenebiliyor
- profil görseli yüklenebiliyor
- silinen görsel backend storage üzerinden kaldırılıyor

Beklenen:

- dönen URL Firebase Storage yerine backend `/storage/...` yolu olabilir, bu normal

## 9. Subscription

- paywall açılıyor
- offerings geliyor
- satın alma akışı başlıyor
- restore purchases çalışıyor
- premium kilitli alanlar satın alma sonrası açılıyor

Beklenen:

- premium kararı sadece local RevenueCat cache değil backend status ile de tutarlı olmalı

## 10. Regression

- onboarding akışı bozulmuyor
- home ekranı açılıyor
- catalog ekranı açılıyor
- search ekranı açılıyor
- profile ekranı açılıyor
- uygulama cold start sonrası crash olmuyor

## Bilinen Kalanlar

- demo seeder hâlâ Firestore batch yazıyor
- image migration helper hâlâ Firestore tarıyor
- Firebase Auth köprüsü hâlâ açık

## Smoke Test Sonrası Karar

Eğer yukarıdaki maddeler geçerse sıradaki iş:

1. kalan Firebase yardımcı servislerini taşımak ya da kaldırmak
2. gerçek cutover checklist hazırlamak
3. Firebase cleanup planını uygulamak
