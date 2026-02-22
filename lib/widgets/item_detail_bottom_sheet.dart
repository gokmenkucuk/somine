import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// YoutubeFullscreenScreen import removed - feature disabled due to iOS issues
import '../core/models/item_model.dart';
import '../core/models/category_model.dart';
import '../core/design/app_colors_extension.dart';
import '../screens/add_content_screen.dart';
import '../widgets/custom_note_icon.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

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

  // YouTube Player State
  YoutubePlayerController? _youtubeController;
  bool _isYoutube = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
    _checkYoutube();
  }

  void _checkYoutube() {
    if (widget.item.url != null) {
      final videoId = YoutubePlayer.convertUrlToId(widget.item.url!);
      if (videoId != null) {
        setState(() {
          _isYoutube = true;
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              enableCaption: false,
              forceHD: false,
              hideControls: false,
              controlsVisibleAtStart: true,
            ),
          )..addListener(_youtubeListener);
        });
      }
    }
  }

  void _youtubeListener() {
    if (_youtubeController != null && mounted) {
      final isPlaying = _youtubeController!.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() => _isPlaying = isPlaying);
      }
      // Orientation management handled by fullscreen screen via MethodChannel
    }
  }

  @override
  void dispose() {
    _youtubeController?.removeListener(_youtubeListener);
    _youtubeController?.dispose();
    super.dispose();
  }

  void _resolveImageSize() {
    final imageUrl = widget.item.displayImage;
    if (imageUrl == null || imageUrl.isEmpty || imageUrl.toLowerCase().contains('.svg')) return;

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
    if (s.contains('tiktok')) return 'TikTok';
    if (s.contains('linkedin')) return 'LinkedIn';
    if (s.contains('spotify')) return 'Spotify';
    if (s.contains('reddit')) return 'Reddit';
    if (s.contains('medium.com')) return 'Medium';
    if (s.contains('behance')) return 'Behance';
    if (s.contains('dribbble')) return 'Dribbble';
    return 'Tarayıcı'; // Generic web = Browser
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
      MaterialPageRoute(builder: (context) => AddContentScreen(editItem: widget.item)),
    ).then((result) {
      if (result != null) {
        Navigator.pop(context, result); 
      }
    });
  }

  Widget _buildFallbackHeader(IconData icon) {
    // For notes: Check if there's an image in ogMetadata, show CustomNoteIcon only if no image
    if (widget.item.type == ItemType.note) {
      // If note has an image, it will be shown by the main image logic
      // This fallback only shows when there's NO image
      return Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.only(top: 48),
        color: context.colors.surfaceWhite,
        child: Center(
          child: Transform.scale(
            scale: 2.0, 
            child: const CustomNoteIcon(),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.only(top: 48),
      color: context.colors.surfaceWhite,
      child: Center(
        child: Icon(icon, size: 56, color: context.colors.primary),
      ),
    );
  }

  Widget _buildYoutubePlayer() {
    // Get status bar height to position video correctly
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      color: Colors.black, // Black background fills status bar area
      child: Column(
        children: [
          // Status bar spacer - black background extends behind status bar
          SizedBox(height: statusBarHeight),
          // Actual YouTube Player
          Expanded(
            child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: context.colors.primary,
                progressColors: ProgressBarColors(
                  playedColor: context.colors.primary,
                  handleColor: context.colors.primary,
                ),
                // Hide fullscreen button by customizing bottom actions
                bottomActions: [
                  CurrentPosition(),
                  ProgressBar(isExpanded: true),
                  RemainingDuration(),
                  PlaybackSpeedButton(),
                  // FullScreenButton removed intentionally
                ],
              ),
              builder: (context, player) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    player,
                    // FIX: Sadece video duraklatıldığında play ikonu göster
                    if (!_isPlaying)
                      GestureDetector(
                        onTap: () => _youtubeController!.play(),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    // Fullscreen button removed due to iOS orientation issues
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.item.displayImage != null && widget.item.displayImage!.isNotEmpty && !widget.item.displayImage!.toLowerCase().contains('.svg');
    final platformName = _getPlatformName(widget.item.url);
    final platformIcon = _getPlatformIcon(widget.item.url);
    
    // Dynamic Header Calculation
    double headerRatio = 0.45;
    if (_isYoutube) {
      // Fixed 16:9 aspect ratio for YouTube videos
      headerRatio = 0.35;
    } else if (!hasImage) {
      headerRatio = 0.45;
    } else if (_imageAspectRatio != null) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final desiredHeight = screenWidth / _imageAspectRatio!;
      double calculatedRatio = desiredHeight / screenHeight;
      if (calculatedRatio > 0.65) calculatedRatio = 0.65;
      if (calculatedRatio < 0.35) calculatedRatio = 0.35; 
      headerRatio = calculatedRatio;
    }
    // Status bar padding
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    // Final header height includes status bar for full page effect
    final headerHeight = (MediaQuery.of(context).size.height * headerRatio) + statusBarHeight;

    // Find assigned category
    final assignedCategory = widget.categories.firstWhere(
      (c) => c.id == widget.item.categoryId, 
      orElse: () => CategoryModel(id: '', userId: '', name: widget.categoryName, icon: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
    );

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.25,
      maxChildSize: 1.0,
      snap: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceWhite,
            // No border radius for full page effect
          ),
          child: Stack(
            children: [
              // --- LAYOUT COLUMN ---
              Column(
                children: [
                   // 1. HEADER IMAGE or YOUTUBE PLAYER
                   SizedBox(
                     height: headerHeight,
                     width: double.infinity,
                     child: ClipRRect(
                        // No border radius for full page
                        child: _isYoutube && _youtubeController != null
                          ? _buildYoutubePlayer()
                          : hasImage
                            ? widget.item.displayImage!.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: widget.item.displayImage!,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    placeholder: (context, url) => _buildFallbackHeader(platformIcon),
                                    errorWidget: (context, url, error) => _buildFallbackHeader(platformIcon),
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
                       color: context.colors.surfaceWhite,
                       child: Column(
                         children: [
                           const SizedBox(height: 20),

                           // DYNAMIC BUTTON: Edit for Notes, Open for Links
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
                                   onTap: widget.item.type == ItemType.note ? _openEditScreen : _openInApp,
                                   borderRadius: BorderRadius.circular(12),
                                   child: Padding(
                                     padding: const EdgeInsets.symmetric(vertical: 14),
                                     child: Row(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         Icon(
                                           widget.item.type == ItemType.note 
                                               ? PhosphorIconsBold.pencilSimple 
                                               : platformIcon, 
                                           size: 20, 
                                           color: Colors.white
                                         ),
                                         const SizedBox(width: 8),
                                         Text(
                                           widget.item.type == ItemType.note 
                                               ? "Düzenle" 
                                               : "$platformName'da Aç",
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
                                    // 1. TITLE (No Label)
                                    Text(
                                      widget.item.displayTitle,
                                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: context.colors.headline),
                                    ),

                                    const SizedBox(height: 20),

                                    // 2. CONTENT/NOTE (No Label)
                                    if (widget.item.note != null && widget.item.note!.isNotEmpty) ...[
                                       Align(
                                         alignment: Alignment.centerLeft,
                                         child: Linkify(
                                           text: widget.item.note!,
                                           onOpen: (link) async {
                                             if (!await launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication)) {
                                               throw Exception('Could not launch ${link.url}');
                                             }
                                           },
                                           textAlign: TextAlign.start,
                                           style: GoogleFonts.poppins(fontSize: 15, color: context.colors.body, height: 1.6),
                                           linkStyle: GoogleFonts.poppins(fontSize: 15, color: context.colors.primary, fontWeight: FontWeight.bold),
                                         ),
                                       ),
                                       const SizedBox(height: 24),
                                    ],

                                    // 3. COLLECTION (No Label, just a subtle chip at the bottom)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: context.colors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(PhosphorIconsRegular.folder, size: 14, color: context.colors.primary),
                                            const SizedBox(width: 6),
                                            Text(
                                              assignedCategory.name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: context.colors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),
                                    
                                    // Bottom padding for scroll content
                                    const SizedBox(height: 24),
                                 ],
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                   
                   // Fixed Footer at Bottom
                   if (widget.item.type != ItemType.note)
                     Container(
                       padding: EdgeInsets.fromLTRB(32, 8, 32, MediaQuery.of(context).padding.bottom + 4),
                       color: context.colors.surfaceWhite,
                       child: Align(
                         alignment: Alignment.centerLeft,
                         child: Text(
                           "Telif hakları ve yayıncı politikaları gereği, bu içerik yalnızca orijinal kaynağında görüntülenebilir.",
                           textAlign: TextAlign.left,
                           style: GoogleFonts.poppins(
                             fontSize: 11,
                             color: context.colors.body.withOpacity(0.9), // Darker text
                             fontWeight: FontWeight.w400,
                           ),
                         ),
                       ),
                     ),
                ],
              ),

              // --- 3. STICKY ICONS (Top Layer) - Premium Glassmorphism Style ---
              // Close Button (Top Left)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56, 
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceWhite.withOpacity(0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.primary.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.primary.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(PhosphorIconsBold.x, size: 20, color: context.colors.headline),
                      ),
                    ),
                  ),
                ),
              ),

              // Share Button (Top Right)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56, 
                right: 16,
                child: GestureDetector(
                  onTap: _shareLink,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceWhite.withOpacity(0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.primary.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.primary.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(PhosphorIconsBold.paperPlaneTilt, size: 20, color: context.colors.primary),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Edit Button (Left of Share)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56, 
                right: 16 + 48 + 12,
                child: GestureDetector(
                  onTap: _openEditScreen,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceWhite.withOpacity(0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.primary.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.primary.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(PhosphorIconsBold.pencilSimple, size: 20, color: context.colors.primary),
                      ),
                    ),
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
