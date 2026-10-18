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
    url: 'https://www.youtube.com/watch?v=E7pt2Zwg79g',
    note: 'Brugge — "Bruges in 4K", Around The World 4K (YouTube, yatay)',
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
    collection: DemoCollection.recipes,
    url: 'https://www.youtube.com/watch?v=xaBo3BxKzp8',
    note: 'Shakshuka With Feta — NYT Cooking (YouTube)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.inspiration,
    url: 'https://www.pinterest.com/pin/529032287499307043/',
    note: 'Pinterest — Mediterranean Style Terrace (dikey)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.places,
    url: 'https://www.youtube.com/watch?v=MnKv22p_fmU',
    note: 'Kaş — Kalkan, Patara, Kaputaş drone 4K, Erman Çatı (YouTube)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.music,
    url: 'https://www.youtube.com/watch?v=EO4r_SV6bbA',
    note: 'Sezen Aksu — Firuze, orijinal plak kaydı (Sezen Aksu resmi kanalı)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.places,
    url: 'https://www.instagram.com/p/DeVt2tNseKn/',
    note: 'Kopenhag — Nyhavn\'da altın saat, @christopherraunleth_cph (Instagram '
        'fotoğrafı, kare). Not: Instagram CDN görsel adresi birkaç gün içinde '
        'sona eriyor; kayıttan sonra kart yer tutucuya düşebilir.',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.recipes,
    url: 'https://www.youtube.com/watch?v=R_YgXQHqWBg',
    note: 'Zeytinyağlı Taze Fasulye — Refika\'nın Mutfağı (YouTube)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.music,
    url: 'https://www.youtube.com/watch?v=frspQ0XRico',
    note: 'Arlo Parks — Hurt, A COLORS SHOW (COLORS resmi kanalı)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.inspiration,
    url: 'https://www.pinterest.com/pin/687643436890530198/',
    note: 'Pinterest — Modern Scandinavian Kitchen (dikey)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.places,
    url: 'https://www.youtube.com/watch?v=Oxv6IRcuNaI',
    note: 'Amsterdam — "by drone [4K]", Drone Snap (YouTube)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.music,
    url: 'https://www.youtube.com/watch?v=qUsE49lUQUY',
    note: 'Mabel Matiz — Öyle Kolaysa, resmi klip (Zoom Music & Management)',
  ),
  OnboardingDemoItem(
    collection: DemoCollection.recipes,
    url: 'https://www.youtube.com/watch?v=tURcFOyD-Q4',
    note: 'Braised halloumi with tomatoes and beans — Ottolenghi resmi kanalı',
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
