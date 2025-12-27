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
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;


import 'dart:math' as math;
import 'package:somine_app/core/design/app_colors.dart';

class AddContentScreen extends StatefulWidget {
  final String? initialText;

  const AddContentScreen({super.key, this.initialText});

  @override
  State<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends State<AddContentScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _linkController = TextEditingController(); // New Link Controller
  final CategoryRepository _categoryRepository = CategoryRepository();
  final ItemRepository _itemRepository = ItemRepository();

  // Animation
  late AnimationController _textAnimationController;
  late Animation<double> _textAnimation;

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

  // ============== COLORS ==============
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _linkController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  // ============== BUSINESS LOGIC ==============

  Future<void> _loadCategories() async {
    const userId = "user_1";
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
      const userId = "user_1";
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
        Navigator.pop(context);
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeroStage(),
                if (_hasLink || _isManualEntry) _buildControlCenter(),
                const SizedBox(height: 140),
              ],
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
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
  }

  // ============== HERO STAGE ==============

  Widget _buildHeroStage() {
    final size = MediaQuery.of(context).size;
    // If has link -> 38% height
    // If manual entry -> 25% height (smaller header)
    // If empty -> 75% height
    double stageHeight;
    if (_hasLink) {
      stageHeight = size.height * 0.38;
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
              child: _isLoadingMetadata
                  ? _buildLoadingState()
                  : hasImage
                      ? _buildImageBackground()
                      : _hasLink
                          ? _buildPlatformBackground()
                          : _buildManualEntryHeader(),
            ),

            // Bottom Fade (only when has image)
            if (hasImage || _hasLink)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white,
                      ],
                    ),
                  ),
                ),
              ),

            // Clear Button (Visible if has link OR manual entry)
            if ((_hasLink || _isManualEntry) && !_isLoadingMetadata)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: _buildCircleButton(
                  icon: PhosphorIconsLight.x,
                  onTap: _clearContent,
                ),
              ),

            // Platform Icon at Bottom Right (minimal, no bg)
            if (_hasLink && !_isLoadingMetadata)
              Positioned(
                bottom: 20,
                right: 24,
                child: Icon(
                  _getPlatformIcon(_detectedPlatform),
                  size: 24,
                  color: _getPlatformColor(_detectedPlatform).withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Manual Entry Header (God Ray / Spotlight Cone Effect)
  Widget _buildManualEntryHeader() {
    return AnimatedBuilder(
      animation: _textAnimation,
      builder: (context, child) {
        return Container(
          key: const ValueKey('manual'),
          width: double.infinity,
          height: double.infinity,
          // Dark Background for Contrast
          color: Colors.black.withOpacity(0.06),
          child: Stack(
            children: [
              // Wave Animation (Right to Left - Large Cloud, Seamless Loop)
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    // Eased animation for ultra-smooth motion
                    final easedValue = Curves.easeInOut.transform(_textAnimation.value);
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          // Large cloud: wider range (3.5x) for bigger coverage
                          // When this exits left, next one enters right (seamless)
                          begin: Alignment(2.0 - (easedValue * 3.5), 0),
                          end: Alignment(-1.5 - (easedValue * 3.5), 0),
                          colors: [
                            Colors.white.withOpacity(0.0),         // Soft start
                            AppColors.secondary.withOpacity(0.2),  // Cloud edge
                            AppColors.secondary.withOpacity(0.5),  // Light
                            AppColors.secondary.withOpacity(0.8),  // Medium
                            AppColors.secondary,                   // Full Gold center
                            AppColors.secondary.withOpacity(0.8),  // Medium
                            AppColors.secondary.withOpacity(0.5),  // Light
                            AppColors.secondary.withOpacity(0.2),  // Cloud edge
                            Colors.white.withOpacity(0.0),         // Soft end
                          ],
                          stops: const [0.0, 0.05, 0.15, 0.3, 0.5, 0.7, 0.85, 0.95, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom Fade to White (for Text readability)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 180,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.9),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Text Content
              Positioned(
                bottom: 20,
                left: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sahnedesin",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headline,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Koleksiyonuna yeni içerik ekle.",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // Loading State
  Widget _buildLoadingState() {
    return Container(
      key: const ValueKey('loading'),
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Platform Icon
            Icon(
              _getPlatformIcon(_detectedPlatform),
              size: 64,
              color: _getPlatformColor(_detectedPlatform),
            ),
            const SizedBox(height: 32),

            // Loading Indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getPlatformColor(_detectedPlatform),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "$_detectedPlatform yükleniyor...",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.body,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Platform Background (no OG image)
  Widget _buildPlatformBackground() {
    return Container(
      key: const ValueKey('platform'),
      color: Colors.white,
      child: Center(
        child: Icon(
          _getPlatformIcon(_detectedPlatform),
          size: 100,
          color: _getPlatformColor(_detectedPlatform).withValues(alpha: 0.15),
        ),
      ),
    );
  }

  // Image Background
  Widget _buildImageBackground() {
    return Stack(
      key: const ValueKey('image'),
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: _ogMetadata!.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildLoadingState(),
          errorWidget: (context, url, error) => _buildPlatformBackground(),
        ),

        // Light overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  // ============== CONTROL CENTER ==============

  Widget _buildControlCenter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Link Preview / Input (Show if link detected OR manual entry mode)
          if (_hasLink || _isManualEntry) ...[
             _buildLinkPreview(),
             const SizedBox(height: 16),
          ],
          
          // Title Input
          _buildInputField(
            controller: _titleController,
            icon: PhosphorIconsLight.pencilSimple, // Updated Icon
            hint: "Başlık ekle (opsiyonel)",
            isTitle: true,
          ),
          
          const SizedBox(height: 12),

          // Note Input
          _buildInputField(
            controller: _noteController,
            icon: PhosphorIconsLight.notePencil,
            hint: "Kişisel not ekle (opsiyonel)",
            maxLines: 3,
          ),

          const SizedBox(height: 32),

          // Category Section Header
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Koleksiyon Seç",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headline,
                ),
              ),
              const Spacer(),
              Text(
                "Birden fazla seçilebilir",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.body,
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Standardized Height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                fontSize: isTitle ? 15 : 14,
                fontWeight: isTitle ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.headline,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: isTitle ? 15 : 14,
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
    final platformColor = hasPlatform ? _getPlatformColor(_detectedPlatform) : AppColors.secondary;
    final platformIcon = hasPlatform ? _getPlatformIcon(_detectedPlatform) : PhosphorIconsRegular.link;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Standardized Height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: platformColor.withValues(alpha: hasPlatform ? 0.25 : 1.0),
          width: 1.5,
        ),
        boxShadow: hasPlatform ? [
           BoxShadow(
            color: platformColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          // Platform Icon
          Container(
            padding: const EdgeInsets.all(4), // Reduced padding to match height
            decoration: BoxDecoration(
              color: platformColor.withValues(alpha: hasPlatform ? 0.08 : 0.0),
              borderRadius: BorderRadius.circular(8), // Adjusted radius
            ),
            child: Icon(
              platformIcon,
              size: 18, // Reduced size to match Title Field icon
              color: hasPlatform ? platformColor : AppColors.body,
            ),
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
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.headline,
              ),
              decoration: InputDecoration(
                hintText: "Bağlantı yapıştır...",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
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
          color: AppColors.accentDark, // Brand Color (Matching FAB)
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentDark.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? SizedBox(
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
                      PhosphorIconsBold.plus, // Changed to Plus
                      size: 20,
                      color: Colors.white, // White Text/Icon
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Koleksiyona Ekle",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // White Text/Icon
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          PhosphorIconsLight.caretLeft,
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
        return PhosphorIconsBold.instagramLogo;
      case 'youtube':
        return PhosphorIconsBold.youtubeLogo;
      case 'x':
      case 'twitter':
        return PhosphorIconsBold.xLogo;
      case 'tiktok':
        return PhosphorIconsBold.tiktokLogo;
      case 'linkedin':
        return PhosphorIconsBold.linkedinLogo;
      case 'spotify':
        return PhosphorIconsBold.spotifyLogo;
      case 'pinterest':
        return PhosphorIconsBold.pinterestLogo;
      case 'reddit':
        return PhosphorIconsBold.redditLogo;
      case 'medium':
        return PhosphorIconsBold.mediumLogo;
      case 'behance':
        return PhosphorIconsBold.behanceLogo;
      case 'dribbble':
        return PhosphorIconsBold.dribbbleLogo;
      default:
        return PhosphorIconsBold.globe;
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
