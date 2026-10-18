import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/map_coordinate.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:somine_app/core/services/storage_service.dart';
import 'package:somine_app/core/services/metadata_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
// import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/widgets/circle_icon_button.dart';
import 'package:somine_app/widgets/brand_gradient.dart';
import 'package:somine_app/widgets/confirm_dialogs.dart';
import 'package:somine_app/widgets/item_detail_bottom_sheet.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart' as net;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/utils/auth_image_provider.dart';
import 'package:somine_app/core/utils/content_preview_policy.dart';
import 'package:somine_app/core/models/reminder_model.dart';
import 'package:somine_app/core/repositories/reminder_repository.dart';
import 'package:somine_app/core/services/analytics_service.dart';
import 'package:somine_app/core/services/widget_data_service.dart';
import 'package:somine_app/core/services/reminder_scheduler_service.dart';
import 'package:somine_app/widgets/reminder_picker_bottom_sheet.dart';
import 'package:somine_app/core/providers/subscription_provider.dart';
import 'package:somine_app/widgets/limit_reached_dialog.dart';
import 'package:somine_app/core/utils/date_display.dart';
import 'package:somine_app/core/utils/category_display.dart';
import 'package:somine_app/core/utils/failure_mapper.dart';

/// AddContentScreen pop sözleşmesi: başarıda `Navigator.pop(context, AddContentResult(...))`
/// döner (eskiden `true` idi). Çağıranlar `result != null` / `result is AddContentResult`
/// kontrolü yapar. Yalnız YENİ kayıtta `createdItemId` dolu gelir — edit/silme
/// akışlarında boş `AddContentResult()` döner (hızlı hatırlatıcı gösterilmez).
class AddContentResult {
  const AddContentResult({this.createdItemId, this.createdItemTitle});

  final String? createdItemId;
  final String? createdItemTitle;

  bool get isNewItem => createdItemId != null && createdItemId!.isNotEmpty;
}

class AddContentScreen extends ConsumerStatefulWidget {
  final String? initialText;
  final String? preSelectedCategoryId;
  final ItemModel? editItem; // For editing existing items

  const AddContentScreen({
    super.key,
    this.initialText,
    this.preSelectedCategoryId,
    this.editItem,
  });

  @override
  ConsumerState<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends ConsumerState<AddContentScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _linkController =
      TextEditingController(); // New Link Controller
  final CategoryRepository _categoryRepository = CategoryRepository();
  final ItemRepository _itemRepository = ItemRepository();

  // Animation (yalnız metadata yüklenirken platform arka planındaki
  // shimmer'ı sürer; Reduce Motion açıksa hiç çalışmaz).
  late AnimationController _loadingController;

  // Sheet boyutu: aşağı kaydırıp min boyuta inince kapatma (maybePop) ve
  // "Düzenlemeye devam et" sonrası tam boya geri dönme için.
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _isDismissPromptOpen = false;
  bool _dragDismissRequested = false;

  // Edit modunda başlangıç durumu; kaydedilmemiş değişiklik tespiti için.
  String? _initialEditSnapshot;

  // State
  bool _isSaving = false;
  bool _isLoadingMetadata = false;
  bool _isManualEntry = true; // Default to true (Skip splash)
  bool _isNoteMode = false; // Toggle between Note and Link mode

  // Clipboard State

  // Link Preview State
  bool _hasLink = false;
  String _detectedLink = "";
  String _detectedPlatform = "";
  OGMetadata? _ogMetadata;

  // Categories (Multi-Select)
  final Set<String> _selectedCategoryIds = {};
  bool _hizliChecked = false;

  // Dynamic Header Height
  double? _imageAspectRatio;

  // Önizleme görselinin ölçülen piksel boyutu ve ölçümün hangi URL'e ait
  // olduğu. Kaydederken item ile birlikte sunucuya gönderilir; böylece masonry
  // kutusu her cihazda ilk karede doğru oranı bilir (bkz. MasonryImage).
  // Ölçüm URL'i, sonuç geç geldiğinde başka bir görselin boyutunu yanlış
  // kayda yazmamak için tutulur.
  String? _measuredImageUrl;
  int? _measuredImageWidth;
  int? _measuredImageHeight;

  // Map Coordinate (for Google/Yandex maps displayed with Apple Maps)
  MapCoordinate? _mapCoordinate;

  // Note Image State (optional image attachment for notes)
  File? _selectedNoteImage;
  Uint8List? _noteImageBytes; // Store bytes to avoid File access issues
  String? _noteImageUrl; // For edit mode - existing image URL

  // Reminder State
  ReminderModel? _currentReminder;
  bool _hasReminder = false;

  // ============== COLORS ==============

  /// Checks if the current URL belongs to a known brand that uses logo as og:image
  /// Maps services are excluded - they return actual map images, not logos
  /// Optionally accepts a custom URL to check instead of _linkController.text
  bool _isKnownBrandSite([String? customUrl]) {
    final url = (customUrl ?? _linkController.text).toLowerCase();
    if (url.isEmpty) return false;

    // Exclude Maps services - they return real map images
    if (_isMapUrl(url)) return false;

    // Pinterest & TikTok return real content images (not logos), so exclude them
    if (url.contains('pinterest') ||
        url.contains('pin.it') ||
        url.contains('tiktok')) {
      return false;
    }

    final knownBrands = [
      'google',
      'youtube',
      'twitter',
      'x.com',
      'instagram',
      'facebook',
      'linkedin',
      'spotify',
      'github',
      'amazon',
      'apple',
      'microsoft',
      'adidas',
      'nike',
      'puma',
      'netflix',
      'discord',
      'slack',
      'notion',
      'figma',
      'twitch',
      'snapchat',
      'whatsapp',
      'telegram',
      'yandex',
      'stackoverflow',
      'gitlab',
      'bitbucket',
    ];

    return knownBrands.any((brand) => url.contains(brand));
  }

