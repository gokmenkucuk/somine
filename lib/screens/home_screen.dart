import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:animate_do/animate_do.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:somine_app/screens/profile_screen.dart';
import 'package:somine_app/screens/notifications_screen.dart';
import 'package:somine_app/screens/add_content_screen.dart';
import 'package:somine_app/screens/search_screen.dart';
import 'package:somine_app/core/design/app_colors.dart';

// Providers & Models
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/utils/demo_seeder.dart'; // Import Seeder
import 'package:somine_app/widgets/item_detail_bottom_sheet.dart';

enum ViewMode { square, masonry, feed }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // State for Grid/List Toggle
  ViewMode _viewMode = ViewMode.square; 
  // No local _selectedCategory string, we use provider state

  // Sharing Intent Subscriptions
  late StreamSubscription _intentDataStreamSubscription;
  
  // Pagination Controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupSharingIntent();
    
    // Pagination Listener
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
    _intentDataStreamSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Setup Share Intent Listener
  void _setupSharingIntent() {
     _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
            if (value.isNotEmpty && value.first.path.isNotEmpty) {
              if (mounted) _openAddContentScreen(initialText: value.first.path);
            }
          }, onError: (err) => debugPrint("getMediaStream error: $err"));

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.path.isNotEmpty) {
        if (mounted) _openAddContentScreen(initialText: value.first.path);
      }
    });
  }

  void _openAddContentScreen({String? initialText}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) => AddContentScreen(initialText: initialText),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch Data Providers
    final userAsync = ref.watch(currentUserModelProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selCategory = ref.watch(selectedCategoryIdProvider);
    
    // Watch Pagination Provider
    final feedState = ref.watch(paginatedFeedProvider);

    // Derived State
    final userName = userAsync.value?.displayName?.split(' ').first ?? 'Misafir';
    final categories = categoriesAsync.value ?? [];
    
    // Items come from Pagination State
    final items = feedState.items;

    // --- FORCE RESEED (Temporary - Remove after first successful run) ---
    ref.listen<AsyncValue<int>>(itemCountProvider, (previous, next) {
        // FORCE RESEED: Always reseed to load new content list
        if (next.hasValue) {
           DemoSeeder.seed(ref).then((_) {
              ref.refresh(paginatedFeedProvider); 
              ref.refresh(categoriesProvider);
           });
        }
    });
    
    // Auto-reseed logic removed to prevent infinite loops.
    // If data is missing (count == 0), the first listener (lines 119-127) handles it.

    return Scaffold(
      backgroundColor: Colors.transparent, 
      extendBody: true,
      
      // Fab Implementation
      floatingActionButton: Container(
        width: 64, 
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentDark,
          boxShadow: [
             BoxShadow(
              color: AppColors.accentDark.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openAddContentScreen(),
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withOpacity(0.3),
            child: const Icon(PhosphorIconsLight.plus, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: AppColors.surfaceWhite,
        elevation: 0,
        height: 50,
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {}, 
              icon: const Icon(PhosphorIconsLight.house, color: AppColors.iconActive, size: 26),
            ),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
              icon: const Icon(PhosphorIconsLight.magnifyingGlass, color: AppColors.iconInactive, size: 26),
            ),
            const SizedBox(width: 48), // Spacer for FAB
            IconButton(
              onPressed: () {},
              icon: const Icon(PhosphorIconsLight.squaresFour, color: AppColors.iconInactive, size: 26),
            ),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
              icon: const Icon(PhosphorIconsLight.user, color: AppColors.iconInactive, size: 26),
            ),
          ],
        ),
      ),

      body: Container(
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
                controller: _scrollController, // Attach controller for pagination
                slivers: [
                  // Header Block
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: User & Actions
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          child: FadeInDown(
                            duration: const Duration(milliseconds: 600),
                            child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Left: Greeting
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("Merhaba,", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.hint, height: 1.2)),
                                        Text(userName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.headline, height: 1.2)),
                                      ],
                                    ),

                                    // Right: Actions (Search, Notif)
                                    Row(
                                      children: [
                                        // Search
                                        GestureDetector(
                                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
                                          child: Container(
                                            width: 48, height: 48,
                                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                            child: const Icon(PhosphorIconsLight.magnifyingGlass, color: AppColors.headline, size: 24),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Notifications
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
                                Text(
                                  "Hep seninle kalsın.",
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.0,
                                      height: 1.2,
                                    ),
                                    children: [
                                      const TextSpan(text: "Sevdiğin içerikleri ", style: TextStyle(color: Colors.black)),
                                      TextSpan(text: "kaybetme.", style: TextStyle(color: const Color(0xFFB7BFD2))),
                                    ],
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
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text("Tümünü Gör", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.headline)),
                                      const SizedBox(width: 4),
                                      const Icon(PhosphorIconsLight.caretRight, size: 14, color: AppColors.iconInactive),
                                    ],
                                  ),
                                ),
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

                  // Bottom Loader for Pagination
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
      ),
    );
  }

  // --- Widgets ---

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
          // Update Provider - The Notifier watches this and reloads automatically if we implemented watchers correctly.
          // In my previous step, I injected 'catId' from ref.watch into the provider via overrides, 
          // but since I used a simple constructor in StateNotifierProvider.autoDispose that only READS once, 
          // I need to ensure it rebuilds.
          // 'PaginatedItemsNotifier' in my defined provider uses:
          // final catId = ref.watch(selectedCategoryIdProvider);
          // return PaginatedItemsNotifier(...)
          // So changing 'selectedCategoryIdProvider' WILL trigger a rebuild of the notifier (resetting state).
          // This creates "Pagination Reset on Filter" automatically! Perfect.
          
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
            label, // Use label passed (can be "Tümü" or category name)
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
    if (items.isEmpty && !isLoading) { // Empty state only if NOT loading
       return SliverToBoxAdapter(
         child: Padding(
           padding: const EdgeInsets.only(top: 40),
           child: Center(child: Text("Henüz içerik yok", style: GoogleFonts.poppins(color: AppColors.hint))),
         ),
       );
    }
    
    // If loading initial state (completely empty), show skeleton or spinner
    if (items.isEmpty && isLoading) {
         return SliverToBoxAdapter(
         child: Padding(
           padding: const EdgeInsets.only(top: 100),
           child: Center(child: CupertinoActivityIndicator()),
         ),
       );
    }

    // Helper to find category name for item
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
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.0,
          ),
        );
      case ViewMode.masonry:
        return SliverMasonryGrid.count(
          key: ValueKey(items.length),
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childCount: items.length,
          itemBuilder: (context, index) => _buildContentCardRefactored(items[index], getBadge(items[index]), categories, isGrid: true),
        );
      case ViewMode.feed:
        return SliverList(
          key: ValueKey(items.length),
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

  // --- REFACTORED CARD WITH REAL DATA & FALLBACK LOGIC ---

  Widget _buildContentCard(ItemModel item, String badgeText, {required bool isGrid, bool forceSquare = false}) {
    // Aspect Ratio Logic
    double aspectRatio = 1.0;
    // Basic approximate aspect ratio from image service or random for demo?
    // Since we don't store aspect ratio in ItemModel yet, we default to 1.0 or random for masonry variation
    // Real implementation should store AR. For now, random variation for Masonry if not square.
    if (!forceSquare && isGrid) {
       // Deterministic "random" based on ID char code. Taller ratio for better fit.
       aspectRatio = (item.id.codeUnitAt(0) % 2 == 0) ? 0.65 : 1.0; 
    }

    final hasImage = item.displayImage != null && item.displayImage!.isNotEmpty;
    final source = item.url ?? '';

    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                      if (item.url != null && await canLaunchUrl(Uri.parse(item.url!))) {
                        await launchUrl(Uri.parse(item.url!));
                      }
                  },
                  child: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: Image or FALLBACK
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: item.displayImage!,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter, // Align top to avoid cutting heads
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                      errorWidget: (context, url, error) => _buildFallbackView(source),
                    )
                  else
                    _buildFallbackView(source),

                  // Layer 1.5: Gradient Overlay (Branded Bottom Fade)
                  // "Bizim renklerimizden silikleşen" -> Primary Color Gradient
                  if (hasImage)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            AppColors.primary.withOpacity(0.9), // Strong at bottom
                            AppColors.primary.withOpacity(0.5), 
                            Colors.transparent // Fade to transparent
                          ],
                          stops: const [0.0, 0.3, 1.0], 
                        ),
                      ),
                    ),

                  // Layer 2: Center Icon
                  if (hasImage) ...[
                     if (item.type == ItemType.link && source.contains('youtu')) 
                       _buildCenterIcon(PhosphorIconsLight.playCircle)
                     else if (item.type == ItemType.link && source.contains('instagram'))
                       _buildCenterIcon(PhosphorIconsLight.instagramLogo) 
                  ],

                  // Layer 3: Header
                  Positioned(
                    top: 12, left: 12, right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badge
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5)),
                              child: Text(badgeText, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF1A1E38))),
                            ),
                          ),
                        ),
                        // Small source icon (Top Right)
                         _buildPlatformIconWidget(source),
                      ],
                    ),
                  ),

                  // Layer 4: Title
                  Positioned(
                    bottom: 16, left: 12, right: 12,
                    child: Text(
                      item.displayTitle,
                      maxLines: 2, // Allow 2 lines for better readability
                      overflow: TextOverflow.ellipsis,
                      // White text on dark gradient for readability
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, height: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ), // Material
      ),
    ));
  }

  Widget _buildContentCardRefactored(ItemModel item, String badgeText, List<CategoryModel> categories, {required bool isGrid, bool forceSquare = false}) {
    final hasImage = item.displayImage != null && item.displayImage!.isNotEmpty;
    final source = item.url ?? '';

    // Image widget builder
    Widget buildImage() {
      if (hasImage) {
        return item.displayImage!.startsWith('http') 
          ? CachedNetworkImage(
              imageUrl: item.displayImage!,
              fit: BoxFit.cover, 
              alignment: Alignment.center,
              placeholder: (context, url) => Container(color: Colors.grey[100]),
              errorWidget: (context, url, error) => _buildFallbackView(source),
            )
          : Image.asset(
              item.displayImage!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => _buildFallbackView(source),
            );
      } else {
        return _buildFallbackView(source);
      }
    }

    // ========== FEED LAYOUT ==========
    if (!isGrid) {
      return FadeIn(
        duration: const Duration(milliseconds: 500),
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
                  if (item.url != null && await canLaunchUrl(Uri.parse(item.url!))) {
                    await launchUrl(Uri.parse(item.url!));
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image with platform icon (same style as other views)
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16/10,
                          child: buildImage(),
                        ),
                        Positioned(
                          top: 10, right: 10,
                          child: _buildPlatformIconWidget(source),
                        ),
                      ],
                    ),
                    // Info section (same style as other views)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                                ),
                                Text(
                                  badgeText,
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ItemDetailBottomSheet.show(context, item, badgeText, categories),
                            child: Icon(PhosphorIconsLight.dotsThreeCircle, size: 24, color: Colors.grey.shade600),
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

    // ========== SQUARE GRID LAYOUT ==========
    if (forceSquare) {
      return FadeIn(
        duration: const Duration(milliseconds: 500),
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
                  if (item.url != null && await canLaunchUrl(Uri.parse(item.url!))) {
                    await launchUrl(Uri.parse(item.url!));
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          buildImage(),
                          Positioned(top: 8, right: 8, child: _buildPlatformIconWidget(source)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                                Text(badgeText, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ItemDetailBottomSheet.show(context, item, badgeText, categories),
                            child: Icon(PhosphorIconsLight.dotsThreeCircle, size: 20, color: Colors.grey.shade600),
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

    // ========== MASONRY LAYOUT ==========
    // Varying aspect ratios for true masonry effect
    final aspectRatio = (item.id.codeUnitAt(0) % 3 == 0) ? 0.75 : (item.id.codeUnitAt(0) % 3 == 1) ? 1.0 : 1.2;
    
    return FadeIn(
      duration: const Duration(milliseconds: 500),
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
                if (item.url != null && await canLaunchUrl(Uri.parse(item.url!))) {
                  await launchUrl(Uri.parse(item.url!));
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        buildImage(),
                        Positioned(top: 8, right: 8, child: _buildPlatformIconWidget(source)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                              Text(badgeText, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ItemDetailBottomSheet.show(context, item, badgeText, categories),
                          child: Icon(PhosphorIconsLight.dotsThreeCircle, size: 20, color: Colors.grey.shade600),
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

  // Simple platform icon (no container)
  Widget _buildPlatformIcon(String source, {double size = 16}) {
    IconData icon = PhosphorIconsLight.link;
    Color color = Colors.grey;
    
    if (source.contains('instagram')) {
      icon = PhosphorIconsBold.instagramLogo;
      color = const Color(0xFFE4405F);
    } else if (source.contains('youtube')) {
      icon = PhosphorIconsBold.youtubeLogo;
      color = const Color(0xFFFF0000);
    } else if (source.contains('x.com') || source.contains('twitter')) {
      icon = PhosphorIconsBold.xLogo;
      color = Colors.black;
    } else if (source.contains('pinterest')) {
      icon = PhosphorIconsBold.pinterestLogo;
      color = const Color(0xFFBD081C);
    }
    
    return Icon(icon, size: size, color: color);
  }

  // --- Helpers ---

  // Clean Card Design for X (Twitter) and Instagram profiles
  // White background with gradient-colored LOGO only
  Widget _buildFallbackView(String source) {
    IconData icon = PhosphorIconsLight.link;
    List<Color> gradientColors = [Colors.grey, Colors.grey.shade600];
    
    if (source.contains('x.com') || source.contains('twitter')) {
      icon = PhosphorIconsBold.xLogo;
      gradientColors = [Colors.grey.shade800, Colors.black];
    } else if (source.contains('instagram')) {
      icon = PhosphorIconsBold.instagramLogo;
      gradientColors = [
        const Color(0xFFFEDA77),
        const Color(0xFFF58529),
        const Color(0xFFDD2A7B),
        const Color(0xFF8134AF),
      ];
    } else if (source.contains('youtube')) {
      icon = PhosphorIconsBold.youtubeLogo;
      gradientColors = [const Color(0xFFFF0000), const Color(0xFFCC0000)];
    } else if (source.contains('pinterest')) {
      icon = PhosphorIconsBold.pinterestLogo;
      gradientColors = [const Color(0xFFBD081C), const Color(0xFF8C0615)];
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
           child: Icon(icon, size: 56, color: Colors.white),
         ),
       ),
    );
  }

  Widget _buildCenterIcon(IconData icon) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 32),
      ),
    );
  }

  Widget _buildPlatformIconWidget(String source) {
    final s = source.toLowerCase();
    Gradient gradient;
    IconData icon;

    if (s.contains('instagram')) {
      gradient = const LinearGradient(colors: [Color(0xFFFEDA75), Color(0xFFD62976), Color(0xFF962FBF)], begin: Alignment.bottomLeft, end: Alignment.topRight);
      icon = PhosphorIconsLight.instagramLogo;
    } else if (s.contains('youtube')) {
      gradient = const LinearGradient(colors: [Color(0xFFFF0000), Color(0xFFCC0000)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      icon = PhosphorIconsLight.youtubeLogo;
    } else if (s.contains('twitter') || s.contains('x.com')) {
      gradient = const LinearGradient(colors: [Colors.black, Color(0xFF333333)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      icon = PhosphorIconsLight.xLogo;
    } else if (s.contains('pinterest')) {
      gradient = const LinearGradient(colors: [Color(0xFFBD081C), Color(0xFF8C0615)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      icon = PhosphorIconsLight.pinterestLogo;
    } else {
      gradient = LinearGradient(colors: [Colors.grey[400]!, Colors.grey[600]!]);
      icon = PhosphorIconsLight.link;
    }

    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient.scale(0.8)), // translucent
      child: Center(child: Icon(icon, color: Colors.white, size: 14)),
    );
  }
}
