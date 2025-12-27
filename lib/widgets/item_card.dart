import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/widgets/loading_indicator.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;

  const ItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Unified Card Design (Book Cover Style)
    // Reference: Tall, Clean, Image dominant, Minimal text
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // More rounded like reference
          boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.05),
               offset: const Offset(0, 4),
               blurRadius: 16,
             )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Area (Dominant)
            // Use aspect ratio or fixed height logic. For masonry, dynamic height is better.
            Stack(
              children: [
                _CardImage(
                   imageUrl: item.displayImage, 
                   heroTag: item.id,
                   url: item.url, // Pass URL for fallback logic
                   // If no image, show a nice gradient placeholder
                   placeholderGradient: _getGradientForType(item.url),
                ),
                
                // Source Icon Badge (Subtle, Top Left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: _getSourceIcon(item.url),
                  ),
                ),
              ],
            ),

            // 2. Info Area (Clean White)
            Padding(
               padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // Title
                   Text(
                     item.displayTitle,
                     style: GoogleFonts.poppins(
                       fontWeight: FontWeight.bold,
                       fontSize: 15,
                       color: AppColors.headline, // Dark grey
                       height: 1.3,
                     ),
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                   ),
                   const SizedBox(height: 6),
                   // Source Name (Author style)
                   Text(
                     _getSourceName(item.url),
                     style: GoogleFonts.poppins(
                       fontWeight: FontWeight.w500,
                       fontSize: 12,
                       color: AppColors.hint,
                     ),
                   ),
                 ],
               ),
            ),
          ],
        ),
      ),
    );
  }
  
  LinearGradient? _getGradientForType(String? url) {
    if (url == null) return null;
    if (url.contains('youtube')) return const LinearGradient(colors: [Color(0xFFFF9966), Color(0xFFFF5E62)]);
    if (url.contains('medium')) return const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]);
    return const LinearGradient(colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)]);
  }

  Widget _getSourceIcon(String? url) {
     if (url == null) return const Icon(Icons.link, size: 14, color: Colors.blue);
     if (url.contains('youtube')) return const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.red);
     if (url.contains('medium')) return const Icon(Icons.article_rounded, size: 14, color: Colors.black);
     if (url.contains('instagram')) return const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.purple);
     return const Icon(Icons.link_rounded, size: 16, color: Colors.blue);
  }

  String _getSourceName(String? url) {
     if (url == null) return 'Link';
     try {
       final uri = Uri.parse(url);
       String host = uri.host.replaceFirst('www.', '');
       return host[0].toUpperCase() + host.substring(1);
     } catch (e) {
       return 'Link';
     }
  }
}

class _CardImage extends StatelessWidget {
  final String? imageUrl;
  final String? heroTag;
  final String? url; // Added to determine fallback type
  final LinearGradient? placeholderGradient;

  const _CardImage({this.imageUrl, this.heroTag, this.url, this.placeholderGradient});

  @override
  Widget build(BuildContext context) {
    Widget content;
    
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
         // Important: Allow height to be determined by image aspect ratio but constrained
         // Actually for Masonry, we want the image to dictate height mostly
         loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 150, // Placeholder height
              color: AppColors.backgroundBottom, // Soft grey/mist
              alignment: Alignment.center,
              child: const LoadingIndicator(size: 20),
            );
         },
        errorBuilder: (_,__,___) => _buildPlaceholder(),
      );
    } else {
      content = _buildPlaceholder();
    }

    if (heroTag != null && imageUrl != null) {
      return Hero(tag: heroTag!, child: content);
    }
    return content;
  }
  
  Widget _buildPlaceholder() {
     IconData icon = Icons.link;
     Color iconColor = Colors.white;
     double iconSize = 48;
     
     if (url != null) {
       if (url!.contains('instagram')) {
         icon = PhosphorIconsBold.instagramLogo; 
       } else if (url!.contains('youtube')) {
         icon = PhosphorIconsBold.youtubeLogo;
       } else if (url!.contains('twitter') || url!.contains('x.com')) {
         icon = PhosphorIconsBold.xLogo;
       }
     }

     return Container(
       height: 150,
       decoration: BoxDecoration(
         gradient: placeholderGradient ?? const LinearGradient(colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)]),
       ),
       alignment: Alignment.center,
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(icon, color: iconColor.withValues(alpha: 0.9), size: iconSize),
         ],
       ),
     );
  }
}
