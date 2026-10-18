/// Yeni kullanıcıya kayıtta eklenen örnek içerik (paketlenmiş yedek liste).
///
/// İleride bu liste API'den gelecek; uygulama, ağdan alamazsa bu sabit
/// listeye düşecek. Aynı liste `docs/onboarding-demo-content.json` dosyasında
/// da duruyor (API'yi beslemek için) — birini değiştirirken diğerini de
/// güncelle.
///
/// Sıralama: liste sırası = ana ekrandaki sıra. İlk öğe en yeni tarihi alır
/// (OnboardingPrepScreen her öğeyi bir öncekinden 1 saat eski kaydeder), bu
/// yüzden koleksiyonlar 2 sütunlu ızgarada karışık ve dengeli görünsün diye
/// iç içe dizildi.
///
/// Doğrulama (2026-10-18): her bağlantı MetadataService'in yaptığı gibi
/// (Safari UA + tr-TR ile HTML çekip og:/twitter: etiketleri) çekildi;
/// HTTP 200, boş olmayan başlık ve 200 dönen bir görsel doğrulandı. YouTube
/// için ayrıca oEmbed 200, `playabilityStatus=OK`, `isFamilySafe=true` ve
/// TR/US/DE'de erişilebilir olduğu kontrol edildi.
library;

/// Koleksiyon anahtarları dile bağlı değildir; OnboardingPrepScreen bunları
/// l10n'daki varsayılan koleksiyon adlarına eşler.
abstract final class DemoCollection {
  static const music = 'music';
  static const places = 'places';
  static const restaurants = 'restaurants';

  /// Eski anahtar (tarifler koleksiyonu restoranlara dönüştü); gelirse
  /// restoran koleksiyonuna konur.
  static const recipes = 'recipes';
  static const inspiration = 'inspiration';
}

/// Tek bir örnek içerik kaydı.
class OnboardingDemoItem {
  /// [DemoCollection] anahtarlarından biri.
  final String collection;
  final String url;

  /// Ekip için kısa açıklama (kullanıcıya gösterilmez).
  final String? note;

  const OnboardingDemoItem({
    required this.collection,
    required this.url,
    this.note,
  });
}

const List<OnboardingDemoItem> onboardingDemoItems = [
  OnboardingDemoItem(
    collection: DemoCollection.places,
    url: 'https://www.youtube.com/watch?v=_xRUeJN-E8A',
    note: 'Brugge — "BRUGES, BELGIUM | 5 Things You SHOULD do in Bruges!", World Wild Hearts (YouTube vlog; 622.717 izlenme, 4.985 beğeni; doğrulama 2026-10-18)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.restaurants,
    url: 'https://www.instagram.com/poulettecph/',
    note: 'Poulette, Kopenhag (Nørrebro) — The Bear dizisinde de görünen, efsane acılı tavuk sandviçi yapan küçük dükkân (Instagram profili; doğrulama 2026-10-18)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.inspiration,
    url: 'https://martivistanbul.com/products/dik-beyaz-cizgili-keten-kirlent/1253',
    note: 'Martivi İstanbul — Dik Beyaz Çizgili Vintage Keten Kırlent (ürün sayfası, kare)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.music,
    url: 'https://www.youtube.com/watch?v=TWcyIpul8OE',
    note: 'Bon Iver — Holocene, resmi klip (Bon Iver resmi kanalı)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.music,
    url: 'https://www.youtube.com/watch?v=oD6fL4yyhDk',
    note: 'Can Ozan — Sar Bu Şehri (Can Ozan resmi kanalı)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.restaurants,
    url: 'https://www.instagram.com/bilokmarestaurant/',
    note: 'Bi Lokma, Kaş — 25 yıllık "anne mutfağı", ev yemekleri ve mezeleriyle Kaşlıların da favorisi (Instagram profili; doğrulama 2026-10-18)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.inspiration,
    url: 'https://www.pinterest.com/pin/529032287499307043/',
    note: 'Pinterest — Mediterranean Style Terrace (dikey)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.places,
    url: 'https://www.youtube.com/watch?v=O7c_bXCF8BU',
    note: 'Kaş — "KAS, TURKEY | Best Things To Do In Beautiful Kaş", World Wild Hearts (YouTube vlog; 319.304 izlenme, 4.054 beğeni; doğrulama 2026-10-18)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.music,
    url: 'https://www.youtube.com/watch?v=EO4r_SV6bbA',
    note: 'Sezen Aksu — Firuze, orijinal plak kaydı (Sezen Aksu resmi kanalı)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.restaurants,
    url: 'https://www.winkel43.nl/',
    note: 'Winkel 43, Amsterdam (Jordaan) — Noordermarkt\'taki köşe kafe; şehrin en sevilen appeltaart\'ı (resmi site, güçlü og:image; IG: @cafewinkel43amsterdam; doğrulama 2026-10-18)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.places,
    url: 'https://www.youtube.com/watch?v=bXaPOjfEKro',
    note: 'Kopenhag — "my first time in denmark: a week in copenhagen", Breanna Quan (YouTube vlog; 757.244 izlenme, 20.955 beğeni; doğrulama 2026-10-18)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.music,
    url: 'https://www.youtube.com/watch?v=frspQ0XRico',
    note: 'Arlo Parks — Hurt, A COLORS SHOW (COLORS resmi kanalı)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.restaurants,
    url: 'https://www.instagram.com/ciyasofrasi/',
    note: 'Çiya Sofrası, İstanbul (Kadıköy) — Musa Dağdeviren\'in unutulmuş Anadolu tariflerini yaşattığı lokanta; Chef\'s Table bölümü (Instagram profili; doğrulama 2026-10-18)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.music,
    url: 'https://www.youtube.com/watch?v=Z2BQK2hO5HI',
    note: 'Max McNown — A Lot More Free, resmi klip',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.inspiration,
    url: 'https://www.pinterest.com/pin/687643436890530198/',
    note: 'Pinterest — Modern Scandinavian Kitchen (dikey)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.restaurants,
    url: 'https://guide.michelin.com/gb/en/west-vlaanderen/brugge/restaurant/quatre-vins',
    note: 'Quatre Vins, Brugge — doğal/biyodinamik şarap ve paylaşımlık tabaklar sunan küçük bistro, Michelin Bib Gourmand (Michelin sayfası, güçlü görsel; IG: @quatre.vins; doğrulama 2026-10-18)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.places,
    url: 'https://www.youtube.com/watch?v=YIUs1pagLnM',
    note: 'Amsterdam — "HOW TO TRAVEL AMSTERDAM in 2019", Lost LeBlanc (YouTube vlog; 1.123.497 izlenme, 17.664 beğeni; doğrulama 2026-10-18)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.music,
    url: 'https://www.youtube.com/watch?v=qUsE49lUQUY',
    note: 'Mabel Matiz — Öyle Kolaysa, resmi klip (Zoom Music & Management)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.inspiration,
    url: 'https://martivistanbul.com/products/yatay-mavi-cizgili-vintage-keten-kirlent/1284',
    note: 'Martivi İstanbul — Yatay Mavi Çizgili Vintage Keten Kırlent (ürün sayfası, kare)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.music,
    url: 'https://www.youtube.com/watch?v=6jYtRQ2tHGg',
    note: 'Norah Jones — Tiny Desk Concert (NPR Music)',
  ),
];
