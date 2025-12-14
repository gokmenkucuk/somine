# Anasayfa Yeniden Tasarım Planı

Mevcut anasayfayı ilettiğiniz profesyonel spesifikasyonlara göre baştan aşağı yenilemek için aşağıdaki adımları izleyeceğim:

## 1. Tasarım Sistemi (Design Tokens) Güncellemesi
*   **Renk Paleti:** Yeni ana renk `#2ECC71` (Yeşil), ikincil renk `#007BFF` (Mavi) ve belirtilen gradient renklerini ekleyeceğim.
*   **Tipografi:** Roboto font ailesini ve belirtilen font boyutlarını/ağırlıklarını tanımlayacağım.
*   **Gölge ve Kenarlıklar:** İçerik alanları için `0 2px 8px rgba(0,0,0,0.05)` gölge stilini ekleyeceğim.

## 2. Üst Bar Revizyonu (Header)
*   Mevcut arama çubuğunu (`HomeSearchBar`) kaldıracağım.
*   **Sol Taraf:** "Merhaba, Gökmen" metnini ekleyeceğim (18px, Medium, #333333).
*   **Sağ Taraf:** Özel tasarımlı "Katalog İkonu"nu (Oval, Yeşil İkon, Gri Çerçeve) ekleyeceğim.

## 3. Yeni Başlık Bölümü (Banner)
*   Mevcut banner alanını **"İçerik Aktarımı"** başlığıyla güncelleyeceğim.
*   **Görünüm:**
    *   Başlık: 32px Bold, Beyaz.
    *   Alt Başlık: "Sende bulabilirsin..." (16px, Regular).
    *   **Arkaplan:** İstenilen 5 renkli özel gradient geçişi (#6EDC3D -> #007BFF).
    *   **Şekil:** Alt köşeleri yuvarlatılmış (Border-radius: 0 0 12px 12px).

## 4. Kategori ve İçerik Alanı
*   **Kategoriler:** 3 adet büyük buton şeklinde, `#2ECC71` ana renkli ve beyaz yazılı yeni stil uygulayacağım.
*   **İçerik Grid:** Arkaplanı `#F5F5F5` yapıp, kartları beyaz zeminli ve gölgeli hale getireceğim.

Bu planı onaylarsanız hemen kodlamaya başlayacağım.