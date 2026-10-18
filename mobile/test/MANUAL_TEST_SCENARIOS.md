# SoMine App - Manuel Test Senaryoları

Bu doküman, uygulamanın ağ dayanıklılığı, hata yönetimi ve kullanıcı deneyimi için kritik senaryoları içerir.

---

## 1. Offline Save / Delete Senaryosu

### Hazırlık
- Uygulamayı açın
- İnternet bağlantısını kapatın (WiFi + Cellular)

### Adımlar
1. **Kayıt Testi:**
   - İçerik ekleme ekranını açın
   - Bir link yapıştırın veya manuel giriş yapın
   - Koleksiyon seçin
   - "Koleksiyona Ekle" butonuna tıklayın
   - **Beklenen:** 10-15 saniye içinde timeout hatası gösterilmeli: "Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin."
   - **Beklenen:** İçerik kaydedilmemeli olmalı

2. **Silme Testi:**
   - İnternet kapalıyken var olan bir içeriği çöp kutusuna sürükleyin
   - **Beklenen:** Hata mesajı gösterilmeli
   - **Beklenen:** İçerik listeden kaldırılmamalı olmalı

3. **Retry Testi:**
   - İnterneti açın
   - "Tekrar Dene" butonuna tıklayın
   - **Beklenen:** İşlem başarıyla tamamlanmalı

---

## 2. Timeout Senaryosu

### Hazırlık
- Charles Proxy veya benzeri araç ile API çağrılarını 60 saniye geciktirin
- Veya sunucu yanıt vermeyecek şekilde yapılandırın

### Adımlar
1. İçerik ekleme işlemi başlatın
2. **Beklenen:** 15 saniye içinde timeout hatası gösterilmeli
3. Hata mesajında teknik detaylar (URL, body) GÖRÜNMEMELİ
4. Kullanıcı dostu Türkçe mesaj gösterilmeli

---

## 3. Double-Tap Stres Testi

### Hazırlık
- İnternet bağlantısı normal

### Adımlar
1. "Koleksiyona Ekle" butonuna hızlıca 3-5 kez tıklayın
2. **Beklenen:** Sadece 1 kayıt işlemi başlatılmalı
3. **Beklenen:** Duplicate içerik oluşmamalı
4. FAB butonu, silme butonu ve form submit için aynı testi tekrarlayın

---

## 4. Delete + Undo Akışı

### Hazırlık
- İnternet bağlantısı normal
- En az 3 içeriği olan bir kullanıcı hesabı

### Adımlar

#### 4.1 Single Delete
1. Bir içeriği çöp kutusuna sürükleyin
2. **Beklenen:** "Silindi" bildirimi silme işleminden SONRA gösterilmeli
3. "Geri Al" butonuna tıklayın
4. **Beklenen:** İçerik restore edilmeli (kopya oluşturulmamalı)
5. İçerik ID'si aynı olmalı

#### 4.2 Batch Delete
1. 3 içeriği seçin (seçim modu)
2. Çöp kutusuna sürükleyin
3. **Beklenen:** "3 içerik silindi" mesajı gösterilmeli
4. **Beklenen:** Tüm 3 içerik listeden kaldırılmalı
5. "Geri Al" butonuna tıklayın
6. **Beklenen:** Tüm 3 içerik restore edilmeli

#### 4.3 Delete with Network Down
1. İnterneti kapatın
2. Bir içeriği silmeyi deneyin
3. **Beklenen:** Hata mesajı gösterilmeli
4. **Beklenen:** İçerik listeden KALDIRILMAMALI (optimistic UI başarısızsa rollback)

---

## 5. 1000+ Item Scroll Performansı

### Hazırlık
- Test hesabına 1000+ içerik yükleyin (script ile)

