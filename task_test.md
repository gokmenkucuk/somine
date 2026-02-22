SoMine QA & Yayın Öncesi Test Listesi
1. Kimlik Doğrulama & İşe Alım (Onboarding)
 Apple ile Giriş test edilecek (iOS Native hissi) -- BAŞARILI
 Google ile Giriş test edilecek  BAŞARILI
 İlk giriş (Onboarding - İsim/Kullanıcı Adı alma) akışı doğrulanacak -- BAŞARILI
 Varsa Misafir Modu (Guest Mode) geri dönüş senaryosu kontrol edilecek -- YOK
 Hesap Silme akışı ve verilerin temizlenmesi test edilecek -- HESAP SİLME BAŞARILI. HESAP SİLİP YENİDEN GİRDİĞİNDE KULLANICI EN SON BU İŞLEMİ PROFİL SAYFASINDA YAPTIĞI İÇİN UYGULAMA PROFİL SAYFASINDA AÇILIYOR. KULLANICI HESABI SİLDİ İSE YENİDEN KAYIT OLDU ANLAMINA GELİR VE ONBOARDİNG SONRASI ANA SAYFADA AÇILMALIDIR.
2. Temel Özellikler (İçerikler & Kategoriler)
 Not Ekleme (Metin girişi, kaydetme ve UI gösterimi) - NOT EKLEME TAMAM, HATIRLATICI KURMA TAMAM. HATIRLATICI BİLDİRİMİ GELDİĞİNDE ÜZERİNE TIKLAYINCA FARKLI VİD DETAY SAYFASINA GİDİYOR GİBİ VAR OLAN NOT DETAY SAYFASINA AÇILMASI GEREKİR. ÜSTTEN BİLDİRİM GELDİ VE DOKUNDU KULLANICI SONRASINDA O HATIRLATICIYA AİT NOT BİLİGLERİ AÇILMALI. AYNI ANASAYFADAN AÇILMIŞ GİBİ DAVRANMALI. FARKLI BİR DETAY SAYFASI VARSA BU İPTAL EDİLMELİ.
 Resim Ekleme (Kamera & Galeri seçicisi) - BAŞARILI
 İçerik Düzenleme (Metni güncelleme, kategorisini değiştirme) - BAŞARILI
 İçerik Silme (Çöp Kutusuna/Son Silinenlere taşıma) - BAŞARILI
 Kalıcı Olarak Silme & Son Silinenlerden Geri Getirme - BAŞARILI
 Kategori Yönetimi (Oluşturma, İkon/Renk düzenleme, Silme) - BAŞARILI
3. Link (Bağlantı) Ekleme & Desteklenen Platformlar
 OG Metadatasının (Başlık, Resim, Site adı vb.) hatasız çekilmesi test edilecek
 Eksik veya hatalı linklerde kullanıcıya gösterilecek hata UI'ı doğrulanacak
Desteklenen (Özel Olarak Tanınan) Platformların Test Edilmesi:
 Instagram
 YouTube
 X (Twitter)
 TikTok
 LinkedIn
 Spotify
 Pinterest
 Reddit
 Medium
 Behance
 Dribbble
 Diğer Genel Web Siteleri (Generic Web)
4. iOS Native & Donanım Özellikleri
 Kasa (Vault) kategorileri için FaceID / TouchID entegrasyonu
 iOS Share Extension (Safari, YouTube vb. diğer uygulamalardan link veya resim alma)
 Harita Koordinatları & Apple Maps önizlemesi
 Uygulama İkonu değiştirme (App Icon switcher) işlevi ve olası hataları
 Video oynatma & iOS 16+ Ekran Döndürme (Orientation) problemleri (YouTube Tam Ekran kontrolü)
5. Hatırlatıcılar & Bildirimler (Reminders)
 Bir içerik için hatırlatıcı kurma
 Lokal bildirimin gelmesi
 Bildirime tıklandığında ilgili içeriğe gitme (Deep link/Action)
 Bildirim izinleri ve ayarları
6. Sosyal & İşbirliği
 Paylaşım linki oluşturma / Arkadaş davet etme
 Paylaşım isteğini alma ve kabul etme
 Paylaşılan Koleksiyonları görüntüleme ("Benimle Paylaşılanlar")
 Erişimi kaldırma / Paylaşımı durdurma
7. Premium & Gelir Modeli (RevenueCat)
 Satın Alma Ekranının (Paywall) doğru gösterimi
 StoreKit üzerinden ürünlerin çekilmesi
 Satın alma akışının başarılı/başarısız mock testleri
 Satın almaları geri yükleme (Restore purchases)
 Premium sınırlarının test edilmesi (Örn: Maksimum içerik sayısı, ikon değiştirme, Kasaya erişim limitlerinin devreye girmesi)
8. Performans & UI/UX Cilas
 Testler sırasında Crashlytics'e düşen logların/hataların incelenmesi
 Karanlık (Dark) / Aydınlık (Light) mod geçişleri
 Ekran boyutlarına göre adaptif (Responsive) UI kontrolü
 Aşırı Widget yeniden çizimlerinin (rebuilds) performans analizi