import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:somine_app/core/services/storage_service.dart';
import 'package:somine_app/core/services/metadata_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'dart:math' as math;
import 'dart:ui' as import_dart_ui;
// import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';

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

  // Animation
  late AnimationController _textAnimationController;
  late Animation<double> _textAnimation;
  late AnimationController _loadingController;
  late AnimationController _rotationController;
  late AnimationController _arrowAnimationController;

  // State
  bool _isSaving = false;
  bool _isLoadingMetadata = false;
  bool _isManualEntry = true; // Default to true (Skip splash)
  bool _isNoteMode = false; // Toggle between Note and Link mode

  // Clipboard State
  bool _hasClipboardContent = false;

  // Link Preview State
  bool _hasLink = false;
  String _detectedLink = "";
  String _detectedPlatform = "";
  OGMetadata? _ogMetadata;

  // Categories (Multi-Select)
  final Set<String> _selectedCategoryIds = {};
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;

  // Dynamic Header Height
  double? _imageAspectRatio;

  // Note Image State (optional image attachment for notes)
  File? _selectedNoteImage;
  String? _noteImageUrl; // For edit mode - existing image URL
  bool _isUploadingImage = false;

  // ============== COLORS ==============

  /// Checks if the current URL belongs to a known brand that uses logo as og:image
  bool _isKnownBrandSite() {
    final url = _linkController.text.toLowerCase();
    if (url.isEmpty) return false;
    
    final knownBrands = [
      'google', 'youtube', 'twitter', 'x.com', 'instagram', 'facebook',
      'linkedin', 'medium', 'spotify', 'github', 'pinterest', 'tiktok',
      'amazon', 'apple', 'microsoft', 'adidas', 'nike', 'puma',
      'netflix', 'discord', 'slack', 'notion', 'figma', 'dribbble',
    ];
    
    return knownBrands.any((brand) => url.contains(brand));
  }

  void _resolveImageSize(String imageUrl) {
    if (imageUrl.isEmpty || imageUrl.toLowerCase().contains('.svg')) return;

    // Reset first
    setState(() => _imageAspectRatio = null);

    final ImageProvider provider = CachedNetworkImageProvider(imageUrl);

    provider
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener(
            (ImageInfo info, bool synchronousCall) {
              if (!mounted) return;
              final myImage = info.image;
              setState(() {
                _imageAspectRatio = myImage.width / myImage.height;
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
    _loadCategories();

    // Text Gradient Animation (Looping)
    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Slow, smooth flow
    )..repeat();
    _textAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_textAnimationController);

    // Arrow shimmer animation for toggle
    _arrowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

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

    // Loading Animation (Heartbeat effect)
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Ambient Rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _linkController.dispose();
    _linkController.dispose();
    _textAnimationController.dispose();
    _loadingController.dispose();
    _rotationController.dispose();
    _arrowAnimationController.dispose();
    super.dispose();
  }

  void _initializeEditMode() {
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
      // Pre-fill metadata from item
      _ogMetadata = item.ogMetadata;
      if (_ogMetadata?.imageUrl != null) {
        _resolveImageSize(_ogMetadata!.imageUrl!);
      }
    }

    // Set Note Image (for notes with images)
    if (_isNoteMode && item.ogMetadata?.imageUrl != null && item.ogMetadata!.imageUrl!.isNotEmpty) {
      _noteImageUrl = item.ogMetadata!.imageUrl;
    }

    // Set Category
    if (item.categoryId != null) {
      _selectedCategoryIds.add(item.categoryId!);
    }

    if (mounted) setState(() {});
  }

  // ============== BUSINESS LOGIC ==============

  Future<void> _loadCategories() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) _useFallbackCategories();
      return;
    }

    try {
      var categories = await _categoryRepository.getCategories(userId);

      // Auto-create "Hızlı" category if not exists
      CategoryModel? quickCategory;
      try {
        quickCategory = categories.cast<CategoryModel?>().firstWhere(
          (c) => c!.name.toLowerCase() == 'hızlı',
          orElse: () => null,
        );

        if (quickCategory == null) {
          // Create "Hızlı" category
          final now = DateTime.now();
          final newCategory = CategoryModel(
            id: '', // Repo generates ID
            userId: userId,
            name: 'Hızlı',
            icon: '⚡', // Lightning icon for Quick
            createdAt: now,
            updatedAt: now,
          );
          quickCategory = await _categoryRepository.createCategory(newCategory);
          // Refresh list
          categories = await _categoryRepository.getCategories(userId);
        }
      } catch (e) {
        debugPrint("Error handling Quick category: $e");
      }

      if (mounted) {
        if (categories.isEmpty) {
          _useFallbackCategories();
        } else {
          setState(() {
            _categories = categories;
            _isLoadingCategories = false;

            // Pre-select category if provided (e.g., from CatalogScreen)
            if (widget.preSelectedCategoryId != null &&
                widget.preSelectedCategoryId!.isNotEmpty) {
              _selectedCategoryIds.add(widget.preSelectedCategoryId!);
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading categories: $e");
      if (mounted) _useFallbackCategories();
    }
  }

  void _useFallbackCategories() {
    final now = DateTime.now();
    setState(() {
      _categories = [
        CategoryModel(
          id: 'seyahat',
          userId: 'user_1',
          name: 'Seyahat',
          icon: '✈️',
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          id: 'spor',
          userId: 'user_1',
          name: 'Spor',
          icon: '🏀',
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          id: 'muzik',
          userId: 'user_1',
          name: 'Müzik',
          icon: '🎵',
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          id: 'komik',
          userId: 'user_1',
          name: 'Komik',
          icon: '😂',
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          id: 'tasarim',
          userId: 'user_1',
          name: 'Tasarım',
          icon: '🎨',
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          id: 'fikir',
          userId: 'user_1',
          name: 'Fikir',
          icon: '💡',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      _isLoadingCategories = false;
    });
  }

  Future<void> _checkClipboardAndProcess({bool auto = false}) async {
    // Phase 1: Checks for existence (Privacy safe on some versions)
    // If auto check, avoid reading data directly to prevent system toast/prompt
    if (auto) {
      final hasContent = await Clipboard.hasStrings();
      if (hasContent) {
        setState(() {
          _hasClipboardContent = true;
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
        _hasClipboardContent = false;
      });
    }
  }

  bool _isUrl(String text) {
    return RegExp(r'(https?:\/\/[^\s]+)').hasMatch(text);
  }

  void _handlePaste() async {
    // This is the manual "Paste" action from the button
    // It should behave same as checkClipboard but force manual entry if failing
    await _checkClipboardAndProcess(auto: false);
  }

  String _detectPlatform(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('instagram.com')) return 'Instagram';
    if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be'))
      return 'YouTube';
    if (lowerUrl.contains('twitter.com') || lowerUrl.contains('x.com'))
      return 'X';
    if (lowerUrl.contains('tiktok.com')) return 'TikTok';
    if (lowerUrl.contains('linkedin.com')) return 'LinkedIn';
    if (lowerUrl.contains('spotify.com')) return 'Spotify';
    if (lowerUrl.contains('pinterest.com')) return 'Pinterest';
    if (lowerUrl.contains('reddit.com')) return 'Reddit';
    if (lowerUrl.contains('medium.com')) return 'Medium';
    if (lowerUrl.contains('behance.net')) return 'Behance';
    if (lowerUrl.contains('dribbble.com')) return 'Dribbble';
    // Google Maps
    if (lowerUrl.contains('maps.app.goo.gl') || 
        lowerUrl.contains('goo.gl/maps') ||
        lowerUrl.contains('google.com/maps') ||
        lowerUrl.contains('maps.google.com')) return 'Maps';
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
        _hasClipboardContent = false;
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
    try {
      // Use centralized MetadataService with all fallbacks
      final metadata = await MetadataService.fetchMetadata(url);

      if (mounted && metadata != null) {
        setState(() {
          _ogMetadata = OGMetadata(
            title: metadata.title,
            description: metadata.description,
            imageUrl: metadata.imageUrl,
            siteName: metadata.siteName ?? _detectedPlatform,
          );
          if (metadata.title != null && _titleController.text.isEmpty) {
            _titleController.text = metadata.title!;
          }
          if (metadata.imageUrl != null) {
            _resolveImageSize(metadata.imageUrl!);
          }
        });
      }
    } catch (e) {
      debugPrint("Metadata fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMetadata = false);
    }
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
        
        // Extract place name from Google Maps shares
        // Format: "Place Name\nhttps://maps.app.goo.gl/..." or "Place Name https://..."
        String? extractedTitle;
        if (_isGoogleMapsUrl(url)) {
          final beforeUrl = value.substring(0, match.start).trim();
          if (beforeUrl.isNotEmpty) {
            // Clean up the title (remove newlines, extra spaces)
            extractedTitle = beforeUrl.replaceAll('\n', ' ').trim();
            debugPrint('📍 [AddContent] Extracted Maps place: $extractedTitle');
          }
        }
        
        if (url != _detectedLink) {
          setState(() {
            _detectedLink = url;
            _detectedPlatform = _detectPlatform(url);
            _hasLink = true;
            _isManualEntry = false;
            
            // Pre-fill title for Google Maps
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
  
  /// Check if URL is a Google Maps link
  bool _isGoogleMapsUrl(String url) {
    return url.contains('maps.app.goo.gl') || 
           url.contains('goo.gl/maps') ||
           url.contains('google.com/maps') ||
           url.contains('maps.google.com');
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
    });
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
      _hasClipboardContent = false;
      _isManualEntry = true; // Always return to manual entry form
      _selectedNoteImage = null;
      _noteImageUrl = null;
    });
  }

  /// Shows a bottom sheet to pick image from gallery or camera
  void _pickNoteImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              "Görsel Ekle",
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
                        color: context.colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.colors.primary.withOpacity(0.2),
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
                            "Galeri",
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
                        color: context.colors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.colors.secondary.withOpacity(0.2),
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
                            "Kamera",
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
        setState(() {
          _selectedNoteImage = File(pickedFile.path);
          _noteImageUrl = null; // Clear any existing URL
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        _showError("Görsel seçilemedi");
      }
    }
  }

  void _removeNoteImage() {
    setState(() {
      _selectedNoteImage = null;
      _noteImageUrl = null;
    });
  }

  Future<void> _saveContent() async {
    // Validation: Note mode requires both title and note
    if (_isNoteMode) {
      if (_titleController.text.trim().isEmpty) {
        _showError("Başlık zorunludur");
        return;
      }
      if (_noteController.text.trim().isEmpty) {
        _showError("Not zorunludur");
        return;
      }
    } else if (_titleController.text.isEmpty &&
        _noteController.text.isEmpty &&
        !_hasLink) {
      return;
    }
    // If no category selected, silently assign to "Hızlı"
    if (_selectedCategoryIds.isEmpty) {
      final quickCat = _categories.cast<CategoryModel?>().firstWhere(
        (c) => c!.name == 'Hızlı',
        orElse: () => null,
      );
      if (quickCat != null) {
        _selectedCategoryIds.add(quickCat.id);
      } else {
        _showError("Lütfen en az bir koleksiyon seçin");
        return;
      }
    }

    setState(() => _isSaving = true);
    final storageService = StorageService();

    try {
      final now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        if (mounted) _showError("Oturum açmanız gerekiyor");
        return;
      }

      // Check for remote image and process if needed
      if (_ogMetadata?.imageUrl != null &&
          !_ogMetadata!.imageUrl!.contains('firebasestorage')) {
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
      
      if (_isNoteMode && _selectedNoteImage != null) {
        // Upload new image to Firebase Storage
        setState(() => _isUploadingImage = true);
        try {
          final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final path = 'users/$userId/notes/$fileName';
          noteImageUrl = await storageService.uploadFile(_selectedNoteImage!, path);
          debugPrint('📸 Note image uploaded: $noteImageUrl');
        } catch (e) {
          debugPrint("Error uploading note image: $e");
          // Continue without image if upload fails
        } finally {
          if (mounted) setState(() => _isUploadingImage = false);
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
          updatedAt: DateTime.now(),
        );

        await _itemRepository.updateItem(updatedItem);

        // Create clones for other selected categories
        if (targetIds.isNotEmpty) {
          final futures = targetIds.map((catId) {
            final clone = updatedItem.copyWith(
              id: '', // New ID
              categoryId: catId,
              createdAt: now,
              updatedAt: now,
            );
            return _itemRepository.createItem(clone);
          });
          await Future.wait(futures);
        }

        if (mounted) {
          Navigator.pop(context, true); // Return success
        }
      }
      // --- CREATE MODE START ---
      else {
        final futures = _selectedCategoryIds.map((catId) {
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
            createdAt: now,
            updatedAt: now,
          );
          return _itemRepository.createItem(newItem);
        });

        await Future.wait(futures);

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint("Save error: $e");
      if (mounted) _showError("Bir hata oluştu");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => _AlertBottomSheet(
            title: "Uyarı",
            message: message,
            type: _AlertType.warning,
          ),
    );
  }

  void _showSuccess(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => _AlertBottomSheet(
            title: "Başarılı!",
            message: message,
            type: _AlertType.success,
          ),
    );
  }

  Future<void> _deleteItem() async {
    try {
      if (widget.editItem != null) {
        await _itemRepository.deleteItem(widget.editItem!.id);
        if (mounted) {
          Navigator.pop(
            context,
            true,
          ); // Return success (true indicates update/delete)
        }
      }
    } catch (e) {
      debugPrint("Delete error: $e");
      if (mounted) _showError("Silme işlemi başarısız");
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              "Silme Onayı",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: context.colors.headline,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Bu içeriği silmek istediğinize emin misiniz?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: context.colors.body,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: context.colors.surfaceWhite,
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "Vazgeç",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context); // Close dialog
                      _deleteItem();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF5252),
                            const Color(0xFFD32F2F),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "Sil",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
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

    return DraggableScrollableSheet(
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
            behavior: HitTestBehavior.opaque, // Ensures taps on empty areas work
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
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
                    controller: scrollController, // Crucial for drag-to-dismiss
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
                            child: _buildCircleButton(
                              icon: PhosphorIconsLight.trash,
                              onTap:
                                  isEditMode
                                      ? _showDeleteConfirmation
                                      : (hasContent ? _clearContent : () {}),
                            ),
                          );
                        },
                      ),
                    ),

                  // Floating CTA Dock
                  // Show dock if we have a link OR manual entry mode OR note mode
                  if (_hasLink || _isManualEntry || _isNoteMode)
                    Positioned(
                      bottom: 40,
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
        stageHeight =
            size.height *
            0.30; // Reduced default height to prevent excessive cropping during load
      }
    } else if (_isManualEntry) {
      stageHeight = size.height * 0.40; // Increased from 0.25
    } else {
      stageHeight = size.height * 0.75;
    }

    final hasImage =
        _ogMetadata?.imageUrl != null &&
        !_ogMetadata!.imageUrl!.toLowerCase().contains('.svg');

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
                  // Show image only if it exists AND it's NOT a known brand (they use logos as og:image)
                  (hasImage && !_isKnownBrandSite())
                      ? _buildImageBackground()
                      : _buildPlatformBackground(animate: _isLoadingMetadata),
            ),

            // Platform Icon removed as requested
          ],
        ),
      ),
    );
  }

  // Manual Entry Header (God Ray / Spotlight Cone Effect)
  Widget _buildManualEntryHeader() {
    return _buildPlatformBackground(animate: false);
  }

  // Loading State (Filling Animation)
  Widget _buildLoadingState() {
    return Container(
      key: const ValueKey('loading'),
      color: context.colors.surfaceWhite,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        children: [
          // Animated Filling Icon
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      context.colors.primary, // Filled Color (Green)
                      context.colors.primary.withOpacity(
                        0.15,
                      ), // Empty Color (Light Green)
                    ],
                    stops: [
                      _loadingController
                          .value, // Fill level moves from 0.0 to 1.0
                      _loadingController.value + 0.05, // Smooth blurred edge
                    ],
                  ).createShader(bounds);
                },
                child: Icon(
                  _getPlatformIcon(_detectedPlatform),
                  size: 60, // Smaller Icon
                  color: Colors.white, // Base color for ShaderMask target
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          Text(
            "Yükleniyor...",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.colors.headline,
            ),
          ),
        ],
      ),
    );
  }

  // Platform Background (Gradient Preview Placeholder)
  Widget _buildPlatformBackground({bool animate = false}) {
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
                color: context.colors.primary.withOpacity(0.25),
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
                            color: Colors.white.withOpacity(0.9),
                            strokeWidth: 4,
                          ),
                        ),
                      ),
                    )
                    : Icon(
                      Icons.add_link_rounded,
                      size: 64,
                      color: Colors.white.withOpacity(0.9),
                    ),
                const SizedBox(height: 12),
                Text(
                  animate
                      ? "Bağlantı taranıyor..."
                      : "Bağlantı önizlemesi burada görünecek",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
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
  Widget _buildImageBackground() {
    return Stack(
      key: const ValueKey('image'),
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: _ogMetadata!.imageUrl!,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          placeholder:
              (context, url) => _buildPlatformBackground(animate: true),
          errorWidget: (context, url, error) => _buildPlatformBackground(),
        ),
      ],
    );
  }

  // Reusable Ambient Animation Core (Liftoff Particles)
  Widget _buildAmbientAnimationCore({double scale = 1.0}) {
    // Scale is ignored in Particle simulation (it fills space),
    // but if needed we could pass it. For now, filling space is better.
    return _ParticleBackground(color: context.colors.primary);
  }

  // ============== CONTROL CENTER ==============

  Widget _buildControlCenter() {
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
            hint: _isNoteMode ? "Başlık *" : "Başlık ekle (opsiyonel)",
            isTitle: true,
          ),

          const SizedBox(height: 12),

          // Note Input (Larger in Note Mode - but keep collection visible)
          _buildInputField(
            controller: _noteController,
            icon: PhosphorIconsThin.notePencil, // Thin
            hint: _isNoteMode ? "Not *" : "Kişisel not ekle (opsiyonel)",
            maxLines: _isNoteMode ? 10 : 3, // Balanced size to show collection
          ),

          // Note Image Picker (Only in Note Mode)
          if (_isNoteMode) ...[
            const SizedBox(height: 16),
            _buildNoteImagePicker(),
          ],

          const SizedBox(height: 18), // Equal spacing
          // Category Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Koleksiyon Seç",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
              GestureDetector(
                onTap: () => _showAddCategoryDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIconsBold.plus,
                    size: 16,
                    color: context.colors.primary,
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
                _isLoadingCategories
                    ? const Center(child: CupertinoActivityIndicator())
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.none,
                      // Hide "Hızlı" from UI - it's used silently for uncategorized items
                      itemCount:
                          _categories.where((c) => c.name != 'Hızlı').length,
                      itemBuilder: (context, index) {
                        final visibleCategories =
                            _categories
                                .where((c) => c.name != 'Hızlı')
                                .toList();
                        final cat = visibleCategories[index];
                        return _buildCategoryChip(cat);
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
    final hasImage = _selectedNoteImage != null || (_noteImageUrl != null && _noteImageUrl!.isNotEmpty);
    
    return Container(
      decoration: BoxDecoration(
        color: context.colors.body.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage ? context.colors.primary.withOpacity(0.3) : Colors.transparent,
          width: hasImage ? 1.5 : 0,
        ),
      ),
      child: hasImage ? _buildImagePreview() : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
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
                    context.colors.primary.withOpacity(0.15),
                    context.colors.secondary.withOpacity(0.15),
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
                    "Görsel Ekle",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.headline,
                    ),
                  ),
                  Text(
                    "Opsiyonel - Notuna görsel ekleyebilirsin",
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
              child: _selectedNoteImage != null
                  ? Image.file(
                      _selectedNoteImage!,
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      imageUrl: _noteImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: context.colors.backgroundTop,
                        child: const Center(child: CupertinoActivityIndicator()),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: context.colors.backgroundTop,
                        child: Icon(PhosphorIconsBold.imageSquare, color: context.colors.hint),
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
                  "Görsel Eklendi",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.headline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedNoteImage != null ? "Yeni görsel seçildi" : "Mevcut görsel",
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
              GestureDetector(
                onTap: _pickNoteImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIconsBold.pencilSimple,
                    size: 18,
                    color: context.colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Remove Image
              GestureDetector(
                onTap: _removeNoteImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsBold.trash,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              color: context.colors.hint.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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
                  textInputAction: isMultiLine ? TextInputAction.newline : TextInputAction.done,
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
                      color: context.colors.body.withOpacity(0.6),
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
        // Visible "Tamam" button for multi-line fields
        if (isMultiLine)
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => FocusScope.of(context).unfocus(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colors.primary, // Solid primary color
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Tamam',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Link Input (Editable)
  Widget _buildLinkPreview() {
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
        border: Border.all(color: themeColor.withOpacity(0.5), width: 1.0),
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
                hintText: "Bağlantını buraya yapıştır",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 15, // Matched with Title Input
                  color: context.colors.body.withOpacity(0.6),
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
  Widget _buildCategoryChip(CategoryModel cat) {
    final bool isSelected = _selectedCategoryIds.contains(cat.id);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap:
            () => setState(() {
              if (isSelected) {
                _selectedCategoryIds.remove(cat.id);
              } else {
                // If selecting a non-Quick category, auto-deselect "Hızlı"
                if (cat.name != 'Hızlı') {
                  try {
                    final quickCat = _categories.firstWhere(
                      (c) => c.name == 'Hızlı',
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
                        context.colors.secondary.withOpacity(0.5),
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
              color: isSelected ? Colors.transparent : context.colors.secondary,
              width: 1.5,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: context.colors.secondary.withOpacity(0.35),
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
    );
  }

  // ============== MODE TOGGLE (Slide Action Style) ==============

  Widget _buildModeToggle() {
    // If in edit mode, show static title instead of toggle
    if (widget.editItem != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            _isNoteMode ? "Notu Düzenle" : "İçeriği Düzenle",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return GestureDetector(
          onTap: () {
            setState(() {
              _isNoteMode = !_isNoteMode;
              if (_isNoteMode) {
                _hasLink = false;
                _detectedLink = "";
                _ogMetadata = null;
              }
            });
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: context.colors.body.withOpacity(0.06),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: context.colors.body.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Center Text
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _isNoteMode ? "İçerik Moduna Geç" : "Not Moduna Geç",
                      key: ValueKey(_isNoteMode),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.colors.body.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),

                // Right Arrows (when in content mode) - ANIMATED
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: !_isNoteMode ? 1.0 : 0.0,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _arrowAnimationController,
                        builder: (context, child) {
                          final offset = _arrowAnimationController.value * 4;
                          return Transform.translate(
                            offset: Offset(offset, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIconsBold.caretRight,
                                  size: 12,
                                  color: context.colors.body.withOpacity(0.25),
                                ),
                                Icon(
                                  PhosphorIconsBold.caretRight,
                                  size: 12,
                                  color: context.colors.body.withOpacity(0.4),
                                ),
                                Icon(
                                  PhosphorIconsBold.caretRight,
                                  size: 12,
                                  color: context.colors.body.withOpacity(0.55),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Left Arrows (when in note mode) - ANIMATED
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isNoteMode ? 1.0 : 0.0,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _arrowAnimationController,
                        builder: (context, child) {
                          final offset = _arrowAnimationController.value * -4;
                          return Transform.translate(
                            offset: Offset(offset, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIconsBold.caretLeft,
                                  size: 12,
                                  color: context.colors.body.withOpacity(0.55),
                                ),
                                Icon(
                                  PhosphorIconsBold.caretLeft,
                                  size: 12,
                                  color: context.colors.body.withOpacity(0.4),
                                ),
                                Icon(
                                  PhosphorIconsBold.caretLeft,
                                  size: 12,
                                  color: context.colors.body.withOpacity(0.25),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Sliding Circle Indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  left: _isNoteMode ? totalWidth - 52 : 4,
                  top: 4,
                  bottom: 4,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.colors.primary,
                          context.colors.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isNoteMode
                              ? PhosphorIconsBold.link
                              : PhosphorIconsBold.notePencil,
                          key: ValueKey(_isNoteMode ? 'link' : 'note'),
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============== FLOATING DOCK ==============

  Widget _buildFloatingDock() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveContent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colors.primary,
              context.colors.secondary,
            ], // Slogan Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: context.colors.secondary.withOpacity(
                0.3,
              ), // Matching shadow
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child:
              _isSaving
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.editItem != null ? "Kaydet" : "Koleksiyona Ekle",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  // ============== HELPER WIDGETS ==============

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          shape: BoxShape.circle, // Circular
          border: Border.all(
            color: context.colors.hint.withOpacity(0.3),
            width: 1,
          ), // Grey Border
          boxShadow: [
            BoxShadow(
              color: context.colors.premiumShadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          PhosphorIconsLight.x, // Changed to X for modal close
          size: 20,
          color: context.colors.headline,
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          shape: BoxShape.circle, // Updated to Circle
          border: Border.all(
            color: context.colors.hint.withOpacity(0.3),
            width: 1,
          ), // Updated to grey border
          boxShadow: [
            BoxShadow(
              color: context.colors.premiumShadow.withOpacity(
                0.1,
              ), // Updated opacity
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: context.colors.headline),
      ),
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

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'x':
      case 'twitter':
        return const Color(0xFF000000);
      case 'tiktok':
        return const Color(0xFF010101);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'spotify':
        return const Color(0xFF1DB954);
      case 'pinterest':
        return const Color(0xFFBD081C);
      case 'reddit':
        return const Color(0xFFFF4500);
      case 'medium':
        return const Color(0xFF000000);
      case 'behance':
        return const Color(0xFF1769FF);
      case 'dribbble':
        return const Color(0xFFEA4C89);

      default:
        return context.colors.primary;
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
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
                  Navigator.pop(context);
                  // Auto-select the new category
                  setState(() {
                    _selectedCategoryIds.clear();
                    _selectedCategoryIds.add(newCategory.id);
                  });
                  // Force refresh categories
                  await _loadCategories();
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
    return Container(
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
            'Yeni Koleksiyon',
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
              hintText: 'Koleksiyon Adı',
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
                'Oluştur',
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
class _WavyStreamPainter extends CustomPainter {
  final double animationValue;
  final Color streamColor;

  _WavyStreamPainter({required this.animationValue, required this.streamColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Stream parameters
    final streamWidth = size.width * 0.15; // Width of the stream
    final centerX = size.width / 2;
    final waveAmplitude = size.width * 0.08; // How much the stream curves
    final waveFrequency = 3.0; // Number of waves
    final phaseShift = animationValue * 2 * math.pi; // Animated phase

    // Draw multiple layers for soft glow effect
    for (int layer = 0; layer < 3; layer++) {
      final layerWidth = streamWidth + (layer * 15);
      final layerOpacity =
          (0.15 - (layer * 0.04)) * (0.5 + animationValue * 0.5);

      final path = Path();

      // Start from top center (slightly offset for each layer)
      path.moveTo(centerX - layerWidth / 2, 0);

      // Draw left edge with sine wave
      for (double y = 0; y <= size.height; y += 5) {
        final progress = y / size.height;
        final fadeMultiplier = 1.0 - (progress * progress); // Quadratic fade
        final wave =
            math.sin((progress * waveFrequency * math.pi) + phaseShift) *
            waveAmplitude *
            fadeMultiplier;
        final x = centerX - (layerWidth / 2) * fadeMultiplier + wave;
        path.lineTo(x, y);
      }

      // Draw right edge with sine wave (reverse)
      for (double y = size.height; y >= 0; y -= 5) {
        final progress = y / size.height;
        final fadeMultiplier = 1.0 - (progress * progress);
        final wave =
            math.sin((progress * waveFrequency * math.pi) + phaseShift) *
            waveAmplitude *
            fadeMultiplier;
        final x = centerX + (layerWidth / 2) * fadeMultiplier + wave;
        path.lineTo(x, y);
      }

      path.close();

      paint.color = streamColor.withOpacity(layerOpacity);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavyStreamPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ==========================================
// LIFTOFF PARTICLE SYSTEM
// ==========================================

class _ParticleBackground extends StatefulWidget {
  final Color color;
  const _ParticleBackground({required this.color});

  @override
  State<_ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<_ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  Offset? _touchPosition;
  final int _particleCount = 120;

  @override
  void initState() {
    super.initState();
    // Initialize Particles
    _particles = List.generate(
      _particleCount,
      (index) => _ArticleFactory.createRandom(),
    );

    // Animation Loop
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(_updateParticles)
          ..repeat();
  }

  void _updateParticles() {
    for (var p in _particles) {
      // 1. Upward Movement (Liftoff)
      p.y -= p.speed;

      // 2. Interaction (Magnetic Repulsion)
      if (_touchPosition != null) {
        final double dx = p.x - _touchPosition!.dx;

        // Aspect ratio correction for Y to make interaction circular
        // Otherwise repulsion is oval if screen is non-square.
        // Assuming roughly 9:16, but simple is fine for now.
        final double dy = p.y - _touchPosition!.dy;

        final double dist = math.sqrt(dx * dx + dy * dy);

        // Repulsion Radius in normalized space (0.0 to 1.0)
        // 0.2 = ~20% of screen width
        const double repulsionRadius = 0.25;

        if (dist < repulsionRadius) {
          final double force = (repulsionRadius - dist) / repulsionRadius;

          // Gentle Nudge (Velocity-ish)
          // Previously 5.0 caused teleportation. Now 0.02.
          final double strength = 0.02 * force;

          p.x += (dx / dist) * strength;
          p.y += (dy / dist) * strength;
        }
      }

      // 3. Reset loop
      if (p.y < -0.1) {
        p.y = 1.1; // Reset to bottom
        p.x = math.Random().nextDouble();
      }

      // Wrap X
      if (p.x < 0) p.x += 1.0;
      if (p.x > 1) p.x -= 1.0;

      // Wrap Y Bottom (if pushed down)
      if (p.y > 1.1) p.y = -0.1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sync touch coordinates to 0..1 space or pixel space?
        // Let's use Pixel space in Painter, normalized in Model?
        // Model is 0..1 for easier resizing.
        return MouseRegion(
          onHover: (event) {
            final size = context.size;
            if (size != null) {
              setState(() {
                _touchPosition = Offset(
                  event.localPosition.dx / size.width,
                  event.localPosition.dy / size.height,
                );
              });
            }
          },
          onExit: (_) => setState(() => _touchPosition = null),
          child: GestureDetector(
            onPanUpdate: (details) {
              final size = context.size;
              if (size != null) {
                setState(() {
                  _touchPosition = Offset(
                    details.localPosition.dx / size.width,
                    details.localPosition.dy / size.height,
                  );
                });
              }
            },
            onPanEnd: (_) => setState(() => _touchPosition = null),
            child: CustomPaint(
              size: Size.infinite,
              painter: _ParticlePainter(
                particles: _particles,
                color: widget.color.withOpacity(0.6), // Base color
                repaint: _controller,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  double x; // 0..1
  double y; // 0..1
  double speed;
  double size;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _ArticleFactory {
  static final _rng = math.Random();

  static _Particle createRandom() {
    return _Particle(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      speed: 0.001 + (_rng.nextDouble() * 0.004), // Varies speed for Parallax
      size: 1.0 + (_rng.nextDouble() * 3.0), // 1..4 radius
      opacity: 0.2 + (_rng.nextDouble() * 0.6), // 0.2..0.8
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.color,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      paint.color = color.withOpacity(p.opacity * 0.6); // Global dim

      final dx = p.x * size.width;
      final dy = p.y * size.height;

      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

// ============== ALERT BOTTOM SHEET ==============
enum _AlertType { success, warning, error }

class _AlertBottomSheet extends StatefulWidget {
  final String title;
  final String message;
  final _AlertType type;

  const _AlertBottomSheet({
    super.key,
    required this.title,
    required this.message,
    required this.type,
  });

  @override
  State<_AlertBottomSheet> createState() => _AlertBottomSheetState();
}

class _AlertBottomSheetState extends State<_AlertBottomSheet> {
  @override
  void initState() {
    super.initState();
    // 2 saniye sonra otomatik kapan
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Yağ Yeşili Gradient Zemin
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary, // Derin Adaçayı
            context.colors.secondary, // Biraz daha canlı ton
          ],
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
                    color: Colors.white.withOpacity(0.3), // Beyaz Opak Handle
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 32),

                // Icon Circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // Beyaz Opak Zemin
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        widget.type == _AlertType.success
                            ? const Icon(
                              PhosphorIconsBold.check,
                              color: Colors.white,
                              size: 32,
                            )
                            : Text(
                              "!",
                              style: GoogleFonts.poppins(
                                fontSize: 32, // Biraz küçültüldü
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
                    color: Colors.white, // Başlık Beyaz
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
                    color: Colors.white.withOpacity(
                      0.9,
                    ), // Hafif kırık beyaz mesaj
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
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    PhosphorIconsLight.x,
                    size: 20,
                    color: Colors.white.withOpacity(0.8), // Beyaz X butonu
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
