# Ekran görüntüsü fotoğraf kaynakları

Mağaza görsellerindeki (ekran görüntüleri, header, App Preview) demo kayıtların
fotoğrafları [Pexels](https://www.pexels.com) üzerinden alındı ve
[Pexels Lisansı](https://www.pexels.com/license/) kapsamındadır (ticari kullanım
serbest, atıf zorunlu değil). Hepsi 720 px genişliğe küçültülüp
`mobile/integration_test/assets/fixtures/` altına konup ekran görüntüsü
düzeneğine gömüldü (`fixture_images.g.dart`; üretim uygulamasına girmez).

Seçimde dikkat edilenler: tanınabilir kişi yüzü yok, marka logosu / gazete /
dergi kapağı yok (bu yüzden bazı aday fotoğraflar elendi).

| Dosya (fixtures/) | Konu | Kaynak | Fotoğrafçı |
|---|---|---|---|
| cph_nyhavn_red.jpg | Kopenhag, Nyhavn | https://www.pexels.com/photo/colorful-nyhavn-harbor-in-copenhagen-denmark-30616668/ | Pexels sayfasında |
| cph_nyhavn_wide.jpg | Kopenhag, Nyhavn | https://www.pexels.com/photo/view-of-boats-and-colorful-buildings-in-nyhavn-copenhagen-denmark-17590892/ | Pexels sayfasında |
| cph_harbour_boats.jpg | Kopenhag limanı | https://www.pexels.com/photo/nyhavn-harbor-in-copenhagen-17580958/ | Pexels sayfasında |
| kas_incebogaz.jpg | Kaş, İnceboğaz | https://www.pexels.com/photo/kas-incebogaz-18582934/ | Okan Demircan |
| kas_night.jpg | Kaş, gece | https://www.pexels.com/photo/seaside-town-kas-in-turkey-18203210/ | Pexels sayfasında |
| kas_theater.jpg | Kaş, Antiphellos tiyatrosu | https://www.pexels.com/photo/an-ancient-theater-overlooking-the-sea-8389217/ | Ahmet Atak |
| brugge_canal.jpg | Brugge kanalı | https://www.pexels.com/photo/picturesque-canal-scene-in-bruges-belgium-28770645/ | Pexels sayfasında |
| brugge_houses.jpg | Brugge | https://www.pexels.com/photo/historic-canal-buildings-in-brugge-belgium-30060869/ | Pexels sayfasında |
| ams_canal_wide.jpg | Amsterdam kanalı | https://www.pexels.com/photo/old-amsterdam-city-houses-on-canal-4237160/ | Adrien Olichon |
| ams_canal_houses.jpg | Amsterdam kanal evleri | https://www.pexels.com/photo/colorful-canal-houses-in-amsterdam-at-sunrise-34234634/ | Pexels sayfasında |
| ams_facades.jpg | Amsterdam cepheleri | https://www.pexels.com/photo/facades-of-the-waterfront-buildings-in-amsterdam-the-netherlands-16092936/ | Pexels sayfasında |
| music_turntable.jpg | Pikap | https://www.pexels.com/photo/vinyl-record-playing-164853/ | Pexels sayfasında |
| music_vinyl_bw.jpg | Plak (siyah-beyaz) | https://www.pexels.com/photo/black-vinyl-record-145707/ | Pexels sayfasında |
| food_pasta.jpg | Makarna | https://www.pexels.com/photo/delicious-pesto-pasta-in-cozy-restaurant-setting-33097104/ | Pexels sayfasında |
| food_apple_pie.jpg | Elmalı turta | https://www.pexels.com/photo/delicious-ice-cream-on-plate-with-apple-pie-4340676/ | Spencer Davis |
| food_meze.jpg | Meze | https://www.pexels.com/photo/traditional-turkish-meze-on-copper-plates-30726875/ | Pexels sayfasında |
| home_living_room.jpg | Salon | https://www.pexels.com/photo/scandinavian-interior-of-a-living-room-9565782/ | Taryn Elliott |
| home_scandi_plants.jpg | Bitkili salon | https://www.pexels.com/photo/cozy-scandinavian-living-room-with-plants-28744513/ | Charm Andaya |

İndirme: `https://images.pexels.com/photos/<id>/pexels-photo-<id>.jpeg?auto=compress&cs=tinysrgb&w=800`
(2026-10-18). Yeni fotoğraf eklersen tabloya ekle ve
`marketing/screenshots/scripts/embed_fixture_images.py` betiğini çalıştır.

Demo veride kişi adları kurgusaldır (`ayse`, `mert`), kayıt bağlantıları
ayrılmış `.example` alan adındadır.
