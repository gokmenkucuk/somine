# Anahtar Kelime Araştırması (tr + en-US)

Tarih: 2026-10-18 · Beceriler: keyword-research, metadata-optimization

## Yöntem ve güven düzeyi (önce bunu oku)

Ücretli bir ASO veri aracına (AppTweak, Sensor Tower, Astro vb.) erişim yok. Bu yüzden **tüm hacim ve zorluk puanları tahmindir**. Kullanılan iki ücretsiz ve gerçek veri kaynağı:

1. **Apple arama önerileri (autocomplete):** `search.itunes.apple.com/WebObjects/MZSearchHints.woa/wa/hints` uç noktası, ABD (143441) ve Türkiye (143480) vitrin başlığıyla. Apple yalnızca gerçekten aranan ifadeleri öneri olarak gösterir. Bir ifadenin **jenerik öneri olarak** çıkması (uygulama adı olarak değil) talep olduğunu gösterir; öneri listesinde üst sıralarda olması daha yüksek talep anlamına gelir. Öneri hiç çıkmıyorsa hacim çok düşüktür.
2. **iTunes Search API** (`itunes.apple.com/search`): her ifade için ilk 10 sonucun değerlendirme sayıları. İlk 10'un medyan değerlendirme sayısı **zorluk vekili** olarak kullanıldı (düşük medyan = yeni bir uygulamanın sıralamaya girmesi kolay).

Puanlama (1–100):
- **Hacim tahmini:** Jenerik öneri yok = 5–10 · yalnızca uzun kuyruk/uygulama adı önerisi = 15–25 · jenerik öneri, alt sıralarda = 30–45 · jenerik öneri, ilk 3 sırada ve çok kelimeli türevleri var = 50–70 · tek kelime, çok genel = 70+.
- **Zorluk tahmini:** İlk 10 medyan değerlendirme <25 → 10–20 · 25–250 → 25–40 · 250–2.500 → 45–60 · 2.500–25.000 → 65–80 · >25.000 → 85+.
- **Alaka:** Elle, uygulamanın gerçekten yaptığına göre.
- **Fırsat** = Hacim×0,4 + (100−Zorluk)×0,3 + Alaka×0,3 (keyword-research becerisinin formülü).

**Güven:** Sıralama (hangisi diğerinden daha iyi) için orta; mutlak sayılar için düşük. Yayından 2–4 hafta sonra ASC → App Analytics → "Kaynak: App Store Araması" ve Search Ads (ücretsiz "popülerlik" puanı için Apple Search Ads Advanced hesabı açmak yeterli, harcama gerekmez) ile doğrulanmalı.

Ham veri komutu: `scratchpad/kw/kw.py` (oturum dosyası; tekrar üretmek için aynı iki uç nokta yeterli).

## en-US adayları

| Anahtar kelime | Öneri kanıtı (ABD) | İlk 10 medyan değ. | Hacim | Zorluk | Alaka | Fırsat | Karar |
|---|---|---|---|---|---|---|---|
| save links | "save links" jenerik öneri + 9 türev | 26 | 55 | 30 | 95 | **71** | Ad |
| bookmark | jenerik, "bookmark manager" 2. sırada | 92 | 65 | 35 | 90 | **72** | Ad |
| bookmark manager | jenerik öneri | 18 | 40 | 20 | 85 | 66 | Ad (bookmark ile kapsanır) |
| read later | jenerik öneri, ilk sırada | 92 | 50 | 38 | 75 | 61 | Alt başlık |
| save for later | jenerik öneri, ilk sırada | 17 | 40 | 15 | 85 | 67 | Ad+alt başlık kelimeleriyle kapsanır |
| reminder(s) | çok yüksek hacim | 48.410 | 85 | 92 | 55 | 53 | Alt başlık (uzun kuyruk "read later reminder") |
| link saver | jenerik öneri, ilk sırada | 6 | 45 | 10 | 95 | **74** | Anahtar alanı: saver |
| link organizer | jenerik öneri | 18 | 35 | 20 | 90 | 65 | Anahtar alanı: organizer |
| collection(s) | jenerik ama koleksiyoncu/envanter niyeti | 13.399 | 60 | 75 | 50 | 47 | Anahtar alanı (alaka orta) |
| idea board | jenerik öneri | 3.983 | 30 | 65 | 55 | 39 | Anahtar alanı: idea |
| inspiration | jenerik ama alıntı/motivasyon niyeti | yüksek | 45 | 60 | 45 | 44 | Anahtar alanı |
| recipe saver | jenerik, "instagram/tiktok recipe saver" türevleri | 6.790 | 45 | 70 | 70 | 48 | Anahtar alanı: recipe |
| private vault | jenerik ama foto kasası niyeti | 30.269 | 55 | 85 | 40 | 38 | Anahtar alanı: vault (düşük öncelik) |
| wishlist | jenerik | orta | 45 | 50 | 55 | 50 | Anahtar alanı |
| social bookmark | **yalnız uygulama adları**, jenerik öneri yok | 16 | 8 | 15 | 70 | 49 | **Adı bırak** |
| save reels | jenerik, ama indirici niyeti baskın | 2.032 | 55 | 65 | 60 | 51 | Kullanma ("Reels" Meta markası, niyet de indirme) |
| pocket | yüksek ama rakip markası | – | – | – | – | – | **Yasak** (2.3.7) |

