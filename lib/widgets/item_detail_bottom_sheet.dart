import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../core/models/item_model.dart';
import '../core/models/category_model.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_colors_extension.dart'; // Import Extension
import '../screens/edit_content_screen.dart'; // Import Edit Screen

class ItemDetailBottomSheet extends StatefulWidget {
  final ItemModel item;
  final String categoryName;
  final List<CategoryModel> categories;
  final VoidCallback? onSave;

  const ItemDetailBottomSheet({
    super.key,
    required this.item,
    required this.categoryName,
    required this.categories,
    this.onSave,
  });

  static Future<void> show(
    BuildContext context, 
    ItemModel item, 
    String categoryName, 
    List<CategoryModel> categories,
    {VoidCallback? onSave}
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => ItemDetailBottomSheet(
        item: item, 
        categoryName: categoryName, 
        categories: categories,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ItemDetailBottomSheet> createState() => _ItemDetailBottomSheetState();
}

class _ItemDetailBottomSheetState extends State<ItemDetailBottomSheet> {
  double? _imageAspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  void _resolveImageSize() {
    final imageUrl = widget.item.displayImage;
    if (imageUrl == null || imageUrl.isEmpty) return;

    ImageProvider? provider;
    if (imageUrl.startsWith('http')) {
      provider = CachedNetworkImageProvider(imageUrl);
    } else {
      provider = AssetImage(imageUrl);
    }

    provider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool synchronousCall) {
        if (!mounted) return;
        final myImage = info.image;
        setState(() {
          _imageAspectRatio = myImage.width / myImage.height;
        });
      }),
    );
  }

  String _getPlatformName(String? url) {
    if (url == null) return 'Link';
    final s = url.toLowerCase();
    if (s.contains('instagram')) return 'Instagram';
    if (s.contains('youtube')) return 'YouTube';
    if (s.contains('x.com') || s.contains('twitter')) return 'X';
    if (s.contains('pinterest')) return 'Pinterest';
    return 'Uygulama';
  }

  IconData _getPlatformIcon(String? url) {
    if (url == null) return PhosphorIconsBold.link;
    final s = url.toLowerCase();
    if (s.contains('instagram')) return PhosphorIconsBold.instagramLogo;
    if (s.contains('youtube')) return PhosphorIconsBold.youtubeLogo;
    if (s.contains('x.com') || s.contains('twitter')) return PhosphorIconsBold.xLogo;
    if (s.contains('pinterest')) return PhosphorIconsBold.pinterestLogo;
    return PhosphorIconsBold.link;
  }

  Future<void> _openInApp() async {
    final url = widget.item.url;
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _shareLink() {
    final url = widget.item.url;
    if (url != null && url.isNotEmpty) {
      Share.share(url);
    }
  }

  void _openEditScreen() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => EditContentScreen(item: widget.item)),
    ).then((result) {
      // Pass the result (true if updated/deleted) back to the caller
      Navigator.pop(context, result); 
    });
  }

  Widget _buildFallbackHeader(IconData icon) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Center(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, Color(0xFF6FBFAC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Icon(icon, size: 96, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.item.displayImage != null && widget.item.displayImage!.isNotEmpty;
    final platformName = _getPlatformName(widget.item.url);
    final platformIcon = _getPlatformIcon(widget.item.url);
    
    // Dynamic Header Calculation
    double headerRatio = 0.45;
    if (_imageAspectRatio != null) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final desiredHeight = screenWidth / _imageAspectRatio!;
      double calculatedRatio = desiredHeight / screenHeight;
      if (calculatedRatio > 0.65) calculatedRatio = 0.65;
      if (calculatedRatio < 0.35) calculatedRatio = 0.35; 
      headerRatio = calculatedRatio;
    }
    
    final headerHeight = MediaQuery.of(context).size.height * headerRatio;

    // Find assigned category
    final assignedCategory = widget.categories.firstWhere(
      (c) => c.id == widget.item.categoryId, 
      orElse: () => CategoryModel(id: '', userId: '', name: widget.categoryName, icon: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
    );

    return DraggableScrollableSheet(
      initialChildSize: hasImage ? 1.0 : 0.85,
      minChildSize: 0.25, // Lowered to allow drag down
      maxChildSize: 1.0,
      snap: false, // Disabled snap to prevent sticking in middle
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.transparent, 
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              // --- LAYOUT COLUMN ---
              Column(
                children: [
                   // 1. HEADER IMAGE
                   SizedBox(
                     height: headerHeight,
                     width: double.infinity,
                     child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: hasImage
                          ? widget.item.displayImage!.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: widget.item.displayImage!,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                )
                              : Image.asset(
                                  widget.item.displayImage!,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (_, __, ___) => _buildFallbackHeader(platformIcon),
                                )
                          : _buildFallbackHeader(platformIcon),
                     ),
                   ),

                   // 2. CONTENT AREA
                   Expanded(
                     child: Container(
                       width: double.infinity,
                       color: context.colors.surfaceWhite, // Dynamic Surface
                       child: Column(
                         children: [
                           // DRAG HANDLE REMOVED
                           const SizedBox(height: 12),


                           // OPEN BUTTON
                           Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 20),
                             child: Container(
                               width: double.infinity,
                               decoration: BoxDecoration(
                                 gradient: LinearGradient(
                                   colors: [context.colors.primary, const Color(0xFF6FBFAC)],
                                   begin: Alignment.topLeft,
                                   end: Alignment.bottomRight,
                                 ),
                                 borderRadius: BorderRadius.circular(12),
                                 boxShadow: [
                                   BoxShadow(
                                     color: const Color(0xFF6FBFAC).withOpacity(0.3),
                                     blurRadius: 10,
                                     offset: const Offset(0, 4),
                                   ),
                                 ],
                               ),
                               child: Material(
                                 color: Colors.transparent,
                                 child: InkWell(
                                   onTap: _openInApp,
                                   borderRadius: BorderRadius.circular(12),
                                   child: Padding(
                                     padding: const EdgeInsets.symmetric(vertical: 14),
                                     child: Row(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         Icon(platformIcon, size: 20, color: Colors.white),
                                         const SizedBox(width: 8),
                                         Text(
                                           "$platformName'da Aç",
                                           style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ),
                               ),
                             ),
                           ),

                           const SizedBox(height: 24),

                           // SCROLLABLE CONTENT
                           Expanded(
                             child: SingleChildScrollView(
                               controller: scrollController,
                               padding: const EdgeInsets.symmetric(horizontal: 20),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                    // Title Display
                                    Text('Başlık', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: context.colors.hint)),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.item.displayTitle,
                                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: context.colors.headline),
                                    ),

                                    const SizedBox(height: 24),

                                    // Category Display
                                    Text('Koleksiyon', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: context.colors.hint)),
                                    const SizedBox(height: 12),
                                    
                                    // Single Category Text
                                    Text(
                                      assignedCategory.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: context.colors.headline,
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // Note (if any)
                                    if (widget.item.note != null && widget.item.note!.isNotEmpty && widget.item.note != widget.item.displayTitle) ...[
                                       Text('Not', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: context.colors.hint)),
                                       const SizedBox(height: 8),
                                       Text(
                                         widget.item.note!,
                                         style: GoogleFonts.poppins(fontSize: 14, color: context.colors.body),
                                       ),
                                       const SizedBox(height: 32),
                                    ],
                                    
                                    
                                    // Footer Text
                                    Center(
                                      child: Text(
                                        "Telif hakları ve yayıncı politikaları gereği, bu içerik yalnızca orijinal kaynağında görüntülenebilir.",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: context.colors.hint,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    
                                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                                 ],
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                ],
              ),

              // --- 3. STICKY ICONS (Top Layer) ---
              // Close Button (Top Left)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56, 
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceWhite,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(PhosphorIconsLight.x, size: 22, color: context.colors.headline),
                  ),
                ),
              ),

              // Share Button (Top Right)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56, 
                right: 16,
                child: GestureDetector(
                  onTap: _shareLink,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceWhite,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(PhosphorIconsLight.paperPlaneTilt, size: 22, color: context.colors.headline),
                  ),
                ),
              ),
              
              // Edit Button (Left of Share)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56, 
                right: 16 + 40 + 12, // 16 (margin) + 40 (share btn width approx) + 12 (gap)
                child: GestureDetector(
                  onTap: _openEditScreen,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceWhite,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(PhosphorIconsLight.pencilSimple, size: 22, color: context.colors.headline),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
