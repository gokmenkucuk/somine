import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add CachedNetworkImage
import 'package:firebase_auth/firebase_auth.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
// Remove ItemCard
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';

import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/widgets/item_detail_bottom_sheet.dart'; // Import Detail Sheet
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/services/preferences_service.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/services/vault_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final ItemRepository _itemRepository = ItemRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  
  List<ItemModel> _allItems = [];
  List<ItemModel> _filteredItems = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  StreamSubscription? _itemsSubscription; // Subscription for live updates

  String? _selectedPlatform;
  bool _isVaultSearch = false;


  final PreferencesService _prefsService = PreferencesService();

  // Computed property to check if search mode is active
  bool get _isSearching => _searchController.text.isNotEmpty || _selectedPlatform != null || _isVaultSearch;

  Widget _buildVaultFilterChip() {
    final isSelected = _isVaultSearch;
    return GestureDetector(
      onTap: () async {
        if (isSelected) {
          // Disable Vault Search
          setState(() {
            _isVaultSearch = false;
          });
          _performSearch();
        } else {
          // Enable Vault Search (Require Auth)
          final vaultService = VaultService();
          final result = await vaultService.authenticate(
            reason: 'Gizli arama yapmak için doğrulama yapın',
          );
          
          if (result == VaultAuthResult.success) {
             setState(() {
               _isVaultSearch = true;
               // Reset platform if needed? No, can search youtube in vault.
             });
             _performSearch();
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary : context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? context.colors.primary : context.colors.primary.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isSelected 
              ? [BoxShadow(color: context.colors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? PhosphorIconsBold.lockKeyOpen : PhosphorIconsBold.lockKey, 
              size: 16, 
              color: isSelected ? Colors.white : context.colors.primary
            ),
            const SizedBox(width: 6),
            Text(
              "Gizli",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : context.colors.headline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Son Aramalar
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _subscribeToItems(); // Use subscription instead of fetch
    _searchController.addListener(_performSearch);
    
    // Auto-focus disabled - was causing keyboard to open on cold start
    // due to IndexedStack rendering all screens at once
    // Future.delayed(const Duration(milliseconds: 400), () {
    //   if (mounted) {
    //     _searchFocusNode.requestFocus();
    //   }
    // });
  }

  void _subscribeToItems() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _isLoading = true);
      
      // 1. Fetch Categories once (or stream if needed, but usually static enough)
      _categoryRepository.getCategories(user.uid).then((categories) {
         if (mounted) setState(() => _categories = categories);
      });

      // 2. Stream Items
      _itemsSubscription = _itemRepository.streamItems(user.uid).listen((items) {
        if (mounted) {
          setState(() {
            _allItems = items;
            _isLoading = false;
          });
          _performSearch(); // Re-run search with new data
        }
      }, onError: (e) {
        debugPrint("Error streaming items: $e");
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }



  Future<void> _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final history = await _prefsService.getSearchHistoryFirebase(user.uid);
    if (mounted) {
      setState(() {
        _recentSearches = history;
      });
    }
  }

  Future<void> _addToHistory(String term) async {
    if (term.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await _prefsService.addSearchTermFirebase(user.uid, term.trim());
    _loadHistory();
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (!_isSearching) {
        _filteredItems = [];
        return;
      }

      // Identify Vault Categories
      final vaultIds = _categories.where((c) => c.isVault).map((c) => c.id).toSet();

      _filteredItems = _allItems.where((item) {
        
        // 1. Vault Filter Logic
        if (_isVaultSearch) {
          // Must be in a vault category
          if (!vaultIds.contains(item.categoryId)) return false;
        } else {
          // Must NOT be in a vault category
          if (vaultIds.contains(item.categoryId)) return false;
        }

        bool matchesQuery = true;
        bool matchesPlatform = true;

        // Text Search
        if (query.isNotEmpty) {
           final searchTerms = query.split(' ').where((s) => s.isNotEmpty).toList();
           final searchableText = '${item.displayTitle} ${item.note ?? ''} ${item.url ?? ''}'.toLowerCase();

           // Check if ALL terms are present in the searchable text
           matchesQuery = searchTerms.every((term) => searchableText.contains(term));
        }

        // Platform Filter
        if (_selectedPlatform != null) {
          final filter = _selectedPlatform!; // No lowercase needed, we match exact platform name from model
          
          if (filter == 'Web') {
            matchesPlatform = item.platform == 'Web';
          } else {
            matchesPlatform = item.platform == filter;
          }
        }
        
        return matchesQuery && matchesPlatform;
      }).toList();
    });
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel(); // Cancel subscription
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _removeSearchItem(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final term = _recentSearches[index];
    await _prefsService.removeSearchTermFirebase(user.uid, term);
    _loadHistory();
  }

  void _clearAllSearches() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await _prefsService.clearSearchHistoryFirebase(user.uid);
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: SafeArea(
          child: Stack(
            children: [
              // === LAYER 1: CONTENT (Filters + Results) ===
              Positioned.fill(
                top: 180, // Increased to prevent SearchBar overlap
                child: GestureDetector(
                  onTap: () {
                    // Unfocus when tapping background
                    _searchFocusNode.unfocus();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === PLATFORM FILTERS ===
                      FadeInDown(
                        delay: const Duration(milliseconds: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                "Kaynaklara Göz At",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.hint,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  _buildVaultFilterChip(),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("Instagram", PhosphorIconsBold.instagramLogo),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("YouTube", PhosphorIconsBold.youtubeLogo),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("X", PhosphorIconsBold.xLogo),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("TikTok", PhosphorIconsBold.tiktokLogo),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("Spotify", PhosphorIconsBold.spotifyLogo),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("LinkedIn", PhosphorIconsBold.linkedinLogo),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("Pinterest", PhosphorIconsBold.pinterestLogo),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("Reddit", PhosphorIconsBold.redditLogo),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("Medium", PhosphorIconsBold.mediumLogo),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("Behance", PhosphorIconsBold.behanceLogo),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("Dribbble", PhosphorIconsBold.dribbbleLogo),
                                  const SizedBox(width: 8),
                                  _buildPlatformFilterChip("Web", PhosphorIconsBold.globe),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // === RESULTS ===
                      // === RESULTS OR HISTORY ===
                      Expanded(
                        child: _isSearching
                            ? (_isLoading
                                ? const Center(child: CupertinoActivityIndicator())
                                : _filteredItems.isEmpty
                                    ? _buildNoResults()
                                    : _buildSearchResults())
                            : _buildRecentSearchesSection(), // Show History Inline
                      ),
                    ],
                  ),
                ),
              ),

              // === LAYER 2: HEADER + SEARCH BAR ===
              Positioned(
                top: 0, left: 0, right: 0,
                child: Column(
                  children: [
                     const SizedBox(height: 12),
                     // Header
                     Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: FadeInDown(
                          duration: const Duration(milliseconds: 400),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                      Text("Ara ", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w300, color: context.colors.headline, height: 1.2)),
                                      Text("ve Keşfet", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w600, color: context.colors.headline, height: 1.2)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text("Koleksiyonlarında arama yap...", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: context.colors.body)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: FadeInDown(
                          delay: const Duration(milliseconds: 150),
                          child: _buildSearchBar(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Extracted Search Bar for reusing
  Widget _buildSearchBar() {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(1.0), // Reduced Border Width further
      decoration: BoxDecoration(
        // Oil Green Gradient Border
        gradient: LinearGradient(
          colors: [context.colors.primary.withOpacity(0.7), context.colors.secondary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E8E91).withOpacity(0.25), // Increased opacity for glow
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(28), // Inner Radius
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: GoogleFonts.poppins(color: context.colors.headline, fontSize: 15, fontWeight: FontWeight.w500),
              cursorColor: const Color(0xFF6E8E91), // Match cursor to theme
              decoration: InputDecoration(
                hintText: "Aramak için bir şeyler yaz...",
                hintStyle: GoogleFonts.poppins(color: context.colors.hint, fontSize: 15, fontWeight: FontWeight.w400),
                prefixIcon: Padding(padding: const EdgeInsets.only(left: 20, right: 14), child: Icon(CupertinoIcons.search, color: context.colors.iconActive, size: 22)),
                prefixIconConstraints: const BoxConstraints(minWidth: 56),
                suffixIcon: _searchController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _searchController.clear()),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // Adjusted padding
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: (value) => _addToHistory(value),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearchesSection() {
    if (_recentSearches.isEmpty) return _buildEmptyState();

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: FadeInDown(
                delay: const Duration(milliseconds: 250),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.clock, size: 16, color: const Color(0xFF9CA3AF)),
                        const SizedBox(width: 8),
                        Text("Son Aramalar", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                      ],
                    ),
                    GestureDetector(
                      onTap: _clearAllSearches,
                      child: Text("Temizle", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: context.colors.primary)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: context.colors.hint.withOpacity(0.2)),
            Flexible(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _recentSearches.length,
                separatorBuilder: (c, i) => Divider(height: 1, color: context.colors.hint.withOpacity(0.2)),
                itemBuilder: (context, index) {
                  return FadeInUp(
                    delay: Duration(milliseconds: 300 + (index * 60)),
                    child: _buildSearchHistoryItem(_recentSearches[index], index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Son Arama Kartı
  Widget _buildSearchHistoryItem(String query, int index) {
    return ListTile(
      onTap: () {
        _searchController.text = query;
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(Icons.history, color: context.colors.body, size: 20), 
      title: Text(
        query,
        style: GoogleFonts.poppins(
          color: context.colors.headline, 
           fontSize: 14,
           fontWeight: FontWeight.w400,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.close, size: 18, color: context.colors.hint),
        onPressed: () => _removeSearchItem(index),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildPlatformFilterChip(String label, IconData icon) {
    final isSelected = _selectedPlatform == label;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedPlatform == label) {
            _selectedPlatform = null; // Toggle off
          } else {
            _selectedPlatform = label;
          }
          _performSearch(); // Trigger search on filter change
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          // Oil Green Gradient for Selected
          gradient: isSelected
              ? LinearGradient(
                  colors: [context.colors.primary, context.colors.secondary], // Oil Green
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(30),
          // Border only for unselected
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1.0),
          // Shadow: Green glow for selected, NONE for unselected (to fix "cut-off" look)
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6FBFAC).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6)
                  )
                ]
              : null, // Completely flat for unselected
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              // White icon when selected
              color: isSelected ? Colors.white : context.colors.hint, 
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                // White text when selected
                color: isSelected ? Colors.white : context.colors.hint,
                // Lighter font weight as requested
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Search Results Grid (Masonry) ---
  Widget _buildSearchResults() {
    // Check if we have any results
    if (_filteredItems.isEmpty) return _buildNoResults();
    
    return MasonryGridView.count(
       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
       physics: const BouncingScrollPhysics(),
       crossAxisCount: 2,
       mainAxisSpacing: 12,
       crossAxisSpacing: 12,
       itemCount: _filteredItems.length,
       itemBuilder: (context, index) {
          final item = _filteredItems[index];
          final cat = _categories.where((c) => c.id == item.categoryId).firstOrNull;
          return FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: Duration(milliseconds: index * 50),
            child: _buildResultCard(item, cat?.name ?? 'Genel'),
          );
       },
     );
  }

  // --- Home Screen Style Card Logic ---
  Widget _buildResultCard(ItemModel item, String badgeText) {
    // Masonry Aspect Ratio Logic from HomeScreen
    final aspectRatio = (item.id.codeUnitAt(0) % 3 == 0) ? 0.75 : (item.id.codeUnitAt(0) % 3 == 1) ? 1.0 : 1.2;
    final hasImage = item.displayImage != null && item.displayImage!.isNotEmpty && !item.displayImage!.toLowerCase().contains('.svg');
    final source = item.url ?? '';

    Widget buildImage() {
      if (hasImage) {
        return item.displayImage!.startsWith('http') 
          ? CachedNetworkImage(
              imageUrl: item.displayImage!,
              fit: BoxFit.cover, 
              alignment: Alignment.center,
              placeholder: (context, url) => Container(
                color: context.colors.surfaceWhite,
                child: Center(child: Icon(PhosphorIconsLight.image, size: 32, color: context.colors.hint)),
              ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.colors.surfaceWhite,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ItemDetailBottomSheet.show(context, item, badgeText, _categories);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!hasImage)
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: _buildFallbackView(source),
                  )
                else
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackView(String source) {
    IconData icon = PhosphorIconsLight.link;
    // Unified Green Gradient for all Empty State Icons
    List<Color> gradientColors = [context.colors.primary, context.colors.secondary];

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
       color: context.colors.surfaceWhite, // Theme-aware background
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.surfaceWhite, 
      ),
      child: Center(child: Icon(icon, color: context.colors.primary, size: 14)), // Green Icon
    );
  }

  Widget _buildNoResults() {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
            Icon(PhosphorIconsBold.magnifyingGlass, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Sonuç bulunamadı", 
              style: GoogleFonts.poppins(
                fontSize: 16, 
                fontWeight: FontWeight.w500, 
                color: Colors.grey.shade600
              )
            ),
            const SizedBox(height: 8),
            Text(
              "Farklı bir arama yapmayı dene", 
              style: GoogleFonts.poppins(
                fontSize: 13, 
                fontWeight: FontWeight.w400, 
                color: Colors.grey.shade400
              )
            ),
         ],
       ),
     );
  }

  // Boş State
  Widget _buildEmptyState() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: SingleChildScrollView(
         physics: const BouncingScrollPhysics(),
         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             // Header Text
             Text(
               "Koleksiyonlarını Keşfet",
               textAlign: TextAlign.center,
               style: GoogleFonts.poppins(
                 fontSize: 16,
                 fontWeight: FontWeight.w600,
                 color: Colors.grey.shade400,
                 letterSpacing: 0.5,
               ),
             ),
             const SizedBox(height: 24),
    
             // Info Card 1: Platform Filters
             _buildInfoCard(
               title: "Kaynaklara Göre Süz",
               description: "Instagram, YouTube veya Web... İlgilendiğin kaynağın ikonuna dokunarak sadece oradan gelen içerikleri gör.",
               icon: PhosphorIconsDuotone.funnel,
               accentColor: const Color(0xFF0EA5E9), // Light Blue
             ),
             
             const SizedBox(height: 16),
    
             // Info Card 2: Search
             _buildInfoCard(
               title: "Detaylı Arama",
               description: "Başlık, not veya link... Aklına gelen herhangi bir anahtar kelimeyi yaz, saniyeler içinde bul.",
               icon: PhosphorIconsDuotone.magnifyingGlass,
               accentColor: const Color(0xFF10B981), // Emerald Green
             ),
             
             const SizedBox(height: 48), // Bottom padding
           ],
         ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
             width: 48, 
             height: 48,
             decoration: BoxDecoration(
               color: accentColor.withOpacity(0.1),
               shape: BoxShape.circle,
             ),
             child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                   title,
                   style: GoogleFonts.poppins(
                     fontSize: 15,
                     fontWeight: FontWeight.w600,
                     color: context.colors.headline,
                   ),
                 ),
                 const SizedBox(height: 6),
                 Text(
                   description,
                   style: GoogleFonts.poppins(
                     fontSize: 13,
                     fontWeight: FontWeight.w400,
                     color: context.colors.body,
                     height: 1.5,
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
