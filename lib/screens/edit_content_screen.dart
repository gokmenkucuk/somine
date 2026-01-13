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


import 'dart:ui' as import_dart_ui;
import 'dart:math' as math;
// import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';

class EditContentScreen extends StatefulWidget {
  final ItemModel item;

  const EditContentScreen({super.key, required this.item});

  @override
  State<EditContentScreen> createState() => _EditContentScreenState();
}

class _EditContentScreenState extends State<EditContentScreen> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _linkController = TextEditingController(); 
  final CategoryRepository _categoryRepository = CategoryRepository();
  final ItemRepository _itemRepository = ItemRepository();

  // Animation
  late AnimationController _loadingController;

  // State
  bool _isSaving = false;
  bool _isLoadingMetadata = false;
  bool _isManualEntry = true; 

  // Link Preview State
  bool _hasLink = false;
  String _detectedLink = "";
  String _detectedPlatform = "";
  OGMetadata? _ogMetadata;

  // Categories (Single-Select for Edit)
  final Set<String> _selectedCategoryIds = {};
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  
  // Dynamic Header
  double? _imageAspectRatio;

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

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initializeData();

    // Loading Animation
    _loadingController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _initializeData() {
    // Pre-fill data from ItemModel
    _titleController.text = widget.item.displayTitle;
    _noteController.text = widget.item.note ?? "";
    
    if (widget.item.categoryId != null) {
      _selectedCategoryIds.add(widget.item.categoryId!);
    }

    if (widget.item.url != null && widget.item.url!.isNotEmpty) {
      _processUrl(widget.item.url!);
    } else {
      _isManualEntry = true;
    }

    _ogMetadata = widget.item.ogMetadata;
    
    // Resolve initial image
    if (widget.item.displayImage != null) {
      _resolveImageSize(widget.item.displayImage!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _linkController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  // ============== BUSINESS LOGIC ==============

  Future<void> _loadCategories() async {
    const userId = "user_1";
    try {
      final categories = await _categoryRepository.getCategories(userId);
      if (mounted) {
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

  bool _isUrl(String text) {
    return RegExp(r'(https?:\/\/[^\s]+)').hasMatch(text);
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
        _linkController.text = url;
        _detectedPlatform = _detectPlatform(url);
        _hasLink = true;
        _isManualEntry = false;
      });
      
      // Only fetch metadata if it wasn't pre-filled or if link changed
      if (_ogMetadata == null || widget.item.url != url) {
        _fetchMetadata(url);
      }
    } else {
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
       _isManualEntry = true;
       // We don't clear title/note in edit mode as user might want to keep them
    });
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                          colors: [const Color(0xFFFF5252), const Color(0xFFD32F2F)],
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

  Future<void> _deleteItem() async {
    try {
      // 1. Delete from Repository
      await _itemRepository.deleteItem(widget.item.id);

      if (mounted) {
        // 2. Return success signal
        // Pop Edit Screen -> Returns to Detail Sheet
        // We pass 'true' to indicate update/delete
        Navigator.pop(context, true); 
      }
    } catch (e) {
      debugPrint("Delete error: $e");
      if (mounted) _showError("Silme işlemi başarısız");
    }
  }

  Future<void> _updateItem() async {
    if (_titleController.text.isEmpty &&
        _noteController.text.isEmpty &&
        !_hasLink) {
      return;
    }
    if (_selectedCategoryIds.isEmpty) {
      _showError("Lütfen bir koleksiyon seçin");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final noteText = _noteController.text.isNotEmpty
          ? _noteController.text
          : _titleController.text;
      
      final categoryId = _selectedCategoryIds.first; // Edit mode supports single category

      final updatedItem = widget.item.copyWith(
          categoryId: categoryId,
          type: _hasLink ? ItemType.link : ItemType.note,
          url: _hasLink ? _detectedLink : null,
          note: noteText,
          ogMetadata: _ogMetadata,
          // displayTitle is usually derived from OG or note/url
      );

      await _itemRepository.updateItem(updatedItem);

      if (mounted) {
        Navigator.pop(context, true); // Return success to reload
      }
    } catch (e) {
      debugPrint("Update error: $e");
      if (mounted) _showError("Güncelleme hatası");
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

  // ============== UI BUILD ==============

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: context.colors.backgroundBottom,
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroStage(),
                _buildControlCenter(),
                const SizedBox(height: 140),
              ],
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _buildBackButton(),
          ),

          // Floating CTA Dock
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
    double stageHeight;
    if (_hasLink) {
      if (_imageAspectRatio != null) {
        double calculatedRatio = (size.width / _imageAspectRatio!) / size.height;
        if (calculatedRatio > 0.65) calculatedRatio = 0.65;
        if (calculatedRatio < 0.20) calculatedRatio = 0.20;
        stageHeight = size.height * calculatedRatio;
      } else {
         stageHeight = size.height * 0.45;
      }
    } else if (_isManualEntry) {
      stageHeight = size.height * 0.40;
    } else {
      stageHeight = size.height * 0.75;
    }

    // Use ogMetadata image first, fallback to original item image
    final imageUrl = _ogMetadata?.imageUrl ?? widget.item.displayImage;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: stageHeight,
      width: double.infinity,
      color: context.colors.backgroundTop, // Using themed background
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: hasImage
                    ? _buildImageBackground(imageUrl!)
                    : _buildPlatformBackground(animate: _isLoadingMetadata),
          ),
          
          if (_hasLink || _isManualEntry)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: _buildCircleButton(
                icon: PhosphorIconsLight.trash,
                onTap: _showDeleteConfirmation,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlatformBackground({bool animate = false}) {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        final double shimmer = animate ? _loadingController.value : 0.0;
        final startAlign = Alignment.lerp(Alignment.topLeft, Alignment.topCenter, shimmer)!;
        final endAlign = Alignment.lerp(Alignment.bottomRight, Alignment.bottomCenter, shimmer)!;
        
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colors.backgroundTop,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            gradient: LinearGradient(
              colors: animate 
                  ? [
                      context.colors.primary, 
                      Color.lerp(context.colors.secondary, context.colors.surfaceWhite, shimmer * 0.3)!, 
                      context.colors.secondary
                    ]
                  : [context.colors.primary, context.colors.secondary],
              begin: startAlign,
              end: endAlign,
              stops: animate ? [0.0, 0.5 + (shimmer * 0.5), 1.0] : null,
            ),
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
                              color: context.colors.surfaceWhite.withOpacity(0.9),
                              strokeWidth: 4,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.edit_note_rounded, // Changed icon for edit
                        size: 64,
                        color: context.colors.surfaceWhite.withOpacity(0.9),
                      ),
                const SizedBox(height: 12),
                Text(
                  animate ? "Bağlantı taranıyor..." : "İçeriği düzenle",
                  style: GoogleFonts.poppins(
                    color: context.colors.surfaceWhite.withOpacity(0.9),
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

  Widget _buildImageBackground(String imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          placeholder: (context, url) => _buildPlatformBackground(animate: true),
          errorWidget: (context, url, error) => _buildPlatformBackground(),
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
          const SizedBox(height: 40),

          // Link Preview
          if (_hasLink || _isManualEntry) ...[
             _buildLinkPreview(),
             const SizedBox(height: 16),
          ],
          
          // Title
          _buildInputField(
            controller: _titleController,
            icon: PhosphorIconsThin.pencilSimple,
            hint: "Başlık",
            isTitle: true,
          ),
          
          const SizedBox(height: 12),

          // Note
          _buildInputField(
            controller: _noteController,
            icon: PhosphorIconsThin.notePencil,
            hint: "Notun",
            maxLines: 3,
          ),

          const SizedBox(height: 32),

          // Category
          Text(
            "Koleksiyon Değiştir", // Changed title
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.colors.hint,
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
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isTitle = false,
    int maxLines = 1,
  }) {
    return Container(
      height: maxLines == 1 ? 52 : null,
      alignment: maxLines == 1 ? Alignment.center : Alignment.topLeft,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.hint.withOpacity(0.3), width: 1),
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
              color: context.colors.body,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: context.colors.primary,
              textAlignVertical: TextAlignVertical.center,
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
              minLines: maxLines > 1 ? 2 : 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkPreview() {
    final hasPlatform = _detectedPlatform.isNotEmpty;
    final themeColor = context.colors.primary; 
    final platformIcon = hasPlatform ? _getPlatformIcon(_detectedPlatform) : PhosphorIconsThin.link;

    return Container(
      height: 52,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16), 
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeColor.withOpacity(0.5), 
          width: 1.0
        ),
      ),
      child: Row(
        children: [
          Icon(
            platformIcon,
            size: 18, 
            color: themeColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _linkController,
              onChanged: _onLinkChanged,
              cursorColor: context.colors.primary,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: context.colors.headline,
              ),
              decoration: InputDecoration(
                hintText: "Bağlantı",
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 1,
            ),
          ),
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

  Widget _buildCategoryChip(CategoryModel cat) {
    final bool isSelected = _selectedCategoryIds.contains(cat.id);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() {
          // Single select behavior for Edit
          _selectedCategoryIds.clear();
          _selectedCategoryIds.add(cat.id);
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [context.colors.secondary.withOpacity(0.5), context.colors.surfaceWhite],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : context.colors.surfaceWhite,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? Colors.transparent : context.colors.secondary,
              width: 1.5,
            ),
            boxShadow: isSelected
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
                  color: isSelected ? context.colors.headline : context.colors.body,
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

  Widget _buildFloatingDock() {
    return GestureDetector(
      onTap: _isSaving ? null : _updateItem, // Call Update
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colors.primary, context.colors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: context.colors.secondary.withOpacity(0.3),
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
                    valueColor: AlwaysStoppedAnimation<Color>(context.colors.surfaceWhite),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIconsBold.check, // Changed to Check
                      size: 20,
                      color: context.colors.surfaceWhite, 
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Değişiklikleri Kaydet", // Updated Text
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.colors.surfaceWhite, 
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.hint.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          PhosphorIconsLight.arrowLeft,
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
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.hint.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: context.colors.headline,
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram': return PhosphorIconsThin.instagramLogo;
      case 'youtube': return PhosphorIconsThin.youtubeLogo;
      case 'x': case 'twitter': return PhosphorIconsThin.xLogo;
      case 'tiktok': return PhosphorIconsThin.tiktokLogo;
      case 'linkedin': return PhosphorIconsThin.linkedinLogo;
      case 'spotify': return PhosphorIconsThin.spotifyLogo;
      case 'pinterest': return PhosphorIconsThin.pinterestLogo;
      case 'reddit': return PhosphorIconsThin.redditLogo;
      case 'medium': return PhosphorIconsThin.mediumLogo;
      case 'behance': return PhosphorIconsThin.behanceLogo;
      case 'dribbble': return PhosphorIconsThin.dribbbleLogo;
      default: return PhosphorIconsThin.globe;
    }
  }
}