### Adımlar
1. Uygulamayı cold start (önce tam kapatın) ile açın
2. **Beklenen:** App açılış süresi < 3 saniye olmalı
3. Feed ekranında scroll yapın
4. **Beklenen:** Jank (takılma) hissedilmemeli
5. Arama sekmesine geçin
6. **Beklenen:** Sekme geçişi anında olmalı
7. Arama yapın
8. **Beklenen:** Sonuçlar < 1 saniye içinde gelmeli
9. Katalog sekmesine geçin
10. **Beklenen:** Koleksiyon kartları akıcı render olmalı

---

## 6. Keyboard Açıkken CTA Erişimi

### Hazırlık
- Küçük ekranlı cihaz (iPhone SE veya benzeri)

### Adımlar
1. İçerik ekleme ekranını açın
2. Not alanına tıklayın (klavye açılacak)
3. "Koleksiyona Ekle" butonu görünürlüğünü kontrol edin
4. **Beklenen:** Buton klavyenin ÜSTÜNDE olmalı
5. Klavyeyi kapatıp açın
6. **Beklenen:** Buton pozisyonu smooth animasyonla güncellenmeli

---

## 7. Empty / Error State Doğrulama

### Hazırlık
- İnternet bağlantısını kontrol edin

### Adımlar

#### 7.1 Search Screen
1. Arama sekmesine geçin
2. İnterneti kapatın
3. Arama yapın
4. **Beklenen:** Error state gösterilmeli (ikon + mesaj + "Tekrar Dene" butonu)
5. "Sonuç bulunamadı" empty state GÖRÜNMEMELİ

#### 7.2 Feed Screen
1. İnterneti kapatın
2. Uygulamayı yeniden açın
3. Feed ekranında error state kontrol edin
4. **Beklenen:** "İçerik yok" DEĞİL, hata mesajı gösterilmeli

#### 7.3 Catalog Screen
1. İnterneti kapatın
2. Katalog sekmesine geçin
3. Error state ve retry butonu kontrol edin

---

## 8. Vault Auto-Lock Doğrulama

### Hazırlık
- Vault özelliği aktif bir kullanıcı hesabı
- En az 1 gizli içerik

### Adımlar
1. Vault'ı açın (PIN/Biometric ile doğrulayın)
2. Gizli içeriği görüntüleyin
3. Uygulamayı background'a gönderin (home button)
4. 5 saniye bekleyin
5. Uygulamayı foreground'a getirin
6. **Beklenen:** Vault tekrar kilitlenmeli olmalı
7. Gizli içeriği görüntülemek için tekrar doğrulama istenmeli

---

## 9. Login / Logout State Temizliği

### Hazırlık
- Aktif bir kullanıcı oturumu

### Adımlar
1. Profil sekmesine geçin
2. Çıkış yapın
3. **Beklenen:** Tüm kullanıcı verileri temizlenmeli
4. Uygulamayı tamamen kapatıp açın
5. Giriş ekranı görülmeli
6. Farklı bir hesapla giriş yapın
7. **Beklenen:** Önceki kullanıcının verileri GÖRÜNMEMELİ
8. RevenueCat customer context temizlendiğini kontrol edin (log backend'e bakın)

---

## 10. Batch Create Partial Failure

### Hazırlık
- İnternet bağlantısı
- En az 3 koleksiyon

### Adımlar

#### Senaryo A: API Batch Endpoint Var
1. İçerik ekleme ekranında 3 koleksiyon seçin
2. Kaydet butonuna tıklayın
3. **Beklenen:** Ya tümü başarılı, ya da hiçbiri başarısız olmalı (atomik)

#### Senaryo B: API Yok (Sequential Create)
1. İçerik ekleme ekranında 3 koleksiyon seçin
2. İnterneti kapatın
3. Kaydet butonuna tıklayın
4. **Beklenen:** Hata mesajı gösterilmeli
5. **Beklenen:** Kısmi başarı varsa kullanıcıya bildirilmeli: "1/3 kategoriye eklendi. Kalanları tekrar deneyin."

---

## Sonuç Raporu

Her senaryo için:
- ✅ Geçti
- ❌ Başarısız
- ⚠️ Kısmi geçti (notlar ile)

Test sonuçlarını buraya kaydedin.
