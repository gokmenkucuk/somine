import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  YoutubePlayerController? _youtubeController;
  bool _isYoutube = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
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
          )..addListener(_listener);
        });
      }
    }
  }

  void _listener() {
    if (_youtubeController != null && mounted) {
      final isPlaying = _youtubeController!.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() => _isPlaying = isPlaying);
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.removeListener(_listener);
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(BuildContext context) async {
    if (widget.item.url != null) {
      final uri = Uri.parse(widget.item.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Link açılamadı: ${widget.item.url}')),
          );
        }
      }
    }
  }

  Future<void> _deleteItem(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            'Silme Onayı',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: context.colors.headline,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bu içeriği silmek istediğinize emin misiniz?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: context.colors.body,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.colors.surfaceWhite,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(context, false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade300, Colors.grey.shade400],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "İptal",
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(context, true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFFF5252), const Color(0xFFD32F2F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Sil",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(itemRepositoryProvider).deleteItem(widget.item.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.asData?.value ?? [];
    final category = categories.cast<CategoryModel?>().firstWhere(
      (c) => c?.id == widget.item.categoryId,
      orElse: () => null,
    );
    final categoryName = category?.name ?? 'Genel';

    return Scaffold(
      backgroundColor: context.colors.surfaceWhite,
      body: CustomScrollView(
        slivers: [
          // 1. Hero Image Header with AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: context.colors.surfaceWhite,
            foregroundColor: context.colors.headline, // For back button on image
            flexibleSpace: FlexibleSpaceBar(
              background: _isYoutube && _youtubeController != null
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        YoutubePlayer(
                          controller: _youtubeController!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: context.colors.primary,
                          progressColors: ProgressBarColors(
                            playedColor: context.colors.primary,
                            handleColor: context.colors.primary,
                          ),
                          onReady: () {
                             // Player Ready
                          },
                        ),
                        // Custom Play Content Overlay
                        if (!_isPlaying)
                          GestureDetector(
                            onTap: () {
                               _youtubeController!.play();
                            },
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
                                color: Colors.white
                              ),
                            ),
                          ),
                      ],
                    )
                  : (widget.item.displayImage != null
                      ? Hero(
                          tag: widget.item.id,
                          child: Image.network(
                            widget.item.displayImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          color: DesignTokens.primary.withValues(alpha: 0.1),
                          child: const Center(
                            child: Icon(Icons.image, size: 64, color: DesignTokens.textTertiary),
                          ),
                        )),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26, 
                    shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.delete, size: 20, color: Colors.white),
                ),
                onPressed: () => _deleteItem(context),
              ),
              const SizedBox(width: 8),
            ],
            leading: IconButton(
               icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26, 
                    shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
            ),
          ),

          // 2. Info Content
          SliverToBoxAdapter(
            child: Padding(
               padding: const EdgeInsets.all(DesignTokens.spacingLG),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // Metadata
                   Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                         decoration: BoxDecoration(
                           color: DesignTokens.primary.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                         ),
                         child: Text(
                           categoryName,
                           style: GoogleFonts.poppins(
                             color: DesignTokens.primary,
                             fontSize: 12,
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                       ),
                       const Spacer(),
                       // Date
                       Text(
                         'Added recently', // Placeholder for relative time
                         style: GoogleFonts.poppins(
                           color: DesignTokens.textTertiary,
                           fontSize: 12,
                         ),
                       ),
                     ],
                   ),
                   
                   const SizedBox(height: DesignTokens.spacingMD),
                   
                   // Title (H1)
                   Text(
                     widget.item.displayTitle,
                     style: GoogleFonts.poppins(
                       fontSize: 24,
                       fontWeight: FontWeight.w500,
                       color: DesignTokens.textPrimary,
                       height: 1.3,
                     ),
                   ),
                   
                   if (widget.item.url != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.item.url!,
                        style: GoogleFonts.poppins(
                          color: context.colors.hint,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                   ],

                   const SizedBox(height: DesignTokens.spacingLG),
                   const Divider(color: DesignTokens.border),
                   const SizedBox(height: DesignTokens.spacingLG),

                   // Note Section
                   if (widget.item.note != null && widget.item.note!.isNotEmpty)
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(DesignTokens.spacingMD),
                       decoration: BoxDecoration(
                         color: DesignTokens.background,
                         borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                         border: Border.all(color: DesignTokens.border),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'Notun:',
                             style: GoogleFonts.poppins(
                               fontSize: 12,
                               fontWeight: FontWeight.bold,
                               color: DesignTokens.textSecondary,
                             ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             widget.item.note!,
                             style: GoogleFonts.kalam(
                               fontSize: 16,
                               color: DesignTokens.textPrimary,
                               height: 1.5,
                             ),
                           ),
                         ],
                       ),
                     )
                   else
                      GestureDetector(
                        onTap: () {
                          // TODO: Open edit modal
                        },
                        child: Text(
                           'Bir not ekle...',
                           style: GoogleFonts.kalam(
                             fontSize: 16,
                             color: DesignTokens.textTertiary,
                           ),
                        ),
                      ),
                      
                   const SizedBox(height: 100), // Spacing for sticky button
                 ],
               ),
            ),
          ),
        ],
      ),
      
      // 3. Sticky Bottom Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingLG),
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: context.colors.premiumShadow.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            )
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => _launchUrl(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.transparent, 
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
              ),
            ).copyWith(
               backgroundColor: WidgetStateProperty.all(Colors.transparent), 
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [context.colors.primary, context.colors.secondary]),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
              ),
              child: Container(
                alignment: Alignment.center,
                height: 56,
                child: Text(
                  'Kaynağa Git',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
