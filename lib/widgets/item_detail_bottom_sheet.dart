import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../core/models/item_model.dart';
import '../core/models/category_model.dart';
import '../core/design/app_colors.dart';

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
      enableDrag: true, // Allow drag to dismiss
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
  late TextEditingController _titleController;
  late Set<String> _selectedCategoryIds;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.displayTitle);
    // Initialize with current category
    _selectedCategoryIds = widget.item.categoryId != null ? {widget.item.categoryId!} : {};
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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

  Color _getPlatformColor(String? url) {
    if (url == null) return Colors.grey;
    final s = url.toLowerCase();
    if (s.contains('instagram')) return const Color(0xFFE4405F);
    if (s.contains('youtube')) return const Color(0xFFFF0000);
    if (s.contains('x.com') || s.contains('twitter')) return Colors.black;
    if (s.contains('pinterest')) return const Color(0xFFBD081C);
    return AppColors.primary;
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('İçeriği Sil', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Bu içeriği silmek istediğinize emin misiniz?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement delete logic
              Navigator.pop(context); // Close dialog
              Navigator.pop(this.context); // Close bottom sheet
            },
            child: Text('Sil', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(CategoryModel cat) {
    final bool isSelected = _selectedCategoryIds.contains(cat.id);

    return GestureDetector(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.secondary.withOpacity(0.5), AppColors.surfaceWhite],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.35),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.item.displayImage != null && widget.item.displayImage!.isNotEmpty;
    final platformName = _getPlatformName(widget.item.url);
    final platformIcon = _getPlatformIcon(widget.item.url);
    final platformColor = _getPlatformColor(widget.item.url);

    return DraggableScrollableSheet(
      initialChildSize: hasImage ? 1.0 : 0.85, // Increased from 0.6 per request
      minChildSize: 0.5,
      maxChildSize: 1.0,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Stack for Image + Handle Bar
            Stack(
              alignment: Alignment.topCenter,
              children: [
                  // Image (Full Width)
                if (hasImage)
                  GestureDetector(
                    onTap: _openInApp,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.70, // Max 70% height as requested
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: widget.item.displayImage!.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: widget.item.displayImage!,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter, 
                              )
                            : Image.asset(
                                widget.item.displayImage!,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 250, 
                                  color: Colors.grey.shade100,
                                  child: Center(child: Icon(platformIcon, size: 48, color: platformColor)),
                                ),
                              ),
                        ),
                      ),
                    ),
                  )
                else
                   // Fallback Header for No Image
                   Container(
                     height: 380, // Increased height for better spacing
                     width: double.infinity,
                     decoration: const BoxDecoration(
                       color: Color(0xFFF9FAFB),
                       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                     ),
                     child: Center(
                        // Add padding to push icon up slightly for visual balance against the bottom button
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 60), 
                          child: Icon(platformIcon, size: 72, color: platformColor.withOpacity(0.5)),
                        ),
                     ),
                   ),

                // Close Button (Top Left)
                Positioned(
                  top: hasImage ? 56 : 24, // Higher for no-image items
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        // Removed border as requested
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(PhosphorIconsLight.x, size: 20, color: Colors.black),
                    ),
                  ),
                ),

                // Share Button (Top Right)
                Positioned(
                  top: hasImage ? 56 : 24, // Higher for no-image items
                  right: 16,
                  child: GestureDetector(
                    onTap: _shareLink,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        // Removed border as requested
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(PhosphorIconsLight.paperPlaneTilt, size: 20, color: Colors.black),
                    ),
                  ),
                ),

                // Open App Button & Disclaimer (Always Visible)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Builder(
                    builder: (context) {
                      final url = widget.item.url?.toLowerCase() ?? '';
                      Color textColor = Colors.white;
                      Color? bgColor;
                      Gradient? bgGradient;
                      Border? border;

                      if (url.contains('instagram')) {
                        bgGradient = const LinearGradient(
                          colors: [Color(0xFFFEDA75), Color(0xFFD62976), Color(0xFF962FBF)],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        );
                        bgColor = null; 
                      } else if (url.contains('x.com') || url.contains('twitter')) {
                        bgColor = Colors.black;
                      } else if (url.contains('youtube')) {
                        bgColor = const Color(0xFFFF0000);
                      } else if (url.contains('pinterest')) {
                        bgColor = const Color(0xFFBD081C);
                      } else {
                        // Generic Link -> White button
                        bgColor = Colors.white;
                        textColor = Colors.black;
                        border = Border.all(color: Colors.grey.shade300, width: 1);
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              gradient: bgGradient,
                              borderRadius: BorderRadius.circular(12),
                              border: border,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
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
                                      Icon(platformIcon, size: 20, color: textColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        "$platformName'da Aç",
                                        style: GoogleFonts.poppins(
                                          fontSize: 15, 
                                          fontWeight: FontWeight.w600, 
                                          color: textColor
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Text color logic: white if hasImage (overlay), dark grey if no image (fallback bg)
                          Text(
                            "Telif hakları ve yayıncı politikaları gereği, bu içerik yalnızca orijinal kaynağında görüntülenebilir.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: hasImage ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                              shadows: hasImage ? [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 3.0,
                                  color: Colors.black.withOpacity(0.5),
                                )
                              ] : null,
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Title section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Başlık', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Başlık girin',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // Category section with chips
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Koleksiyon Seç', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 45,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 16),
                      itemCount: widget.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => _buildCategoryChip(widget.categories[index]),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions: Delete and Save (Minimalist)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Delete Button
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(),
                    icon: Icon(PhosphorIconsLight.trash, size: 20, color: Colors.grey.shade600),
                    label: Text('Sil', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  
                  // Save Button
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement save logic
                      Navigator.pop(context);
                    },
                    icon: const Icon(PhosphorIconsLight.check, size: 20, color: Colors.black),
                    label: Text('Kaydet', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
        );
      },
    );
  }
}
