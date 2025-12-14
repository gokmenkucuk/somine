Bir sorun yok! Sistem gereği kod yazmaya başlamadan önce yapılacak işlemleri onayana sunmam gerekiyor. Verdiğin "Swimlanes" ve "Showcase" mimarisine tam uygun planım şudur:

1.  **Temel Tasarım (Design System):**
    *   Renkleri güncelle: Zemin `#F8F9FB`, Yazılar `#1A1E38`.
    *   Gradients: Cyan `#22D3EE` -> Blue `#0EA5E9`.
    *   Font: `Outfit` (zaten ekli, her yerde kullanıldığından emin olunacak).

2.  **Yeni Widget Mimarisi (Home Screen Parçaları):**
    *   **`HomeHeader`**: Standart AppBar yerine özel `Row`. "Merhaba Gökmen" + Profil Fotosu.
    *   **`ShowcaseSection`**: Üstteki yatay "Kredi Kartı/Albüm" görünümlü kategori listesi. (Glassmorphism ikonlu).
    *   **`ContentSwimlane` (Kritik):** Başlık + "Tümü" butonu + Yatay Liste içeren tekrar kullanılabilir widget.
    *   **`SwimlaneItemCard`**: 160px genişliğinde, dikey (portrait) odaklı, görsel ağırlıklı (%75) kartlar.

3.  **Ana Sayfa (Home Screen) İnşası:**
    *   Mevcut `MasonryGridView` yapısını kaldırıp, yukarıdaki parçaları içeren `SingleChildScrollView` + `Column` yapısına geçilecek.
    *   **Mock Data:** "Tatil Planlarım", "Instagram Reels", "Okunacaklar" bölümleri dummy verilerle doldurulacak.

4.  **Navigasyon (RootShell):**
    *   Alt barı (BottomNavBar) temiz beyaz zemine çekip, orta ikonu "Studio" için özel gradient FAB (Yüzen Buton) görünümüne kavuşturacağım.

Onayladığın an kodlamaya başlıyorum.