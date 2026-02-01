import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
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
    final bool isNote = item.type == ItemType.note;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
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
                   isNote: isNote, // Pass note type for special handling
                   // If no image, show a nice gradient placeholder
                   placeholderGradient: _getGradientForType(item.url, isNote),
                ),
                
                // Source Icon Badge (Subtle, Top Left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 32, 
                    height: 32,
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceWhite.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _getSourceIcon(item.url, isNote),
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
                     _getSourceName(item.url, isNote),
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
  
  LinearGradient? _getGradientForType(String? url, bool isNote) {
    if (isNote) return const LinearGradient(colors: [Color(0xFFF6D365), Color(0xFFFDA085)]); // Warm note gradient
    if (url == null) return null;
    if (url.contains('youtube')) return const LinearGradient(colors: [Color(0xFFFF9966), Color(0xFFFF5E62)]);
    if (url.contains('medium')) return const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]);
    return const LinearGradient(colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)]);
  }

  Widget _getSourceIcon(String? url, bool isNote) {
     if (isNote) return const Icon(PhosphorIconsBold.notePencil, size: 14, color: Color(0xFFF97316)); // Orange for notes
     if (url == null) return const Icon(Icons.link, size: 14, color: Colors.blue);
     if (url.contains('youtube')) return const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.red);
     if (url.contains('medium')) return const Icon(Icons.article_rounded, size: 14, color: Colors.black);
     if (url.contains('instagram')) return const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.purple);
     return const Icon(Icons.link_rounded, size: 16, color: Colors.blue);
  }

  String _getSourceName(String? url, bool isNote) {
     if (isNote) return 'Not';
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
  final bool isNote; // Note type for special handling
  final LinearGradient? placeholderGradient;

  const _CardImage({super.key, this.imageUrl, this.heroTag, this.url, this.isNote = false, this.placeholderGradient});

  @override
  Widget build(BuildContext context) {
    Widget content;
    
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (isNote) {
        // NOTE: Keep full cover for user photos
        content = Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
             if (loadingProgress == null) return child;
             return Container(
               height: 150,
               color: AppColors.backgroundBottom,
               alignment: Alignment.center,
               child: const LoadingIndicator(size: 20),
             );
          },
          errorBuilder: (_,__,___) => _buildPlaceholder(),
        );
      } else {
        // LINK: Check if it's a known brand that uses logo as og:image
        // These sites put their logo as og:image, so we show icon instead
        final bool isKnownBrand = _isKnownBrandSite(url);
        
        if (isKnownBrand) {
          // Known brands (Google, Adidas, etc): Show placeholder with icon (like X card)
          content = _buildPlaceholder();
        } else {
          // Unknown sites: Show the og:image as product photo (cover style)
          content = Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
               if (loadingProgress == null) return child;
               return Container(
                 height: 150,
                 color: AppColors.backgroundBottom,
                 alignment: Alignment.center,
                 child: const LoadingIndicator(size: 20),
               );
            },
            errorBuilder: (_,__,___) => _buildPlaceholder(),
          );
        }
      }
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
     
     if (isNote) {
       icon = PhosphorIconsBold.notePencil;
       iconSize = 32;
     } else if (url != null) {
       // Known brand icons
       if (url!.contains('instagram')) {
         icon = PhosphorIconsBold.instagramLogo; 
       } else if (url!.contains('youtube')) {
         icon = PhosphorIconsBold.youtubeLogo;
       } else if (url!.contains('twitter') || url!.contains('x.com')) {
         icon = PhosphorIconsBold.xLogo;
       } else if (url!.contains('google')) {
         icon = PhosphorIconsBold.googleLogo;
       } else if (url!.contains('medium')) {
         icon = PhosphorIconsBold.mediumLogo;
       } else if (url!.contains('spotify')) {
         icon = PhosphorIconsBold.spotifyLogo;
       } else if (url!.contains('linkedin')) {
         icon = PhosphorIconsBold.linkedinLogo;
       } else if (url!.contains('github')) {
         icon = PhosphorIconsBold.githubLogo;
       } else if (url!.contains('facebook')) {
         icon = PhosphorIconsBold.facebookLogo;
       } else if (url!.contains('pinterest')) {
         icon = PhosphorIconsBold.pinterestLogo;
       } else if (url!.contains('tiktok')) {
         icon = PhosphorIconsBold.tiktokLogo;
       } else if (url!.contains('amazon')) {
         icon = PhosphorIconsBold.amazonLogo;
       } else if (url!.contains('apple')) {
         icon = PhosphorIconsBold.appleLogo;
       } else if (url!.contains('adidas') || url!.contains('nike') || url!.contains('puma')) {
         // Sport brands - use generic shopping icon
         icon = PhosphorIconsBold.sneaker;
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
  
  /// Checks if the URL belongs to a known brand that uses logo as og:image
  /// These sites should show icon placeholder instead of their logo image
  bool _isKnownBrandSite(String? url) {
    if (url == null) return false;
    
    final knownBrands = [
      'google', 'youtube', 'twitter', 'x.com', 'instagram', 'facebook',
      'linkedin', 'medium', 'spotify', 'github', 'pinterest', 'tiktok',
      'amazon', 'apple', 'microsoft', 'adidas', 'nike', 'puma',
      'netflix', 'discord', 'slack', 'notion', 'figma', 'dribbble',
    ];
    
    final lowerUrl = url.toLowerCase();
    return knownBrands.any((brand) => lowerUrl.contains(brand));
  }
}
