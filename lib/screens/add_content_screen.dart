import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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


import 'dart:math' as math;
import 'dart:ui' as import_dart_ui;
import 'package:somine_app/core/design/app_colors.dart';

class AddContentScreen extends StatefulWidget {
  final String? initialText;

  const AddContentScreen({super.key, this.initialText});

  @override
  State<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends State<AddContentScreen> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _linkController = TextEditingController(); // New Link Controller
  final CategoryRepository _categoryRepository = CategoryRepository();
  final ItemRepository _itemRepository = ItemRepository();

  // Animation
  late AnimationController _textAnimationController;
  late Animation<double> _textAnimation;
  late AnimationController _loadingController;
  late AnimationController _rotationController;

  // State
  bool _isSaving = false;
  bool _isLoadingMetadata = false;
  bool _isManualEntry = true; // Default to true (Skip splash)

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

  // ============== COLORS ==============

  void _resolveImageSize(String imageUrl) {
    if (imageUrl.isEmpty) return;
    
    // Reset first
    setState(() => _imageAspectRatio = null);

    final ImageProvider provider = CachedNetworkImageProvider(imageUrl);
    
    provider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool synchronousCall) {
        if (!mounted) return;
        final myImage = info.image;
        setState(() {
          _imageAspectRatio = myImage.width / myImage.height;
        });
      }, onError: (exception, stackTrace) {
        debugPrint("Image resolution error: $exception");
      }),
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
    _textAnimation = Tween<double>(begin: 0, end: 1).animate(_textAnimationController);

    // Check clipboard on open to show notice (auto: true just sets the flag)
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (widget.initialText != null && widget.initialText!.isNotEmpty) {
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
    super.dispose();
  }

  // ============== BUSINESS LOGIC ==============

  Future<void> _loadCategories() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) _useFallbackCategories();
      return;
    }

    try {
      final categories = await _categoryRepository.getCategories(userId);
      if (mounted) {
        // If Firestore returns empty, use fallback
        if (categories.isEmpty) {
          _useFallbackCategories();
        } else {
          setState(() {
            _categories = categories;
            _isLoadingCategories = false;

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
        CategoryModel(id: 'seyahat', userId: 'user_1', name: 'Seyahat', icon: '✈️', createdAt: now, updatedAt: now),
        CategoryModel(id: 'spor', userId: 'user_1', name: 'Spor', icon: '🏀', createdAt: now, updatedAt: now),
        CategoryModel(id: 'muzik', userId: 'user_1', name: 'Müzik', icon: '🎵', createdAt: now, updatedAt: now),
        CategoryModel(id: 'komik', userId: 'user_1', name: 'Komik', icon: '😂', createdAt: now, updatedAt: now),
        CategoryModel(id: 'tasarim', userId: 'user_1', name: 'Tasarım', icon: '🎨', createdAt: now, updatedAt: now),
        CategoryModel(id: 'fikir', userId: 'user_1', name: 'Fikir', icon: '💡', createdAt: now, updatedAt: now),
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
    if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be')) return 'YouTube';
    if (lowerUrl.contains('twitter.com') || lowerUrl.contains('x.com')) return 'X';
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
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final metaTags = document.getElementsByTagName('meta');

        String? title, description, image, siteName;

        for (var tag in metaTags) {
          final property = tag.attributes['property'];
          final name = tag.attributes['name'];
          final content = tag.attributes['content'];

          if (content == null) continue;

          if (property == 'og:title' || name == 'title') title = content;
          if (property == 'og:description' || name == 'description') {
            description = content;
          }
          if (property == 'og:image' || name == 'image') image = content;
          if (property == 'og:site_name') siteName = content;
        }

        if (mounted) {
          setState(() {
            _ogMetadata = OGMetadata(
              title: title,
              description: description,
              imageUrl: image,
              siteName: siteName ?? _detectedPlatform,
            );
            if (title != null && _titleController.text.isEmpty) {
              _titleController.text = title;
            }
            if (image != null) {
              _resolveImageSize(image);
            }
          });
        }
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
        if (url != _detectedLink) {
           setState(() {
              _detectedLink = url;
              _detectedPlatform = _detectPlatform(url);
              _hasLink = true;
              _isManualEntry = false;
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
    });
  }

  Future<void> _saveContent() async {
    if (_titleController.text.isEmpty &&
        _noteController.text.isEmpty &&
        !_hasLink) {
      return;
    }
    if (_selectedCategoryIds.isEmpty) {
      _showError("Lütfen en az bir koleksiyon seçin");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        if (mounted) _showError("Oturum açmanız gerekiyor");
        return;
      }
      
      final noteText = _noteController.text.isNotEmpty
          ? _noteController.text
          : _titleController.text;

      final futures = _selectedCategoryIds.map((catId) {
        final newItem = ItemModel(
          id: '',
          userId: userId,
          categoryId: catId,
          type: _hasLink ? ItemType.link : ItemType.note,
          url: _hasLink ? _detectedLink : null,
          note: noteText,
          ogMetadata: _ogMetadata,
          createdAt: now,
          updatedAt: now,
        );
        return _itemRepository.createItem(newItem);
      });

      await Future.wait(futures);

      if (mounted) {
        Navigator.pop(context, true);
        _showSuccess("${_selectedCategoryIds.length} koleksiyona eklendi");
      }
    } catch (e) {
      debugPrint("Save error: $e");
      if (mounted) _showError("Bir hata oluştu");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============== UI BUILD ==============

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.6,
      maxChildSize: 1.0,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              // Main Content
              SingleChildScrollView(
                controller: scrollController, // Crucial for drag-to-dismiss
                physics: const AlwaysScrollableScrollPhysics(), // Ensure drag works even if content is short
                child: Column(
                  children: [
                    _buildHeroStage(),
                    if (_hasLink || _isManualEntry) _buildControlCenter(),
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

              // Floating CTA Dock
              // Show dock if we have a link OR we are in manual entry mode
              if (_hasLink || _isManualEntry)
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: _buildFloatingDock(),
                ),
            ],
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
        double calculatedRatio = (size.width / _imageAspectRatio!) / size.height;
        if (calculatedRatio > 0.65) calculatedRatio = 0.65;
        // Relaxing lower bound to allow landscape images to fit fully without zoom
        if (calculatedRatio < 0.20) calculatedRatio = 0.20; 
        stageHeight = size.height * calculatedRatio;
      } else {
         stageHeight = size.height * 0.30; // Reduced default height to prevent excessive cropping during load
      }
    } else if (_isManualEntry) {
      stageHeight = size.height * 0.40;  // Increased from 0.25 
    } else {
      stageHeight = size.height * 0.75;
    }

    final hasImage = _ogMetadata?.imageUrl != null;

    return GestureDetector(
      // Only check clipboard if we are in the initial empty state
      onTap: (!_hasLink && !_isManualEntry && !_isLoadingMetadata) ? () => _checkClipboardAndProcess(auto: false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: stageHeight,
        width: double.infinity,
        color: Colors.white,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Layer
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: hasImage
                      ? _buildImageBackground()
                      : _buildPlatformBackground(animate: _isLoadingMetadata),
            ),



            // Clear Button (Visible if has link OR manual entry)
            if ((_hasLink || _isManualEntry) && !_isLoadingMetadata)
              Positioned(
                top: 56, // Aligned with Close button
                right: 16,
                child: _buildCircleButton(
                  icon: PhosphorIconsLight.trash, // Changed to Trash to avoid confusion with Close X
                  onTap: _clearContent,
                ),
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
      color: Colors.white,
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
                      AppColors.primary, // Filled Color (Green)
                      AppColors.primary.withOpacity(0.15), // Empty Color (Light Green)
                    ],
                    stops: [
                      _loadingController.value, // Fill level moves from 0.0 to 1.0
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
              color: AppColors.headline,
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
        final startAlign = Alignment.lerp(Alignment.topLeft, Alignment.topCenter, shimmer)!;
        final endAlign = Alignment.lerp(Alignment.bottomRight, Alignment.bottomCenter, shimmer)!;
        
        return Container(
          key: const ValueKey('platform'),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white, // Fallback
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: animate 
                  ? [
                      const Color(0xFF6E8E91), 
                      Color.lerp(const Color(0xFF6FBFAC), Colors.white, shimmer * 0.3)!, // Subtle lighten
                      const Color(0xFF6FBFAC)
                    ]
                  : [const Color(0xFF6E8E91), const Color(0xFF6FBFAC)],
              begin: startAlign,
              end: endAlign,
              stops: animate ? [0.0, 0.5 + (shimmer * 0.5), 1.0] : null,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6E8E91).withOpacity(0.25),
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
                  animate ? "Bağlantı taranıyor..." : "Bağlantı önizlemesi burada görünecek",
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
          placeholder: (context, url) => _buildPlatformBackground(animate: true),
          errorWidget: (context, url, error) => _buildPlatformBackground(),
        ),
      ],
    );
  }

  // Reusable Ambient Animation Core (Liftoff Particles)
  Widget _buildAmbientAnimationCore({double scale = 1.0}) {
      // Scale is ignored in Particle simulation (it fills space), 
      // but if needed we could pass it. For now, filling space is better.
      return _ParticleBackground(color: AppColors.primary);
  }

  // ============== CONTROL CENTER ==============

  Widget _buildControlCenter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          // Link Preview / Input (Show if link detected OR manual entry mode)
          if (_hasLink || _isManualEntry) ...[
             _buildLinkPreview(),
             const SizedBox(height: 16),
          ],
          
          // Title Input
          _buildInputField(
            controller: _titleController,
            icon: PhosphorIconsThin.pencilSimple, // Thin
            hint: "Başlık ekle (opsiyonel)",
            isTitle: true,
          ),
          
          const SizedBox(height: 12),

          // Note Input
          _buildInputField(
            controller: _noteController,
            icon: PhosphorIconsThin.notePencil, // Thin
            hint: "Kişisel not ekle (opsiyonel)",
            maxLines: 3,
          ),

          const SizedBox(height: 32),

          // Category Section Header
          Text(
            "Koleksiyon Seç",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 16),

          // Category Chips
          SizedBox(
            height: 44,
            child: _isLoadingCategories
                ? const Center(child: CupertinoActivityIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return _buildCategoryChip(cat);
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Selected Count
          if (_selectedCategoryIds.isNotEmpty)
            Center(
              child: Text(
                "${_selectedCategoryIds.length} koleksiyon seçildi",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
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
    return Container(
      height: maxLines == 1 ? 52 : null, // Fix height for single line inputs (Title)
      alignment: maxLines == 1 ? Alignment.center : Alignment.topLeft,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1), // Subtle border
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 2 : 0),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.body,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: AppColors.primary,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.headline,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.body.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero, 
              ),
              maxLines: maxLines,
              minLines: maxLines > 1 ? 2 : 1,
            ),
          ),
        ],
      ),
    );
  }

  // Link Input (Editable)
  Widget _buildLinkPreview() {
    final hasPlatform = _detectedPlatform.isNotEmpty;
    // Always use Primary Brand Color to match design, ignoring platform specific colors (e.g. Red for YouTube)
    final themeColor = AppColors.primary; 
    final platformIcon = hasPlatform ? _getPlatformIcon(_detectedPlatform) : PhosphorIconsThin.link;

    return Container(
      height: 52, // Fixed height to match filled state stability
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16), 
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(12),
        // Always use Primary Color border
        border: Border.all(
          color: themeColor.withOpacity(0.5), 
          width: 1.0
        ),
      ),
      child: Row(
        children: [
          // Platform Icon
          Icon(
            platformIcon,
            size: 18, 
            color: themeColor,
          ),
          const SizedBox(width: 12),

          // Editable Link Field
          Expanded(
            child: TextField(
              controller: _linkController,
              onChanged: _onLinkChanged,
              onTap: () {
                if (_linkController.text.isEmpty) {
                   _checkClipboardAndProcess(auto: false); // Prompt paste if empty
                }
              },
              cursorColor: AppColors.primary,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.poppins(
                fontSize: 15, // Matched with Title Input
                fontWeight: FontWeight.w400,
                color: AppColors.headline,
              ),
              decoration: InputDecoration(
                hintText: "Bağlantını buraya yapıştır",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 15, // Matched with Title Input
                  color: AppColors.body.withValues(alpha: 0.6),
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
                color: AppColors.body,
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
        onTap: () => setState(() {
          if (isSelected) {
            _selectedCategoryIds.remove(cat.id);
          } else {
            _selectedCategoryIds.add(cat.id);
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [AppColors.secondary.withValues(alpha: 0.5), AppColors.surfaceWhite],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.secondary,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.35),
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
                  color: isSelected ? AppColors.headline : AppColors.body,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  PhosphorIconsBold.check,
                  size: 12,
                  color: AppColors.headline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============== FLOATING DOCK ==============

  Widget _buildFloatingDock() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveContent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF6FBFAC)], // Slogan Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6FBFAC).withOpacity(0.3), // Matching shadow
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
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
                      PhosphorIconsBold.plus, 
                      size: 20,
                      color: Colors.white, 
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Koleksiyona Ekle",
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
          color: Colors.white,
          shape: BoxShape.circle, // Circular
          border: Border.all(color: Colors.grey.shade300, width: 1), // Grey Border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          PhosphorIconsLight.x, // Changed to X for modal close
          size: 20,
          color: AppColors.headline,
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
          color: Colors.white,
          shape: BoxShape.circle, // Updated to Circle
          border: Border.all(color: Colors.grey.shade300, width: 1), // Updated to grey border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Updated opacity
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.headline,
        ),
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
        return AppColors.primary;
    }
  }
}

// Custom Painter for Wavy Stream Effect (Flowing River)
class _WavyStreamPainter extends CustomPainter {
  final double animationValue;
  final Color streamColor;

  _WavyStreamPainter({
    required this.animationValue,
    required this.streamColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Stream parameters
    final streamWidth = size.width * 0.15; // Width of the stream
    final centerX = size.width / 2;
    final waveAmplitude = size.width * 0.08; // How much the stream curves
    final waveFrequency = 3.0; // Number of waves
    final phaseShift = animationValue * 2 * math.pi; // Animated phase

    // Draw multiple layers for soft glow effect
    for (int layer = 0; layer < 3; layer++) {
      final layerWidth = streamWidth + (layer * 15);
      final layerOpacity = (0.15 - (layer * 0.04)) * (0.5 + animationValue * 0.5);
      
      final path = Path();
      
      // Start from top center (slightly offset for each layer)
      path.moveTo(centerX - layerWidth / 2, 0);
      
      // Draw left edge with sine wave
      for (double y = 0; y <= size.height; y += 5) {
        final progress = y / size.height;
        final fadeMultiplier = 1.0 - (progress * progress); // Quadratic fade
        final wave = math.sin((progress * waveFrequency * math.pi) + phaseShift) * waveAmplitude * fadeMultiplier;
        final x = centerX - (layerWidth / 2) * fadeMultiplier + wave;
        path.lineTo(x, y);
      }
      
      // Draw right edge with sine wave (reverse)
      for (double y = size.height; y >= 0; y -= 5) {
        final progress = y / size.height;
        final fadeMultiplier = 1.0 - (progress * progress);
        final wave = math.sin((progress * waveFrequency * math.pi) + phaseShift) * waveAmplitude * fadeMultiplier;
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

class _ParticleBackgroundState extends State<_ParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  Offset? _touchPosition;
  final int _particleCount = 120;

  @override
  void initState() {
    super.initState();
    // Initialize Particles
    _particles = List.generate(_particleCount, (index) => _ArticleFactory.createRandom());
    
    // Animation Loop
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
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
                    event.localPosition.dy / size.height
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
                      details.localPosition.dy / size.height
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
    final paint = Paint()
      ..style = PaintingStyle.fill;

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

