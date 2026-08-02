import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:somine_app/core/utils/auth_image_provider.dart';
import 'package:somine_app/core/utils/image_aspect_ratio_cache.dart';
import 'package:somine_app/widgets/image_shimmer_placeholder.dart';

/// Masonry ızgarasındaki kart görselini, kutusu sıçramadan gösterir.
///
/// Sorun: masonry modunda yer tutucu sabit bir orana (kare) sahipken gerçek
/// görsel kendi doğal oranında çiziliyordu. Görsel gelince kutunun yüksekliği
/// değişiyor, kart ve altındaki tüm sütun yeniden yerleşiyordu; kullanıcı bunu
/// "önce geniş, sonra fit" olarak görüyordu.
///
/// Çözüm: hem yer tutucu hem görsel **aynı** [AspectRatio] kutusunun içine
/// konur. Kutu daha ilk karede doğru yükseklikte çizilirse hiç sıçrama olmaz.
///
/// Oran şu sırayla çözülür:
///   1. [knownAspectRatio] — item ile birlikte sunucudan gelen og:image boyutu.
///      Kaydetme anında ölçülüp saklandığı için **her** cihazda, ilk
///      görüntülemede bile bilinir. Bu geldiğinde ölçüm de önbellek yazımı da
///      gereksizdir.
///   2. [ImageAspectRatioCache] — bu cihazda daha önce ölçülmüş oran. Sunucuda
///      boyutu olmayan eski kayıtlar için hâlâ gerekli.
///   3. [ImageAspectRatioCache.defaultAspectRatio] — hiçbiri yoksa 16:9.
///
/// 2. yolda oran ilk kez öğrenildiğinde önbelleğe yazılır; o tek seferlik
/// yerleşme dışında kutu bir daha kımıldamaz.
class MasonryImage extends StatefulWidget {
  const MasonryImage({
    super.key,
    required this.imageUrl,
    required this.errorBuilder,
    this.knownAspectRatio,
  });

  /// `http(s)://`, `data:` veya asset yolu olabilir.
  final String imageUrl;

  /// Görsel yüklenemediğinde gösterilecek yedek görünüm.
  final WidgetBuilder errorBuilder;

  /// Sunucudan gelen, önceden bilinen genişlik / yükseklik oranı.
  ///
  /// `null` ise oran yerel önbellekten okunur veya ölçülür.
  final double? knownAspectRatio;

  @override
  State<MasonryImage> createState() => _MasonryImageState();
}

class _MasonryImageState extends State<MasonryImage> {
  double? _ratio;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageProvider? _measuredProvider;
  bool _measurementScheduled = false;

  @override
  void initState() {
    super.initState();
    _ratio = _resolveKnownRatio();
  }

  /// Sunucu boyutu → yerel önbellek sırası. İkisi de yoksa `null` döner ve
  /// ölçüm başlatılır.
  double? _resolveKnownRatio() {
    final fromServer = widget.knownAspectRatio;
    if (fromServer != null && fromServer.isFinite && fromServer > 0) {
      // Yerel ölçümle aynı sınırlara çekilir; aksi halde aynı görsel sunucu
      // oranıyla farklı, ölçülen oranla farklı bir kutu boyu alırdı.
      return fromServer
          .clamp(
            ImageAspectRatioCache.minAspectRatio,
            ImageAspectRatioCache.maxAspectRatio,
          )
          .toDouble();
    }
    return ImageAspectRatioCache.instance.ratioFor(widget.imageUrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Yerel kaynaklar (data:/asset) ağ beklemeden ölçülebilir; oranı ilk
    // karelerde öğrenip sıçramayı kısaltır.
    if (_ratio == null) _startMeasurement();
  }

  @override
  void didUpdateWidget(covariant MasonryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.knownAspectRatio != widget.knownAspectRatio) {
      _detachListener();
      _measuredProvider = null;
      _ratio = _resolveKnownRatio();
      if (_ratio == null) _startMeasurement();
    }
  }

  @override
  void dispose() {
    _detachListener();
    super.dispose();
  }

