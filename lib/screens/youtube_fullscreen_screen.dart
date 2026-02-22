import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../core/services/orientation_service.dart';

/// YouTube Fullscreen Screen
/// 
/// This screen handles proper fullscreen YouTube playback with landscape mode.
/// 
/// Flow:
/// 1. Navigate to this screen
/// 2. Native gatekeeper unlocks landscape permission
/// 3. Flutter requests landscape orientation
/// 4. Video plays in fullscreen landscape
/// 5. On exit: Flutter requests portrait, native locks it again
class YoutubeFullscreenScreen extends StatefulWidget {
  final YoutubePlayerController controller;
  final String videoTitle;

  const YoutubeFullscreenScreen({
    super.key,
    required this.controller,
    this.videoTitle = '',
  });

  @override
  State<YoutubeFullscreenScreen> createState() => _YoutubeFullscreenScreenState();
}

class _YoutubeFullscreenScreenState extends State<YoutubeFullscreenScreen> {
  bool _isInitialized = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    // Use post frame callback to ensure widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterFullscreen();
    });
  }

  /// Enter fullscreen landscape mode
  Future<void> _enterFullscreen() async {
    if (!mounted) return;
    
    debugPrint('🎬 YoutubeFullscreen: Entering fullscreen mode...');
    
    // Step 1: Native gatekeeper - unlock landscape permission FIRST
    await OrientationService.enableLandscape();
    
    // Step 2: CRITICAL - Give iOS time to update supported orientations
    // iOS needs to process the orientation mask change before we request landscape
    await Future.delayed(const Duration(milliseconds: 150));
    
    // Step 3: Hide system UI for immersive experience
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Step 4: Request landscape orientation at Flutter level with retry
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        debugPrint('✅ YoutubeFullscreen: Orientation changed on attempt ${attempt + 1}');
        break;
      } catch (e) {
        debugPrint('⚠️ YoutubeFullscreen: Orientation attempt ${attempt + 1} failed: $e');
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }
    
    if (mounted) {
      setState(() => _isInitialized = true);
    }
    
    debugPrint('✅ YoutubeFullscreen: Fullscreen mode entered');
  }

  /// Exit fullscreen and return to portrait
  Future<void> _exitFullscreen() async {
    if (_isExiting) return;
    _isExiting = true;
    
    debugPrint('🔙 YoutubeFullscreen: Exiting fullscreen mode...');
    
    // Step 1: Request portrait orientation at Flutter level FIRST
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    // Step 2: Restore system UI
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Step 3: Native gatekeeper - lock to portrait only
    await OrientationService.disableLandscape();
    
    debugPrint('✅ YoutubeFullscreen: Portrait mode restored');
  }

  Future<void> _handleExit() async {
    await _exitFullscreen();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    // Ensure we exit fullscreen on dispose
    if (!_isExiting) {
      _exitFullscreen();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !_isExiting) {
          await _handleExit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video Player - fills entire screen
            if (_isInitialized)
              Positioned.fill(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: YoutubePlayer(
                      controller: widget.controller,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: Colors.red,
                      progressColors: const ProgressBarColors(
                        playedColor: Colors.red,
                        handleColor: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            
            // Exit Button - top right (safe area aware)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _handleExit,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
            
            // Video Title - top left (optional)
            if (widget.videoTitle.isNotEmpty && _isInitialized)
              Positioned(
                top: 16,
                left: 16,
                right: 80,
                child: SafeArea(
                  child: Text(
                    widget.videoTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
