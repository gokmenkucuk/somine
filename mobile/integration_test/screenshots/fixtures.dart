// Ekran görüntüleri için kurgusal demo veri (TR ve EN ayrı "hesap").
//
// Kurallar (docs/app-store/screenshots-plan.md):
//  - Gerçek kişi adı yok: kullanıcılar `ayse` ve `mert` kurgusaldır.
//  - Kayıt bağlantıları ayrılmış `.example` alan adındadır; hiçbir gerçek siteyi
//    ve sosyal platformu işaret etmez (kartlarda jenerik link ikonu çıkar).
//  - Görseller Pexels lisanslı fotoğraflardır, bkz.
//    docs/app-store/screenshots/CREDITS.md.

/// Uygulama içinden istenen görsellerin servis edildiği sahte alan adı.
const fixtureImageHost = 'img.somine.test';

String fixtureImageUrl(String name) => 'https://$fixtureImageHost/$name.jpg';

class FixtureCategory {
  const FixtureCategory(
    this.id,
    this.icon,
    this.color,
    this.tr,
    this.en, {
    this.isVault = false,
  });

  final String id;
  final String icon;
  final String color;
  final String tr;
  final String en;
  final bool isVault;
}

class FixtureItem {
  const FixtureItem({
    required this.id,
    required this.categoryId,
    required this.image,
    required this.width,
    required this.height,
    required this.tr,
    required this.en,
    required this.slug,
    this.hasReminder = false,
    this.isFavorite = false,
  });

  final String id;
  final String categoryId;
  final String image;
  final int width;
  final int height;
  final String tr;
  final String en;
  final String slug;
  final bool hasReminder;
  final bool isFavorite;

  String url(String locale) =>
      locale == 'tr'
          ? 'https://gezi-notlari.example/$slug'
          : 'https://travel-notes.example/$slug';

  String title(String locale) => locale == 'tr' ? tr : en;
}

const catCopenhagen = 'cat-copenhagen';
const catKas = 'cat-kas';
const catAmsterdam = 'cat-amsterdam';
const catBruges = 'cat-bruges';
const catFood = 'cat-food';
const catMusic = 'cat-music';
const catInspiration = 'cat-inspiration';
const catVault = 'cat-vault';
const catQuick = 'cat-quick';

const fixtureCategories = <FixtureCategory>[
  FixtureCategory(catCopenhagen, '⛵', '#0EA5E9', 'Kopenhag', 'Copenhagen'),
  FixtureCategory(catKas, '🌊', '#14B8A6', 'Kaş', 'Kaş'),
  FixtureCategory(catFood, '🍽️', '#EF4444', 'Restoranlar', 'Restaurants'),
  FixtureCategory(catAmsterdam, '🚲', '#F97316', 'Amsterdam', 'Amsterdam'),
  FixtureCategory(catMusic, '🎵', '#8B5CF6', 'Müzik', 'Music'),
  FixtureCategory(catBruges, '🏰', '#A16207', 'Brugge', 'Bruges'),
  FixtureCategory(
    catInspiration,
    '💡',
    '#FBBF24',
    'Ev İçin İlham',
    'Home Ideas',
  ),
  FixtureCategory(
    catVault,
    '🎁',
    '#EC4899',
    'Hediye Fikirleri',
    'Gift Ideas',
    isVault: true,
  ),
  // Uygulama "Hızlı" koleksiyonunu kendisi oluşturur ve arayüzde gizler;
  // fixture'da hazır olsun ki ekleme ekranı oluşturmaya çalışmasın.
  FixtureCategory(catQuick, '⚡', '#64748B', 'Hızlı', 'Hızlı'),
];