  void _detachListener() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _stream = null;
    _listener = null;
  }

  /// Oranı öğrenmek için görseli ayrıca çözer.
  ///
  /// Görselin kendisi [buildAuthImage] tarafından çizilir; oraya karışılmaz
  /// (denendi: `imageBuilder` ile araya girmek CachedNetworkImage'in kendi
  /// yerleşimini bozup görselin kutuyu doldurmamasına yol açıyor). Bunun yerine
  /// aynı sağlayıcı burada ikinci kez kurulur: `CachedNetworkImageProvider`
  /// aynı url + cacheKey ile eşit sayıldığı için Flutter'ın görsel önbelleği
  /// tek bir indirme/çözme yapar.
  void _measureNetworkSource() {
    if (_measurementScheduled) return;
    final url = widget.imageUrl;
    _measurementScheduled = true;
    resolveImageHeaders(url)
        .then((headers) {
          _measurementScheduled = false;
          // Ölçüm başlatıldığından beri kart geri dönüştürülüp başka bir öğeye
          // bağlanmış olabilir; oranı yanlış URL'ye yazmamak için kontrol et.
          if (!mounted || widget.imageUrl != url) return;
          _measure(
            CachedNetworkImageProvider(
              url,
              headers: headers,
              cacheKey: isApiStorageUrl(url) ? '${url}_auth' : null,
            ),
            url,
          );
        })
        .catchError((_) {
          _measurementScheduled = false;
        });
  }

  void _measureLocalSource() {
    final url = widget.imageUrl;
    try {
      final provider =
          url.startsWith('data:')
              ? MemoryImage(
                const Base64Decoder().convert(url.split(',').last),
              )
              : AssetImage(url) as ImageProvider;
      _measure(provider, url);
    } catch (_) {
      // Bozuk data: URI — errorBuilder zaten devreye girecek.
    }
  }

  void _startMeasurement() {
    if (widget.imageUrl.startsWith('http')) {
      _measureNetworkSource();
    } else {
      _measureLocalSource();
    }
  }

  void _measure(ImageProvider provider, String url) {
    if (identical(_measuredProvider, provider)) return;
    _measuredProvider = provider;
    _detachListener();

    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        final width = info.image.width.toDouble();
        final height = info.image.height.toDouble();
        if (height <= 0 || width <= 0) return;
        final ratio = width / height;
        // Ölçüm başlatıldığından beri widget başka bir öğeye bağlandıysa bu
        // sonucu ne önbelleğe yaz ne de kutuya uygula.
        if (!mounted || widget.imageUrl != url) return;
        ImageAspectRatioCache.instance.record(url, ratio);
        final clamped =
            ratio
                .clamp(
                  ImageAspectRatioCache.minAspectRatio,
                  ImageAspectRatioCache.maxAspectRatio,
                )
                .toDouble();
        if (_ratio == clamped) return;
        setState(() => _ratio = clamped);
      },
      onError: (_, __) {
        // Ölçüm başarısız: varsayılan oranla devam edilir.
      },
    );
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ratio ?? ImageAspectRatioCache.defaultAspectRatio;
    final url = widget.imageUrl;

    final Widget image;
    if (url.startsWith('http')) {
      image = buildAuthImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        alignment: Alignment.center,
        placeholder: (context, _) => const ImageShimmerPlaceholder(),
        errorWidget: (context, _, __) => widget.errorBuilder(context),
      );
    } else if (url.startsWith('data:')) {
      image = Image.memory(
        const Base64Decoder().convert(url.split(',').last),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        errorBuilder: (context, _, __) => widget.errorBuilder(context),
      );
    } else {
      image = Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        errorBuilder: (context, _, __) => widget.errorBuilder(context),
      );
    }

    // İlk görüntülemedeki tek seferlik yerleşmeyi yumuşatmak için AnimatedSize
    // denendi ve kaldırıldı: önbellek dolduktan sonra oran zaten ilk karede
    // doğru olduğu için animasyon neredeyse hiç tetiklenmiyor, buna karşılık
    // her kare masonry şeridini yeniden yerleştirme riski taşıyordu.
    return AspectRatio(aspectRatio: ratio, child: image);
  }
}
