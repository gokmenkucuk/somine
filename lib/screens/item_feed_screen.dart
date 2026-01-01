import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:ui' as ui;

import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/utils/demo_seeder.dart';
import 'package:somine_app/widgets/item_detail_bottom_sheet.dart';
import 'package:somine_app/widgets/item_card.dart';
import 'package:somine_app/screens/notifications_screen.dart';
import 'package:somine_app/screens/search_screen.dart';

enum ViewMode { square, masonry, feed }

class ItemFeedScreen extends ConsumerStatefulWidget {
  final VoidCallback onSearchTap;

  const ItemFeedScreen({super.key, required this.onSearchTap});

  @override
  ConsumerState<ItemFeedScreen> createState() => _ItemFeedScreenState();
}

class _ItemFeedScreenState extends ConsumerState<ItemFeedScreen> {
  ViewMode _viewMode = ViewMode.masonry; 
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final feedState = ref.read(paginatedFeedProvider);
      if (!feedState.isLoading && feedState.hasMore) {
        ref.read(paginatedFeedProvider.notifier).loadMore();
      }
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

    final rawName = userAsync.value?.displayName?.split(' ').first ?? 'Misafir';
    final userName = rawName.isNotEmpty 
        ? '${rawName[0].toUpperCase()}${rawName.substring(1)}' 
        : rawName;
    final categories = categoriesAsync.value ?? [];
    final items = feedState.items;

    // Force Reseed Logic - DISABLED FOR REAL DATA
    // ref.listen<AsyncValue<int>>(itemCountProvider, (previous, next) {
    //     if (next.hasValue) {
    //        DemoSeeder.seed(ref).then((_) {
    //           ref.refresh(paginatedFeedProvider); 
    //           ref.refresh(categoriesProvider);
    //        });
    //     }
    // });

