import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../core/design/app_colors_extension.dart';
import '../core/models/map_coordinate.dart';

/// Widget that displays an Apple Map preview with coordinates
/// Shows a button to open the original URL in Google/Yandex Maps
class AppleMapPreview extends StatefulWidget {
  final MapCoordinate coordinate;
  final VoidCallback? onTap;
  final double height;

  const AppleMapPreview({
    super.key,
    required this.coordinate,
    this.onTap,
    this.height = 200,
  });

  @override
  State<AppleMapPreview> createState() => _AppleMapPreviewState();
}

class _AppleMapPreviewState extends State<AppleMapPreview> {
  @override
  Widget build(BuildContext context) {
    // iOS check - if not iOS, show fallback
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.iOS) {
      return _buildFallback();
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // Apple Map
          AppleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.coordinate.latitude,
                widget.coordinate.longitude,
              ),
              zoom: 15.0,
            ),
          ),

          // Marker overlay (center of map)
          Center(
            child: Icon(
              Icons.location_on,
              size: 40,
              color: context.colors.primary.withValues(alpha: 0.85),
            ),
          ),

          // Gesture detector for tap to open
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Provider badge (bottom left)
          Positioned(bottom: 16, left: 16, child: _buildProviderBadge()),
        ],
      ),
    );
  }

  Widget _buildProviderBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.accentDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 14, color: context.colors.surfaceWhite),
          const SizedBox(width: 4),
          Text(
            widget.coordinate.provider.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.colors.surfaceWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    // Fallback for non-iOS platforms
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: _getGradient(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 48,
                  color: context.colors.surfaceWhite.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.mapPreviewFallbackTitle,
                  style: TextStyle(
                    color: context.colors.surfaceWhite.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.coordinate.latitude.toStringAsFixed(4)}, ${widget.coordinate.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    color: context.colors.surfaceWhite.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradient() {
    final context = this.context;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [context.colors.primary, context.colors.secondary],
    );
  }
}
