import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Görsellerin en-boy oranını (genişlik / yükseklik) hatırlayan kalıcı önbellek.
///
/// Masonry görünümünde kartın yüksekliğini görselin oranı belirler. Oran
/// önceden bilinmiyorsa kutu önce varsayılan bir oranla çizilir, görsel gelince
/// gerçek oranına sıçrar; kullanıcı bu yeniden yerleşimi görür. Bu önbellek
/// oranı ilk yüklemede öğrenip diske yazar, böylece sonraki her görüntülemede
/// kutu en baştan doğru oranla çizilir ve sıçrama olmaz.
///
/// Okumalar senkron olmak zorundadır (kutu ilk kare çizilirken oran bilinmeli),
/// bu yüzden kalıcı harita uygulama açılışında [init] ile belleğe alınır.
class ImageAspectRatioCache {
  ImageAspectRatioCache._();

  static final ImageAspectRatioCache instance = ImageAspectRatioCache._();

  /// v2: v1'de ölçüm sonucu yanlış URL'ye yazılabiliyordu (masonry kart geri
  /// dönüşümü). Sürüm artırımı, kirlenmiş eski kayıtların atılmasını sağlar.
  static const String _prefsKey = 'image_aspect_ratio_cache_v2';

  /// Diskte tutulacak azami kayıt sayısı. Aşılınca en eski kullanılanlar düşer.
  static const int maxEntries = 400;

  /// Oran henüz bilinmediğinde kullanılan varsayılan.
  ///
  /// Tahmin değil, ölçüm: simülatörde gerçek kütüphane üzerinde 33 görselin
  /// oranı toplandı. Dağılım 24x 16:9 (1.78), 5x 4:3 (1.33), 4x 9:16 (0.56) —
  /// yani içerik ezici çoğunlukla yatay video/bağlantı kapağı. 175 px genişlik
  /// şeridinde varsayılan başına ortalama sıçrama:
  ///   4:5 (0.80) -> 112.0 px, 1:1 (kare, eski davranış) -> 78.8 px,
  ///   4:3 (1.33) -> 45.9 px, 16:9 (1.78) -> 30.9 px.
  /// 16:9 hem ortalama sıçramayı en aza indiriyor hem de medyanla örtüşüyor;
  /// ayrıca web'de OpenGraph kapaklarının baskın oranı da yatay.
  static const double defaultAspectRatio = 16 / 9;

  /// Bozuk/uç değerlere karşı güvenlik sınırları. Aşırı yatay bir görsel kartı
  /// okunamayacak kadar inceltir, aşırı dikey olan ise ekranı kaplar.
  /// Ölçülen dağılımda uçlar 0.56 (9:16 dikey) ile 1.78 (16:9 yatay) arasında.
  /// Sınırlar bunun biraz dışında tutuldu: dışına taşan görsel kırpılır ama
  /// kutu kararlı kalır.
  static const double minAspectRatio = 0.5;
  static const double maxAspectRatio = 2.0;

  /// Ekleme sırası korunan harita; sıra LRU tahliyesi için kullanılıyor.
  final Map<String, double> _ratios = <String, double>{};

  SharedPreferences? _prefs;
  Timer? _persistTimer;

  /// Kalıcı haritayı belleğe alır. `main()` içinde, ilk kare çizilmeden önce
  /// çağrılmalıdır; aksi halde ilk açılışta oranlar bilinmez.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs?.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is num && value.isFinite && value > 0) {
          _ratios[entry.key as String] = value.toDouble();
        }
      }
    } catch (_) {
      // Önbellek en iyi çaba (best effort) çalışır; bozuk veri sessizce yok
      // sayılır, uygulama varsayılan oranla devam eder.
      _ratios.clear();
    }
  }

  /// [url] için bilinen oran, yoksa `null`.
  double? ratioFor(String? url) {
    if (url == null || url.isEmpty) return null;
    final key = _keyFor(url);
    final ratio = _ratios[key];
    if (ratio == null) return null;
    // Erişileni sona taşı: LRU sırasını güncel tut.
    _ratios
      ..remove(key)
      ..[key] = ratio;
    return ratio;
  }

  /// [url] için ölçülen gerçek oranı kaydeder.
  void record(String? url, double ratio) {
    if (url == null || url.isEmpty) return;
    if (!ratio.isFinite || ratio <= 0) return;
    final clamped = ratio.clamp(minAspectRatio, maxAspectRatio).toDouble();
    final key = _keyFor(url);
    if (_ratios[key] == clamped) return;
    _ratios
      ..remove(key)
      ..[key] = clamped;
    while (_ratios.length > maxEntries) {
      _ratios.remove(_ratios.keys.first);
    }
    _schedulePersist();
  }

  /// Yazmaları toplu hale getirir: ilk açılışta onlarca görsel aynı anda
  /// yüklendiği için her kayıtta diske yazmak gereksiz I/O yaratır.
  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 2), _persist);
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_prefsKey, jsonEncode(_ratios));
    } catch (_) {
      // Yazılamazsa oran bellekte kalır; yalnızca kalıcılık kaybedilir.
    }
  }

  /// URL'i kısa, kararlı bir anahtara indirger (FNV-1a 64-bit).
  ///
  /// URL'lerin tamamını saklamak SharedPreferences'ta gereksiz yer kaplar;
  /// `String.hashCode` ise çalışmalar arasında kararlı olduğu garanti
  /// edilmediği için kalıcı anahtar olarak kullanılamaz.
  static String _keyFor(String url) {
    const int fnvOffset = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    var hash = fnvOffset;
    for (final unit in utf8.encode(url)) {
      hash ^= unit;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  /// Yalnızca testler için: belleği ve zamanlayıcıyı sıfırlar.
  void resetForTest() {
    _persistTimer?.cancel();
    _persistTimer = null;
    _ratios.clear();
    _prefs = null;
  }
}