/// Liste sırası = akıştaki sıra (en yeni önce).
const fixtureItems = <FixtureItem>[
  FixtureItem(
    id: 'item-01',
    categoryId: catCopenhagen,
    image: 'cph_nyhavn_red',
    width: 720,
    height: 1080,
    tr: 'Kopenhag: Nyhavn\'da bir gün',
    en: 'A day in Nyhavn, Copenhagen',
    slug: 'kopenhag-nyhavn',
    isFavorite: true,
  ),
  FixtureItem(
    id: 'item-02',
    categoryId: catFood,
    image: 'food_meze',
    width: 720,
    height: 1080,
    tr: 'Kaş\'ta ev yemekleri ve mezeler',
    en: 'Home-style meze in Kaş',
    slug: 'kas-meze-lokantasi',
    hasReminder: true,
  ),
  FixtureItem(
    id: 'item-03',
    categoryId: catMusic,
    image: 'music_turntable',
    width: 720,
    height: 480,
    tr: 'Pazar sabahı plak listesi',
    en: 'Sunday morning vinyl list',
    slug: 'pazar-plak-listesi',
  ),
  FixtureItem(
    id: 'item-04',
    categoryId: catKas,
    image: 'kas_incebogaz',
    width: 720,
    height: 1280,
    tr: 'Kaş, İnceboğaz koyu',
    en: 'İnceboğaz cove, Kaş',
    slug: 'kas-incebogaz',
  ),
  FixtureItem(
    id: 'item-05',
    categoryId: catInspiration,
    image: 'home_scandi_plants',
    width: 720,
    height: 960,
    tr: 'Bitkili, ahşap bir salon',
    en: 'Warm wooden living room',
    slug: 'ahsap-salon',
  ),
  FixtureItem(
    id: 'item-06',
    categoryId: catFood,
    image: 'food_apple_pie',
    width: 720,
    height: 900,
    tr: 'Amsterdam\'ın sevilen elmalı turtası',
    en: 'Amsterdam\'s favourite appeltaart',
    slug: 'amsterdam-appeltaart',
    hasReminder: true,
  ),
  FixtureItem(
    id: 'item-07',
    categoryId: catBruges,
    image: 'brugge_canal',
    width: 720,
    height: 480,
    tr: 'Brugge\'de kanal turu',
    en: 'Canal tour in Bruges',
    slug: 'brugge-kanal-turu',
  ),
  FixtureItem(
    id: 'item-08',
    categoryId: catAmsterdam,
    image: 'ams_canal_houses',
    width: 720,
    height: 1080,
    tr: 'Amsterdam kanal evleri rotası',
    en: 'Amsterdam canal houses walk',
    slug: 'amsterdam-kanal-evleri',
  ),
  FixtureItem(
    id: 'item-09',
    categoryId: catFood,
    image: 'food_pasta',
    width: 720,
    height: 1080,
    tr: 'Kopenhag\'da taze makarna',
    en: 'Fresh pasta in Copenhagen',
    slug: 'kopenhag-taze-makarna',
  ),
  FixtureItem(
    id: 'item-10',
    categoryId: catMusic,
    image: 'music_vinyl_bw',
    width: 720,
    height: 480,
    tr: 'Akustik akşamlar listesi',
    en: 'Acoustic evenings playlist',
    slug: 'akustik-aksamlar',
  ),
  FixtureItem(
    id: 'item-11',
    categoryId: catCopenhagen,
    image: 'cph_harbour_boats',
    width: 720,
    height: 1280,
    tr: 'Kopenhag limanında yürüyüş',
    en: 'Copenhagen harbour walk',
    slug: 'kopenhag-liman',
  ),
  FixtureItem(
    id: 'item-12',
    categoryId: catKas,
    image: 'kas_theater',
    width: 720,
    height: 480,
    tr: 'Kaş antik tiyatroda gün batımı',
    en: 'Sunset at the ancient theatre, Kaş',
    slug: 'kas-antik-tiyatro',
  ),
  FixtureItem(
    id: 'item-13',
    categoryId: catInspiration,
    image: 'home_living_room',
    width: 720,
    height: 480,
    tr: 'Sade salon fikirleri',
    en: 'Calm living room ideas',
    slug: 'sade-salon',
  ),
  FixtureItem(
    id: 'item-14',
    categoryId: catBruges,
    image: 'brugge_houses',
    width: 720,
    height: 481,
    tr: 'Brugge\'nin eski sokakları',
    en: 'Old streets of Bruges',
    slug: 'brugge-sokaklar',
  ),
  FixtureItem(
    id: 'item-15',
    categoryId: catAmsterdam,
    image: 'ams_facades',
    width: 720,
    height: 1080,
    tr: 'Amsterdam\'da bir hafta sonu',
    en: 'A weekend in Amsterdam',
    slug: 'amsterdam-hafta-sonu',
  ),
  FixtureItem(
    id: 'item-16',
    categoryId: catKas,
    image: 'kas_night',
    width: 720,
    height: 480,
    tr: 'Kaş\'ta gece manzarası',
    en: 'Kaş by night',
    slug: 'kas-gece',
  ),
  FixtureItem(
    id: 'item-17',
    categoryId: catCopenhagen,
    image: 'cph_nyhavn_wide',
    width: 720,
    height: 480,
    tr: 'Kopenhag\'da kanal kenarında kahvaltı',
    en: 'Canal-side breakfast in Copenhagen',
    slug: 'nyhavn-kahvalti',
  ),
  FixtureItem(
    id: 'item-18',
    categoryId: catAmsterdam,
    image: 'ams_canal_wide',
    width: 720,
    height: 480,
    tr: 'Amsterdam\'da bisikletle kanallar',
    en: 'Amsterdam canals by bike',
    slug: 'amsterdam-bisiklet',
  ),
];

/// Ekleme ekranında "yeni paylaşılmış" gibi gelen bağlantı.
const addFlowSlugTr = 'kas-gezi-rehberi';
const addFlowSlugEn = 'kas-travel-guide';
const addFlowTitleTr = 'Kaş rehberi: antik tiyatro ve koylar';
const addFlowTitleEn = 'Kaş guide: ancient theatre and coves';
const addFlowImage = 'kas_theater';

/// Kurgusal arkadaş.
const friendUserId = 'fixture-user-mert';
const friendUsername = 'mert';
const friendDisplayName = 'Mert';
