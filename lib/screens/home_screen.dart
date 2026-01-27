import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/providers/theme_provider.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/widgets/vibe_background.dart';
import 'package:somine_app/screens/item_feed_screen.dart';
import 'package:somine_app/screens/search_screen.dart';
import 'package:somine_app/screens/profile_screen.dart';
import 'package:somine_app/core/providers/navigation_providers.dart'; // Added
import 'package:somine_app/screens/catalog_screen.dart';
import 'package:somine_app/screens/add_content_screen.dart';
import 'package:somine_app/core/services/share_service.dart';
import 'package:somine_app/widgets/success_notification_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  // Removed duplicate share intent listener - ShareService handles this centrally

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register observer
    
    // Listen for share intents (Moved from main.dart for safe loading)
    ShareService().sharedUrlNotifier.addListener(_handleSharedUrl);
    
    // Check initial value (Cold start) - Fetch manually from native
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkShareData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Unregister observer
    ShareService().sharedUrlNotifier.removeListener(_handleSharedUrl);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - check for new share data
      _checkShareData();
    }
  }

  void _checkShareData() {
     // First check native storage, populate notifier, then handle
     ShareService().checkInitialShare().then((_) {
         if (mounted) _handleSharedUrl();
     });
  }

  void _handleSharedUrl() {
    final url = ShareService().sharedUrlNotifier.value;
    if (url != null && mounted) {
      // Clear immediately to prevent re-processing
      ShareService().sharedUrlNotifier.value = null;
      
      _openAddContentScreen(initialText: url);
    }
  }

  void _onItemTapped(int index) {
    ref.read(homeTabIndexProvider.notifier).state = index;
  }

  void _openAddContentScreen({String? initialText}) async {
    // Get selected catalog category if on Catalog tab (index 2)
    final selectedIndex = ref.read(homeTabIndexProvider);
    String? preSelectedCategoryId;
    if (selectedIndex == 2) {
      preSelectedCategoryId = ref.read(selectedCatalogIdProvider);
      // Don't pre-select special values like 'uncategorized' or null (Tümü)
      if (preSelectedCategoryId == 'uncategorized') {
        preSelectedCategoryId = null;
      }
    }
    
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      useSafeArea: false, 
      backgroundColor: Colors.transparent, 
      barrierColor: Colors.black.withOpacity(0.5),
      enableDrag: true,
      builder: (context) => AddContentScreen(
        initialText: initialText,
        preSelectedCategoryId: preSelectedCategoryId,
      ),
    );

    if (result == true) {
      // Refresh feed content
      ref.invalidate(paginatedFeedProvider); 
      ref.invalidate(itemCountProvider);
      
      if (mounted) {
         SuccessNotificationSheet.show(
            context,
            title: "Başarılı!",
            message: "İçerik koleksiyona eklendi"
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(homeTabIndexProvider);

    // Determine active color for tabs
    Color getIconColor(int index) {
      return selectedIndex == index ? context.colors.primary : context.colors.iconInactive; 
    }

    // Check if Vibe theme is active
    final isVibeTheme = ref.watch(themeProvider) == AppThemeEnum.vibe;

    return Scaffold(
      backgroundColor: isVibeTheme ? const Color(0xFF0A0A12) : context.colors.backgroundBottom,
      extendBody: true, // Important for floating dock style

      // FAB for Adding Content
      floatingActionButton: Container(
        width: 64, 
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [context.colors.primary, context.colors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: context.colors.surfaceWhite.withOpacity(0.2), // Subtle midnight-like border
            width: 1.5,
          ),
          boxShadow: [
             BoxShadow(
              color: context.colors.primary.withOpacity(0.3),
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

      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: context.colors.surfaceWhite, 
        elevation: 0,
        height: 60, // Slight height increase for touch target
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Feed
            IconButton(
              alignment: Alignment.topCenter,
              onPressed: () => _onItemTapped(0), 
              icon: Icon(
                selectedIndex == 0 ? PhosphorIconsFill.house : PhosphorIconsLight.house, 
                color: getIconColor(0), 
                size: 26
              ),
            ),
            
            // Search
            IconButton(
              alignment: Alignment.topCenter,
              onPressed: () => _onItemTapped(1),
              icon: Icon(
                 selectedIndex == 1 ? PhosphorIconsFill.magnifyingGlass : PhosphorIconsLight.magnifyingGlass,
                 color: getIconColor(1), 
                 size: 26
              ),
            ),
            
            const SizedBox(width: 48), // Spacer for FAB

            // Catalog (Squares)
            IconButton(
              alignment: Alignment.topCenter,
              onPressed: () => _onItemTapped(2),
              icon: Icon(
                selectedIndex == 2 ? PhosphorIconsFill.squaresFour : PhosphorIconsLight.squaresFour,
                color: getIconColor(2), 
                size: 26
              ),
            ),

            // Profile
            IconButton(
              alignment: Alignment.topCenter,
              onPressed: () => _onItemTapped(3),
              icon: Icon(
                selectedIndex == 3 ? PhosphorIconsFill.user : PhosphorIconsLight.user,
                color: getIconColor(3), 
                size: 26
              ),
            ),
          ],
        ),
      ),

      // Main Content Switching
      body: _buildBody(isVibeTheme, selectedIndex),
    );
  }

  Widget _buildBody(bool isVibeTheme, int selectedIndex) {
    final content = IndexedStack(
      index: selectedIndex,
      children: [
        // 0: Feed
        ItemFeedScreen(
          onSearchTap: () => _onItemTapped(1), // Switch to Search Tab
          onCatalogTap: () => _onItemTapped(2), // Switch to Catalog Tab
        ),
        
        // 1: Search
        const SearchScreen(),

        // 2: Catalog
        const CatalogScreen(),

        // 3: Profile
        const ProfileScreen(),
      ],
    );

    // Wrap with VibeBackground for Vibe theme
    if (isVibeTheme) {
      return VibeBackground(child: content);
    }
    return content;
  }
}
