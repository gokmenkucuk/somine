import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/models/reminder_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/providers/subscription_provider.dart';
import 'package:somine_app/core/repositories/reminder_repository.dart';
import 'package:somine_app/core/services/reminder_scheduler_service.dart';
import 'package:somine_app/core/utils/auth_image_provider.dart';
import 'package:somine_app/widgets/limit_reached_dialog.dart';
import 'package:somine_app/widgets/reminder_indicator.dart';
import 'package:somine_app/widgets/reminder_picker_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'youtube_fullscreen_screen.dart';

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
  ReminderModel? _reminder;

  @override
  void initState() {
    super.initState();
    _checkYoutube();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    if (widget.item.hasReminder) {
      final reminderRepo = ReminderRepository();
      final reminder = await reminderRepo.getItemReminder(widget.item.id);
      if (mounted) {
        setState(() {
          _reminder = reminder;
        });
      }
    }
  }

  Future<void> _editReminder() async {
    final result = await ReminderPickerBottomSheet.show(
      context,
      existingReminder: _reminder,
      onDelete: () async {
        await _deleteReminder();
      },
    );

    if (result == null) return;

    try {
      final scheduler = ReminderSchedulerService();
      final reminder = result.copyWith(itemId: widget.item.id);
      await scheduler.updateReminder(reminder, widget.item.displayTitle);
      if (mounted) {
        setState(() => _reminder = reminder);
      }
    } catch (e) {
      debugPrint('Error updating reminder: $e');
    }
  }

  Future<void> _deleteReminder() async {
    try {
      final scheduler = ReminderSchedulerService();
      await scheduler.cancelReminder(widget.item.id);
      if (mounted) {
        setState(() => _reminder = null);
      }
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
    }
  }

  Future<void> _addReminder() async {
    // Limit check
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final subState = ref.read(subscriptionProvider);
      if (!subState.isPremium) {
        try {
          final reminders = await ReminderRepository().getUserReminders(uid);
          final activeCount = reminders.where((r) => r.isActive).length;
          final canCreate = ref
              .read(subscriptionProvider.notifier)
              .canCreateReminder(activeCount);
          if (!canCreate) {
            if (mounted) {
              await LimitReachedDialog.show(
                context: context,
                ref: ref,
                title: "Hatırlatıcı Sınırına Ulaştın",
                message:
                    "Ücretsiz planda en fazla 3 aktif hatırlatıcı kurabilirsin. Daha fazlası için Premium'a geçin!",
                type: LimitType.item,
              );
            }
            return;
          }
        } catch (e) {
          debugPrint('Error checking reminder limit: $e');
        }
      }
    }

    if (!mounted) return;
    final result = await ReminderPickerBottomSheet.show(context);
    if (result == null) return;

    try {
      final scheduler = ReminderSchedulerService();
      final reminder = result.copyWith(itemId: widget.item.id);
      final success = await scheduler.scheduleReminder(
        reminder,
        widget.item.displayTitle,
      );
      if (success && mounted) {
        setState(() => _reminder = reminder);
      }
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
    }
  }

  Widget _buildAddReminderRow() {
    return GestureDetector(
      onTap: _addReminder,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: DesignTokens.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DesignTokens.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.15),
                    context.colors.secondary.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                PhosphorIconsBold.bell,
                size: 22,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hatırlatıcı Ekle',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  Text(
                    'Bu içerik için hatırlatıcı belirle',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: DesignTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 20,
              color: DesignTokens.textSecondary,
            ),
          ],
        ),
      ),
    );
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
              hideControls: false, // FIX: Kontrolleri göster
              controlsVisibleAtStart:
                  true, // FIX: Başlangıçta kontrolleri göster
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
      // Orientation management handled by fullscreen screen via MethodChannel
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
      builder:
          (context) => AlertDialog(
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
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
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade400,
                            ],
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
                            colors: [
                              const Color(0xFFFF5252),
                              const Color(0xFFD32F2F),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
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
            foregroundColor:
                context.colors.headline, // For back button on image
            flexibleSpace: FlexibleSpaceBar(
              background:
                  _isYoutube && _youtubeController != null
                      ? YoutubePlayerBuilder(
                        player: YoutubePlayer(
                          controller: _youtubeController!,
                          showVideoProgressIndicator: false,
                          onReady: () {
                            // Player Ready
                          },
                        ),
                        builder: (context, player) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: player,
                                ),
                              ),
                              // FIX: Sadece video duraklatıldığında play ikonu göster
                              if (!_isPlaying)
                                GestureDetector(
                                  onTap: () {
                                    // Sadece videoya oynatmak için tıkla
                                    _youtubeController!.play();
                                  },
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 42,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              // FIX: Fullscreen butonu
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    // Fullscreen screen'e yönlendir
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        fullscreenDialog: true,
                                        builder:
                                            (context) =>
                                                YoutubeFullscreenScreen(
                                                  controller:
                                                      _youtubeController!,
                                                  videoTitle:
                                                      widget.item.displayTitle,
                                                ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                      : (widget.item.displayImage != null
                          ? Hero(
                            tag: widget.item.id,
                            child: buildAuthImage(
                              imageUrl: widget.item.displayImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                          : Container(
                            color: DesignTokens.primary.withValues(alpha: 0.1),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 64,
                                color: DesignTokens.textTertiary,
                              ),
                            ),
                          )),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete,
                    size: 20,
                    color: Colors.white,
                  ),
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
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Colors.white,
                ),
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
                  // Title (H1)
                  Text(
                    widget.item.displayTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.w600, // Slightly bolder for hierarchy
                      color: DesignTokens.textPrimary,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: DesignTokens.spacingLG),

                  // Reminder Section (interactive)
                  if (_reminder != null) ...[
                    ReminderIndicator(
                      reminder: _reminder!,
                      onTap: () => _editReminder(),
                    ),
                  ] else ...[
                    _buildAddReminderRow(),
                  ],

                  const SizedBox(height: DesignTokens.spacingLG),

                  // Note Section (Content) - No Label, just text
                  if (widget.item.note != null && widget.item.note!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ), // Minimal padding shift
                      child: Text(
                        widget.item.note!,
                        style: GoogleFonts.kalam(
                          fontSize:
                              18, // Larger for readability since it's the main content
                          color: DesignTokens.textPrimary,
                          height: 1.6,
                        ),
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

                  const SizedBox(
                    height: DesignTokens.spacingXXL,
                  ), // More breathing room
                  // Metadata (Collection) - Subtle footer
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            DesignTokens.background, // Very subtle background
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusXL,
                        ),
                        border: Border.all(color: DesignTokens.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.folder,
                            size: 14,
                            color: DesignTokens.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            categoryName,
                            style: GoogleFonts.poppins(
                              color: DesignTokens.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
              color: context.colors.premiumShadow.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
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
                gradient: LinearGradient(
                  colors: [context.colors.primary, context.colors.secondary],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
              ),
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dynamic Platform Icon
                    Icon(
                      _getPlatformIcon(widget.item.platform),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    // Dynamic Text
                    Text(
                      _getPlatformActionText(widget.item.platform),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper for dynamic icon
  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'Instagram':
        return PhosphorIconsBold.instagramLogo;
      case 'YouTube':
        return PhosphorIconsBold.youtubeLogo;
      case 'X':
        return PhosphorIconsBold.xLogo;
      case 'TikTok':
        return PhosphorIconsBold.tiktokLogo;
      case 'LinkedIn':
        return PhosphorIconsBold.linkedinLogo;
      case 'Spotify':
        return PhosphorIconsBold.spotifyLogo;
      case 'Pinterest':
        return PhosphorIconsBold.pinterestLogo;
      case 'Reddit':
        return PhosphorIconsBold.redditLogo;
      case 'Medium':
        return PhosphorIconsBold.mediumLogo;
      case 'Behance':
        return PhosphorIconsBold.behanceLogo;
      case 'Dribbble':
        return PhosphorIconsBold.dribbbleLogo;
      default:
        return PhosphorIconsBold.link; // Generic link icon for Web
    }
  }

  // Helper for dynamic text
  String _getPlatformActionText(String platform) {
    if (platform == 'Web') return 'Tarayıcıda Aç';
    return '$platform\'da Aç'; // e.g. "Instagram'da Aç"
  }
}
