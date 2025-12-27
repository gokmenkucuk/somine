import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: AspectRatio(
                      aspectRatio: 16/10,
                      child: widget.item.displayImage!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: widget.item.displayImage!,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            widget.item.displayImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade100,
                              child: Center(child: Icon(platformIcon, size: 48, color: platformColor)),
                            ),
                          ),
                    ),
                  )
                else
                  const SizedBox(height: 48), // Spacing for handle if no image

                // Handle Bar (overlay)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: hasImage ? Colors.white.withOpacity(0.8) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
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

            // Category section with multi-select chips
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kategoriler', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
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

            // Open in app button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openInApp,
                  icon: Icon(platformIcon, size: 20),
                  label: Text("$platformName'da Aç"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: platformColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement save logic with _titleController.text and _selectedCategoryIds
                    Navigator.pop(context);
                  },
                  child: Text('Kaydet', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Delete button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(),
                  icon: Icon(PhosphorIconsLight.trash, size: 18, color: Colors.red.shade400),
                  label: Text('Sil', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.red.shade400)),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
