import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/providers/theme_provider.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/providers/vault_provider.dart';
import 'package:somine_app/widgets/vibe_background.dart';
import 'package:somine_app/screens/item_feed_screen.dart';
import 'package:somine_app/screens/search_screen.dart';
import 'package:somine_app/screens/profile_screen.dart';
import 'package:somine_app/core/providers/navigation_providers.dart'; // Added
import 'package:somine_app/screens/catalog_screen.dart';
import 'package:somine_app/screens/add_content_screen.dart';
import 'package:somine_app/core/services/share_service.dart';
import 'package:somine_app/widgets/success_notification_sheet.dart';
import 'package:somine_app/widgets/brand_gradient.dart';
import 'package:somine_app/widgets/item_delete_flow.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  // Removed duplicate share intent listener - ShareService handles this centrally
  bool _isTrashActionInProgress = false;
  bool _isOpeningModal = false;

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
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background or became inactive - lock vault
      ref.read(vaultProvider.notifier).onAppPaused();
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

    ref.read(initializedHomeTabsProvider.notifier).state = {
      ...ref.read(initializedHomeTabsProvider),
      index,
    };
    ref.read(homeTabIndexProvider.notifier).state = index;
  }

  void _openAddContentScreen({String? initialText}) async {
    if (_isOpeningModal) return;
    if (mounted) setState(() => _isOpeningModal = true);

    try {
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
        barrierColor: Colors.black.withValues(alpha: 0.5),
        // Aşağı kaydırarak kapatma AddContentScreen içinde (DraggableScrollableSheet
        // min boyuta inince maybePop) yönetilir; böylece kaydedilmemiş
        // değişiklik onayı (PopScope) atlanmaz.
        enableDrag: false,
        builder:
            (context) => AddContentScreen(
              initialText: initialText,
              preSelectedCategoryId: preSelectedCategoryId,
            ),
      );

      if (mounted) setState(() => _isOpeningModal = false);

      if (result is AddContentResult) {
        // Refresh feed content
        ref.invalidate(paginatedFeedProvider);
        ref.invalidate(itemCountProvider);

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          SuccessNotificationSheet.show(
            context,
            title: l10n.commonSuccessBang,
            message: l10n.homeAddSuccessMessage,
            // Yalnız YENİ kayıtta hızlı hatırlatıcı aksiyonları göster.
            quickReminderItemId: result.isNewItem ? result.createdItemId : null,
            quickReminderItemTitle:
                result.isNewItem ? result.createdItemTitle : null,
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isOpeningModal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(homeTabIndexProvider);

    final l10n = AppLocalizations.of(context)!;

    // Determine active color for tabs. Pasif ikon rengi, sekme çubuğu
    // zeminiyle en az 3:1 (WCAG ikon) kontrast sağlayacak şekilde koyulaştırılır.
    final inactiveTabColor = BrandGradient.ensureContrast(
      context.colors.iconInactive,
      context.colors.surfaceWhite,
      BrandGradient.iconContrast,
    );
    Color getIconColor(int index) {
      return selectedIndex == index ? context.colors.primary : inactiveTabColor;
    }

    // Check if Vibe theme is active
    final isVibeTheme = ref.watch(themeProvider) == AppThemeEnum.vibe;

    return Scaffold(
      backgroundColor:
          isVibeTheme
              ? const Color(0xFF0A0A12)
              : context.colors.backgroundBottom,
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
            _buildTabButton(
              index: 0,
              selectedIndex: selectedIndex,
              label: l10n.a11yTabFeed,
              activeIcon: PhosphorIconsFill.house,
              inactiveIcon: PhosphorIconsLight.house,
              color: getIconColor(0),
            ),
            _buildTabButton(
              index: 1,
              selectedIndex: selectedIndex,
              label: l10n.a11yTabSearch,
              activeIcon: PhosphorIconsFill.magnifyingGlass,
              inactiveIcon: PhosphorIconsLight.magnifyingGlass,
              color: getIconColor(1),
            ),
            const SizedBox(width: 48), // Spacer for FAB
            _buildTabButton(
              index: 2,
              selectedIndex: selectedIndex,
              label: l10n.a11yTabCatalog,
              activeIcon: PhosphorIconsFill.squaresFour,
              inactiveIcon: PhosphorIconsLight.squaresFour,
              color: getIconColor(2),
            ),
            _buildTabButton(
              index: 3,
              selectedIndex: selectedIndex,
              label: l10n.a11yTabProfile,
              activeIcon: PhosphorIconsFill.user,
              inactiveIcon: PhosphorIconsLight.user,
              color: getIconColor(3),
            ),
          ],
        ),
      ),

      // Main Content Switching
      body: _buildBody(isVibeTheme, selectedIndex),
    );
  }

  /// İkon-only sekme butonu: VoiceOver için yerelleştirilmiş etiket +
  /// seçili durumu, uzun basışta tooltip.
  Widget _buildTabButton({
    required int index,
    required int selectedIndex,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color color,
  }) {
    final isSelected = selectedIndex == index;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      onTap: () => _onItemTapped(index),
      child: IconButton(
        alignment: Alignment.topCenter,
        tooltip: label,
        onPressed: () => _onItemTapped(index),
        icon: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: color,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildBody(bool isVibeTheme, int selectedIndex) {
    final initializedTabs = ref.watch(initializedHomeTabsProvider);
    final content = IndexedStack(
      index: selectedIndex,
      children: [
        // 0: Feed
        ItemFeedScreen(
          onSearchTap: () => _onItemTapped(1), // Switch to Search Tab
          onCatalogTap: () => _onItemTapped(2), // Switch to Catalog Tab
          onAddTap: () => _openAddContentScreen(),
        ),

        // 1: Search
        initializedTabs.contains(1)
            ? const SearchScreen()
            : const SizedBox.shrink(),

        // 2: Catalog
        initializedTabs.contains(2)
            ? CatalogScreen(onAddTap: () => _openAddContentScreen())
            : const SizedBox.shrink(),

        // 3: Profile
        initializedTabs.contains(3)
            ? const ProfileScreen()
            : const SizedBox.shrink(),
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
      final l10n = AppLocalizations.of(context)!;
      final fabForeground = BrandGradient.foreground(context);
      return Semantics(
        button: true,
        enabled: !_isTrashActionInProgress,
        label: l10n.a11yAddContent,
        excludeSemantics: true,
        onTap: _isTrashActionInProgress ? null : () => _openAddContentScreen(),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // İkon-only kontrol: beyaz/onPrimary artı ikonu için ≥3:1.
            gradient: BrandGradient.linear(
              context,
              minContrast: BrandGradient.iconContrast,
            ),
            border: Border.all(
              color: context.colors.surfaceWhite.withValues(
                alpha: 0.2,
              ), // Subtle midnight-like border
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  _isTrashActionInProgress
                      ? null
                      : () => _openAddContentScreen(),
              customBorder: const CircleBorder(),
              splashColor: fabForeground.withValues(alpha: 0.3),
              child: Tooltip(
                message: l10n.a11yAddContent,
                child: Icon(
                  PhosphorIconsLight.plus,
                  color: fabForeground,
                  size: 28,
                ),
              ),
            ),
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
        if (_isTrashActionInProgress) {
          return;
        }

        setState(() => _isTrashActionInProgress = true);
        HapticFeedback.mediumImpact();

        // Reset drag state
        ref.read(isDraggingProvider.notifier).state = false;

        try {
          await deleteFeedItemsWithUndo(context, ref, details.data);
        } finally {
          if (mounted) {
            setState(() => _isTrashActionInProgress = false);
          } else {
            _isTrashActionInProgress = false;
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          width: 64,
          height: 64,
          // Restore Container Scaling (Vacuum Effect)
          transform:
              isHovering
                  ? (Matrix4.identity()..scale(0.75)) // Shrink Container
                  : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Theme-aware gradient
            gradient: LinearGradient(
              colors: [
                context.colors.secondary.withValues(
                  alpha: 0.3,
                ), // Light secondary
                context.colors.surfaceWhite, // Surface white
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.3),
                blurRadius: isHovering ? 2 : 15, // Shadow decreases on shrink
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: context.colors.surfaceWhite, width: 2),
          ),
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              scale: isHovering ? 0.8 : 1.0, // Icon ALSO shrinks a bit more
              child: Icon(
                PhosphorIconsLight.trash,
                color:
                    isHovering
                        ? context.colors.headline
                        : context.colors.primary,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }
}