## tr adayları

Not: TR mağazasında bu kategori Türkçe ifadeyle çok az aranıyor; aynı vitrinde İngilizce ifadeler ("save link", "read later", "link saver", "bookmark manager") öneri olarak çıkıyor. Türkiye vitrini **en-GB + tr** yerelleştirmelerini dizinlediği için İngilizce terimler en-GB'ye, Türkçeler tr'ye konmalı.

| Anahtar kelime | Öneri kanıtı (TR) | İlk 10 medyan değ. | Hacim | Zorluk | Alaka | Fırsat | Karar |
|---|---|---|---|---|---|---|---|
| link | jenerik, LinkedIn baskın | 1.579 | 60 | 55 | 70 | 58 | Ad |
| kaydet / kaydetme | jenerik ("video/ekran kaydetme" baskın) | 209 | 55 | 35 | 70 | **62** | Ad |
| hatırlat / hatırlatıcı | jenerik, ilk sırada + türevler | 1.965 | 55 | 55 | 75 | 58 | Ad (hatırlat) + anahtar alanı (hatırlatıcı) |
| koleksiyon | jenerik, ilk sırada | 221 | 40 | 35 | 80 | 59 | Alt başlık |
| yer imi | öneri yok | 0 | 8 | 10 | 95 | 59 | Alt başlık (sıfır rekabet, kategori tanımı) |
| not / notlar | çok yüksek ("not defteri") | 1.966 | 75 | 60 | 55 | 59 | Alt başlık (notlar) |
| sonra oku | öneri yok | 0 | 8 | 5 | 85 | 57 | Anahtar alanı (sonra, oku ayrı) |
| okuma listesi | tek öneri | – | 15 | 20 | 70 | 51 | Anahtar alanı (okuma, liste) |
| tarif / tarif defteri | jenerik, "tarifleri kaydet" önerisi var | 75 | 50 | 30 | 65 | **60** | Anahtar alanı: tarif |
| ilham | jenerik ama dini/alıntı niyeti | 4 | 30 | 15 | 50 | 53 | Anahtar alanı |
| favori | jenerik | 93 | 30 | 30 | 60 | 51 | Anahtar alanı |
| arşiv | "e-arşiv fatura" baskın | – | 50 | 50 | 40 | 47 | Anahtar alanı (düşük öncelik) |
| gizli / kasa | "gizli fotoğraf albümü", "kasa defteri" | – | 50 | 55 | 45 | 47 | Anahtar alanı |
| pano | pano/clipboard niyeti | 147 | 25 | 35 | 45 | 43 | Anahtar alanı (Pinterest panosu çağrışımı) |
| gönderi / paylaş / klasör | zayıf öneri | – | 20 | 30 | 65 | 49 | Anahtar alanı |
| sosyal medya arşivi (eski ad) | öneri yok | – | 5 | 10 | 60 | 41 | Bırak |

## Final alanlar (ASC'ye girilecek)

Kurallar uygulandı: tekil, virgülden sonra boşluk yok, ad/alt başlıktaki kelimeler tekrar edilmedi, "app/free/ücretsiz" yok, rakip markası yok, marka adı yok.

### en-US

```
Ad:          somine: Save Links & Bookmarks          (30/30)
Alt başlık:  Read later with reminders                (25/30)
Anahtar:     saver,organizer,collection,folder,post,recipe,idea,inspiration,vault,note,wishlist,favorite,article   (99/100)
```

### tr

```
Ad:          somine: Link Kaydet, Hatırlat            (29/30)
Alt başlık:  Yer imi, koleksiyon ve notlar            (29/30)
Anahtar:     hatırlatıcı,sonra,oku,okuma,liste,arşiv,favori,gizli,kasa,tarif,ilham,gönderi,paylaş,klasör,pano   (96/100)
```

### en-GB (öneri, ASC'ye girilmedi; bkz. README)

Türkiye mağazası varsayılan olarak English (U.K.) dizinler. en-GB yerelleştirmesi açılırsa TR aramalarında ikinci bir 100 karakterlik alan kazanılır.

```
Ad:          somine: Save Links & Bookmarks          (30/30)
Alt başlık:  Read later with reminders                (25/30)
Anahtar:     saver,organiser,collection,folder,post,recipe,idea,inspiration,vault,note,wishlist,favourite,video   (98/100)
```

## Kapsam matrisi (en-US)

| Hedef ifade | Ad | Alt başlık | Anahtar alanı |
|---|---|---|---|
| save links / save link | ✓ | | |
| bookmark / bookmark manager | ✓ | | |
| read later | | ✓ | |
| save for later | ✓ (save) | ✓ (later) | |
| reminder | | ✓ | |
| link saver | ✓ (link) | | ✓ (saver) |
| link organizer | ✓ (link) | | ✓ (organizer) |
| recipe saver | | | ✓ recipe + saver |
| idea board / inspiration | | | ✓ |

## İzleme listesi (ilk 8 hafta haftalık)

en-US: save links, bookmark manager, link saver, read later, save for later, link organizer, bookmark, recipe saver.
tr: link kaydet, hatırlatıcı, koleksiyon, yer imi, tarif, not defteri (aspirasyonel), sonra oku.

Dört haftada sıralamaya girmeyen kelimeyi değiştir; anahtar alanı yeni sürüm gönderiminde güncellenir (promosyon metni hariç her şey incelemeye tabi).
