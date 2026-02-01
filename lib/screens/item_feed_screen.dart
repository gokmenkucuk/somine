import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/widgets/custom_note_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:ui' as ui;

// import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/providers/navigation_providers.dart'; // Added for drag state
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/utils/demo_seeder.dart';
import 'package:somine_app/widgets/item_detail_bottom_sheet.dart';
import 'package:somine_app/widgets/item_card.dart';
import 'package:somine_app/core/services/vault_service.dart';
import 'package:somine_app/screens/notifications_screen.dart';
import 'package:somine_app/core/providers/notification_providers.dart';
import 'package:somine_app/screens/search_screen.dart';

enum ViewMode { square, masonry, feed }

class ItemFeedScreen extends ConsumerStatefulWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onCatalogTap;

  const ItemFeedScreen({super.key, required this.onSearchTap, required this.onCatalogTap});

  @override
  ConsumerState<ItemFeedScreen> createState() => _ItemFeedScreenState();
}

class _ItemFeedScreenState extends ConsumerState<ItemFeedScreen> {
  ViewMode _viewMode = ViewMode.masonry; 
  final ScrollController _scrollController = ScrollController();
  
  // For smooth skeleton-to-content transition
  double _contentOpacity = 0.0;
  int _lastItemCount = 0;
  

  
  // DRAG-TO-DELETE STATE (Moved to Provider)
  // bool _isDragging = false;
  // bool _isHoveringTrash = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final feedState = ref.read(paginatedFeedProvider);
      if (!feedState.isLoading && feedState.hasMore) {
        // DO NOT reset opacity - keep existing content visible
        // Just load more items
        ref.read(paginatedFeedProvider.notifier).loadMore();
      }
    }
  }
  
  void _onItemsLoaded(int newCount) {
    if (newCount > _lastItemCount && newCount > 0) {
      _lastItemCount = newCount;
      // Wait for layout to complete, then fade in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _contentOpacity = 1.0);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserModelProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selCategory = ref.watch(selectedCategoryIdProvider);
    final feedState = ref.watch(paginatedFeedProvider);
    
    // Listen for item changes to trigger fade-in after layout
    ref.listen<PaginatedItemsState>(paginatedFeedProvider, (previous, next) {
      if (!next.isLoading && next.items.isNotEmpty) {
        _onItemsLoaded(next.items.length);
      }
    });

    final rawName = userAsync.value?.displayName?.split(' ').first ?? 'Misafir';
    final userName = rawName.isNotEmpty 
        ? '${rawName[0].toUpperCase()}${rawName.substring(1)}' 
        : rawName;
    final categories = categoriesAsync.value ?? [];
    final allItems = ref.watch(catalogItemsProvider).value ?? [];

    // Filter out empty categories and hide "Hızlı" from UI (User Request)
    final filteredCategories = categories.where((cat) {
      // Hide "Hızlı" category from chips
      if (cat.name == 'Hızlı') return false;
      return allItems.any((item) => item.categoryId == cat.id);
    }).toList();

    final items = feedState.items;

    // Ensure content is visible if items already loaded (e.g., after theme change)
    if (items.isNotEmpty && _contentOpacity == 0.0 && !feedState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _contentOpacity = 1.0;
            _lastItemCount = items.length;
          });
        }
      });
    }



    return Container(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== FIXED HEADER SECTION =====
              // Top Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Merhaba,", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: context.colors.hint, height: 1.2)),
                              Text(userName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: context.colors.headline, height: 1.2)),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: widget.onSearchTap,
                                child: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(color: context.colors.surfaceWhite.withOpacity(0.6), shape: BoxShape.circle, border: Border.all(color: context.colors.surfaceWhite, width: 1.5)),
                                  child: Icon(PhosphorIconsLight.magnifyingGlass, color: context.colors.headline, size: 24),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(color: context.colors.surfaceWhite.withOpacity(0.6), shape: BoxShape.circle, border: Border.all(color: context.colors.surfaceWhite, width: 1.5)),
                                      child: Icon(PhosphorIconsLight.bell, color: context.colors.headline, size: 24),
                                    ),
                                    // Notification Badge
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
                                        final unreadCount = unreadCountAsync.valueOrNull ?? 0;
                                        
                                        if (unreadCount > 0) {
                                          return Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Slogan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeInLeft(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final colors = Theme.of(context).brightness == Brightness.light
                              ? [context.colors.primary, const Color(0xFF6FBFAC)]
                              : [context.colors.primary, context.colors.secondary];
                          
                          return Text(
                            "Dijital İçeriklerini\nKoleksiyona Kaydet",
                            style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.0,
                              height: 1.1,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(const Rect.fromLTWH(0, 0, 300, 80)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Özenle sakla, keyifle paylaş!",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: context.colors.headline,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Categories List
              FadeInUp(
                delay: const Duration(milliseconds: 1000),
                child: SizedBox(
                  height: 48,
                  child: ListView.builder(
                    clipBehavior: Clip.none,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredCategories.length + 1, 
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Center(child: _buildCategoryChip(ref, null, "Tümü", selCategory == null));
                      }
                      final cat = filteredCategories[index - 1];
                      return Center(child: _buildCategoryChip(ref, cat, cat.name, selCategory == cat.id));
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
              
              // Controls Row
              FadeInUp(
                delay: const Duration(milliseconds: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceWhite, 
                          borderRadius: BorderRadius.circular(12),
                          border: Theme.of(context).brightness == Brightness.light 
                              ? Border.all(color: Colors.grey.shade300, width: 0.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            _buildViewModeButton(icon: PhosphorIconsLight.squaresFour, mode: ViewMode.square),
                            const SizedBox(width: 4),
                            _buildViewModeButton(icon: PhosphorIconsLight.layout, mode: ViewMode.masonry),
                            const SizedBox(width: 4),
                            _buildViewModeButton(icon: PhosphorIconsLight.list, mode: ViewMode.feed),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onCatalogTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Tümü", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.headline)),
                            const SizedBox(width: 4),
                            Icon(PhosphorIconsLight.caretRight, size: 14, color: context.colors.hint),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8), 

              // ===== SCROLLABLE CONTENT WITH SMOOTH TRANSITION =====
              Expanded(
                child: Stack(
                  children: [
                    // LAYER 1: Actual Content (starts invisible, fades in)
                    AnimatedOpacity(
                      opacity: _contentOpacity,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          // Content Grid
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: _buildSliverContent(items, categories, feedState.isLoading),
                          ),

                          // Pagination Skeleton Loader - Adapts to view mode
                          if (feedState.isLoading && items.isNotEmpty)
                             SliverPadding(
                               padding: const EdgeInsets.symmetric(horizontal: 20),
                               sliver: _buildPaginationSkeleton(),
                             ),

                          const SliverToBoxAdapter(child: SizedBox(height: 140)),
                        ],
                      ),
                    ),
                    
          // LAYER 2: Skeleton Overlay (visible until content fades in)
                    if (_contentOpacity < 1.0)
                      AnimatedOpacity(
                        opacity: 1.0 - _contentOpacity,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          color: Colors.transparent, // Transparent to show VibeBackground
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildSkeletonOverlay(),
                          ),
                        ),
                      ),
                      
                    // LAYER 3: TRASH ZONE OVERLAY -> MOVED TO HOME SCREEN FAB
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildViewModeButton({required IconData icon, required ViewMode mode}) {
    final bool isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.backgroundTop : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: context.colors.premiumShadow.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Icon(icon, size: 20, color: isSelected ? context.colors.primary : context.colors.hint),
      ),
    );
  }

  Widget _buildCategoryChip(WidgetRef ref, CategoryModel? category, String label, bool isSelected) {
    final isVault = category?.isVault ?? false;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () async {
          // If vault category, require biometric auth first
          if (isVault && !isSelected) {
            final vaultService = VaultService();
            final result = await vaultService.authenticate(
              reason: '${category?.name ?? "Gizli Kasa"} koleksiyonuna erişmek için doğrulama yapın',
            );
            
            if (result == VaultAuthResult.canceled) {
              return; // Do nothing on cancel
            }
            
            if (result != VaultAuthResult.success) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Doğrulama başarısız')),
                );
              }
              return;
            }
          }
          
          // Trigger skeleton loading for smooth transition
          if (ref.read(selectedCategoryIdProvider) != category?.id) {
            setState(() {
              _contentOpacity = 0.0; // Show skeleton
              _lastItemCount = 0; // Reset item count to re-trigger fade-in
            });
          }
          ref.read(selectedCategoryIdProvider.notifier).state = category?.id;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [context.colors.secondary.withOpacity(0.5), context.colors.surfaceWhite],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : (isVault 
                      ? null // No gradient for unselected vault, just clear or specific style
                      : null),
              color: isSelected 
                  ? null 
                  : (isVault ? context.colors.primary.withOpacity(0.1) : context.colors.surfaceWhite),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected 
                    ? Colors.transparent 
                    : (isVault ? context.colors.primary.withOpacity(0.5) : context.colors.secondary),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: context.colors.secondary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                  : [BoxShadow(color: context.colors.premiumShadow.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isVault) ...[
                  Icon(
                    PhosphorIconsBold.lockKey, // Key icon as requested
                    size: 16,
                    color: isSelected ? context.colors.headline : context.colors.primary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? context.colors.headline : context.colors.body,
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildSliverContent(List<ItemModel> items, List<CategoryModel> categories, bool isLoading) {
    if (items.isEmpty && !isLoading) {
       return SliverFillRemaining(
         hasScrollBody: false,
         child: Center(
           child: Padding(
             padding: const EdgeInsets.symmetric(horizontal: 40),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Container(
                   width: 120, height: 120,
                   decoration: BoxDecoration(
                     color: context.colors.surfaceWhite,
                     shape: BoxShape.circle,
                     boxShadow: [
                       BoxShadow(color: context.colors.premiumShadow.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                     ]
                   ),
                   child: Icon(PhosphorIconsDuotone.folderPlus, size: 60, color: context.colors.primary),
                 ),
                 const SizedBox(height: 24),
                 Text(
                   "Koleksiyonun Boş",
                   style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: context.colors.headline),
                 ),
                 const SizedBox(height: 12),
                 Text(
                   "Henüz hiç içerik eklememişsin.\nLinklerini ve notlarını kaydetmeye başla!",
                   textAlign: TextAlign.center,
                   style: GoogleFonts.poppins(fontSize: 14, color: context.colors.body, height: 1.5),
                 ),
                 const SizedBox(height: 32),
                 // Note: We don't have a direct callback for Add Content here easily without passing it down, 
                 // but we can guide user to the FAB or Search if needed.
                 // For now, simple directional text is good, or a button if we had the callback.
                 // Since the FAB/BottomBar handles add, maybe just an arrow down?
                 // Or better, let's make it actionable if possible.
               ],
             ),
           ),
         ),
       );
    }
    
    if (items.isEmpty && isLoading) {
         // Skeleton Loading - Adapt to current view mode
         switch (_viewMode) {
           case ViewMode.square:
             return SliverGrid(
               delegate: SliverChildBuilderDelegate(
                 (context, index) => _buildSkeletonCard(index),
                 childCount: 6,
               ),
               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
               ),
             );
           case ViewMode.masonry:
             return SliverMasonryGrid.count(
               crossAxisCount: 2, 
               mainAxisSpacing: 12, 
               crossAxisSpacing: 12, 
               childCount: 6,
               itemBuilder: (context, index) => _buildSkeletonCard(index),
             );
           case ViewMode.feed:
             return SliverList(
               delegate: SliverChildBuilderDelegate(
                 (context, index) => Padding(
                   padding: const EdgeInsets.only(bottom: 24),
                   child: _buildSkeletonCard(index),
                 ),
                 childCount: 4, // Less for feed mode
               ),
             );
         }
    }

    String getBadge(ItemModel item) {
       final cat = categories.where((c) => c.id == item.categoryId).firstOrNull;
       return cat?.name ?? 'Genel';
    }

    switch (_viewMode) {
      case ViewMode.square:
        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildContentCardRefactored(items[index], getBadge(items[index]), categories, isGrid: true, forceSquare: true),
            childCount: items.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.75,
          ),
        );
      case ViewMode.masonry:
        return SliverMasonryGrid.count(
          // key: ValueKey(items.length), // Removed to prevent full rebuild flash
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childCount: items.length,
          itemBuilder: (context, index) => _buildContentCardRefactored(items[index], getBadge(items[index]), categories, isGrid: true, forceSquare: false),
        );
      case ViewMode.feed:
        return SliverList(
          // key: ValueKey(items.length),
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildContentCardRefactored(items[index], getBadge(items[index]), categories, isGrid: false),
            ),
            childCount: items.length,
          ),
        );
    }
  }

  Widget _buildContentCardRefactored(ItemModel item, String badgeText, List<CategoryModel> categories, {required bool isGrid, bool forceSquare = false}) {
    // Notes AND Links can have images now
    final isNote = item.type == ItemType.note;
    final hasImage = item.displayImage != null && item.displayImage!.isNotEmpty && !item.displayImage!.toLowerCase().endsWith('.svg');
    final source = item.url ?? '';

    // --- FALLBACK VIEW (UNIFIED with Catalog) ---
    Widget buildFallbackView() {
       IconData icon;
       List<Color> gradientColors = [context.colors.primary, context.colors.secondary];
       final s = source.toLowerCase();
       
       if (isNote) {
          icon = PhosphorIconsBold.note;
       } else if (s.contains('twitter') || s.contains('x.com')) {
          icon = PhosphorIconsBold.xLogo;
       } else if (s.contains('instagram')) {
          icon = PhosphorIconsBold.instagramLogo;
       } else if (s.contains('youtube')) {
          icon = PhosphorIconsBold.youtubeLogo;
       } else if (s.contains('pinterest')) {
          icon = PhosphorIconsBold.pinterestLogo;
       } else if (s.contains('tiktok')) {
          icon = PhosphorIconsBold.tiktokLogo;
       } else if (s.contains('spotify')) {
          icon = PhosphorIconsBold.spotifyLogo;
       } else if (s.contains('linkedin')) {
          icon = PhosphorIconsBold.linkedinLogo;
       } else {
          icon = PhosphorIconsBold.link;
       }

       // STANDARDIZED CARD SIZE: Square (1.0) for grid
       return AspectRatio(
         aspectRatio: 1.0,
         child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.colors.surfaceWhite, context.colors.backgroundTop],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: isNote 
              ? const CustomNoteIcon(size: 48)
              : ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Icon(icon, size: 48, color: Colors.white),
              ),
         ),
       );
    }

    // Helper to build Platform Icon
    Widget buildPlatformIcon() {
      IconData icon = PhosphorIconsBold.link;
      final s = source.toLowerCase();

      if (s.contains('instagram')) {
        icon = PhosphorIconsBold.instagramLogo;
      } else if (s.contains('youtube')) {
        icon = PhosphorIconsBold.youtubeLogo;
      } else if (s.contains('twitter') || s.contains('x.com')) {
        icon = PhosphorIconsBold.xLogo;
      } else if (s.contains('pinterest')) {
        icon = PhosphorIconsBold.pinterestLogo;
      } else if (s.contains('tiktok')) {
        icon = PhosphorIconsBold.tiktokLogo;
      } else if (s.contains('spotify')) {
        icon = PhosphorIconsBold.spotifyLogo;
      } else if (s.contains('linkedin')) {
        icon = PhosphorIconsBold.linkedinLogo;
      }

      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, size: 14, color: context.colors.primary)),
      );
    }

    Widget contentHeader;
    
    if (hasImage) {
      if (forceSquare) {
        // SQUARE MODE: Use AspectRatio with cover fit
        contentHeader = AspectRatio(
          aspectRatio: 1.0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              item.displayImage!.startsWith('http')
                 ? CachedNetworkImage(
                     imageUrl: item.displayImage!,
                     fit: BoxFit.cover,
                     placeholder: (context, url) => _ImageShimmerPlaceholder(),
                     errorWidget: (context, url, error) => buildFallbackView(),
                   )
                 : item.displayImage!.startsWith('data:')
                 ? Image.memory(
                     const Base64Decoder().convert(item.displayImage!.substring(23)),
                     fit: BoxFit.cover,
                     errorBuilder: (context, url, error) => buildFallbackView(),
                   )
                 : Image.asset(item.displayImage!, fit: BoxFit.cover),

              Positioned(top: 8, right: 8, child: buildPlatformIcon()),
            ],
          ),
        );
      } else {
        // MASONRY MODE: Use natural image height
        contentHeader = Stack(
          children: [
            item.displayImage!.startsWith('http')
               ? CachedNetworkImage(
                   imageUrl: item.displayImage!,
                   fit: BoxFit.fitWidth,
                   placeholder: (context, url) => AspectRatio(
                     aspectRatio: 1.0,
                     child: _ImageShimmerPlaceholder(),
                   ),
                   errorWidget: (context, url, error) => buildFallbackView(),
                 )
               : item.displayImage!.startsWith('data:')
               ? Image.memory(
                   const Base64Decoder().convert(item.displayImage!.substring(23)),
                   fit: BoxFit.fitWidth,
                   errorBuilder: (context, url, error) => buildFallbackView(),
                 )
               : Image.asset(item.displayImage!, fit: BoxFit.fitWidth),

            Positioned(top: 8, right: 8, child: buildPlatformIcon()),
          ],
        );
      }
    } else {
      // No Image: Use buildFallbackView (already has AspectRatio inside)
      contentHeader = buildFallbackView();
    }

    // WRAP WITH LONG PRESS DRAGGABLE
    return LongPressDraggable<ItemModel>(
      data: item,
      delay: const Duration(milliseconds: 300), // Short delay to prevent accidental drags
      dragAnchorStrategy: pointerDragAnchorStrategy, // Makes drag follow finger exactly
      feedback: Transform.rotate(
        angle: 0.05, // Slight tilt for drag effect
        child: Material(
          color: Colors.transparent,
          elevation: 8,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: 0.9,
            child: SizedBox(
              width: 100, // Standardized size
              height: 100,
              child: ClipRRect(
                 borderRadius: BorderRadius.circular(16),
                 child: Stack(
                   fit: StackFit.expand,
                   children: [
                      Container(color: Colors.white), // Background
                      if (isNote && !hasImage)
                        const Center(child: Icon(PhosphorIconsBold.note, size: 40, color: Colors.grey))
                      else if (hasImage)
                        item.displayImage!.startsWith('http')
                          ? CachedNetworkImage(imageUrl: item.displayImage!, fit: BoxFit.cover)
                          : item.displayImage!.startsWith('data:')
                              ? Image.memory(
                                  const Base64Decoder().convert(item.displayImage!.substring(23)),
                                  fit: BoxFit.cover)
                              : Image.asset(item.displayImage!, fit: BoxFit.cover)
                      else
                         const Center(child: Icon(PhosphorIconsBold.link, size: 40, color: Colors.grey)),
                   ],
                 ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: FadeInUp(
          // Reuse same container but faded
           child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: context.colors.surfaceWhite,
            ),
            child: const SizedBox(height: 100), // Placeholder
           ),
        ),
      ),
      onDragStarted: () {
        ref.read(isDraggingProvider.notifier).state = true;
        HapticFeedback.selectionClick();
      },
      onDragEnd: (details) {
         ref.read(isDraggingProvider.notifier).state = false;
      },
      onDraggableCanceled: (velocity, offset) {
         ref.read(isDraggingProvider.notifier).state = false;
      },
      child: FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: context.colors.surfaceWhite,
            boxShadow: [BoxShadow(color: context.colors.premiumShadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      enableDrag: true, 
                      builder: (context) => ItemDetailBottomSheet(item: item, categoryName: badgeText, categories: categories),
                  );
                  
                  if (result == true) {
                     ref.invalidate(paginatedFeedProvider);
                     ref.invalidate(itemCountProvider);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    contentHeader,
                    // Thin grey line above text area
                    Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.15),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.displayTitle, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.headline)
                          ),
                          Text(
                            badgeText, 
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w400, color: context.colors.hint)
                          ),
                        ],
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

  // DEDICATED NOTE CARD
  Widget _buildNoteCard(ItemModel item, String badgeText, List<CategoryModel> categories) {
    final notePreview = item.note ?? item.displayTitle;
    
    return LongPressDraggable<ItemModel>(
       data: item,
       delay: const Duration(milliseconds: 300),
       dragAnchorStrategy: pointerDragAnchorStrategy,
       feedback: Transform.rotate(
         angle: 0.05, // Slight tilt for drag effect
         child: Material(
          color: Colors.transparent,
          elevation: 8,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: 0.9,
            child: SizedBox(
              width: 100, // Standardized size
              height: 100,
              child: Container(
                 decoration: BoxDecoration(
                   color: const Color(0xFFFFFBF5), // Note color
                   borderRadius: BorderRadius.circular(16),
                 ),
                 child: const Center(
                   child: Icon(PhosphorIconsBold.note, size: 40, color: Colors.orange),
                 ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: FadeInUp(
           child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: context.colors.surfaceWhite,
            ),
            child: const SizedBox(height: 100),
           ),
        ),
      ),
      onDragStarted: () {
         ref.read(isDraggingProvider.notifier).state = true;
        HapticFeedback.selectionClick();
      },
      onDragEnd: (details) {
         ref.read(isDraggingProvider.notifier).state = false;
      },
      onDraggableCanceled: (velocity, offset) {
         ref.read(isDraggingProvider.notifier).state = false;
      },
       child: FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Warm paper-like gradient for notes
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFFBF5), // Warm cream
                const Color(0xFFF5F0E8), // Soft beige
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: context.colors.premiumShadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      enableDrag: true, 
                      builder: (context) => ItemDetailBottomSheet(item: item, categoryName: badgeText, categories: categories),
                  );
                  
                  if (result == true) {
                     ref.invalidate(paginatedFeedProvider);
                     ref.invalidate(itemCountProvider);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Note Icon Row
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: context.colors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              PhosphorIconsBold.note,
                              size: 16,
                              color: context.colors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            badgeText,
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: context.colors.hint),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Title
                      if (item.displayTitle.isNotEmpty)
                        Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.headline),
                        ),
                      
                      const SizedBox(height: 6),
                      
                      // Note Preview
                      Text(
                        notePreview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: context.colors.body,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackView(String source, {bool isNote = false}) {
    IconData icon;
    
    // UNIFIED: Same icon style for notes and links
    if (isNote) {
      icon = PhosphorIconsBold.note; // Note icon
    } else if (source.contains('x.com') || source.contains('twitter')) {
      icon = PhosphorIconsBold.xLogo;
    } else if (source.contains('instagram')) {
      icon = PhosphorIconsBold.instagramLogo;
    } else if (source.contains('youtube')) {
      icon = PhosphorIconsBold.youtubeLogo;
    } else if (source.contains('pinterest')) {
      icon = PhosphorIconsBold.pinterestLogo;
    } else {
      icon = PhosphorIconsBold.link;
    }
    
    // Unified Green Gradient for all Empty State Icons
    List<Color> gradientColors = [context.colors.primary, context.colors.secondary];

    // Return container only - parent handles AspectRatio
    return Container(
       decoration: BoxDecoration(
         gradient: LinearGradient(
           colors: [context.colors.surfaceWhite, context.colors.backgroundTop],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
         ),
       ),
       alignment: Alignment.center,
       // Notes use CustomNoteIcon, links use gradient platform icon
       child: isNote 
         ? const CustomNoteIcon(size: 48)
         : ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Icon(icon, size: 48, color: Colors.white),
          ),
    );
  }

  // Custom notepad icon with text lines inside
  Widget _buildNotepadGraphic(BuildContext context) {
    return Container(
      width: 40,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.colors.primary, context.colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Text lines mimicking written content
           Container(height: 2, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(1))),
           const SizedBox(height: 4),
           Container(height: 2, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(1))),
           const SizedBox(height: 4),
           Container(height: 2, width: 16, decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(1))),
        ],
      ),
    );
  }

  /* 
  Widget _buildCustomNoteGraphic() { ... } 
  Removed custom graphic to use standard icons
  */

  Widget _buildPlatformIconWidget(String source) {
    final s = source.toLowerCase();
    IconData icon;

    if (s.contains('instagram')) {
      icon = PhosphorIconsBold.instagramLogo;
    } else if (s.contains('youtube')) {
      icon = PhosphorIconsBold.youtubeLogo;
    } else if (s.contains('twitter') || s.contains('x.com')) {
      icon = PhosphorIconsBold.xLogo;
    } else if (s.contains('pinterest')) {
      icon = PhosphorIconsBold.pinterestLogo;
    } else {
      icon = PhosphorIconsBold.link;
    }

    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.surfaceWhite, 
      ),
      child: Center(child: Icon(icon, color: context.colors.primary, size: 14)), // Green Icon
    );
  }

  Widget _buildSkeletonCard(int index) {
    // Alternate heights for masonry effect
    final heights = [180.0, 220.0, 160.0, 200.0, 190.0, 240.0];
    final height = heights[index % heights.length];
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.colors.surfaceWhite,
        boxShadow: [BoxShadow(color: context.colors.premiumShadow.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Placeholder with Shimmer - use ClipRRect for top corners
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: _ShimmerBox(height: height),
            ),
            
            // Text Placeholder
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _ShimmerBox(height: 14, width: double.infinity),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _ShimmerBox(height: 10, width: 80),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationSkeleton() {
    switch (_viewMode) {
      case ViewMode.square:
        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSkeletonCard(index),
            childCount: 4,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
          ),
        );
      case ViewMode.masonry:
        return SliverMasonryGrid.count(
          crossAxisCount: 2, 
          mainAxisSpacing: 12, 
          crossAxisSpacing: 12, 
          childCount: 4,
          itemBuilder: (context, index) => _buildSkeletonCard(index),
        );
      case ViewMode.feed:
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildSkeletonCard(index),
            ),
            childCount: 2,
          ),
        );
    }
  }
  
  Widget _buildSkeletonOverlay() {
    // Build a non-sliver skeleton grid for the overlay
    switch (_viewMode) {
      case ViewMode.square:
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => _buildSkeletonCard(index),
        );
      case ViewMode.masonry:
        return MasonryGridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: 6,
          itemBuilder: (context, index) => _buildSkeletonCard(index),
        );
      case ViewMode.feed:
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 4,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildSkeletonCard(index),
          ),
        );
    }
  }
}

// Shimmer Effect Widget
class _ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const _ShimmerBox({required this.height, this.width, this.borderRadius = 0});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment((_animation.value - 1), 0),
              end: Alignment(_animation.value, 0),
              colors: [
                context.colors.hint.withOpacity(0.1),
                context.colors.hint.withOpacity(0.05),
                context.colors.hint.withOpacity(0.1),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Shimmer placeholder for images
class _ImageShimmerPlaceholder extends StatefulWidget {
  const _ImageShimmerPlaceholder();

  @override
  State<_ImageShimmerPlaceholder> createState() => _ImageShimmerPlaceholderState();
}

class _ImageShimmerPlaceholderState extends State<_ImageShimmerPlaceholder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment((_animation.value - 1), 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
        );
      },
    );
  }
}