    return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Header Block
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                        Text("Merhaba,", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.hint, height: 1.2)),
                                        Text(userName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.headline, height: 1.2)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        // Search Icon triggers Tab Change
                                        GestureDetector(
                                          onTap: widget.onSearchTap,
                                          child: Container(
                                            width: 48, height: 48,
                                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                            child: const Icon(PhosphorIconsLight.magnifyingGlass, color: AppColors.headline, size: 24),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                                          child: Container(
                                            width: 48, height: 48,
                                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                            child: const Icon(PhosphorIconsLight.bell, color: AppColors.headline, size: 24),
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
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [AppColors.primary, Color(0xFF6FBFAC)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Text(
                                    "Dijital İçeriklerini\nKoleksiyona Kaydet",
                                    style: GoogleFonts.outfit(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.0,
                                      height: 1.1,
                                      color: Colors.white, 
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Özenle sakla, keyifle paylaş!",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.headline,
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
                              itemCount: categories.length + 1, 
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Center(child: _buildCategoryChip(ref, null, "Tümü", selCategory == null));
                                }
                                final cat = categories[index - 1];
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
                                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Tümünü Gör", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.headline)),
                                    const SizedBox(width: 4),
                                    const Icon(PhosphorIconsLight.caretRight, size: 14, color: AppColors.iconInactive),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8), 
                      ],
                    ),
                  ),

                  // Content Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: _buildSliverContent(items, categories, feedState.isLoading),
                  ),

                  // Bottom Loader
                  if (feedState.isLoading && items.isNotEmpty)
                     SliverToBoxAdapter(
                       child: Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Center(
                             child: CupertinoActivityIndicator(radius: 12),
                         ),
                       ),
                     ),

                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ),
            ),
          ],
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
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.iconInactive),
      ),
    );
  }

  Widget _buildCategoryChip(WidgetRef ref, CategoryModel? category, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () {
          ref.read(selectedCategoryIdProvider.notifier).state = category?.id;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [AppColors.primary.withOpacity(0.1), AppColors.surfaceWhite], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: isSelected
                ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
                : Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
            boxShadow: isSelected
                ? [BoxShadow(color: const Color(0xFF6B8C96).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]
                : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Text(
            label, 
            style: GoogleFonts.poppins(
              color: isSelected ? const Color(0xFF1A1E38) : const Color(0xFF4B5563),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverContent(List<ItemModel> items, List<CategoryModel> categories, bool isLoading) {
    if (items.isEmpty && !isLoading) {
       return SliverToBoxAdapter(
         child: Padding(
           padding: const EdgeInsets.only(top: 40),
           child: Center(child: Text("Henüz içerik yok", style: GoogleFonts.poppins(color: AppColors.hint))),
         ),
       );
    }
    
    if (items.isEmpty && isLoading) {
         return SliverToBoxAdapter(
         child: Padding(
           padding: const EdgeInsets.only(top: 100),
           child: Center(child: CupertinoActivityIndicator()),
         ),
       );
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
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
          ),
        );
      case ViewMode.masonry:
        return SliverMasonryGrid.count(
          // key: ValueKey(items.length), // Removed to prevent full rebuild flash
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childCount: items.length,
          itemBuilder: (context, index) => _buildContentCardRefactored(items[index], getBadge(items[index]), categories, isGrid: true),
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
    final hasImage = item.displayImage != null && item.displayImage!.isNotEmpty;
    final source = item.url ?? '';

    Widget buildImage() {
      if (hasImage) {
        // Use BoxFit.cover for Square mode, fitWidth (natural) for others
        final fit = forceSquare ? BoxFit.cover : BoxFit.fitWidth;
        
        return item.displayImage!.startsWith('http') 
          ? CachedNetworkImage(
              imageUrl: item.displayImage!,
              fit: fit, 
              alignment: Alignment.center,
              // Use an AspectRatio placeholder to prevent zero-height during load if possible, 
              // or just a fixed height container.
              placeholder: (context, url) => AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  color: Colors.grey[100],
                  child: Center(child: Icon(PhosphorIconsLight.image, size: 32, color: Colors.grey[300])),
                ),
              ),
              errorWidget: (context, url, error) => _buildFallbackView(source),
            )
          : Image.asset(
              item.displayImage!,
              fit: fit,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => _buildFallbackView(source),
            );
      } else {
        return _buildFallbackView(source);
      }
    }

    Widget cardContent;

    if (!hasImage) {
      // Empty content: Always Square, No Icon
      cardContent = AspectRatio(
        aspectRatio: 1.0,
        child: _buildFallbackView(source),
      );
    } else {
      // Has Image: Natural or Forced Square, With Icon
      cardContent = Stack(
        fit: forceSquare ? StackFit.expand : StackFit.loose,
        children: [
           buildImage(),
           Positioned(top: 8, right: 8, child: _buildPlatformIconWidget(source)),
        ],
      );

      // Only wrap in AspectRatio if we are FORCING square.
      // Otherwise, let the image define the size.
      if (forceSquare) {
         cardContent = AspectRatio(aspectRatio: 1.0, child: cardContent);
      }
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade100,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
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
                  cardContent,
                  Padding(
                    padding: const EdgeInsets.all(12), // Increased padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.displayTitle, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis, 
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800)
                        ),
                        Text(
                          badgeText, 
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.grey.shade500)
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
    );
  }

  Widget _buildFallbackView(String source) {
    IconData icon = PhosphorIconsLight.link;
    // Unified Green Gradient for all Empty State Icons
    List<Color> gradientColors = [AppColors.primary, const Color(0xFF6FBFAC)];

    if (source.contains('x.com') || source.contains('twitter')) {
      icon = PhosphorIconsBold.xLogo;
    } else if (source.contains('instagram')) {
      icon = PhosphorIconsBold.instagramLogo;
    } else if (source.contains('youtube')) {
      icon = PhosphorIconsBold.youtubeLogo;
    } else if (source.contains('pinterest')) {
      icon = PhosphorIconsBold.pinterestLogo;
    }

    return Container(
       color: Colors.white, // White background
       child: Center(
         child: ShaderMask(
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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white, // White background
      ),
      child: Center(child: Icon(icon, color: AppColors.primary, size: 14)), // Green Icon
    );
  }
}