  /// Checks if the image URL appears to be a favicon (small logo image)
  bool _isFaviconUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return false;
    final lowerUrl = imageUrl.toLowerCase();
    return lowerUrl.contains('favicon') ||
        lowerUrl.contains('s2/favicons') ||
        lowerUrl.contains('/favicon.') ||
        lowerUrl.contains('icon=') ||
        lowerUrl.contains('googleusercontent.com/s2/favicons');
  }

  void _resolveImageSize(String imageUrl) async {
    if (imageUrl.isEmpty || imageUrl.toLowerCase().contains('.svg')) return;

    // X ve Maps URL'leri için görsel çözümleme yapma (sadece ikon gösterilecek)
    if (_isXUrl(_detectedLink.toLowerCase()) ||
        _isMapUrl(_detectedLink.toLowerCase())) {
      return;
    }

    // Fix stale IP address pointing to old server
    String correctedUrl = imageUrl;
    if (correctedUrl.contains('46.224.146.102')) {
      correctedUrl = correctedUrl.replaceAll(
        'http://46.224.146.102',
        ApiConfig.baseUrl,
      );
    }

    // Reset first
    setState(() {
      _imageAspectRatio = null;
      // Ölçüm bu URL'e ait; sonuç geldiğinde hâlâ güncel mi diye bakılır.
      // Kaynak (düzeltilmemiş) URL saklanır: kaydederken _ogMetadata.imageUrl
      // ile karşılaştırılacak.
      _measuredImageUrl = imageUrl;
      _measuredImageWidth = null;
      _measuredImageHeight = null;
    });

    final headers = await resolveImageHeaders(correctedUrl);
    if (!mounted) return;

    final ImageProvider provider = CachedNetworkImageProvider(
      correctedUrl,
      cacheKey: isApiStorageUrl(correctedUrl) ? '${correctedUrl}_auth' : null,
      headers: headers,
    );

    provider
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener(
            (ImageInfo info, bool synchronousCall) {
              if (!mounted) return;
              // Ölçüm başlatıldığından beri kullanıcı başka bir link/görsel
              // seçmiş olabilir; geç gelen sonucu yeni görselin üzerine yazma.
              if (_measuredImageUrl != imageUrl) return;
              final myImage = info.image;
              if (myImage.width <= 0 || myImage.height <= 0) return;
              setState(() {
                _imageAspectRatio = myImage.width / myImage.height;
                _measuredImageWidth = myImage.width;
                _measuredImageHeight = myImage.height;
              });
            },
            onError: (exception, stackTrace) {
              debugPrint("Image resolution error: $exception");
            },
          ),
        );
  }
  // Using AppColors constants directly now

  @override
  void initState() {
    super.initState();

    // Listeners for UI updates (Delete icon opacity)
    _titleController.addListener(() => setState(() {}));
    _noteController.addListener(() => setState(() {}));
    _linkController.addListener(() => setState(() {}));

    // Check clipboard on open to show notice (auto: true just sets the flag)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 4. Handle Edit Mode Initialization
      if (widget.editItem != null) {
        _initializeEditMode();
      } else if (widget.initialText != null && widget.initialText!.isNotEmpty) {
        _processUrl(widget.initialText!);
      } else {
        _checkClipboardAndProcess(auto: true);
      }
    });

    // Loading Animation (Heartbeat effect). Tekrarı didChangeDependencies'te
    // Reduce Motion ayarına göre başlatılır/durdurulur.
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_loadingController.isAnimating) _loadingController.stop();
    } else if (!_loadingController.isAnimating) {
      _loadingController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _linkController.dispose();
    _loadingController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _initializeEditMode() async {
    final item = widget.editItem!;

    // Set Mode
    _isNoteMode = item.type == ItemType.note;

    // Set Text Fields
    _titleController.text = item.displayTitle;
    _noteController.text = item.note ?? "";

    // Set Link
    if (item.url != null && item.url!.isNotEmpty) {
      _linkController.text = item.url!;
      _detectedLink = item.url!;
      _hasLink = true;
      _isManualEntry = false;
    }

    // Pre-fill metadata from item
    _ogMetadata = ContentPreviewPolicy.sanitizeMetadataForUrl(
      item.url,
      item.ogMetadata,
    );
    // Also fallback to generic imageUrl if OGMetadata lacks one
    if ((_ogMetadata == null || _ogMetadata!.imageUrl == null) &&
        !ContentPreviewPolicy.isMapUrl(item.url) &&
        item.imageUrl != null) {
      _ogMetadata = (_ogMetadata ?? const OGMetadata()).copyWith(
        imageUrl: item.imageUrl,
      );
    }
    if (ContentPreviewPolicy.canUsePreviewImage(
      url: item.url,
      imageUrl: _ogMetadata?.imageUrl,
    )) {
      _resolveImageSize(_ogMetadata!.imageUrl!);
    }

    // Set Note Image (for notes with images)
    if (_isNoteMode && item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      _noteImageUrl = item.imageUrl;
    } else if (_isNoteMode &&
        _ogMetadata?.imageUrl != null &&
        _ogMetadata!.imageUrl!.isNotEmpty) {
      _noteImageUrl = _ogMetadata!.imageUrl;
    }

    // Set Category
    if (item.categoryId != null) {
      _selectedCategoryIds.add(item.categoryId!);
    }

    // Load Reminder
    if (item.hasReminder) {
      await _loadReminder(item.id);
    }

    _initialEditSnapshot = _formSnapshot();
    if (mounted) setState(() {});
  }

  // ============== UNSAVED CHANGES ==============

  /// Formun kullanıcıya ait kısmının özeti (edit modunda karşılaştırma için).
  String _formSnapshot() {
    final categories = _selectedCategoryIds.toList()..sort();
    return [
      _isNoteMode,
      _titleController.text.trim(),
      _noteController.text.trim(),
      _linkController.text.trim(),
      categories.join(','),
      _noteImageBytes?.length ?? 0,
      _noteImageUrl ?? '',
      _hasReminder,
      _currentReminder?.reminderDate.toIso8601String() ?? '',
      _currentReminder == null
          ? ''
          : '${_currentReminder!.reminderTime.hour}:${_currentReminder!.reminderTime.minute}',
      _currentReminder?.repeat.name ?? '',
    ].join('|');
  }

  /// Kapatılırsa kaybolacak bir girdi var mı?
  bool get _hasUnsavedChanges {
    if (_isSaving) return false;
    if (widget.editItem != null) {
      final initial = _initialEditSnapshot;
      return initial != null && initial != _formSnapshot();
    }
    return _hasLink ||
        _titleController.text.trim().isNotEmpty ||
        _noteController.text.trim().isNotEmpty ||
        _linkController.text.trim().isNotEmpty ||
        _noteImageBytes != null;
  }

  /// Kirli formda kapatma isteği (barrier, X, aşağı kaydırma): onay sorar.
  Future<void> _confirmDiscardAndClose() async {
    if (_isDismissPromptOpen) return;
    _isDismissPromptOpen = true;
    final l10n = AppLocalizations.of(context)!;
    final discard = await showDiscardChangesSheet(
      context,
      title: l10n.addContentUnsavedTitle,
      discardLabel: l10n.addContentDiscardChanges,
      keepEditingLabel: l10n.addContentKeepEditing,
    );
    _isDismissPromptOpen = false;
    if (!mounted) return;
    if (discard) {
      Navigator.of(context).pop();
    } else {
      _restoreSheetSize();
    }
  }

  void _restoreSheetSize() {
    if (!_sheetController.isAttached || _sheetController.size >= 0.99) return;
    _sheetController.animateTo(
      1.0,
      duration:
          MediaQuery.disableAnimationsOf(context)
              ? const Duration(milliseconds: 1)
              : const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  /// Sheet min boyuta sürüklendiğinde kapatmayı dene (kirliyse onay sorulur).
  bool _onSheetExtentChanged(DraggableScrollableNotification notification) {
    final atMin = notification.extent <= notification.minExtent + 0.01;
    if (!atMin) {
      // Kullanıcı sheet'i yeniden yukarı çekti; bir sonraki iniş yine
      // kapatmayı tetikleyebilsin.
      if (notification.extent > notification.minExtent + 0.05) {
        _dragDismissRequested = false;
      }
      return false;
    }
    if (_dragDismissRequested || _isDismissPromptOpen) return false;
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      // Bildirimler min boyutta art arda gelir; tek bir kapatma isteği yolla.
      _dragDismissRequested = true;
      Navigator.of(context).maybePop();
    }
    return false;
  }

  // ============== BUSINESS LOGIC ==============

  Future<void> _ensureHizliCategory(List<CategoryModel> categories) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final hasHizli = categories.any(
      (c) => c.name.toLowerCase() == kQuickCategoryKey.toLowerCase(),
    );
    if (!hasHizli) {
      final now = DateTime.now();
      await _categoryRepository.createCategory(
        CategoryModel(
          id: '',
          userId: userId,
          name: kQuickCategoryKey,
          icon: '⚡',
          createdAt: now,
          updatedAt: now,
        ),
      );
      // Riverpod stream otomatik günceller, manuel refresh gerekmez
    }
  }

  Future<void> _checkClipboardAndProcess({bool auto = false}) async {
    // Phase 1: Checks for existence (Privacy safe on some versions)
    // If auto check, avoid reading data directly to prevent system toast/prompt
    if (auto) {
      final hasContent = await Clipboard.hasStrings();
      if (hasContent) {
        setState(() {
          // _isManualEntry = false; // logic removed - keep manual entry active
        });
      }
      return;
    }

    // Phase 2: Explicit Paste (User tapped button)
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;

    if (text != null && text.isNotEmpty && _isUrl(text)) {
      // Valid link found - Process immediately
      _processUrl(text);
    } else {
      // No URL found or invalid
      // If triggered manually by user (tapping button), open manual entry
      setState(() {
        _hasLink = false;
      });
    }
  }

  bool _isUrl(String text) {
    return RegExp(r'(https?:\/\/[^\s]+)').hasMatch(text);
  }

  String _detectPlatform(String url) {
    final lowerUrl = url.toLowerCase();

    // Maps Checks (Priority)
    if (lowerUrl.contains('maps.app.goo.gl') ||
        lowerUrl.contains('goo.gl/maps') ||
        lowerUrl.contains('google.com/maps') ||
        lowerUrl.contains('maps.google.com') ||
        lowerUrl.contains('share.google')) {
      return 'Maps';
    }

    if (lowerUrl.contains('yandex.com/maps') ||
        lowerUrl.contains('yandex.ru/maps') ||
        lowerUrl.contains('yandex.o')) {
      return 'Yandex Maps';
    }

    if (lowerUrl.contains('maps.apple.com')) return 'Apple Maps';
    if (lowerUrl.contains('openstreetmap.org')) return 'OpenStreetMap';

    if (lowerUrl.contains('instagram.com')) return 'Instagram';
    if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be')) {
      return 'YouTube';
    }

    // Fix: strict check for x.com to avoid matching 'yandex.com' logic
    if (lowerUrl.contains('twitter.com') ||
        lowerUrl.contains('//x.com') ||
        lowerUrl.contains('.x.com') ||
        (lowerUrl.contains('x.com') &&
            !lowerUrl.contains('yandex') &&
            !lowerUrl.contains('netflix') &&
            !lowerUrl.contains('box.com'))) {
      return 'X';
    }

    if (lowerUrl.contains('tiktok.com')) return 'TikTok';
    if (lowerUrl.contains('linkedin.com')) return 'LinkedIn';
    if (lowerUrl.contains('spotify.com')) return 'Spotify';
    if (lowerUrl.contains('pinterest.com')) return 'Pinterest';
    if (lowerUrl.contains('reddit.com')) return 'Reddit';
    if (lowerUrl.contains('medium.com')) return 'Medium';
    if (lowerUrl.contains('behance.net')) return 'Behance';
    if (lowerUrl.contains('dribbble.com')) return 'Dribbble';

    return 'Web';
  }

  void _processUrl(String text) {
    final urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');
    final match = urlRegExp.firstMatch(text);

    if (match != null) {
      String url = match.group(0)!;
      setState(() {
        _detectedLink = url;
        _linkController.text = url; // Sync controller
        _detectedPlatform = _detectPlatform(url);
        _hasLink = true;
        _isManualEntry = false; // Disable manual entry mode if link found
      });
      _fetchMetadata(url);
    } else {
      // Fallback to manual entry
      setState(() {
        _isManualEntry = true;
        _hasLink = false;
      });
    }
  }

  Future<void> _fetchMetadata(String url) async {
    setState(() => _isLoadingMetadata = true);
    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint('📍 [AddContent] Starting metadata fetch for: $url');
    debugPrint('📍 [AddContent] Is map URL: ${_isMapUrl(url)}');

    try {
      // Extract coordinates and place name from map URLs FIRST
      // DISABLED: Coordinate extraction for Google/Yandex as per user request
      // MapCoordinate? coordinate;

      // if (_isMapUrl(url)) {
      //   debugPrint('📍 [AddContent] Calling MapCoordinateService.extract()...');
      //   final startTime = DateTime.now();

      //   coordinate = await MapCoordinateService.extract(url);

      //   final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      //   debugPrint('📍 [AddContent] Extract took ${elapsed}ms');

      //   if (coordinate != null) {
      //     debugPrint('📍 [AddContent] Coordinate result:');
      //     debugPrint('   - lat: ${coordinate.latitude}');
      //     debugPrint('   - lng: ${coordinate.longitude}');
      //     debugPrint('   - valid: ${coordinate.isValid}');
      //     debugPrint('   - placeName: ${coordinate.placeName ?? "null"}');
      //     debugPrint('   - provider: ${coordinate.provider}');

      //     if (coordinate.isValid) {
      //       setState(() => _mapCoordinate = coordinate);
      //       debugPrint('✅ [AddContent] Coordinate state updated');
      //     } else {
      //       debugPrint('⚠️ [AddContent] Coordinate INVALID, not setting state');
      //       setState(() => _mapCoordinate = null);
      //     }
      //   } else {
      //     debugPrint('⚠️ [AddContent] Coordinate is NULL');
      //     setState(() => _mapCoordinate = null);
      //   }
      // }

      // Fetch OG metadata (includes place name extraction)
      debugPrint('📄 [AddContent] Calling MetadataService.fetchMetadata()...');
      final metadata = await MetadataService.fetchMetadata(url);

      if (mounted) {
        setState(() {
          if (metadata != null) {
            final descriptionPreview =
                metadata.description == null
                    ? 'null'
                    : metadata.description!.length <= 50
                    ? metadata.description!
                    : '${metadata.description!.substring(0, 50)}...';

            debugPrint('📄 [AddContent] Metadata received:');
            debugPrint('   - title: ${metadata.title ?? "null"}');
            debugPrint('   - description: $descriptionPreview');
            debugPrint('   - imageUrl: ${metadata.imageUrl ?? "null"}');

            final sanitizedMetadata =
                ContentPreviewPolicy.sanitizeMetadataForUrl(
                  url,
                  OGMetadata(
                    title: metadata.title,
                    description: metadata.description,
                    imageUrl: metadata.imageUrl,
                    siteName: metadata.siteName ?? _detectedPlatform,
                  ),
                );

            _ogMetadata = sanitizedMetadata;

            if (sanitizedMetadata?.imageUrl != null) {
              _resolveImageSize(sanitizedMetadata!.imageUrl!);
            }

            // DISABLED: Fallback coordinate extraction from MapKit snapshots
            // if (_mapCoordinate == null &&
            //     metadata.imageUrl?.contains('apple-mapkit.com') == true) {
            //   debugPrint('🗺️ [AddContent] Trying MapKit snapshot fallback...');

            //   final match = RegExp(r'center=(-?\d+\.?\d*),(-?\d+\.?\d*)')
            //       .firstMatch(metadata.imageUrl!);

            //   if (match != null) {
            //     final lat = double.tryParse(match.group(1) ?? '');
            //     final lng = double.tryParse(match.group(2) ?? '');

            //     if (lat != null && lng != null) {
            //       debugPrint('✅ [AddContent] Extracted from snapshot: $lat, $lng');

            //       // Detect provider from URL
            //       MapProvider provider = MapProvider.unknown;
            //       if (_isGoogleMapsUrl(url)) {
            //         provider = MapProvider.googleMaps;
            //       } else if (_isYandexMapsUrl(url)) {
            //         provider = MapProvider.yandexMaps;
            //       } else if (_isAppleMapsUrl(url)) {
            //         provider = MapProvider.appleMaps;
            //       }

            //       _mapCoordinate = MapCoordinate(
            //         latitude: lat,
            //         longitude: lng,
            //         originalUrl: url,
            //         provider: provider,
            //         placeName: null, // Will try to get from metadata title below
            //       );
            //       debugPrint('✅ [AddContent] Fallback coordinate set');
            //     }
            //   }
            // }

            // Note: If no coordinates found, HTML extraction will be attempted
            // by MapCoordinateService as a fallback mechanism
          } else {
            debugPrint('⚠️ [AddContent] Metadata is NULL');
          }

          // UNIFIED TITLE LOGIC - Check all sources in priority order
          if (_titleController.text.isEmpty) {
            String? titleToUse;

            // DISABLED: Priority 1: Coordinate place name (most specific)
            // if (coordinate?.placeName != null &&
            //     coordinate!.placeName!.isNotEmpty) {
            //   titleToUse = coordinate.placeName;
            //   debugPrint('📍 [AddContent] Using coordinate place name: $titleToUse');
            // }
            // Priority 1: Metadata title (may contain extracted place name)
            if (metadata?.title != null && metadata!.title!.isNotEmpty) {
              // Filter out generic titles for maps
              final isGeneric = _isGenericMapsTitle(metadata.title!);
              if (!isGeneric) {
                titleToUse = metadata.title;
                debugPrint('📄 [AddContent] Using metadata title: $titleToUse');
              } else {
                debugPrint(
                  '⚠️ [AddContent] Metadata title is generic, skipping: ${metadata.title}',
                );
              }
            }

            if (titleToUse != null) {
              _titleController.text = titleToUse;
            }
          }
        });

        // debugPrint('📍 [AddContent] Final _mapCoordinate state: ${_mapCoordinate != null ? "SET" : "NULL"}');

        // If no coordinates were found, log a helpful message
        if (_mapCoordinate == null && metadata?.title != null) {
          debugPrint(
            '⚠️ [AddContent] Could not extract coordinates for: ${metadata!.title}',
          );
          debugPrint(
            '⚠️ [AddContent] HTML extraction was attempted but no patterns matched',
          );
        }
      }
    } catch (e) {
      debugPrint("🔴 [AddContent] Metadata fetch error: $e");
      debugPrint(
        '════════════════════════════════════════════════════════════',
      );
    } finally {
      if (mounted) setState(() => _isLoadingMetadata = false);
      debugPrint(
        '════════════════════════════════════════════════════════════',
      );
    }
  }

  /// Checks if title is a generic maps title that should be ignored
  bool _isGenericMapsTitle(String title) {
    final genericTitles = [
      'google',
      'google maps',
      'google haritalar',
      'apple maps',
      'yandex',
      'yandex maps',
      'yandex haritalar',
      'maps',
      'haritalar',
      'harita',
    ];

    final lowerTitle = title.toLowerCase().trim();
    return genericTitles.any(
      (term) =>
          lowerTitle == term ||
          lowerTitle == '$term - harita' ||
          lowerTitle.startsWith('$term '),
    );
  }

  // Handle Link Edit
  void _onLinkChanged(String value) {
    if (value.isEmpty) {
      _clearLinkField();
      return;
    }

    if (_isUrl(value)) {
      final urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');
      final match = urlRegExp.firstMatch(value);
      if (match != null) {
        String url = match.group(0)!;

        // Extract place name from Map shares (Google, Yandex, Apple)
        // Format: "Place Name\nhttps://..." or "Place Name https://..."
        String? extractedTitle;
        if (_isMapUrl(url)) {
          final beforeUrl = value.substring(0, match.start).trim();
          if (beforeUrl.isNotEmpty) {
            // Clean up the title (remove newlines, extra spaces)
            extractedTitle = beforeUrl.replaceAll('\n', ' ').trim();
            debugPrint('📍 [AddContent] Extracted Map place: $extractedTitle');
          }
        }

        if (url != _detectedLink) {
          setState(() {
            _detectedLink = url;
            _detectedPlatform = _detectPlatform(url);
            _hasLink = true;
            _isManualEntry = false;

            // Pre-fill title for Maps
            if (extractedTitle != null && _titleController.text.isEmpty) {
              _titleController.text = extractedTitle;
            }
          });
          _fetchMetadata(url);
        }
      }
    } else {
      // Invalid URL, maybe reset platform to default?
      setState(() {
        _detectedPlatform = "Web";
      });
    }
  }

  /// Check if URL is any known Map link
  bool _isMapUrl(String url) {
    return ContentPreviewPolicy.isMapUrl(url);
  }

  /// Check if URL is X (Twitter) link
  bool _isXUrl(String url) {
    return ContentPreviewPolicy.isXUrl(url);
  }

  bool _shouldPersistRemoteMetadataImage(String imageUrl) {
    final lower = imageUrl.toLowerCase();
    if (lower.endsWith('.svg')) return false;
    if (lower.contains('/emoji/') || lower.contains('twemoji')) return false;
    // Don't persist favicon images - they're too small and will be blurry
    if (_isFaviconUrl(imageUrl)) return false;
    return true;
  }

  bool _isGoogleMapsUrl(String url) {
    return ContentPreviewPolicy.isGoogleMapsUrl(url);
  }

  bool _isYandexMapsUrl(String url) {
    return ContentPreviewPolicy.isYandexMapsUrl(url);
  }

  bool _isAppleMapsUrl(String url) {
    return ContentPreviewPolicy.isAppleMapsUrl(url);
  }

  void _clearLinkField() {
    setState(() {
      _detectedLink = "";
      _detectedPlatform = "";
      _ogMetadata = null;
      _hasLink = false;
      _isManualEntry = true; // Keep manual entry active
      _titleController.clear();
      _noteController.clear();
      _mapCoordinate = null; // Reset map coordinate
      _clearMeasuredImageSize();
    });
  }

  /// Ölçülen görsel boyutunu düşürür. Görsel değiştiğinde çağrılmalı; aksi
  /// halde bir önceki görselin boyutu yeni içerikle birlikte kaydedilirdi.
  void _clearMeasuredImageSize() {
    _measuredImageUrl = null;
    _measuredImageWidth = null;
    _measuredImageHeight = null;
  }

  /// Oluşturma modundaki çöp kutusu: girilen her şeyi silmeden önce onay.
  Future<void> _confirmClearContent() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDestructiveConfirmDialog(
      context,
      title: l10n.addContentClearConfirmTitle,
      confirmLabel: l10n.addContentClearAction,
      cancelLabel: l10n.commonCancel,
    );
    if (confirmed && mounted) _clearContent();
  }

  void _clearContent() {
    setState(() {
      _ogMetadata = null;
      _hasLink = false;
      _detectedLink = "";
      _detectedPlatform = "";
      _titleController.clear();
      _noteController.clear();
      _linkController.clear(); // Clear link input
      _isManualEntry = true; // Always return to manual entry form
      _selectedNoteImage = null;
      _noteImageBytes = null;
      _noteImageUrl = null;
      _mapCoordinate = null; // Reset map coordinate
      _clearMeasuredImageSize();
    });
  }

  /// Shows a bottom sheet to pick image from gallery or camera
  void _pickNoteImage() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.surfaceWhite,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: context.colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  l10n.addContentImagePickerTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.headline,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Gallery Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.colors.primary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                PhosphorIconsBold.images,
                                size: 32,
                                color: context.colors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.addContentGallery,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.headline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Camera Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: context.colors.secondary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.colors.secondary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                PhosphorIconsBold.camera,
                                size: 32,
                                color: context.colors.secondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.addContentCamera,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.headline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1080, // Compress to max 1080px width
        maxHeight: 1080, // Compress to max 1080px height
        imageQuality: 80, // 80% quality for good balance
      );

      if (pickedFile != null && mounted) {
        // Read bytes immediately to avoid File access issues later
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedNoteImage = File(pickedFile.path);
          _noteImageBytes = bytes; // Store bytes
          _noteImageUrl = null; // Clear any existing URL
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        _showError(AppLocalizations.of(context)!.addContentImagePickFailed);
      }
    }
  }

  void _removeNoteImage() {
    // Delete from Storage if it's a Storage URL (not base64)
    if (_noteImageUrl != null && !_noteImageUrl!.startsWith('data:')) {
      final storageService = StorageService();
      storageService.deleteFile(_noteImageUrl!);
      debugPrint('🗑️ Note image deleted from Storage');
    }

    setState(() {
      _selectedNoteImage = null;
      _noteImageBytes = null;
      _noteImageUrl = null;
    });
  }

  Future<void> _saveContent() async {
    final l10n = AppLocalizations.of(context)!;

    if (_isSaving) return;

    // Validation: Note mode requires both title and note
    if (_isNoteMode) {
      if (_titleController.text.trim().isEmpty) {
        _showError(l10n.addContentTitleRequired);
        return;
      }
      if (_noteController.text.trim().isEmpty) {
        _showError(l10n.addContentNoteRequired);
        return;
      }
    } else if (_titleController.text.isEmpty &&
        _noteController.text.isEmpty &&
        !_hasLink) {
      return;
    }
    // If no category selected, silently assign to "Hızlı"
    if (_selectedCategoryIds.isEmpty) {
      final quickCat = (ref.read(categoriesProvider).value ?? [])
          .cast<CategoryModel?>()
          .firstWhere((c) => c!.name == kQuickCategoryKey, orElse: () => null);
      if (quickCat != null) {
        _selectedCategoryIds.add(quickCat.id);
      } else {
        _showError(l10n.addContentSelectCategory);
        return;
      }
    }

    // --- DUPLICATE LINK CHECK (create mode) ---
    if (widget.editItem == null && !_isNoteMode && _hasLink) {
      final proceed = await _confirmIfDuplicateLink(l10n);
      if (!proceed || !mounted) return;
    }

    // --- ITEM LIMIT CHECK FOR STARTER TIER ---
    final subState = ref.read(subscriptionProvider);
    final subNotifier = ref.read(subscriptionProvider.notifier);
    if (!subState.isPremium) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Is at least one genuinely new item being created (not just editing
        // the existing item within its original category)?
        final originalCatId = widget.editItem?.categoryId;
        final isNewAdd =
            widget.editItem == null ||
            _selectedCategoryIds.any((catId) => catId != originalCatId);

        if (isNewAdd) {
          final totalItemCount = await ref.read(itemCountProvider.future);
          if (!subNotifier.canAddItem(totalItemCount)) {
            if (mounted) {
              LimitReachedDialog.show(
                context: context,
                ref: ref,
                title: l10n.limitItemTitle,
                message: l10n.limitItemReachedDescription(500),
                type: LimitType.item,
              );
            }
            return;
          }
        }
      }
    }
    // --- END LIMIT CHECK ---

    setState(() => _isSaving = true);
    final storageService = StorageService();

    try {
      final now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        if (mounted) _showError(l10n.addContentLoginRequired);
        return;
      }

      // Masonry kutusunun oranını sunucuda saklayabilmek için ölçülen boyutu
      // burada, kalıcı depoya yükleme URL'i değiştirmeden ÖNCE sabitle.
      // Yükleme yalnız adresi değiştirir, görselin pikselleri aynı kalır.
      final measuredForImageUrl = _ogMetadata?.imageUrl;
      final bool hasMeasuredOgImageSize =
          measuredForImageUrl != null &&
          _measuredImageUrl == measuredForImageUrl &&
          _measuredImageWidth != null &&
          _measuredImageHeight != null;

      // Check for remote image and process if needed
      if (_ogMetadata?.imageUrl != null &&
          !_ogMetadata!.imageUrl!.contains('firebasestorage') &&
          _shouldPersistRemoteMetadataImage(_ogMetadata!.imageUrl!)) {
        // Only attempt upload if it looks like an external URL
        final persistentUrl = await storageService.uploadImageFromUrl(
          _ogMetadata!.imageUrl!,
          userId,
        );

        if (!mounted) return;

        // Use Firebase Storage URL if upload succeeded, otherwise KEEP original URL
        _ogMetadata = OGMetadata(
          title: _ogMetadata!.title,
          description: _ogMetadata!.description,
          imageUrl:
              persistentUrl ?? _ogMetadata!.imageUrl, // Fallback to original!
          siteName: _ogMetadata!.siteName,
        );
      }

      // FIX: Note mode should save title in ogMetadata.title and content in note field
      final noteText = _noteController.text.trim();
      final titleText = _titleController.text.trim();

      // Handle note image upload
      String? noteImageUrl = _noteImageUrl; // Existing URL (edit mode)

      if (_isNoteMode && _noteImageBytes != null) {
        // Upload to Firebase Storage
        try {
          final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final path = 'items/$userId/$fileName';
          noteImageUrl = await storageService.uploadBytes(
            _noteImageBytes!,
            path,
          );
          debugPrint('📸 Note image uploaded: $noteImageUrl');

          // Delete old image from Storage if it was a Storage URL (not base64)
          if (_noteImageUrl != null && !_noteImageUrl!.startsWith('data:')) {
            await storageService.deleteFile(_noteImageUrl!);
            debugPrint('🗑️ Old note image deleted from Storage');
          }
        } catch (e) {
          debugPrint("Error uploading note image: $e");
        }
      }

      // Determine final metadata: Prioritize USER INPUT over fetched metadata
      OGMetadata? finalMetadata;

      if (_isNoteMode) {
        // Note mode: Title + optional image
        finalMetadata = OGMetadata(
          title: titleText.isNotEmpty ? titleText : null,
          imageUrl: noteImageUrl, // Include optional image
        );
      } else {
        // Link mode: Use existing metadata BUT override with user title if provided
        finalMetadata =
            _ogMetadata?.copyWith(
              title: titleText.isNotEmpty ? titleText : _ogMetadata?.title,
              // Keep other fields (image, description, etc.) from fetched metadata
            ) ??
            OGMetadata(title: titleText.isNotEmpty ? titleText : null);
      }

      finalMetadata = ContentPreviewPolicy.sanitizeMetadataForUrl(
        _detectedLink,
        finalMetadata,
      );

      // Boyut yalnızca gerçekten kaydedilen görsele aitse gönderilir. Note
      // modunda kaydedilen görsel note görselidir; kullanıcı yeni bir görsel
      // seçtiyse (bytes yüklendiyse) ölçüm ona ait değildir. Emin olunamayan
      // her durumda null gider ve istemci yerel önbelleğe/varsayılana düşer —
      // eski davranış, kırılma yok.
      final bool sendOgImageSize =
          hasMeasuredOgImageSize &&
          finalMetadata?.imageUrl != null &&
          (!_isNoteMode ||
              (_noteImageBytes == null && noteImageUrl == measuredForImageUrl));
      final int? ogImageWidth = sendOgImageSize ? _measuredImageWidth : null;
      final int? ogImageHeight = sendOgImageSize ? _measuredImageHeight : null;

      // --- EDIT MODE START ---
      if (widget.editItem != null) {
        final originalCatId = widget.editItem!.categoryId;
        final Set<String> targetIds = Set.from(_selectedCategoryIds);
        String primaryTargetId;

        if (originalCatId != null && targetIds.contains(originalCatId)) {
          primaryTargetId = originalCatId;
          targetIds.remove(originalCatId);
        } else {
          primaryTargetId = targetIds.first;
          targetIds.remove(primaryTargetId);
        }

        final updatedItem = widget.editItem!.copyWith(
          categoryId: primaryTargetId,
          type:
              _isNoteMode
                  ? ItemType.note
                  : (_hasLink ? ItemType.link : ItemType.note),
          url: _isNoteMode ? null : (_hasLink ? _detectedLink : null),
          note: noteText.isNotEmpty ? noteText : null,
          ogMetadata: finalMetadata,
          // Ölçüm yapılamadıysa null geçilir; copyWith null'ı "değişmedi"
          // sayarak mevcut boyutu korur, sunucu da PUT'ta null'ı yok sayar.
          ogImageWidth: ogImageWidth,
          ogImageHeight: ogImageHeight,
          updatedAt: DateTime.now(),
        );

        await _itemRepository.updateItem(updatedItem);

        // Handle reminder
        await _handleReminderAfterSave(updatedItem.id, titleText);

        // Create clones for other selected categories
        if (targetIds.isNotEmpty) {
          final results = <String, bool>{};
          Object? lastError;
          for (final catId in targetIds) {
            try {
              final clone = updatedItem.copyWith(
                id: '', // New ID
                categoryId: catId,
                createdAt: now,
                updatedAt: now,
              );
              await _itemRepository.createItem(clone);
              results[catId] = true;
            } catch (e) {
              debugPrint('Failed to create clone for category $catId: $e');
              results[catId] = false;
              lastError = e;
            }
          }

          // Check for partial success
          final successCount = results.values.where((v) => v).length;
          final failCount = results.values.where((v) => !v).length;

          if (failCount > 0 && failCount < results.length) {
            // Partial success - show warning but continue
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.addContentPartialSuccess(successCount, results.length),
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else if (failCount == results.length) {
            // All failed — hata sheet'in İÇİNDE gösterilir (Home'un
            // Scaffold'una düşen SnackBar tam boy sheet'in altında kalıyordu).
            if (mounted) {
              _showError(_saveFailureMessage(lastError, l10n));
              return; // Don't close the screen
            }
          }
        }

        await _maybeShowItemLimitWarning();
        _logContentAddAnalytics(updatedItem.type);
        _syncHomeWidgetData();
        if (mounted) {
          // Edit modu: yeni kayıt bilgisi taşınmaz (hızlı hatırlatıcı yok).
          Navigator.pop(context, const AddContentResult());
        }
      }
      // --- CREATE MODE START ---
      else {
        // Create items for each selected category with error tracking
        final results = <String, bool>{};
        ItemModel? firstSuccessfulItem;
        Object? lastError;

        for (final catId in _selectedCategoryIds) {
          try {
            final newItem = ItemModel(
              id: '',
              userId: userId,
              categoryId: catId,
              type:
                  _isNoteMode
                      ? ItemType.note
                      : (_hasLink ? ItemType.link : ItemType.note),
              url: _isNoteMode ? null : (_hasLink ? _detectedLink : null),
              note: noteText.isNotEmpty ? noteText : null,
              ogMetadata: finalMetadata,
              ogImageWidth: ogImageWidth,
              ogImageHeight: ogImageHeight,
              createdAt: now,
              updatedAt: now,
            );
            final createdItem = await _itemRepository.createItem(newItem);
            results[catId] = true;

            // Store first successful item for reminder
            firstSuccessfulItem ??= createdItem;
          } catch (e) {
            debugPrint('Failed to create item for category $catId: $e');
            results[catId] = false;
            lastError = e;
          }
        }

        // Check for partial success
        final successCount = results.values.where((v) => v).length;
        final failCount = results.values.where((v) => !v).length;

        if (failCount == results.length) {
          // All failed — hata sheet'in içinde, link/girdi korunarak gösterilir.
          if (mounted) _showError(_saveFailureMessage(lastError, l10n));
          return; // Don't close the screen
        }

        // Handle reminder (only for first successful item)
        if (firstSuccessfulItem != null) {
          await _handleReminderAfterSave(firstSuccessfulItem.id, titleText);
        }

        // Show partial success warning if needed
        if (failCount > 0 && failCount < results.length) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.addContentPartialSuccess(successCount, results.length),
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        await _maybeShowItemLimitWarning();
        _logContentAddAnalytics(firstSuccessfulItem?.type ?? ItemType.note);
        _syncHomeWidgetData();
        if (mounted) {
          Navigator.pop(
            context,
            AddContentResult(
              createdItemId: firstSuccessfulItem?.id,
              createdItemTitle:
                  titleText.isNotEmpty
                      ? titleText
                      : firstSuccessfulItem?.displayTitle,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Save error: $e");
      if (mounted) _showError(_saveFailureMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Başarılı kayıt sonrası analitik: content_add + (ilk kayıtta) activation.
  /// Fire-and-forget; akışı asla bozmaz.
  void _logContentAddAnalytics(ItemType type) {
    final source =
        (widget.initialText != null && widget.initialText!.isNotEmpty)
            ? 'share_ext'
            : 'app';
    // ref yerine singleton: await sonrası dispose edilmiş ref kullanımı
    // istisna fırlatıp kayıt akışını bozmasın.
    AnalyticsService.instance
      ..logContentAdd(type: type.name, source: source)
      ..logActivation();
  }

  /// Başarılı kayıt sonrası iOS ana ekran widget'ı verisini tazeler.
  /// Fire-and-forget; hatalar WidgetDataService içinde yutulur.
  void _syncHomeWidgetData() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    unawaited(WidgetDataService().sync(userId));
  }

  /// Starter planında toplam içerik sayısı yumuşak uyarı eşiğine
  /// (450/500) yaklaştıysa/geçtiyse bilgilendirici bir SnackBar gösterir.
  Future<void> _maybeShowItemLimitWarning() async {
    final l10n = AppLocalizations.of(context)!;
    final subState = ref.read(subscriptionProvider);
    if (subState.isPremium) return;

    final subNotifier = ref.read(subscriptionProvider.notifier);
    ref.invalidate(itemCountProvider);
    final totalItemCount = await ref.read(itemCountProvider.future);

    if (subNotifier.shouldWarnItemLimit(totalItemCount) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.limitItemWarning(totalItemCount)),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Kayıt hatasını kullanıcı mesajına çevirir. Bağlantı/zaman aşımı
  /// hatalarında girdinin korunduğunu söyleyen özel mesaj gösterilir.
  String _saveFailureMessage(Object? error, AppLocalizations l10n) {
    if (error is net.NetworkFailure ||
        error is net.TimeoutException ||
        error is TimeoutException ||
        error is SocketException) {
      return l10n.addContentOfflineError;
    }
    if (error is net.ValidationException ||
        error is net.ConflictException ||
        error is net.UnauthorizedException) {
      return FailureMapper.toUserMessage(error!, l10n);
    }
    return l10n.addContentAddFailed;
  }

  // ============== DUPLICATE LINK ==============

  /// Karşılaştırma için URL'i sadeleştirir: şema/host küçük harf, `www.`,
  /// fragment, izleme parametreleri (utm_*, fbclid, gclid, igsh, si) ve
  /// sondaki `/` atılır.
  static String _normalizeUrl(String raw) {
    final trimmed = raw.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return trimmed.toLowerCase().replaceAll(RegExp(r'/+$'), '');
    }
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    if (host == 'm.youtube.com') host = 'youtube.com';
    const tracking = {'fbclid', 'gclid', 'igsh', 'igshid', 'si', 'ref'};
    final params =
        uri.queryParameters.entries
            .where(
              (e) =>
                  !e.key.toLowerCase().startsWith('utm_') &&
                  !tracking.contains(e.key.toLowerCase()),
            )
            .map((e) => '${e.key}=${e.value}')
            .toList()
          ..sort();
    final path = uri.path.replaceAll(RegExp(r'/+$'), '');
    return '$host$path${params.isEmpty ? '' : '?${params.join('&')}'}';
  }

  /// Aynı link zaten kayıtlıysa kullanıcıya sorar. Yeni bir API çağrısı
  /// yapmaz; cihazda zaten yüklü olan liste(ler)e bakar. Kaydetmeye devam
  /// edilecekse `true` döner.
  Future<bool> _confirmIfDuplicateLink(AppLocalizations l10n) async {
    if (_detectedLink.isEmpty) return true;
    final target = _normalizeUrl(_detectedLink);
    final loaded = <ItemModel>[
      ...?ref.read(catalogItemsProvider).valueOrNull,
      ...ref.read(paginatedFeedProvider).items,
    ];
    ItemModel? existing;
    for (final item in loaded) {
      final url = item.url;
      if (url != null && url.isNotEmpty && _normalizeUrl(url) == target) {
        existing = item;
        break;
      }
    }
    if (existing == null) return true;

    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    CategoryModel? category;
    for (final c in categories) {
      if (c.id == existing.categoryId) {
        category = c;
        break;
      }
    }
    final collectionName =
        category == null
            ? l10n.commonDefaultCategory
            : categoryDisplayName(context, category.name);

    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder:
          (ctx) => CupertinoActionSheet(
            title: Text(l10n.addContentDuplicateTitle(collectionName)),
            actions: [
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(ctx).pop('open'),
                child: Text(l10n.addContentDuplicateOpen),
              ),
              CupertinoActionSheetAction(
                onPressed: () => Navigator.of(ctx).pop('save'),
                child: Text(l10n.addContentDuplicateSaveAnyway),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonCancel),
            ),
          ),
    );
    if (!mounted) return false;
    if (choice == 'save') return true;
    if (choice == 'open') {
      final existingItem = existing;
      // Var olan kaydı aç; detay kapanınca ekleme sheet'i de kapanır
      // (aynı link ikinci kez kaydedilmedi, kaybolan girdi yok).
      await ItemDetailBottomSheet.show(
        context,
        existingItem,
        collectionName,
        categories,
      );
      if (mounted) Navigator.of(context).pop();
    }
    return false;
  }

  void _showError(String message) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => _AlertBottomSheet(
            title: l10n.addContentWarningTitle,
            message: message,
            type: _AlertType.warning,
          ),
    );
  }

  // Reminder Methods
  Future<void> _loadReminder(String itemId) async {
    try {
      final reminderRepo = ReminderRepository();
      final reminder = await reminderRepo.getItemReminder(itemId);
      if (mounted) {
        setState(() {
          _currentReminder = reminder;
          _hasReminder = reminder != null;
        });
      }
    } catch (e) {
      debugPrint('Error loading reminder: $e');
      if (mounted) {
        setState(() {
          _currentReminder = null;
          _hasReminder = false;
        });
      }
    }
  }

  Future<void> _handleReminderAfterSave(String itemId, String noteTitle) async {
    try {
      final scheduler = ReminderSchedulerService();

      if (_hasReminder && _currentReminder != null) {
        // Update or create reminder
        final reminder = _currentReminder!.copyWith(itemId: itemId);
        if (_currentReminder!.id != null) {
          await scheduler.updateReminder(reminder, noteTitle);
        } else {
          await scheduler.scheduleReminder(reminder, noteTitle);
        }
      } else if (!_hasReminder && widget.editItem?.hasReminder == true) {
        // Cancel existing reminder
        await scheduler.cancelReminder(itemId);
      }
    } catch (e) {
      debugPrint('Error handling reminder: $e');
    }
  }

  Future<void> _showReminderPicker() async {
    final l10n = AppLocalizations.of(context)!;

    // Limit check: only when creating a NEW reminder
    if (_currentReminder == null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final subState = ref.read(subscriptionProvider);
        if (!subState.isPremium) {
          try {
            final reminders = await ReminderRepository().getUserReminders(uid);
            final activeCount = reminders.where((r) => r.isActive).length;
            final canCreate = ref
                .read(subscriptionProvider.notifier)
                .canCreateReminder(activeCount);
            if (!canCreate) {
              if (mounted) {
                await LimitReachedDialog.show(
                  context: context,
                  ref: ref,
                  title: l10n.limitReminderTitle,
                  message: l10n.limitReminderDescription,
                  type: LimitType.item,
                );
              }
              return;
            }
          } catch (e) {
            debugPrint('Error checking reminder limit: $e');
          }
        }
      }
    }

    if (!mounted) return;
    final reminder = await ReminderPickerBottomSheet.show(
      context,
      existingReminder: _currentReminder,
      onDelete:
          _currentReminder != null
              ? () async {
                await _deleteReminder();
              }
              : null,
    );

    if (reminder != null) {
      setState(() {
        _currentReminder = reminder;
        _hasReminder = true;
      });
    }
  }

  Future<void> _deleteReminder() async {
    if (_currentReminder?.id != null) {
      try {
        final scheduler = ReminderSchedulerService();
        await scheduler.cancelReminder(_currentReminder!.itemId);
        setState(() {
          _currentReminder = null;
          _hasReminder = false;
        });
      } catch (e) {
        debugPrint('Error deleting reminder: $e');
      }
    }
  }

  Future<void> _deleteItem() async {
    try {
      if (widget.editItem != null) {
        // Delete image from Storage if exists
        final imageUrl = widget.editItem!.ogMetadata?.imageUrl;
        if (imageUrl != null && !imageUrl.startsWith('data:')) {
          final storageService = StorageService();
          await storageService.deleteFile(imageUrl);
          debugPrint('🗑️ Item image deleted from Storage');
        }

        // Delete item from Firestore
        await _itemRepository.deleteItem(widget.editItem!.id);
        if (mounted) {
          // Silme akışı: çağıranlar için "değişiklik oldu" sinyali yeterli.
          Navigator.pop(context, const AddContentResult());
        }
      }
    } catch (e) {
      debugPrint("Delete error: $e");
      if (mounted) {
        _showError(AppLocalizations.of(context)!.addContentDeleteFailed);
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDestructiveConfirmDialog(
      context,
      title: l10n.deleteConfirmTitle,
      message: l10n.deleteItemConfirm,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
    );
    if (confirmed && mounted) _deleteItem();
  }

  // ============== UI BUILD ==============

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
      ),
    );

    // Pre-select category if provided (e.g., from CatalogScreen)
    if (widget.preSelectedCategoryId != null &&
        widget.preSelectedCategoryId!.isNotEmpty &&
        _selectedCategoryIds.isEmpty) {
      _selectedCategoryIds.add(widget.preSelectedCategoryId!);
    }

    // "Hızlı" category auto-creation (one-time)
    ref.listen(categoriesProvider, (prev, next) {
      next.whenData((cats) {
        if (!_hizliChecked && mounted) {
          _hizliChecked = true;
          _ensureHizliCategory(cats);
        }
      });
    });

    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      // Kirli formda barrier dokunuşu / X / aşağı kaydırma doğrudan kapatmaz;
      // önce "Değişiklikleri at / Düzenlemeye devam et" sorulur.
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmDiscardAndClose();
      },
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: _onSheetExtentChanged,
        child: DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 1.0,
          minChildSize: 0.6,
          maxChildSize: 1.0,
          snap: true,
          builder: (context, scrollController) {
            return Material(
              color:
                  Colors
                      .transparent, // Material typically needs a color or transparent
              type: MaterialType.transparency, // Important for overlay
              child: GestureDetector(
                behavior:
                    HitTestBehavior.opaque, // Ensures taps on empty areas work
                onTap: () => FocusScope.of(context).unfocus(),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceWhite,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Main Content
                      SingleChildScrollView(
                        controller:
                            scrollController, // Crucial for drag-to-dismiss
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Ensure drag works even if content is short
                        child: Column(
                          children: [
                            // Hide hero stage in Note mode
                            if (!_isNoteMode) _buildHeroStage(),
                            if (_hasLink || _isManualEntry || _isNoteMode)
                              _buildControlCenter(),
                            const SizedBox(height: 140),
                          ],
                        ),
                      ),

                      // Back Button (re-styled as Drag Handle/Close)
                      Positioned(
                        top: 56, // Matched ItemDetailBottomSheet hasImage state
                        left: 16,
                        child: _buildBackButton(),
                      ),

                      // Sticky Trash Button (Moved from HeroStage)
                      if ((_hasLink || _isManualEntry || _isNoteMode) &&
                          !_isLoadingMetadata)
                        Positioned(
                          top: 56, // Matched Left button
                          right: 16,
                          child: Builder(
                            builder: (context) {
                              final hasContent =
                                  _hasLink ||
                                  _titleController.text.isNotEmpty ||
                                  _noteController.text.isNotEmpty ||
                                  _linkController.text.isNotEmpty;

                              // In edit mode, trash button is always enabled (delete item)
                              final isEditMode = widget.editItem != null;
                              final isEnabled = isEditMode || hasContent;

                              return Opacity(
                                opacity: isEnabled ? 1.0 : 0.4,
                                child: CircleIconButton(
                                  icon: PhosphorIconsLight.trash,
                                  iconSize: 18,
                                  enabled: isEnabled,
                                  semanticLabel:
                                      isEditMode
                                          ? l10n.a11yDelete
                                          : l10n.a11yClearContent,
                                  onTap:
                                      isEditMode
                                          ? _showDeleteConfirmation
                                          : (hasContent
                                              ? _confirmClearContent
                                              : () {}),
                                ),
                              );
                            },
                          ),
                        ),

                      // Floating CTA Dock
                      // Show dock if we have a link OR manual entry mode OR note mode
                      if (_hasLink || _isManualEntry || _isNoteMode)
                        Positioned(
                          bottom: 32 + MediaQuery.viewInsetsOf(context).bottom,
                          left: 24,
                          right: 24,
                          child: _buildFloatingDock(),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============== HERO STAGE ==============

  Widget _buildHeroStage() {
    final size = MediaQuery.of(context).size;
    // If has link -> 38% height
    // If manual entry -> 25% height (smaller header)
    // If empty -> 75% height
    double stageHeight;
    if (_hasLink) {
      if (_imageAspectRatio != null) {
        double calculatedRatio =
            (size.width / _imageAspectRatio!) / size.height;
        if (calculatedRatio > 0.65) calculatedRatio = 0.65;
        // Relaxing lower bound to allow landscape images to fit fully without zoom
        if (calculatedRatio < 0.20) calculatedRatio = 0.20;
        stageHeight = size.height * calculatedRatio;
      } else {
        // Görsel yoksa minimum 180px garanti et (X, Maps ve normal linkler için)
        final minHeight = 180.0;
        final calculatedHeight = size.height * 0.30;
        stageHeight =
            calculatedHeight < minHeight ? minHeight : calculatedHeight;
      }
    } else if (_isManualEntry) {
      stageHeight = size.height * 0.40; // Increased from 0.25
    } else {
      stageHeight = size.height * 0.75;
    }

    final hasImage = ContentPreviewPolicy.canUsePreviewImage(
      url: _detectedLink,
      imageUrl: _ogMetadata?.imageUrl,
    );

    return GestureDetector(
      // Only check clipboard if we are in the initial empty state
      onTap:
          (!_hasLink && !_isManualEntry && !_isLoadingMetadata)
              ? () => _checkClipboardAndProcess(auto: false)
              : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: stageHeight,
        width: double.infinity,

        color:
            Colors
                .transparent, // Fix: Transparent to show underlying white surface at corners
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Layer
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child:
                  // Priority order:
                  // 1. Loading state - show animated platform background
                  // 2. X (Twitter) URL - show X logo
                  // 3. Map URL - show placeholder with logo
                  // 4. Images - show if not a known brand OR if it's a social platform
                  //    AND it's not a favicon URL
                  // 5. Fallback - platform background
                  _isLoadingMetadata
                      ? _buildPlatformBackground(animate: true)
                      : _isMapUrl(_detectedLink.toLowerCase())
                      ? _buildMapPlaceholder()
                      : (hasImage && !_isFaviconUrl(_ogMetadata?.imageUrl))
                      ? _buildImageBackground()
                      : _buildPlatformBackground(animate: false),
            ),

            // Platform Icon removed as requested
          ],
        ),
      ),
    );
  }

  // Manual Entry Header (God Ray / Spotlight Cone Effect)

  // Loading State (Filling Animation)

  // Platform Background (Gradient Preview Placeholder)
  Widget _buildPlatformBackground({bool animate = false}) {
    final l10n = AppLocalizations.of(context)!;
    final bool showFavicon =
        !animate &&
        _hasLink &&
        !_isLoadingMetadata &&
        _ogMetadata?.imageUrl != null &&
        _isFaviconUrl(_ogMetadata!.imageUrl) &&
        !_isKnownBrandSite();

    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        // Subtle shimmer animation values
        final double shimmer = animate ? _loadingController.value : 0.0;
        final startAlign =
            Alignment.lerp(Alignment.topLeft, Alignment.topCenter, shimmer)!;
        final endAlign =
            Alignment.lerp(
              Alignment.bottomRight,
              Alignment.bottomCenter,
              shimmer,
            )!;

        return Container(
          clipBehavior: Clip.antiAlias,
          key: const ValueKey('platform'),
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colors.surfaceWhite, // Fallback
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ), // Fix: Square bottom to merge with content
            gradient: LinearGradient(
              colors:
                  animate
                      ? [
                        context.colors.primary,
                        Color.lerp(
                          context.colors.secondary,
                          Colors.white,
                          shimmer * 0.3,
                        )!, // Subtle lighten
                        context.colors.secondary,
                      ]
                      : [context.colors.primary, context.colors.secondary],
              begin: startAlign,
              end: endAlign,
              stops: animate ? [0.0, 0.5 + (shimmer * 0.5), 1.0] : null,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                animate
                    ? SizedBox(
                      height: 64,
                      width: 64,
                      child: Center(
                        child: SizedBox(
                          height: 48,
                          width: 48,
                          child: CircularProgressIndicator(
                            color: Colors.white.withValues(alpha: 0.9),
                            strokeWidth: 4,
                          ),
                        ),
                      ),
                    )
                    : showFavicon
                    ? Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: buildAuthImage(
                        imageUrl: _ogMetadata!.imageUrl!,
                        fit: BoxFit.contain,
                        errorWidget:
                            (_, __, ___) => const Icon(
                              Icons.language,
                              color: Colors.grey,
                              size: 32,
                            ),
                      ),
                    )
                    : _buildPlatformIcon(),
                const SizedBox(height: 12),
                Text(
                  animate
                      ? l10n.addContentScanning
                      : ContentPreviewPolicy.shouldShowMissingPreviewLabel(
                        url: _detectedLink,
                        hasImage: ContentPreviewPolicy.canUsePreviewImage(
                          url: _detectedLink,
                          imageUrl: _ogMetadata?.imageUrl,
                        ),
                        isKnownBrandSite: _isKnownBrandSite(),
                      )
                      ? l10n.addContentNoPreview
                      : showFavicon
                      ? (_ogMetadata?.title ?? l10n.addContentLinkAdded)
                      : l10n.addContentPreviewHint,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Image Background
  // Image Background (Cover)
  // Image Background
  // Image Background (Cover)
  Widget _buildImageBackground() {
    // Fix stale IP address pointing to old server
    final rawUrl = _ogMetadata!.imageUrl!;
    String imageUrl =
        rawUrl.contains('46.224.146.102')
            ? rawUrl.replaceAll('http://46.224.146.102', ApiConfig.baseUrl)
            : rawUrl;
    // Migrate old public /storage/ to authenticated /api/storage/
    if (imageUrl.contains(ApiConfig.baseUrl) &&
        imageUrl.contains('/storage/') &&
        !imageUrl.contains('/api/storage/')) {
      imageUrl = imageUrl.replaceAll('/storage/', '/api/storage/');
    }

    return Stack(
      key: const ValueKey('image'),
      fit: StackFit.expand,
      children: [
        buildAuthImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox.shrink(),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // Custom Map Preview (Gradient + Icon) like ItemCard
  // If coordinates are available, show Apple Map preview

  // Map placeholder - tema rengi gradient + provider brand ikonu
  Widget _buildMapPlaceholder() {
    final url = _detectedLink.toLowerCase();
    final iconColor = context.colors.surfaceWhite.withValues(alpha: 0.9);
    final Widget icon;
    if (_isGoogleMapsUrl(url)) {
      icon = FaIcon(FontAwesomeIcons.google, size: 64, color: iconColor);
    } else if (_isYandexMapsUrl(url)) {
      icon = FaIcon(FontAwesomeIcons.yandex, size: 64, color: iconColor);
    } else if (_isAppleMapsUrl(url)) {
      icon = FaIcon(FontAwesomeIcons.apple, size: 64, color: iconColor);
    } else {
      icon = Icon(PhosphorIconsBold.mapTrifold, size: 64, color: iconColor);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      key: const ValueKey('map_placeholder'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.primary, context.colors.secondary],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Center(child: icon),
    );
  }

  // X (Twitter) placeholder - show X logo
  /// Returns platform-specific icon for preview placeholder
  Widget _buildPlatformIcon() {
    final url = _detectedLink.toLowerCase();
    const iconColor = Colors.white;
    const iconSize = 48.0;

    // Social/Content platforms
    if (url.contains('x.com') || url.contains('twitter.com')) {
      return const FaIcon(
        FontAwesomeIcons.xTwitter,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('facebook.com') || url.contains('fb.watch')) {
      return const FaIcon(
        FontAwesomeIcons.facebook,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('instagram.com')) {
      return const FaIcon(
        FontAwesomeIcons.instagram,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return const FaIcon(
        FontAwesomeIcons.youtube,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('tiktok.com')) {
      return const FaIcon(
        FontAwesomeIcons.tiktok,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('spotify.com')) {
      return const FaIcon(
        FontAwesomeIcons.spotify,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('linkedin.com')) {
      return const FaIcon(
        FontAwesomeIcons.linkedin,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('pinterest.com') || url.contains('pin.it')) {
      return const FaIcon(
        FontAwesomeIcons.pinterest,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('reddit.com')) {
      return const FaIcon(
        FontAwesomeIcons.reddit,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('github.com')) {
      return const FaIcon(
        FontAwesomeIcons.github,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('twitch.tv')) {
      return const FaIcon(
        FontAwesomeIcons.twitch,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('discord.com') || url.contains('discord.gg')) {
      return const FaIcon(
        FontAwesomeIcons.discord,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('medium.com')) {
      return const FaIcon(
        FontAwesomeIcons.medium,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('whatsapp.com')) {
      return const FaIcon(
        FontAwesomeIcons.whatsapp,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('telegram.org') || url.contains('t.me')) {
      return const FaIcon(
        FontAwesomeIcons.telegram,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('snapchat.com')) {
      return const FaIcon(
        FontAwesomeIcons.snapchat,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('amazon.com') || url.contains('amazon.')) {
      return const FaIcon(
        FontAwesomeIcons.amazon,
        size: iconSize,
        color: iconColor,
      );
    }
    if (url.contains('hepsiburada.com')) {
      return const FaIcon(
        FontAwesomeIcons.bagShopping,
        size: iconSize,
        color: iconColor,
      );
    }

    // Default link icon
    return Icon(
      _hasLink && !_isLoadingMetadata && (_ogMetadata?.imageUrl == null)
          ? Icons.link_off
          : Icons.add_link_rounded,
      size: 64,
      color: Colors.white.withValues(alpha: 0.9),
    );
  }

  // Launch the original map URL in Google/Yandex Maps

  // Launch in Apple Maps when we have coordinates

  // Map icon placeholder for Google/Yandex (no map, just icon)

  // Gradient fallback when no coordinates

  // Launch the original map URL in Google/Yandex Maps

  // Reusable Ambient Animation Core (Liftoff Particles)

  // ============== CONTROL CENTER ==============

  Widget _buildControlCenter() {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Extra top spacing in Note mode (since hero is hidden)
          SizedBox(height: _isNoteMode ? 110 : 24),

          // MODE TOGGLE: Type selector
          _buildModeToggle(),
          const SizedBox(height: 18), // Slightly more spacing
          // Link Preview / Input (Hide if Note Mode is active)
          if (!_isNoteMode && (_hasLink || _isManualEntry)) ...[
            _buildLinkPreview(),
            const SizedBox(height: 16),
          ],

          // Title Input
          _buildInputField(
            controller: _titleController,
            icon: PhosphorIconsThin.pencilSimple, // Thin
            hint:
                _isNoteMode
                    ? l10n.addContentTitleHintNote
                    : l10n.addContentTitleHintLink,
            isTitle: true,
          ),

          const SizedBox(height: 12),

          // Note Input (Larger in Note Mode - but keep collection visible)
          _buildInputField(
            controller: _noteController,
            icon: PhosphorIconsThin.notePencil, // Thin
            hint:
                _isNoteMode
                    ? l10n.addContentNoteHintNote
                    : l10n.addContentNoteHintLink,
            maxLines: _isNoteMode ? 10 : 3, // Balanced size to show collection
          ),

          // Note Image Picker (Only in Note Mode)
          if (_isNoteMode) ...[
            const SizedBox(height: 16),
            _buildNoteImagePicker(),
          ],

          // Reminder Picker (All content types)
          const SizedBox(height: 16),
          _buildReminderPicker(),

          const SizedBox(height: 18), // Equal spacing
          // Category Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.addContentSelectCollection,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.colors.body,
                ),
              ),
              Semantics(
                button: true,
                label: l10n.a11yNewCollection,
                excludeSemantics: true,
                onTap: () => _showAddCategoryDialog(context),
                child: GestureDetector(
                  onTap: () => _showAddCategoryDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsBold.plus,
                      size: 16,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Category Chips
          SizedBox(
            height: 44,
            child:
                categoriesAsync.isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.none,
                      // Hide "Hızlı" from UI - it's used silently for uncategorized items
                      itemCount:
                          categories
                              .where((c) => c.name != kQuickCategoryKey)
                              .length,
                      itemBuilder: (context, index) {
                        final visibleCategories =
                            categories
                                .where((c) => c.name != kQuickCategoryKey)
                                .toList();
                        final cat = visibleCategories[index];
                        return _buildCategoryChip(cat, categories);
                      },
                    ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Builds the note image picker UI
  Widget _buildNoteImagePicker() {
    final hasImage =
        _selectedNoteImage != null ||
        (_noteImageUrl != null && _noteImageUrl!.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.body.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              hasImage
                  ? context.colors.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
          width: hasImage ? 1.5 : 0,
        ),
      ),
      child: hasImage ? _buildImagePreview() : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: _pickNoteImage,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.15),
                    context.colors.secondary.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                PhosphorIconsBold.image,
                size: 24,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.addContentImagePickerTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.headline,
                    ),
                  ),
                  Text(
                    l10n.addContentImageOptional,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: context.colors.hint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 20,
              color: context.colors.hint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Image Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child:
                  _selectedNoteImage != null
                      ? Image.file(_selectedNoteImage!, fit: BoxFit.cover)
                      : buildAuthImage(
                        imageUrl: _noteImageUrl!,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, __) => Container(
                              color: context.colors.backgroundTop,
                              child: const Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            ),
                        errorWidget:
                            (_, __, ___) => Container(
                              color: context.colors.backgroundTop,
                              child: Icon(
                                PhosphorIconsBold.imageSquare,
                                color: context.colors.hint,
                              ),
                            ),
                      ),
            ),
          ),
          const SizedBox(width: 16),
          // Info & Actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addContentImageAdded,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.headline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedNoteImage != null
                      ? l10n.addContentNewImageSelected
                      : l10n.addContentExistingImage,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: context.colors.hint,
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Change Image
              Semantics(
                button: true,
                label: AppLocalizations.of(context)!.a11yChangeImage,
                excludeSemantics: true,
                onTap: _pickNoteImage,
                child: GestureDetector(
                  onTap: _pickNoteImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsBold.pencilSimple,
                      size: 18,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Remove Image
              Semantics(
                button: true,
                label: AppLocalizations.of(context)!.a11yRemoveImage,
                excludeSemantics: true,
                onTap: _removeNoteImage,
                child: GestureDetector(
                  onTap: _removeNoteImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.danger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsBold.trash,
                      size: 18,
                      color: context.colors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderPicker() {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: _showReminderPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color:
              _hasReminder
                  ? context.colors.primary.withValues(alpha: 0.1)
                  : context.colors.body.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _hasReminder
                    ? context.colors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
            width: _hasReminder ? 1.5 : 0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.15),
                    context.colors.secondary.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _hasReminder
                    ? PhosphorIconsBold.bellRinging
                    : PhosphorIconsBold.bell,
                size: 22,
                color:
                    _hasReminder ? context.colors.primary : context.colors.hint,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasReminder && _currentReminder != null
                        ? l10n.reminderSetActive
                        : l10n.reminderAddTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          _hasReminder
                              ? context.colors.primary
                              : context.colors.headline,
                    ),
                  ),
                  if (_hasReminder && _currentReminder != null)
                    Text(
                      _formatReminderSummary(_currentReminder!),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: context.colors.hint,
                      ),
                    )
                  else
                    Text(
                      l10n.reminderSetHint,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: context.colors.hint,
                      ),
                    ),
                ],
              ),
            ),
            if (_hasReminder)
              Icon(
                PhosphorIconsRegular.checkCircle,
                size: 22,
                color: context.colors.primary,
              )
            else
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 20,
                color: context.colors.hint,
              ),
          ],
        ),
      ),
    );
  }

  String _formatReminderSummary(ReminderModel reminder) {
    final nextOccurrence = reminder.calculateNextOccurrence();
    final isToday = _isSameDay(nextOccurrence, DateTime.now());
    final isTomorrow = _isSameDay(
      nextOccurrence,
      DateTime.now().add(const Duration(days: 1)),
    );

    final l10n = AppLocalizations.of(context)!;

    String dateLabel;
    if (isToday) {
      dateLabel = l10n.commonToday;
    } else if (isTomorrow) {
      dateLabel = l10n.commonTomorrow;
    } else {
      dateLabel = formatShortDate(context, nextOccurrence);
    }

    final time =
        '${reminder.reminderTime.hour.toString().padLeft(2, '0')}:'
        '${reminder.reminderTime.minute.toString().padLeft(2, '0')}';

    if (reminder.repeat != RepeatFrequency.none) {
      return '$dateLabel, $time • ${_getRepeatLabel(reminder.repeat)}';
    }
    return '$dateLabel, $time';
  }

  String _getRepeatLabel(RepeatFrequency frequency) {
    final l10n = AppLocalizations.of(context)!;

    switch (frequency) {
      case RepeatFrequency.none:
        return l10n.addContentRepeatOnce;
      case RepeatFrequency.daily:
        return l10n.addContentRepeatDaily;
      case RepeatFrequency.weekly:
        return l10n.addContentRepeatWeekly;
      case RepeatFrequency.monthly:
        return l10n.addContentRepeatMonthly;
      case RepeatFrequency.yearly:
        return l10n.addContentRepeatYearly;
      case RepeatFrequency.weekdays:
        return l10n.addContentRepeatWeekdays;
      case RepeatFrequency.weekends:
        return l10n.addContentRepeatWeekends;
      case RepeatFrequency.customMinutes:
        return l10n.addContentRepeatCustomMinutes;
      case RepeatFrequency.customDays:
        return l10n.addContentRepeatCustomDays;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Input Field
  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isTitle = false,
    int maxLines = 1,
  }) {
    final isMultiLine = maxLines > 1;

    return Stack(
      children: [
        Container(
          height:
              maxLines == 1
                  ? 52
                  : null, // Fix height for single line inputs (Title)
          alignment: maxLines == 1 ? Alignment.center : Alignment.topLeft,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isMultiLine ? 14 : 0,
          ),
          decoration: BoxDecoration(
            color: context.colors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.hint.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                isMultiLine
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: isMultiLine ? 2 : 0),
                child: Icon(icon, size: 18, color: context.colors.body),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  cursorColor: context.colors.primary,
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {
                    // Dismiss keyboard when Done is pressed
                    FocusScope.of(context).unfocus();
                  },
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: context.colors.headline,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: context.colors.body.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: maxLines,
                  minLines: maxLines > 3 ? maxLines : (maxLines > 1 ? 2 : 1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Link Input (Editable)
  Widget _buildLinkPreview() {
    final l10n = AppLocalizations.of(context)!;
    final hasPlatform = _detectedPlatform.isNotEmpty;
    // Always use Primary Brand Color to match design, ignoring platform specific colors (e.g. Red for YouTube)
    final themeColor = context.colors.primary;
    final platformIcon =
        hasPlatform
            ? _getPlatformIcon(_detectedPlatform)
            : PhosphorIconsThin.link;

    return Container(
      height: 52, // Fixed height to match filled state stability
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        // Always use Primary Color border
        border: Border.all(
          color: themeColor.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Platform Icon
          Icon(platformIcon, size: 18, color: themeColor),
          const SizedBox(width: 12),

          // Editable Link Field
          Expanded(
            child: TextField(
              controller: _linkController,
              onChanged: _onLinkChanged,
              onTap: () {
                if (_linkController.text.isEmpty) {
                  _checkClipboardAndProcess(
                    auto: false,
                  ); // Prompt paste if empty
                }
              },
              cursorColor: context.colors.primary,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.poppins(
                fontSize: 15, // Matched with Title Input
                fontWeight: FontWeight.w400,
                color: context.colors.headline,
              ),
              decoration: InputDecoration(
                hintText: l10n.addContentLinkHint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 15, // Matched with Title Input
                  color: context.colors.body.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 1,
            ),
          ),

          // Clear Action
          if (_linkController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _linkController.clear();
                _clearLinkField();
              },
              icon: Icon(
                PhosphorIconsBold.x,
                size: 16,
                color: context.colors.body,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
        ],
      ),
    );
  }

  // Category Chip
  Widget _buildCategoryChip(CategoryModel cat, List<CategoryModel> categories) {
    final bool isSelected = _selectedCategoryIds.contains(cat.id);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Semantics(
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap:
              () => setState(() {
                if (isSelected) {
                  _selectedCategoryIds.remove(cat.id);
                } else {
                  // If selecting a non-Quick category, auto-deselect "Hızlı"
                  if (cat.name != kQuickCategoryKey) {
                    try {
                      final quickCat = categories.firstWhere(
                        (c) => c.name == kQuickCategoryKey,
                      );
                      _selectedCategoryIds.remove(quickCat.id);
                    } catch (_) {}
                  }
                  _selectedCategoryIds.add(cat.id);
                }
              }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient:
                  isSelected
                      ? LinearGradient(
                        colors: [
                          context.colors.secondary.withValues(alpha: 0.5),
                          context.colors.surfaceWhite,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : null,
              color:
                  isSelected
                      ? null
                      : context.colors.surfaceWhite, // White/Dark Surface
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color:
                    isSelected ? Colors.transparent : context.colors.secondary,
                width: 1.5,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: context.colors.secondary.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cat.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected
                            ? context.colors.headline
                            : context.colors.body,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    PhosphorIconsBold.check,
                    size: 12,
                    color: context.colors.headline,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============== MODE TOGGLE (Slide Action Style) ==============

  Widget _buildModeToggle() {
    final l10n = AppLocalizations.of(context)!;

    // If in edit mode, show static title instead of toggle
    if (widget.editItem != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            _isNoteMode ? l10n.addContentEditNote : l10n.addContentEditContent,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
        ),
      );
    }

    // Hide note toggle in create mode
    return const SizedBox.shrink();
  }

  // ============== FLOATING DOCK ==============

  Widget _buildFloatingDock() {
    final l10n = AppLocalizations.of(context)!;

    final foreground = BrandGradient.foreground(context);
    final label =
        widget.editItem != null ? l10n.commonSave : l10n.addContentAddButton;

    return Semantics(
      button: true,
      enabled: !_isSaving,
      label: label,
      excludeSemantics: true,
      onTap: _isSaving ? null : _saveContent,
      child: GestureDetector(
        onTap: _isSaving ? null : _saveContent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            // Slogan gradyanı; beyaz/onPrimary yazı için ≥4.5:1'e koyulaştırılmış.
            gradient: BrandGradient.linear(context),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: context.colors.secondary.withValues(
                  alpha: 0.3,
                ), // Matching shadow
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child:
                _isSaving
                    ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(foreground),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.editItem != null
                              ? PhosphorIconsBold.floppyDisk
                              : PhosphorIconsBold.plus,
                          size: 20,
                          color: foreground,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  // ============== HELPER WIDGETS ==============

  Widget _buildBackButton() {
    return CircleIconButton(
      icon: PhosphorIconsLight.x, // X for modal close
      semanticLabel: AppLocalizations.of(context)!.a11yClose,
      // maybePop: kaydedilmemiş değişiklik varsa PopScope onay sorar.
      onTap: () => Navigator.maybePop(context),
    );
  }

  // ============== PLATFORM HELPERS ==============

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return PhosphorIconsThin.instagramLogo;
      case 'youtube':
        return PhosphorIconsThin.youtubeLogo;
      case 'x':
      case 'twitter':
        return PhosphorIconsThin.xLogo;
      case 'tiktok':
        return PhosphorIconsThin.tiktokLogo;
      case 'linkedin':
        return PhosphorIconsThin.linkedinLogo;
      case 'spotify':
        return PhosphorIconsThin.spotifyLogo;
      case 'pinterest':
        return PhosphorIconsThin.pinterestLogo;
      case 'reddit':
        return PhosphorIconsThin.redditLogo;
      case 'medium':
        return PhosphorIconsThin.mediumLogo;
      case 'behance':
        return PhosphorIconsThin.behanceLogo;
      case 'dribbble':
        return PhosphorIconsThin.dribbbleLogo;
      default:
        return PhosphorIconsThin.globe;
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    // --- COLLECTION LIMIT CHECK ---
    final addSubState = ref.read(subscriptionProvider);
    final addSubNotifier = ref.read(subscriptionProvider.notifier);
    if (!addSubState.isPremium) {
      final categories = ref.read(categoriesProvider).value ?? [];
      if (!addSubNotifier.canCreateCollection(categories.length)) {
        LimitReachedDialog.show(
          context: context,
          ref: ref,
          title: null,
          message: null,
          type: LimitType.collection,
        );
        return;
      }
    }
    // --- END LIMIT CHECK ---

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _SimpleCategoryFormSheet(
            onSave: (name) async {
              try {
                final categoryRepo = ref.read(categoryRepositoryProvider);
                final newCategory = await categoryRepo.createCategory(
                  CategoryModel(
                    id: '',
                    name: name,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    userId: ref.read(authStateProvider).value?.uid ?? '',
                  ),
                );

                if (mounted) {
                  Navigator.pop(
                    this.context,
                  ); // ignore: use_build_context_synchronously
                  // Auto-select the new category
                  setState(() {
                    _selectedCategoryIds.clear();
                    _selectedCategoryIds.add(newCategory.id);
                  });
                  // Riverpod stream otomatik günceller, manuel refresh gerekmez
                }
              } catch (e) {
                // Handle error
              }
            },
          ),
    );
  }
} // End of _AddContentScreenState

class _SimpleCategoryFormSheet extends StatefulWidget {
  final Function(String name) onSave;

  const _SimpleCategoryFormSheet({required this.onSave});

  @override
  State<_SimpleCategoryFormSheet> createState() =>
      _SimpleCategoryFormSheetState();
}

class _SimpleCategoryFormSheetState extends State<_SimpleCategoryFormSheet> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.catalogNewCollection,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.colors.headline,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.catalogCollectionNameHint,
              filled: true,
              fillColor: context.colors.backgroundTop,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isNotEmpty) {
                  widget.onSave(_nameController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.commonCreate,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

// Custom Painter for Wavy Stream Effect (Flowing River)

// ==========================================
// LIFTOFF PARTICLE SYSTEM
// ==========================================

// ============== ALERT BOTTOM SHEET ==============
enum _AlertType { success, warning }

class _AlertBottomSheet extends StatefulWidget {
  final String title;
  final String message;
  final _AlertType type;

  const _AlertBottomSheet({
    required this.title,
    required this.message,
    required this.type,
  });

  @override
  State<_AlertBottomSheet> createState() => _AlertBottomSheetState();
}

class _AlertBottomSheetState extends State<_AlertBottomSheet> {
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // VoiceOver/Switch Control kullanıcısı mesajı okuyup kapatabilsin diye
      // otomatik kapanma yok; diğerlerinde uyarı 4 sn görünür kalır.
      if (MediaQuery.accessibleNavigationOf(context)) return;
      _autoDismissTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) Navigator.pop(context);
      });
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = BrandGradient.foreground(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        clipBehavior: Clip.antiAlias,
        width: double.infinity,
        decoration: BoxDecoration(
          // Yağ Yeşili Gradient Zemin
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Derin Adaçayı → canlı ton; beyaz/onPrimary yazı için ≥4.5:1.
            colors: BrandGradient.colors(context),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Stack(
          alignment: Alignment.center, // Stack içeriğini de ortala
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(
                32,
                16,
                32,
                56,
              ), // Yanlardan padding artırıldı
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Kesinlikle ortala
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: foreground.withValues(
                        alpha: 0.3,
                      ), // Beyaz Opak Handle
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Icon Circle
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: foreground.withValues(
                        alpha: 0.2,
                      ), // Beyaz Opak Zemin
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child:
                          widget.type == _AlertType.success
                              ? Icon(
                                PhosphorIconsBold.check,
                                color: foreground,
                                size: 32,
                              )
                              : Text(
                                "!",
                                style: GoogleFonts.poppins(
                                  fontSize: 32, // Biraz küçültüldü
                                  fontWeight: FontWeight.w700,
                                  color: foreground,
                                  height: 1.0, // Dikey ortalama için
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20, // Biraz daha büyük ve iddialı
                      fontWeight: FontWeight.w700,
                      color: foreground, // Başlık Beyaz
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ), // Mesaj ile başlık arası biraz açıldı
                  // Message
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15, // Biraz daha okunur
                      fontWeight: FontWeight.w500,
                      color: foreground,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16), // Buton olmadığı için alt boşluk
                ],
              ),
            ),

            // Close Button (Top Right)
            Positioned(
              top: 20,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: Semantics(
                  button: true,
                  label: AppLocalizations.of(context)!.a11yClose,
                  excludeSemantics: true,
                  onTap: () => Navigator.pop(context),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        PhosphorIconsLight.x,
                        size: 20,
                        color: foreground, // Beyaz X butonu
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
