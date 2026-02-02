import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
              color: Colors.red.withOpacity(0.8),
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
          Positioned(
            bottom: 16,
            left: 16,
            child: _buildProviderBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            widget.coordinate.provider.displayName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    // Fallback for non-iOS platforms
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
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 12),
                Text(
                  'Harita Önizlemesi',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.coordinate.latitude.toStringAsFixed(4)}, ${widget.coordinate.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
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
    switch (widget.coordinate.provider) {
      case MapProvider.googleMaps:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF34A853), Color(0xFF1EA362)],
        );
      case MapProvider.yandexMaps:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFCC00), Color(0xFFFF9900)],
        );
      case MapProvider.appleMaps:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFAAAAAA), Color(0xFF888888)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF666666), Color(0xFF444444)],
        );
    }
  }
}
