import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/utils/auth_image_provider.dart';
import 'package:somine_app/widgets/loading_indicator.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
          borderRadius: BorderRadius.circular(
            20,
          ), // More rounded like reference
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image Area (Dominant)
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
    if (isNote)
      return const LinearGradient(
        colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
      ); // Warm note gradient
    if (url == null) return null;

    final s = url.toLowerCase();

    // Maps Gradients
    if (s.contains('maps.app.goo') ||
        s.contains('goo.gl/maps') ||
        s.contains('google.com/maps') ||
        s.contains('maps.google'))
      return const LinearGradient(
        colors: [Color(0xFF34A853), Color(0xFF1EA362)],
      ); // Google Green

    if (s.contains('yandex.com/maps') ||
        s.contains('yandex.ru/maps') ||
        s.contains('yandex.o/maps'))
      return const LinearGradient(
        colors: [Color(0xFFFFCC00), Color(0xFFFF9900)],
      ); // Yandex Yellow/Orange

    if (s.contains('maps.apple.com'))
      return const LinearGradient(
        colors: [Color(0xFFAAAAAA), Color(0xFF888888)],
      ); // Apple Grey

    // Brand Gradients
    if (s.contains('youtube'))
      return const LinearGradient(
        colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
      );
    if (s.contains('medium'))
      return const LinearGradient(
        colors: [Color(0xFF000000), Color(0xFF444444)],
      );
    if (s.contains('instagram'))
      return const LinearGradient(
        colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
      );
    if (s.contains('twitter') || s.contains('x.com'))
      return const LinearGradient(
        colors: [Color(0xFF000000), Color(0xFF14171A)],
      );
    if (s.contains('facebook'))
      return const LinearGradient(
        colors: [Color(0xFF1877F2), Color(0xFF0C5DC7)],
      );
    if (s.contains('linkedin'))
      return const LinearGradient(
        colors: [Color(0xFF0A66C2), Color(0xFF004182)],
      );
    if (s.contains('github'))
      return const LinearGradient(
        colors: [Color(0xFF24292e), Color(0xFF000000)],
      );
    if (s.contains('pinterest'))
      return const LinearGradient(colors: [Color(0xFFE60023), Color(0xFDBDCC)]);
    if (s.contains('tiktok'))
      return const LinearGradient(
        colors: [Color(0xFF000000), Color(0xFF25F4EE), Color(0xFFFE2C55)],
      );
    if (s.contains('spotify'))
      return const LinearGradient(
        colors: [Color(0xFF1DB954), Color(0xFF191414)],
      );
    if (s.contains('twitch'))
      return const LinearGradient(
        colors: [Color(0xFF9146FF), Color(0xFF6441A5)],
      );
    if (s.contains('discord'))
      return const LinearGradient(
        colors: [Color(0xFF5865F2), Color(0xFF404EED)],
      );
    if (s.contains('reddit'))
      return const LinearGradient(
        colors: [Color(0xFFFF4500), Color(0xFFFF5700)],
      );
    if (s.contains('snapchat'))
      return const LinearGradient(
        colors: [Color(0xFFFFFC00), Color(0xFFFFD700)],
      );
    if (s.contains('whatsapp'))
      return const LinearGradient(
        colors: [Color(0xFF25D366), Color(0xFF128C7E)],
      );
    if (s.contains('telegram'))
      return const LinearGradient(
        colors: [Color(0xFF0088cc), Color(0xFF0077b5)],
      );
    if (s.contains('amazon'))
      return const LinearGradient(
        colors: [Color(0xFFFF9900), Color(0xFF146eb4)],
      );
    if (s.contains('netflix'))
      return const LinearGradient(
        colors: [Color(0xFFE50914), Color(0xFFB81D24)],
      );
    if (s.contains('google'))
      return const LinearGradient(
        colors: [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
        ],
      );
    if (s.contains('yandex'))
      return const LinearGradient(
        colors: [Color(0xFFFFCC00), Color(0xFF000000)],
      );

    return const LinearGradient(colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)]);
  }

  Widget _getSourceIcon(String? url, bool isNote) {
    if (isNote)
      return const Icon(
        PhosphorIconsBold.notePencil,
        size: 14,
        color: Color(0xFFF97316),
      ); // Orange for notes
    if (url == null)
      return const Icon(Icons.link, size: 14, color: Colors.blue);

    final s = url.toLowerCase();

    // Maps Icons
    if (s.contains('maps.app.goo') ||
        s.contains('goo.gl/maps') ||
        s.contains('google.com/maps') ||
        s.contains('maps.google') ||
        s.contains('yandex.com/maps') ||
        s.contains('yandex.ru/maps') ||
        s.contains('yandex.o/maps') ||
        s.contains('maps.apple.com')) {
      return const Icon(
        PhosphorIconsBold.mapPin,
        size: 14,
        color: Colors.green,
      );
    }

    // FontAwesome Brand Icons (Small)
    if (s.contains('youtube'))
      return const FaIcon(
        FontAwesomeIcons.youtube,
        size: 14,
        color: Colors.red,
      );
    if (s.contains('instagram'))
      return const FaIcon(
        FontAwesomeIcons.instagram,
        size: 14,
        color: Colors.purple,
      );
    if (s.contains('twitter') || s.contains('x.com'))
      return const FaIcon(
        FontAwesomeIcons.xTwitter,
        size: 13,
        color: Colors.black,
      );
    if (s.contains('facebook'))
      return const FaIcon(
        FontAwesomeIcons.facebook,
        size: 14,
        color: Color(0xFF1877F2),
      );
    if (s.contains('linkedin'))
      return const FaIcon(
        FontAwesomeIcons.linkedin,
        size: 14,
        color: Color(0xFF0A66C2),
      );
    if (s.contains('github'))
      return const FaIcon(
        FontAwesomeIcons.github,
        size: 14,
        color: Colors.black,
      );
    if (s.contains('pinterest'))
      return const FaIcon(
        FontAwesomeIcons.pinterest,
        size: 14,
        color: Color(0xFFE60023),
      );
    if (s.contains('tiktok'))
      return const FaIcon(
        FontAwesomeIcons.tiktok,
        size: 13,
        color: Colors.black,
      );
    if (s.contains('spotify'))
      return const FaIcon(
        FontAwesomeIcons.spotify,
        size: 14,
        color: Color(0xFF1DB954),
      );
    if (s.contains('twitch'))
      return const FaIcon(
        FontAwesomeIcons.twitch,
        size: 13,
        color: Color(0xFF9146FF),
      );
    if (s.contains('discord'))
      return const FaIcon(
        FontAwesomeIcons.discord,
        size: 13,
        color: Color(0xFF5865F2),
      );
    if (s.contains('reddit'))
      return const FaIcon(
        FontAwesomeIcons.reddit,
        size: 14,
        color: Color(0xFFFF4500),
      );
    if (s.contains('snapchat'))
      return const FaIcon(
        FontAwesomeIcons.snapchat,
        size: 14,
        color: Color(0xFFFFFC00),
      );
    if (s.contains('whatsapp'))
      return const FaIcon(
        FontAwesomeIcons.whatsapp,
        size: 14,
        color: Color(0xFF25D366),
      );
    if (s.contains('telegram'))
      return const FaIcon(
        FontAwesomeIcons.telegram,
        size: 14,
        color: Color(0xFF0088cc),
      );
    if (s.contains('medium'))
      return const FaIcon(
        FontAwesomeIcons.medium,
        size: 14,
        color: Colors.black,
      );
    if (s.contains('amazon'))
      return const FaIcon(
        FontAwesomeIcons.amazon,
        size: 14,
        color: Colors.black,
      );
    if (s.contains('google'))
      return const FaIcon(
        FontAwesomeIcons.google,
        size: 13,
        color: Colors.blue,
      );
    if (s.contains('yandex'))
      return const FaIcon(
        FontAwesomeIcons.yandex,
        size: 13,
        color: Colors.red,
      ); // Yandex Red
    if (s.contains('apple'))
      return const FaIcon(
        FontAwesomeIcons.apple,
        size: 14,
        color: Colors.black,
      );

    return const Icon(Icons.link_rounded, size: 16, color: Colors.blue);
  }

  String _getSourceName(String? url, bool isNote) {
    if (isNote) return 'Not';
    if (url == null) return 'Link';
    try {
      // Custom names for Maps
      if (url.contains('maps.app.goo') ||
          url.contains('goo.gl/maps') ||
          url.contains('google.com/maps') ||
          url.contains('maps.google'))
        return 'Google Maps';
      if (url.contains('yandex.com/maps') ||
          url.contains('yandex.ru/maps') ||
          url.contains('yandex.o/maps'))
        return 'Yandex Maps';
      if (url.contains('maps.apple.com')) return 'Apple Maps';

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

  const _CardImage({
    super.key,
    this.imageUrl,
    this.heroTag,
    this.url,
    this.isNote = false,
    this.placeholderGradient,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      debugPrint('🖼️ [CardImage] url=$url | imageUrl=$imageUrl');
      if (isNote) {
        // NOTE: Check for base64 data URL or Storage URL
        final isBase64 = imageUrl!.startsWith('data:');

        if (isBase64) {
          // Base64 encoded image - use Image.memory
          final bytes = const Base64Decoder().convert(imageUrl!.substring(23));
          content = SizedBox(
            height: 200, // Fixed height for card display
            width: double.infinity, // Ensure full width
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            ),
          );
        } else {
          // Storage URL - use buildAuthImage to handle auth headers
          content = SizedBox(
            height: 200,
            width: double.infinity,
            child: buildAuthImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.backgroundBottom,
                    alignment: Alignment.center,
                    child: const LoadingIndicator(size: 20),
                  ),
              errorWidget: (_, __, ___) => _buildPlaceholder(),
            ),
          );
        }
      } else {
        // LINK with og:image
        // Check if it's a known brand OR if image is a favicon (small, pixelated when enlarged)
        final bool isKnownBrand = _isKnownBrandSite(url);
        final bool isSocialPlatform = _isSocialPlatform(url);
        final bool isFavicon =
            imageUrl!.contains('favicon') || imageUrl!.contains('s2/favicons');
        final bool isMaps = _isMapUrl(url?.toLowerCase() ?? '');
        debugPrint(
          '🖼️ [CardImage] isKnownBrand=$isKnownBrand | isSocial=$isSocialPlatform | isFavicon=$isFavicon | isMaps=$isMaps',
        );

        // Maps URLs: Always show the image (even if it's a favicon - they return map previews)
        // Social platforms (Spotify, YouTube, etc.): Show real content images
        // Known brands or favicons (non-maps, non-social): Show placeholder with appropriate icon
        if ((isKnownBrand || isFavicon) && !isMaps && !isSocialPlatform) {
          // Known brands or favicons: Show placeholder with appropriate icon
          content = _buildPlaceholder(
            faviconUrl: (isFavicon && !isKnownBrand) ? imageUrl : null,
          );
        } else {
          // Unknown sites with og:image: Show the image (product photo, article image, etc.)
          content = SizedBox(
            height: 200,
            width: double.infinity,
            child: buildAuthImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.backgroundBottom,
                    alignment: Alignment.center,
                    child: const LoadingIndicator(size: 20),
                  ),
              errorWidget: (_, __, ___) => _buildPlaceholder(),
            ),
          );
        }
      }
    } else {
      // No image available: Show placeholder with icon
      content = _buildPlaceholder();
    }

    if (heroTag != null && imageUrl != null) {
      return Hero(tag: heroTag!, child: content);
    }
    return content;
  }

  Widget _buildPlaceholder({String? faviconUrl}) {
    Widget iconWidget = Icon(
      Icons.link,
      color: Colors.white,
      size: 48,
    ); // Default
    Color iconColor =
        Colors.white; // We override this usually but keeping for safety
    double iconSize = 48;

    if (isNote) {
      iconWidget = Icon(
        PhosphorIconsBold.notePencil,
        color: Colors.white,
        size: 32,
      );
    } else if (url != null) {
      final s = url!.toLowerCase();

      if (s.contains('maps.app.goo') ||
          s.contains('goo.gl/maps') ||
          s.contains('google.com/maps') ||
          s.contains('maps.google') ||
          s.contains('yandex.com/maps') ||
          s.contains('yandex.ru/maps') ||
          s.contains('yandex.o/maps') ||
          s.contains('maps.apple.com')) {
        iconWidget = Icon(
          PhosphorIconsBold.mapPin,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('instagram')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.instagram,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('youtube')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.youtube,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('twitter') || s.contains('x.com')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.xTwitter,
          color: Colors.white,
          size: 40,
        );
      } else if (s.contains('facebook')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.facebook,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('linkedin')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.linkedin,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('github')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.github,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('pinterest')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.pinterest,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('tiktok')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.tiktok,
          color: Colors.white,
          size: 40,
        );
      } else if (s.contains('spotify')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.spotify,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('medium')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.medium,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('amazon')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.amazon,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('google')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.google,
          color: Colors.white,
          size: 40,
        );
      } else if (s.contains('yandex')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.yandex,
          color: Colors.white,
          size: 40,
        );
      } else if (s.contains('apple')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.apple,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('netflix')) {
        iconWidget = Text(
          'N',
          style: GoogleFonts.bebasNeue(fontSize: 60, color: Colors.white),
        ); // Text fallback or FontAwesome if available
      } else if (s.contains('twitch')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.twitch,
          color: Colors.white,
          size: 40,
        );
      } else if (s.contains('discord')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.discord,
          color: Colors.white,
          size: 40,
        );
      } else if (s.contains('reddit')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.reddit,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('whatsapp')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('telegram')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.telegram,
          color: Colors.white,
          size: 48,
        );
      } else if (s.contains('snapchat')) {
        iconWidget = FaIcon(
          FontAwesomeIcons.snapchat,
          color: Colors.white,
          size: 40,
        );
      }
    }

    // Use favicon visually if no brand icon was matched and a favicon URL is available
    if (!isNote &&
        faviconUrl != null &&
        iconWidget is Icon &&
        iconWidget.icon == Icons.link) {
      iconWidget = Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: buildAuthImage(
          imageUrl: faviconUrl,
          fit: BoxFit.contain,
          errorWidget:
              (_, __, ___) =>
                  const Icon(Icons.language, color: Colors.grey, size: 32),
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity, // Ensure full width for placeholder too
      decoration: BoxDecoration(
        gradient:
            placeholderGradient ??
            const LinearGradient(
              colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
            ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use iconWidget directly instead of Icon(icon...)
          iconWidget,
        ],
      ),
    );
  }

  bool _isKnownBrandSite(String? url) {
    if (url == null) return false;

    final lowerUrl = url.toLowerCase();

    // Exclude Maps services - they return real map images
    if (_isMapUrl(lowerUrl)) return false;

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

    return knownBrands.any((brand) => lowerUrl.contains(brand));
  }

  /// Check if URL is a social platform where images are actual content
  bool _isSocialPlatform(String? url) {
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.contains('instagram.com') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        lower.contains('tiktok.com') ||
        lower.contains('pinterest.com') ||
        lower.contains('pin.it') ||
        lower.contains('open.spotify.com') ||
        lower.contains('x.com') ||
        lower.contains('twitter.com') ||
        lower.contains('github.com') ||
        lower.contains('linkedin.com') ||
        lower.contains('reddit.com') ||
        lower.contains('amazon.') ||
        lower.contains('netflix.com') ||
        lower.contains('twitch.tv') ||
        lower.contains('gitlab.com') ||
        lower.contains('bitbucket.org') ||
        lower.contains('medium.com') ||
        lower.contains('behance.net') ||
        lower.contains('dribbble.com');
  }

  /// Check if URL is a maps service
  bool _isMapUrl(String url) {
    return url.contains('maps.app.goo.gl') ||
        url.contains('goo.gl/maps') ||
        url.contains('google.com/maps') ||
        url.contains('maps.google') ||
        url.contains('yandex.com/maps') ||
        url.contains('yandex.ru/maps') ||
        url.contains('maps.apple.com');
  }
}
