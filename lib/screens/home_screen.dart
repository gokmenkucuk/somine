import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
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
import 'package:somine_app/core/models/item_model.dart';
import 'package:google_fonts/google_fonts.dart'; // For snackbar text

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
    final currentIndex = ref.read(homeTabIndexProvider);
    if (currentIndex == index) {
      if (index == 0) {
        ref.read(homeReselectTriggerProvider.notifier).state++;
      }
      return;
    }

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

      // FAB for Adding Content OR Trash Zone
      floatingActionButton: _buildFabOrTrashZone(context, ref),
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

  Widget _buildFabOrTrashZone(BuildContext context, WidgetRef ref) {
     final isDragging = ref.watch(isDraggingProvider);

     if (!isDragging) {
       // NORMAL FAB
       return Container(
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
      );
     }

     // TRASH ZONE FAB
     return DragTarget<ItemModel>(
        onWillAcceptWithDetails: (item) {
          // Provide feedback when dragging enters zone
          HapticFeedback.lightImpact(); 
          return true;
        },
        onAcceptWithDetails: (details) async {
           HapticFeedback.mediumImpact();

           // Reset drag state
           ref.read(isDraggingProvider.notifier).state = false;

           final repo = ref.read(itemRepositoryProvider);
           final selectedItems = ref.read(selectedItemsProvider);
           final isSelectionMode = ref.read(isSelectionModeProvider);
           final isBatchDelete = isSelectionMode && selectedItems.contains(details.data.id);

           if (isBatchDelete) {
              // BATCH DELETE
              final itemsToDelete = selectedItems.toList();
              // Show Undo for Batch
              if (mounted) {
                SuccessNotificationSheet.show(
                  context,
                  title: "Silindi",
                  message: "${itemsToDelete.length} içerik silindi",
                  onUndo: () async {
                     // Restore all (createItems logic needed or restore logic)
                     // Since softDelete is used, we can restore by ID if we had them or just re-create.
                     // IMPORTANT: softDeleteItems actually moves to trash (deletedAt != null).
                     // So we can restore them using restoreItem(id).
                     for (final id in itemsToDelete) {
                        await repo.restoreItem(id);
                     }
                     ref.invalidate(paginatedFeedProvider);
                     ref.invalidate(itemCountProvider);
                  },
                );
              }
              
              await repo.softDeleteItems(itemsToDelete);
              
              // Clear selection
              ref.read(isSelectionModeProvider.notifier).state = false;
              ref.read(selectedItemsProvider.notifier).state = {};

           } else {
              // SINGLE DELETE
              if (mounted) {
                SuccessNotificationSheet.show(
                  context,
                  title: "Silindi",
                  message: "${details.data.displayTitle.isEmpty ? 'İçerik' : details.data.displayTitle} silindi",
                  onUndo: () async {
                     await repo.createItem(details.data.copyWith(id: ''));
                     ref.invalidate(paginatedFeedProvider);
                     ref.invalidate(itemCountProvider);
                  },
                );
              }
              // Note: Using softDelete for single item too for consistency?
              // Existing code used deleteItem (Permanent?).
              // User said "Trash Zone", usually implies Soft Delete.
              // Let's use deleteItem logic as before to be safe, OR switch to softDelete?
              // Existing code: await repo.deleteItem(item.id);
              // I will stick to existing logic for single item to minimize risk,
              // BUT createItem(item.copyWith(id:'')) implies permanent delete was used before (re-creating).
              // If I use softDelete, Undo just needs restoreItem.
              // Let's keep single delete as it was (deleteItem) unless I'm sure.
              // Actually, RecenlyDeletedScreen exists, so `deleteItem` likely performs Soft Delete in this repo?
              // Let's check ItemRepository for deleteItem vs softDeleteItems.
              // Actually, to be safe, I'll keep the single delete logic identical to previous (deleteItem).

              await repo.deleteItem(details.data.id);
           }
           
           ref.invalidate(paginatedFeedProvider);
           ref.invalidate(itemCountProvider);
        },
        builder: (context, candidateData, rejectedData) {
           final isHovering = candidateData.isNotEmpty;
           
           return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              width: 64, 
              height: 64,
              // Restore Container Scaling (Vacuum Effect)
              transform: isHovering 
                  ? (Matrix4.identity()..scale(0.75)) // Shrink Container
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Theme-aware gradient
                gradient: LinearGradient(
                  colors: [
                    context.colors.secondary.withOpacity(0.3), // Light secondary
                    context.colors.surfaceWhite,                // Surface white
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                   BoxShadow(
                    color: context.colors.primary.withOpacity(0.3), 
                    blurRadius: isHovering ? 2 : 15, // Shadow decreases on shrink
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: context.colors.surfaceWhite, 
                  width: 2
                ),
              ),
              child: Center(
                child: AnimatedScale( 
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  scale: isHovering ? 0.8 : 1.0, // Icon ALSO shrinks a bit more
                  child: Icon(
                    PhosphorIconsLight.trash, 
                    color: isHovering ? context.colors.headline : context.colors.primary, 
                    size: 30, 
                  ),
                ),
              ),
           );
        },
     );
  }
}
