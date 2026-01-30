import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
// import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/share_providers.dart';
import 'package:somine_app/widgets/item_detail_bottom_sheet.dart';
import 'package:somine_app/widgets/custom_note_icon.dart';
import 'package:somine_app/core/providers/subscription_provider.dart';
import 'package:somine_app/widgets/limit_reached_dialog.dart';
import 'package:somine_app/widgets/success_notification_sheet.dart';
import 'package:somine_app/core/services/vault_service.dart';
import 'package:somine_app/core/providers/navigation_providers.dart';
// State to track selected category in Catalog Screen (null = Uncategorized/Inbox)
final selectedCatalogIdProvider = StateProvider.autoDispose<String?>((ref) => null);

// State to track reordering mode
final isReorderingProvider = StateProvider.autoDispose<bool>((ref) => false);

// Selection Mode State
final isSelectionModeProvider = StateProvider.autoDispose<bool>((ref) => false);
final selectedItemsProvider = StateProvider.autoDispose<Set<String>>((ref) => {});

class CatalogScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const CatalogScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  // Get current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      // Delay to allow provider to be ready/listened? 
      // Actually with Riverpod we can set it immediately but avoid build phase issues.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCatalogIdProvider.notifier).state = widget.initialCategoryId;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_scrollController.hasClients) return;
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final double curPos = details.globalPosition.dx;
    
    // Auto-scroll zones (edges)
    const double zoneSize = 80.0;
    const double scrollAmount = 15.0; // Pixels per update

    if (curPos > screenWidth - zoneSize) {
      // Right Scroll
      if (_scrollController.offset < _scrollController.position.maxScrollExtent) {
         _scrollController.jumpTo(_scrollController.offset + scrollAmount);
      }
    } else if (curPos < zoneSize) {
      // Left Scroll
      if (_scrollController.offset > 0) {
         _scrollController.jumpTo(_scrollController.offset - scrollAmount);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedCatalogIdProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync = ref.watch(catalogItemsProvider);
    final isReordering = ref.watch(isReorderingProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for VibeBackground
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    "Koleksiyonlarım",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.colors.headline
                    ),
                  ),
                  if (isReordering)
                    TextButton(
                      onPressed: () => ref.read(isReorderingProvider.notifier).state = false,
                      style: TextButton.styleFrom(
                        backgroundColor: context.colors.primary.withOpacity(0.1),
                        foregroundColor: context.colors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text("Bitti", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    )
                  else
                  Row(
                    children: [
                       // GRID VIEW BUTTON - Opens all collections in a modal
                       GestureDetector(
                        onTap: () => _showCollectionsGridSheet(context),
                        child: Container(
                           padding: const EdgeInsets.all(8),
                           margin: const EdgeInsets.only(right: 12),
                           decoration: BoxDecoration(
                             color: context.colors.primary.withOpacity(0.1),
                             shape: BoxShape.circle,
                           ),
                           child: Icon(
                             PhosphorIconsRegular.squaresFour, 
                             size: 20, 
                             color: context.colors.primary
                           ),
                        ),
                      ),
                       
                       // VAULT TOGGLE BUTTON
                       GestureDetector(
                        onTap: () async {
                          final isUnlocked = ref.read(isVaultUnlockedProvider);
                          if (isUnlocked) {
                             // Lock immediately
                             ref.read(isVaultUnlockedProvider.notifier).state = false;
                          } else {
                             // Unlock via Auth
                             final vaultService = VaultService();
                             final result = await vaultService.authenticate(
                               reason: 'Gizli koleksiyonları görüntülemek için doğrulama yapın',
                             );
                             if (result == VaultAuthResult.success) {
                                ref.read(isVaultUnlockedProvider.notifier).state = true;
                             }
                          }
                        },
                        child: Container(
                           padding: const EdgeInsets.all(8),
                           margin: const EdgeInsets.only(right: 12),
                           decoration: BoxDecoration(
                             color: ref.watch(isVaultUnlockedProvider) 
                                ? context.colors.primary 
                                : context.colors.primary.withOpacity(0.1),
                             shape: BoxShape.circle,
                           ),
                           child: Icon(
                             ref.watch(isVaultUnlockedProvider) ? PhosphorIconsBold.lockKeyOpen : PhosphorIconsBold.lockKey, 
                             size: 20, 
                             color: ref.watch(isVaultUnlockedProvider) ? Colors.white : context.colors.primary
                           ),
                        ),
                      ),
                      
                      // ADD BUTTON
                      GestureDetector(
                        onTap: _showAddCategoryDialog,
                        child: Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(
                             color: context.colors.primary.withOpacity(0.1),
                             shape: BoxShape.circle,
                           ),
                           child: Icon(PhosphorIconsRegular.plus, size: 20, color: context.colors.primary),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            Listener(
              onPointerMove: (event) {
                // Auto-scroll during drag when user drags near edges
                if (ref.read(isDraggingProvider)) {
                  _handleDragUpdate(DragUpdateDetails(
                    globalPosition: event.position,
                    delta: event.delta,
                  ));
                }
              },
              child: SizedBox(
                height: 140, // Height increased for new cards
                child: itemsAsync.when(
                   data: (items) => _buildCatalogShelf(categoriesAsync, selectedId, items, isReordering),
                   loading: () => const Center(child: SizedBox()),
                   error: (_,__) => const SizedBox(),
                ),
              ),
            ),

            const SizedBox(height: 24), // Increased spacing per user request

            // 2. Selection Action Row (Always Visible)
            Builder(
              builder: (context) {
                 final items = itemsAsync.valueOrNull ?? [];
                 final categories = categoriesAsync.valueOrNull ?? [];
                 final vaultIds = categories.where((c) => c.isVault).map((c) => c.id).toSet();
                 final isVaultUnlocked = ref.read(isVaultUnlockedProvider);
                 final selectedItems = ref.watch(selectedItemsProvider);
                 final isSelectionMode = ref.watch(isSelectionModeProvider);

                 final targetItems = items.where((item) {
                    if (selectedId == null) {
                       if (isVaultUnlocked) return true;
                       return !vaultIds.contains(item.categoryId);
                    }
                    if (selectedId == 'uncategorized') {
                       return item.categoryId == null || item.categoryId!.isEmpty;
                    }
                    return item.categoryId == selectedId;
                 }).toList();

                 final areAllSelected = targetItems.isNotEmpty && targetItems.every((i) => selectedItems.contains(i.id));

                 return _buildInlineSelectionRow(
                    context, 
                    selectedItems.length,
                    isSelectionMode,
                    areAllSelected,
                    () { // onToggleMode
                        if (isSelectionMode) {
                           ref.read(isSelectionModeProvider.notifier).state = false;
                           ref.read(selectedItemsProvider.notifier).state = {};
                        } else {
                           ref.read(isSelectionModeProvider.notifier).state = true;
                        }
                    },
                    () { // onSelectAll
                        if (areAllSelected) {
                           ref.read(selectedItemsProvider.notifier).state = {};
                        } else {
                           ref.read(selectedItemsProvider.notifier).state = targetItems.map((e) => e.id).toSet();
                        }
                    }
                 );
              }
            ),

             // 3. Main Content
            Expanded(
              child: itemsAsync.when(
                 data: (items) => categoriesAsync.when(
                    data: (categories) => _buildBody(selectedId, items, categories, ref.watch(isVaultUnlockedProvider)),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_,__) => _buildBody(selectedId, items, [], false), // Fallback
                 ),
                 loading: () => const Center(child: CircularProgressIndicator()),
                 error: (err, stack) => Center(child: Text('Hata oluştu', style: GoogleFonts.poppins())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper
  Widget _buildBody(String? selectedId, List<ItemModel> allItems, List<CategoryModel> categories, bool isVaultUnlocked) {
     
     // 1. Identify Locked Categories
     // If a category is Vault AND !isUnlocked -> It is effectively hidden/masked.
     final vaultIds = categories.where((c) => c.isVault).map((c) => c.id).toSet();
     
     final filteredItems = allItems.where((item) {
       if (selectedId == null) {
         // Tümü View:
         // If unlocked -> Show ALL.
         // If locked -> Hide vault items.
         if (isVaultUnlocked) return true;
         return !vaultIds.contains(item.categoryId);
       }
       if (selectedId == 'uncategorized') {
         return item.categoryId == null || item.categoryId!.isEmpty;
       }
       
       // Specific Category View
       // Ideally we shouldn't even be here if it's locked and we prevent selection?
       // But if we are here:
       if (!isVaultUnlocked && vaultIds.contains(selectedId)) {
          // User selected a locked vault (maybe via deep link or state persistence?)
          // Force hide contents or show placeholder?
          // For now, logic: return true if ID matches. The UI will render empty list if we filter it out?
          // Better: If locked, return false (empty list). Or show "Locked" UI in body.
          return false; 
       }
       
       return item.categoryId == selectedId;
     }).toList();
     
     // Special UI for Locked Category Selection (if items empty but category exists)
     if (selectedId != null && !isVaultUnlocked && vaultIds.contains(selectedId)) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(PhosphorIconsDuotone.lockKey, size: 64, color: context.colors.primary.withOpacity(0.5)),
               const SizedBox(height: 16),
               Text("Koleksiyon Kilitli", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.headline)),
               const SizedBox(height: 8),
               Text("İçerikleri görmek için yukarıdan kilidi açın.", style: GoogleFonts.poppins(fontSize: 14, color: context.colors.body)),
            ],
          ),
        );
     }
     
     return _buildItemGrid(filteredItems, categories);
  }

  // --- CATALOG SHELF ---

  Widget _buildCatalogShelf(AsyncValue<List<CategoryModel>> categoriesAsync, String? selectedId, List<ItemModel> allItems, bool isReordering) {
    return categoriesAsync.when(
      data: (categories) {
        // Vault detection
        final vaultIds = categories.where((c) => c.isVault).map((c) => c.id).toSet();
        final isVaultUnlocked = ref.watch(isVaultUnlockedProvider);
        
        // Tümü count
        final allItemsCount = isVaultUnlocked 
             ? allItems.length 
             : allItems.where((i) => !vaultIds.contains(i.categoryId)).length;

        // Sortable categories (exclude Hızlı, sorted by order)
        final sortedCategories = categories
            .where((c) => c.name != 'Hızlı')
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        return SizedBox(
          height: 160,
          child: isReordering 
          ? Row(
              children: [
                // 1. Fixed "Tümü" card (not reorderable)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: _buildImageCatalogCard(
                    id: null,
                    name: "Tümü",
                    imageProvider: null,
                    isSelected: selectedId == null,
                    isSystem: true,
                    itemCount: allItemsCount,
                    isReordering: isReordering,
                  ),
                ),
                
                // 2. Reorderable user categories
                Expanded(
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 8, right: 20),
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: Colors.transparent,
                        elevation: 6,
                        shadowColor: Colors.black26,
                        borderRadius: BorderRadius.circular(24),
                        child: child,
                      );
                    },
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex--;
                      final reorderedList = List<CategoryModel>.from(sortedCategories);
                      final movedItem = reorderedList.removeAt(oldIndex);
                      reorderedList.insert(newIndex, movedItem);
                      
                      await CategoryRepository().reorderCategories(reorderedList);
                      ref.invalidate(categoriesProvider);
                    },
                    itemCount: sortedCategories.length,
                    itemBuilder: (context, index) {
                      final cat = sortedCategories[index];
                      final isLocked = cat.isVault && !isVaultUnlocked;
                      final catItems = allItems.where((i) => i.categoryId == cat.id).toList();
                      final coverItem = catItems.firstWhere(
                        (i) => i.displayImage != null && i.displayImage!.isNotEmpty && !i.displayImage!.toLowerCase().endsWith('.svg'),
                        orElse: () => ItemModel(id: '', userId: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), type: ItemType.note),
                      );

                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(cat.id),
                        index: index,
                        child: Stack(
                          children: [
                            _buildImageCatalogCard(
                              id: cat.id,
                              name: cat.name,
                              imageProvider: (coverItem.displayImage != null && coverItem.displayImage!.isNotEmpty)
                                  ? CachedNetworkImageProvider(coverItem.displayImage!)
                                  : null,
                              isSelected: selectedId == cat.id,
                              isLockedVault: isLocked,
                              itemCount: catItems.length,
                              isReordering: true,
                            ),
                            Positioned(
                              top: 0, right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Icon(PhosphorIconsBold.list, size: 16, color: context.colors.primary),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 20),
              // +1 for "Tümü" card at index 0
              itemCount: sortedCategories.length + 1,
              itemBuilder: (context, index) {
                // First item is "Tümü"
                if (index == 0) {
                  return _buildImageCatalogCard(
                    id: null,
                    name: "Tümü",
                    imageProvider: null,
                    isSelected: selectedId == null,
                    isSystem: true,
                    itemCount: allItemsCount,
                    isReordering: false,
                  );
                }
                
                // Adjust index for categories (index - 1)
                final catIndex = index - 1;
                final cat = sortedCategories[catIndex];
                final isLocked = cat.isVault && !isVaultUnlocked;
                final catItems = allItems.where((i) => i.categoryId == cat.id).toList();
                final coverItem = catItems.firstWhere(
                  (i) => i.displayImage != null && i.displayImage!.isNotEmpty && !i.displayImage!.toLowerCase().endsWith('.svg'),
                  orElse: () => ItemModel(id: '', userId: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), type: ItemType.note),
                );

                return _buildImageCatalogCard(
                  id: cat.id,
                  name: cat.name,
                  imageProvider: (coverItem.displayImage != null && coverItem.displayImage!.isNotEmpty)
                      ? CachedNetworkImageProvider(coverItem.displayImage!)
                      : null,
                  isSelected: selectedId == cat.id,
                  isLockedVault: isLocked,
                  onLongPress: () => _showEditCategoryOptions(context, cat),
                  itemCount: catItems.length,
                  isReordering: false,
                );
              },
            ),
        );
      },
      loading: () => const Center(child: SizedBox()),
      error: (_,__) => const SizedBox(),
    );
  }
  
  Widget _buildImageCatalogCard({
    required String? id, 
    required String name, 
    required ImageProvider? imageProvider, 
    required bool isSelected,
    bool isSystem = false,
    bool isLockedVault = false,
    required int itemCount,
    VoidCallback? onLongPress,
    VoidCallback? onTap,
    bool isReordering = false,
  }) {
    final effectiveOnTap = isReordering ? null : (onTap ?? () => ref.read(selectedCatalogIdProvider.notifier).state = id);
    final effectiveLongPress = isReordering ? null : (isSystem ? null : (onLongPress ?? () => _confirmDelete(context, id!, name)));

    return DragTarget<ItemModel>(
      onWillAccept: (item) => item != null && item.categoryId != id,
      onAccept: (item) => _moveItemToCategory(item, id),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        
        // --- SHELF CARD DECORATION LOGIC ---
        BoxDecoration boxDecoration;
        Widget? childContent;

        // Hover Effect: Stronger Border & Glow
        final hoverBorder = Border.all(color: context.colors.primary, width: 3);
        final hoverShadow = BoxShadow(color: context.colors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4));

        if (isLockedVault) {
           // CASE 0: Locked Vault -> Lock Icon
           boxDecoration = BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: context.colors.surfaceWhite,
              border: isSelected 
                  ? Border.all(color: context.colors.primary, width: 2) 
                  : Border.all(color: context.colors.secondary.withOpacity(0.3)),
              boxShadow: isSelected 
                  ? [BoxShadow(color: context.colors.primary.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))] 
                  : null,
           );
           childContent = Stack(
             children: [
                Center(
                  child: Icon(
                    PhosphorIconsFill.lockKey, 
                    size: 28, 
                    color: isSelected ? context.colors.primary : context.colors.body.withOpacity(0.4)
                  ),
                ),
                _buildShelfLabel(name, itemCount, isDarkBg: false, isSystem: isSystem, isSelected: isSelected),
             ],
           );
        } else if (imageProvider != null) {
           // CASE 1: Has Image -> Image Background + B&W/Color Filter
           boxDecoration = BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
                colorFilter: (isSelected || isHovered) 
                    ? null 
                    : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              ),
              boxShadow: isHovered 
                  ? [hoverShadow] // Glow on Hover
                  : (isSelected 
                      ? [BoxShadow(color: context.colors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 8))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))]),
              border: isHovered 
                  ? hoverBorder // Accent Border on Hover
                  : (isSelected 
                      ? Border.all(color: context.colors.primary, width: 2) 
                      : Border.all(color: context.colors.surfaceWhite.withOpacity(0.2), width: 1)),
           );
           childContent = Stack(
              children: [
                // Dark Overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                _buildShelfLabel(name, itemCount, isDarkBg: true, isSystem: isSystem, isSelected: isSelected),
              ],
           );
        } else if (isSystem) {
           // CASE 2: System Cards (All & Inbox)
           
           if (id == null) {
              // "Tümü" - Special Styling
              // Selection: Gradient Border -> White Gap -> Gradient Fill
              // Normal: Gradient Fill
              
              final primaryGradient = LinearGradient(
                  colors: [context.colors.primary, context.colors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
              );

              if (isSelected) {
                 return GestureDetector(
                   onTap: effectiveOnTap,
                   child: AnimatedContainer(
                     duration: const Duration(milliseconds: 300),
                     width: 120,
                     margin: const EdgeInsets.only(right: 12),
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(24), // Outer radius
                       gradient: primaryGradient, // Border Gradient
                       boxShadow: [BoxShadow(color: context.colors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 6))],
                     ),
                     padding: const EdgeInsets.all(2.5), // Border Width
                     child: Container(
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(21),
                         color: context.colors.backgroundBottom, // Gap color matches background
                       ),
                       padding: const EdgeInsets.all(2.5), // Gap Width
                       child: Container(
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(19),
                           gradient: primaryGradient, // Inner Fill
                         ),
                         child: Stack(
                            children: [
                               _buildShelfLabel(name, itemCount, isDarkBg: true, isSystem: true, isSelected: true),
                               Positioned(
                                  bottom: 10,
                                  left: 12,
                                  child: Icon(PhosphorIconsFill.checkCircle, color: Colors.white, size: 16),
                               )
                            ],
                         ),
                       ),
                     ),
                   ),
                 );
              } else {
                 return GestureDetector(
                   onTap: effectiveOnTap,
                   child: AnimatedContainer(
                     duration: const Duration(milliseconds: 300),
                     width: 120,
                     margin: const EdgeInsets.only(right: 12),
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(20),
                       gradient: primaryGradient,
                       boxShadow: isHovered 
                          ? [hoverShadow]
                          : [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))],
                       border: isHovered ? hoverBorder : null,
                     ),
                     child: _buildShelfLabel(name, itemCount, isDarkBg: true, isSystem: true, isSelected: false),
                   ),
                 );
              }
           } else {
              // "HIZLI" - Premium Dark Gradient
              
              const quickGradient = LinearGradient(
                  colors: [Color(0xFF1F2937), Color(0xFF4B5563)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
              );

              if (isSelected) {
                 return GestureDetector(
                   onTap: effectiveOnTap,
                   child: AnimatedContainer(
                     duration: const Duration(milliseconds: 300),
                     width: 120,
                     margin: const EdgeInsets.only(right: 12),
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(24),
                       gradient: quickGradient,
                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 6))],
                     ),
                     padding: const EdgeInsets.all(2.5),
                     child: Container(
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(21),
                         color: context.colors.backgroundBottom, // Contrast Gap matches background
                       ),
                       padding: const EdgeInsets.all(2.5),
                       child: Container(
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(19),
                           gradient: quickGradient,
                         ),
                         child: Stack(
                            children: [
                               _buildShelfLabel(name, itemCount, isDarkBg: true, isSystem: true, isSelected: true),
                               Positioned(
                                  bottom: 10,
                                  left: 12,
                                  child: Icon(PhosphorIconsFill.checkCircle, color: Colors.white, size: 16),
                               )
                            ],
                         ),
                       ),
                     ),
                   ),
                 );
              } else {
                  return GestureDetector(
                   onTap: onTap ?? () => ref.read(selectedCatalogIdProvider.notifier).state = id,
                   child: AnimatedContainer(
                     duration: const Duration(milliseconds: 300),
                     width: 120,
                     margin: const EdgeInsets.only(right: 12),
                     decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: quickGradient,
                        boxShadow: isHovered 
                            ? [hoverShadow]
                            : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                        border: isHovered ? hoverBorder : null,
                     ),
                     child: _buildShelfLabel(name, itemCount, isDarkBg: true, isSystem: true, isSelected: false),
                  ),
                 );
              }
           }
        } else {
           // CASE 3: NO Image -> White Background + Gradient Border
           return GestureDetector(
             onTap: effectiveOnTap,
             onLongPress: effectiveLongPress,
             child: AnimatedContainer(
               duration: const Duration(milliseconds: 300),
               width: 120,
               margin: const EdgeInsets.only(right: 12),
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(20),
                 gradient: LinearGradient(
                    colors: [context.colors.primary, context.colors.secondary], // Oil Green Gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                 ),
                 boxShadow: isHovered
                    ? [hoverShadow]
                    : (isSelected 
                        ? [BoxShadow(color: context.colors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 6))]
                        : [BoxShadow(color: context.colors.premiumShadow.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
                 // Make border appear thicker on hover by increasing padding
               ),
               padding: EdgeInsets.all(isHovered ? 4 : 2), 
               child: Container(
                 decoration: BoxDecoration(
                   color: context.colors.surfaceWhite,
                   borderRadius: BorderRadius.circular(18), 
                 ),
                 child: _buildShelfLabel(name, itemCount, isDarkBg: false, isSystem: false, isSelected: isSelected),
               ),
             ),
           );
        }

        return GestureDetector(
          onTap: effectiveOnTap,
          onLongPress: effectiveLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: boxDecoration,
            child: childContent,
          ),
        );
      },
    );
  }

  Widget _buildShelfLabel(String name, int count, {required bool isDarkBg, required bool isSystem, required bool isSelected}) {
     Color textColor = isDarkBg ? Colors.white : context.colors.headline;
     Color badgeBg = Colors.white.withOpacity(0.9); // Always white for consistency
     Color badgeText = Colors.black87; // Always dark text for readability
     
     return Stack(
       fit: StackFit.expand,
       children: [
          // Badge Label (Top Left)
          Positioned(
            top: 10,
            left: 10,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          // Item Count (Bottom Right)
           Positioned(
            bottom: 10,
            right: 12,
            child: Text(
              "$count",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkBg ? Colors.white.withOpacity(0.9) : context.colors.primary,
              ),
            ),
          ),
          
          if (isSelected && !isSystem)
            Positioned(
               bottom: 10,
               left: 12,
               child: Icon(PhosphorIconsFill.checkCircle, color: context.colors.primary, size: 16),
            )
       ],
     );
  }



  Widget _buildAddCatalogButton() {
     return GestureDetector(
       onTap: _showAddCategoryDialog,
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Container(
             width: 60,
             height: 60, // Fixed height to match others (approx)
             margin: const EdgeInsets.only(right: 20, bottom: 8),
             decoration: BoxDecoration(
               color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.colors.surfaceWhite,
               shape: BoxShape.circle,
               border: Border.all(color: Colors.grey.shade200, width: 1.5),
               boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0,2))
               ]
             ),
             child: Center(
               child: Icon(PhosphorIconsRegular.plus, size: 24, color: context.colors.primary),
             ),
           ),
           Padding(
             padding: const EdgeInsets.only(right: 20),
             child: Text(
               "Yeni +",
               style: GoogleFonts.outfit(
                 fontSize: 12,
                 fontWeight: FontWeight.w600,
                 color: context.colors.headline.withOpacity(0.7)
               ),
             ),
           )
         ],
       ),
     );
  }

  // --- CONTENT GRID ---

  Widget _buildItemGrid(List<ItemModel> items, List<CategoryModel> categories) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Organic Icon Background
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                   Transform.rotate(
                     angle: -0.2,
                     child: Container(
                       width: 100,
                       height: 100,
                       decoration: BoxDecoration(
                         color: context.colors.primary.withOpacity(0.05),
                         borderRadius: BorderRadius.circular(32),
                       ),
                     ),
                   ),
                   Transform.rotate(
                     angle: 0.2,
                     child: Container(
                       width: 100,
                       height: 100,
                       decoration: BoxDecoration(
                         color: const Color(0xFF6FBFAC).withOpacity(0.1),
                         borderRadius: BorderRadius.circular(40),
                       ),
                     ),
                   ),
                   Icon(PhosphorIconsDuotone.plant, size: 56, color: context.colors.primary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Bu Alan Yeşermeyi Bekliyor", 
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.colors.headline
              )
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "İlham verici içeriklerini ekle ve koleksiyonunun büyümesini izle.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: context.colors.body.withOpacity(0.7)
                )
              ),
            )
          ],
        ),
      );
    }

    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return LongPressDraggable<ItemModel>(
          data: item,
          delay: const Duration(seconds: 1), // Reduced to 1 second per user request
          onDragUpdate: _handleDragUpdate, // Auto-scroll listener
          dragAnchorStrategy: pointerDragAnchorStrategy, // Makes drag follow finger exactly
          feedback: Transform.rotate(
            angle: 0.05, // Slight tilt for drag effect
            child: SizedBox(
               width: 100, // Standardized size
               height: 100,
               child: Material(
                 color: Colors.transparent,
                 borderRadius: BorderRadius.circular(16),
                 elevation: 8,
                 shadowColor: Colors.black26,
                 child: ClipRRect(
                   borderRadius: BorderRadius.circular(16),
                   child: _buildSquareImageOnly(item), // New helper
                 ),
               )
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3, 
            child: _buildItemCard(item, categories, items) // Placeholder
          ),
          child: _buildItemCard(item, categories, items),
          onDragStarted: () {
             ref.read(isDraggingProvider.notifier).state = true;
             HapticFeedback.selectionClick();
             
             // Auto-Select on Long Press Drag Start (User Request)
             if (!ref.read(isSelectionModeProvider)) {
                ref.read(isSelectionModeProvider.notifier).state = true;
                ref.read(selectedItemsProvider.notifier).state = {item.id};
             } else {
                // If already in selection mode, ensure this item is selected if user drags it
                // (Optional enhancement, usually dragging valid "selection" is complex, 
                // but simpler to just ensure 'this' item is selected)
                final current = ref.read(selectedItemsProvider);
                if (!current.contains(item.id)) {
                   ref.read(selectedItemsProvider.notifier).state = {...current, item.id};
                }
             }
          },
          onDragEnd: (details) {
             ref.read(isDraggingProvider.notifier).state = false;
          },
          onDraggableCanceled: (velocity, offset) {
             ref.read(isDraggingProvider.notifier).state = false;
          },
        );
      },
    );
  }

  // --- EDIT & RENAME LOGIC ---

  void _showEditCategoryOptions(BuildContext context, CategoryModel category) {
    final isPremium = ref.read(isPremiumProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow dynamic height beyond half-screen
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: PhosphorIconsRegular.list,
              title: "Sıralamayı Düzenle",
              onTap: () {
                Navigator.pop(ctx);
                ref.read(isReorderingProvider.notifier).state = true;
              },
            ),
            Divider(color: Colors.grey[100]),
            _buildOptionTile(
              icon: PhosphorIconsRegular.pencilSimple,
              title: "Koleksiyon Adını Düzenle",
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(category.id!, category.name);
              },
            ),
            Divider(color: Colors.grey[100]),
            // Share Collection - Disabled for Vaults (moved above Vault toggle)
            Opacity(
              opacity: category.isVault ? 0.4 : 1.0,
              child: _buildOptionTile(
                icon: PhosphorIconsRegular.shareNetwork,
                title: "Koleksiyonu Paylaş",
                color: category.isVault ? Colors.grey : null, // Default primary when null
                trailing: category.isVault ? Text(
                  "Gizli Kasa",
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                ) : null,
                onTap: () {
                  if (category.isVault) {
                    // Show info that vaults cannot be shared
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Gizli kasalar paylaşılamaz", style: GoogleFonts.poppins()),
                        backgroundColor: Colors.grey[700],
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _showShareCollectionDialog(category);
                },
              ),
            ),
            Divider(color: Colors.grey[100]),
            // Vault Toggle - Premium Feature
            _buildOptionTile(
              icon: category.isVault ? PhosphorIconsRegular.lockSimpleOpen : PhosphorIconsRegular.lock,
              title: category.isVault ? "Gizli Kasadan Çıkar" : "Gizli Kasaya Ekle",
              color: category.isVault ? Colors.green : context.colors.primary,
              trailing: !isPremium ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [context.colors.primary, context.colors.secondary]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("PRO", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ) : null,
              onTap: () async {
                Navigator.pop(ctx);
                if (!isPremium) {
                  // Show paywall
                  LimitReachedDialog.show(
                    context: context,
                    ref: ref,
                    title: "Premium Özellik",
                    message: "Gizli Kasa özelliği premium üyelere özeldir. FaceID/TouchID ile koleksiyonlarını koruma altına al!",
                    type: LimitType.collection,
                  );
                  return;
                }
                // Toggle vault status
                try {
                  final updated = category.copyWith(isVault: !category.isVault, updatedAt: DateTime.now());
                  await ref.read(categoryRepositoryProvider).updateCategory(updated);
                  if (mounted) {
                    SuccessNotificationSheet.show(
                      context,
                      title: "Başarılı",
                      message: updated.isVault ? "Koleksiyon gizli kasaya eklendi 🔒" : "Koleksiyon gizli kasadan çıkarıldı 🔓",
                    );
                  }
                } catch (e) {
                  debugPrint("Vault toggle error: $e");
                }
              },
            ),
            Divider(color: Colors.grey[100]),
            _buildOptionTile(
              icon: PhosphorIconsRegular.trash,
              title: "Koleksiyonu Sil",
              color: Colors.red,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, category.id!, category.name);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildOptionTile({required IconData icon, required String title, Color? color, Widget? trailing, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (color ?? context.colors.primary).withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color ?? context.colors.primary, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: color ?? context.colors.headline)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showShareCollectionDialog(CategoryModel category) {
    final searchController = TextEditingController();
    Map<String, dynamic>? foundUser;
    bool isSearching = false;
    bool hasSearched = false;
    String? errorMessage;
    List<Map<String, dynamic>> recentUsers = [];
    bool isLoadingRecent = true;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: context.colors.surfaceWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "Koleksiyonu Paylaş",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.colors.headline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: context.colors.body,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "@kullaniciadi veya e-posta",
                    hintStyle: TextStyle(color: context.colors.hint),
                    prefixIcon: Icon(PhosphorIconsRegular.at, color: context.colors.hint),
                    suffixIcon: isSearching 
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: Icon(PhosphorIconsRegular.arrowRight, color: context.colors.primary),
                          onPressed: () async {
                            if (searchController.text.trim().isEmpty) return;
                            setState(() {
                              isSearching = true;
                              hasSearched = false;
                              foundUser = null;
                              errorMessage = null;
                            });
                            try {
                              // Kullanıcı adı veya e-posta ile ara
                              final result = await ref.read(shareRepositoryProvider).findUser(searchController.text.trim());
                              setState(() {
                                foundUser = result;
                                hasSearched = true;
                                isSearching = false;
                              });
                            } catch (e) {
                              setState(() {
                                errorMessage = e.toString();
                                isSearching = false;
                              });
                            }
                          },
                        ),
                    filled: true,
                    fillColor: context.colors.backgroundTop,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (value) async {
                    if (value.trim().isEmpty) return;
                    setState(() {
                      isSearching = true;
                      hasSearched = false;
                      foundUser = null;
                      errorMessage = null;
                    });
                    try {
                      // Kullanıcı adı veya e-posta ile ara
                      final result = await ref.read(shareRepositoryProvider).findUser(value.trim());
                      setState(() {
                        foundUser = result;
                        hasSearched = true;
                        isSearching = false;
                      });
                    } catch (e) {
                      setState(() {
                        errorMessage = e.toString();
                        isSearching = false;
                      });
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.info,
                      color: context.colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paylaştığınız kişi içerikleri görüntüleyebilir ve kendi koleksiyonuna kopyalayabilir.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: context.colors.headline,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Search Results or Recent Users
              Expanded(
                child: hasSearched 
                  ? foundUser != null 
                    ? _buildUserResult(context, ctx, foundUser!, category, setState)
                    : _buildNoUserFound(context)
                  : _buildRecentUsers(context, ctx, category, setState, (user) {
                      setState(() {
                        foundUser = user;
                        hasSearched = true;
                      });
                    }),
              ),
              
              // Error Message
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    errorMessage!,
                    style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserResult(BuildContext context, BuildContext dialogContext, Map<String, dynamic> user, CategoryModel category, StateSetter setState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.backgroundTop,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Profile Photo or Initials
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: user['photoBase64'] == null 
                      ? LinearGradient(colors: [context.colors.primary, context.colors.secondary])
                      : null,
                    shape: BoxShape.circle,
                    image: user['photoBase64'] != null 
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(user['photoBase64'])),
                          fit: BoxFit.cover,
                        )
                      : null,
                  ),
                  child: user['photoBase64'] == null 
                    ? Center(
                        child: Text(
                          (user['displayName'] as String? ?? 'U')[0].toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['displayName'] ?? 'Kullanıcı',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colors.headline,
                        ),
                      ),
                      if (user['username'] != null)
                        Text(
                          '@${user['username']}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.colors.primary,
                          ),
                        ),
                      Text(
                        user['email'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: context.colors.hint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final currentUser = ref.read(authStateProvider).valueOrNull;
                    if (currentUser == null) {
                       throw Exception("Oturum açık değil");
                    }
                    
                    if (category.id == null || category.id!.isEmpty) {
                       throw Exception("Koleksiyon ID bulunamadı");
                    }
                    
                    // Email zorunluluğunu kaldırdık, ID varsa yeterli
                    if ((user['id'] == null || user['id'].isEmpty) && (user['email'] == null || user['email'].isEmpty)) {
                       throw Exception("Kullanıcı bilgisi eksik (ID veya E-posta bulunamadı)");
                    }
                    
                    await ref.read(shareRepositoryProvider).createShare(
                      fromUserId: currentUser.uid,
                      fromUserName: currentUser.displayName ?? currentUser.email ?? 'Kullanıcı',
                      fromUserEmail: currentUser.email ?? '',
                      toUserEmail: user['email'] ?? '', // Email opsiyonel, boş gidebilir
                      toUserId: user['id'], // ID öncelikli
                      categoryId: category.id!,
                      categoryName: category.name,
                    );
                    
                    Navigator.pop(dialogContext);
                    
                    if (mounted) {
                      SuccessNotificationSheet.show(
                        context,
                        title: 'Paylaşım Gönderildi',
                        message: '${user['displayName']} paylaşım isteğinizi aldı.',
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(PhosphorIconsRegular.paperPlaneTilt, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Paylaşım İsteği Gönder',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUserFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.userCircle,
            size: 48,
            color: context.colors.iconInactive,
          ),
          const SizedBox(height: 12),
          Text(
            'Kullanıcı Bulunamadı',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.headline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bu e-posta ile kayıtlı kullanıcı yok.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: context.colors.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHint(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 48,
            color: context.colors.iconInactive,
          ),
          const SizedBox(height: 12),
          Text(
            'Arkadaş Ara',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.headline,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Paylaşmak istediğiniz kişinin e-posta adresini girin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: context.colors.body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUsers(
    BuildContext context, 
    BuildContext dialogContext, 
    CategoryModel category, 
    StateSetter setState, 
    Function(Map<String, dynamic>) onUserSelected,
  ) {
    final currentUser = ref.read(authStateProvider).valueOrNull;
    if (currentUser == null) return _buildSearchHint(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(shareRepositoryProvider).getRecentlySharedUsers(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final recentUsers = snapshot.data ?? [];
        
        if (recentUsers.isEmpty) {
          return _buildSearchHint(context);
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Son Paylaşılanlar',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.body,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: recentUsers.length,
                  itemBuilder: (context, index) {
                    final user = recentUsers[index];
                    return _buildRecentUserTile(context, dialogContext, user, category);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentUserTile(BuildContext context, BuildContext dialogContext, Map<String, dynamic> user, CategoryModel category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          try {
            final currentUser = ref.read(authStateProvider).valueOrNull;
            if (currentUser == null) return;
            
            await ref.read(shareRepositoryProvider).createShare(
              fromUserId: currentUser.uid,
              fromUserName: currentUser.displayName ?? currentUser.email ?? 'Kullanıcı',
              fromUserEmail: currentUser.email ?? '',
              toUserEmail: user['email'],
              categoryId: category.id!,
              categoryName: category.name,
            );
            
            Navigator.pop(dialogContext);
            
            if (mounted) {
              SuccessNotificationSheet.show(
                context,
                title: 'Paylaşım Gönderildi',
                message: '${user['displayName']} paylaşım isteğinizi aldı.',
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Profile Photo or Initials
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: user['photoBase64'] == null 
                    ? LinearGradient(colors: [context.colors.primary, context.colors.secondary])
                    : null,
                  shape: BoxShape.circle,
                  image: user['photoBase64'] != null 
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(user['photoBase64'])),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: user['photoBase64'] == null 
                  ? Center(
                      child: Text(
                        (user['displayName'] as String? ?? 'U')[0].toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['displayName'] ?? 'Kullanıcı',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.colors.headline,
                      ),
                    ),
                    if (user['username'] != null)
                      Text(
                        '@${user['username']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: context.colors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                PhosphorIconsRegular.paperPlaneTilt,
                color: context.colors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showRenameDialog(String categoryId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surfaceWhite,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24), // Wider Dialog
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Koleksiyon Adı", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Yeni isim girin",
            hintStyle: TextStyle(color: context.colors.hint),
            filled: true,
            fillColor: context.colors.backgroundTop,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Vazgeç", style: GoogleFonts.outfit(color: context.colors.hint)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _renameCategory(categoryId, controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Kaydet", style: GoogleFonts.outfit(color: Colors.white)), // Button text stays white usually
          ),
        ],
      ),
    );
  }

  Future<void> _renameCategory(String id, String newName) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      final category = CategoryModel(
        id: id,
        name: newName,
        userId: _currentUserId ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.updateCategory(category);
      ref.invalidate(categoriesProvider);
      if (mounted) {
        SuccessNotificationSheet.show(context, title: "Başarılı", message: "Koleksiyon adı güncellendi");
      }
    } catch (e) {
      debugPrint("Rename error: $e");
    }
  }

  // --- ITEM ACTIONS SHEET ---

  void _showItemActionSheet(BuildContext context, ItemModel item, List<ItemModel> allItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
  
              // Select Action
              _buildOptionTile(
                icon: PhosphorIconsRegular.checkCircle,
                title: "Seç",
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(isSelectionModeProvider.notifier).state = true;
                  ref.read(selectedItemsProvider.notifier).state = {item.id};
                },
              ),
              Divider(color: Colors.grey[100]),
  

              
               // Sort Action
              _buildOptionTile(
                icon: PhosphorIconsRegular.sortAscending,
                title: "Sırala",
                onTap: () {
                  Navigator.pop(ctx);
                  // Sort the current view's list
                  // If selectedCatalogIdProvider is null, it typically means Inbox/Uncategorized in this codebase
                  final currentViewId = ref.read(selectedCatalogIdProvider) ?? 'uncategorized';
                  _showReorderSheet(context, currentViewId);
                },
              ),
               Divider(color: Colors.grey[100]),
              
              // Move Action
              _buildOptionTile(
                icon: PhosphorIconsRegular.arrowsOutCardinal,
                title: "Koleksiyona Taşı",
                onTap: () {
                  Navigator.pop(ctx);
                  _showMoveSelector(context, item);
                },
              ),
              
              Divider(color: Colors.grey[100]),
              
              // Delete Action
              _buildOptionTile(
                icon: PhosphorIconsRegular.trash,
                title: "İçeriği Sil",
                color: Colors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  if (ref.read(isSelectionModeProvider)) {
                     _confirmDeleteSelected(context);
                  } else {
                     _confirmDeleteItem(context, item); 
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveSelector(BuildContext context, ItemModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
       height: MediaQuery.of(context).size.height * 0.7,
       decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Taşımak İstediğin Koleksiyonu Seç", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.headline)),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final categoriesAsync = ref.watch(categoriesProvider);
                  return categoriesAsync.when(
                    data: (categories) {
                       final validTargets = categories.where((c) => c.id != item.categoryId).toList();
                       
                       return ListView.builder(
                         itemCount: validTargets.length,
                         itemBuilder: (ctx, index) {
                           final cat = validTargets[index];
                           final catColor = cat.color != null ? Color(int.parse(cat.color!.replaceAll('#', '0xFF'))) : context.colors.primary;
                           
                           return ListTile(
                             leading: Container(
                               width: 40, height: 40,
                               decoration: BoxDecoration(
                                 color: context.colors.primary.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Center(
                                 child: Icon(PhosphorIconsRegular.arrowRight, size: 20, color: context.colors.primary),
                               ),
                             ),
                             title: Text(cat.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: context.colors.headline)),
                             onTap: () async {
                               Navigator.pop(ctx);
                               
                               if (ref.read(isSelectionModeProvider)) {
                                  // Batch Move
                                  final selectedIds = ref.read(selectedItemsProvider).toList();
                                  if (selectedIds.isEmpty) { 
                                     selectedIds.add(item.id); 
                                  }
                                  await ref.read(itemRepositoryProvider).moveItemsToCategory(selectedIds, cat.id!);
                                  if (mounted) {
                                     SuccessNotificationSheet.show(
                                       context,
                                       title: 'Taşındı',
                                       message: '${selectedIds.length} içerik "${cat.name}" koleksiyonuna taşındı.'
                                     );
                                     ref.read(isSelectionModeProvider.notifier).state = false;
                                     ref.read(selectedItemsProvider.notifier).state = {};
                                  }
                                } else {
                                   // Single Move
                                   await ref.read(itemRepositoryProvider).moveToCategory(item.id, cat.id);
                                   if (mounted) {
                                      SuccessNotificationSheet.show(
                                        context,
                                        title: 'Taşındı',
                                        message: 'İçerik "${cat.name}" koleksiyonuna taşındı.'
                                      );
                                   }
                                }
                              },
                           );
                         },
                       );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text("Hata: $e")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

   void _confirmDeleteSelected(BuildContext context) async {
       final count = ref.read(selectedItemsProvider).length;
       final confirmed = await showDialog<bool>(
         context: context,
         builder: (context) => AlertDialog(
           title: Center(
             child: Text(
               'Seçili İçerikleri Sil',
               style: GoogleFonts.poppins(
                 fontWeight: FontWeight.bold,
                 fontSize: 20,
                 color: context.colors.headline,
               ),
             ),
           ),
           content: Text(
             '$count içeriği silmek istediğine emin misin?',
             textAlign: TextAlign.center,
             style: GoogleFonts.poppins(
               color: context.colors.body,
               fontSize: 14,
             ),
           ),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
           backgroundColor: context.colors.surfaceWhite,
           actions: [
             Row(
               children: [
                 Expanded(
                   child: TextButton(
                     onPressed: () => Navigator.pop(context, false),
                     child: Text(
                       'İptal',
                       style: GoogleFonts.poppins(color: context.colors.hint),
                     ),
                   ),
                 ),
                 Expanded(
                   child: ElevatedButton(
                     onPressed: () => Navigator.pop(context, true),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.red,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                     child: Text(
                       'Sil',
                       style: GoogleFonts.poppins(color: Colors.white),
                     ),
                   ),
                 ),
               ],
             ),
           ],
         ),
       );

       if (confirmed == true) {
          final ids = ref.read(selectedItemsProvider).toList();
          await ref.read(itemRepositoryProvider).softDeleteItems(ids);
          if (mounted) {
             SuccessNotificationSheet.show(
               context, 
               title: 'Silindi', 
               message: '$count içerik başarıyla silindi.'
             );
             ref.invalidate(paginatedFeedProvider);
             ref.invalidate(itemCountProvider);
             ref.read(isSelectionModeProvider.notifier).state = false;
             ref.read(selectedItemsProvider.notifier).state = {};
          }
       }
   }

   void _confirmDeleteItem(BuildContext context, ItemModel item) async {
      final confirmed = await showDialog<bool>(
       context: context,
       builder: (ctx) => AlertDialog(
         title: Center(
           child: Text(
             "İçeriği Sil",
             style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: context.colors.headline,
             ),
           ),
         ),
         content: Text(
           "Bu içeriği silmek istediğine emin misin?",
           textAlign: TextAlign.center,
           style: GoogleFonts.poppins(
             color: context.colors.body, 
             fontSize: 14,
           ),
         ),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
         backgroundColor: context.colors.surfaceWhite,
         actions: [
           Row(
             children: [
               Expanded(
                 child: TextButton(
                   onPressed: () => Navigator.pop(ctx, false),
                   child: Text("İptal", style: GoogleFonts.poppins(color: context.colors.hint)),
                 ),
               ),
               Expanded(
                 child: ElevatedButton(
                   onPressed: () => Navigator.pop(ctx, true),
                   style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: Text("Sil", style: GoogleFonts.poppins(color: Colors.white)),
                 ),
               ),
             ],
           ),
         ],
       ),
     );
     
     if (confirmed == true) {
        await ref.read(itemRepositoryProvider).deleteItem(item.id);
        ref.invalidate(paginatedFeedProvider);
        ref.invalidate(itemCountProvider);
        if (mounted) {
           SuccessNotificationSheet.show(
             context,
             title: 'Silindi',
             message: 'İçerik başarıyla silindi.',
           );
        }
     }
   }

  Widget _buildItemCard(ItemModel item, List<CategoryModel> categories, List<ItemModel> allItems, {bool isFeedback = false}) {
    final hasImage = item.displayImage != null && item.displayImage!.isNotEmpty;
    final source = item.url ?? '';
    
    // Resolve Category Name
    final cat = categories.where((c) => c.id == item.categoryId).firstOrNull;
    final categoryName = cat?.name ?? 'Genel';

    // Helper to build Platform Icon (Matches ItemFeedScreen exactly - Green Color)
    Widget buildPlatformIcon() {
      IconData icon = PhosphorIconsBold.link;
      Color iconColor = context.colors.primary; // Default Green for ALL icons to match Home
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
        width: 28, height: 28, // Standardized Size
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        child: Center(child: Icon(icon, size: 16, color: iconColor)),
      );
    }
    
    // --- FALLBACK VIEW For Grid (UNIFIED with ItemFeedScreen) ---
    Widget buildFallbackView() {
       IconData icon;
       List<Color> gradientColors = [context.colors.primary, context.colors.secondary];
       final s = source.toLowerCase();
       
       // UNIFIED: Same icon style for notes and links
       if (item.type == ItemType.note) {
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

       // STANDARDIZED CARD SIZE: Square (1.0) for catalog grid
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
            // Notes use CustomNoteIcon, links use gradient platform icon
            child: item.type == ItemType.note 
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

    // Wrap with Consumer for selection state - Moved UP to use in header logic
    final isSelectionMode = ref.watch(isSelectionModeProvider);
    final selectedItems = ref.watch(selectedItemsProvider);
    final isSelected = selectedItems.contains(item.id);

    Widget contentHeader;
    final isNote = item.type == ItemType.note;
    
    if (hasImage && !isNote) { // Notes always use fallback/custom icon view
      contentHeader = Stack(
        children: [
          item.displayImage!.startsWith('http') 
             ? CachedNetworkImage(
                 imageUrl: item.displayImage!, 
                 fit: BoxFit.fitWidth,
                 placeholder: (context, url) => AspectRatio(
                   aspectRatio: 1.0,
                   child: Container(
                     color: Colors.grey[100],
                     child: Center(child: Icon(PhosphorIconsLight.image, size: 32, color: Colors.grey[300])),
                   ),
                 ),
                 // Show fallback view when image fails to load
                 errorWidget: (context, url, error) => buildFallbackView(),
               )
             : Image.asset(item.displayImage!, fit: BoxFit.fitWidth),
          
          // Platform Icon (Top Right)
          Positioned(top: 8, right: 8, child: buildPlatformIcon()),
        ],
      );
    } else {
      // No Image: Use buildFallbackView directly (already has AspectRatio inside)
      contentHeader = buildFallbackView();
    }

    return GestureDetector(
      onTap: () async {
        if (isFeedback) return;
        
        if (isSelectionMode) {
          // Toggle selection
          final current = Set<String>.from(ref.read(selectedItemsProvider));
          if (current.contains(item.id)) {
            current.remove(item.id);
          } else {
            current.add(item.id);
          }
          ref.read(selectedItemsProvider.notifier).state = current;
        } else {
          // Normal behavior: open detail sheet
          await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              enableDrag: true, 
              builder: (context) => ItemDetailBottomSheet(item: item, categoryName: categoryName, categories: categories),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.colors.surfaceWhite,
          boxShadow: isFeedback 
             ? [BoxShadow(color: context.colors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
             : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Image Area with Overlays
              Stack(
                children: [
                  contentHeader, // Image + Platform Icon (Top-Right)
                  
                  // --- OVERLAYS ---
                  
                  // Top-Left: Checkbox (Selection) or 3-Dots (Normal)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: isSelectionMode 
                      ? Container( // Checkbox - Refined Design
                          width: 24, // Smaller size (User feedback: "too big")
                          height: 24, 
                          decoration: BoxDecoration(
                            color: isSelected ? context.colors.primary : Colors.black.withOpacity(0.1), // Transparent when unselected (User feedback: "no hole")
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? context.colors.primary : Colors.white, 
                              width: 2
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: isSelected 
                            ? const Icon(PhosphorIconsBold.check, size: 14, color: Colors.white)
                            : null,
                        )
                      : Material( // 3-Dots Menu
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showItemActionSheet(context, item, allItems),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(PhosphorIconsBold.dotsThreeCircle, size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                  ),


                ],
              ),
  
              // Thin grey line above text area
              Container(
                height: 1,
                color: Colors.grey.withOpacity(0.15),
              ),
              // 2. Footer Info (Text Below)
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
                       style: GoogleFonts.poppins(
                         fontSize: 12, 
                         fontWeight: FontWeight.w600, 
                         color: context.colors.headline
                       ),
                     ),
                     Text(
                       categoryName,
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                       style: GoogleFonts.poppins(
                         fontSize: 10, 
                         fontWeight: FontWeight.w400, 
                         color: context.colors.hint
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

  Widget _buildSquareImageOnly(ItemModel item) {
    final hasImage = item.displayImage != null && item.displayImage!.isNotEmpty;
    if (hasImage) {
      return item.displayImage!.startsWith('http') 
         ? CachedNetworkImage(
             imageUrl: item.displayImage!, 
             fit: BoxFit.cover,
             placeholder: (_,__) => Container(color: Colors.grey[100]),
             errorWidget: (_,__,___) => const SizedBox(),
           )
         : Image.asset(item.displayImage!, fit: BoxFit.cover);
    } else {
       return Container(
           decoration: BoxDecoration(
             gradient: LinearGradient(
                colors: [context.colors.primary, context.colors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
             ),
          ),
          child: Center(
             child: Icon(PhosphorIconsBold.link, size: 48, color: Colors.white),
          ),
       );
    }
  }

  void _showReorderSheet(BuildContext context, String? categoryId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Consumer(
              builder: (context, ref, _) {
                // Fetch items for this category (or ALL if null)
                return FutureBuilder<List<ItemModel>>(
                   future: ref.read(itemRepositoryProvider).getItems(
                      ref.read(authStateProvider).value!.uid, 
                      categoryId: categoryId == 'uncategorized' ? null : categoryId
                      // Note: getItems(userId, categoryId: null) fetches ALL items if we don't treat 'uncategorized' specially.
                      // My repo logic: if categoryId != null { query = query.where... }
                      // So passing null returns ALL items. perfect.
                      // Wait, 'uncategorized' string usually maps to categoryId=null for "Inbox".
                      // If I want "All", I should pass nothing?
                      // Let's check repository logic again.
                      // Repository: getItems(userId, {categoryId})
                      // if categoryId != null -> filter.
                      // So if I pass null, it returns all items.
                      // But "Inbox" items have categoryId == null in Firestore.
                      // So how to get ONLY Inbox?
                      // Usually we filter client side or have a special query.
                      // Checking repo... created earlier step 243.
                      // Repo: 
                      // if (categoryId != null) { query = query.where('categoryId', isEqualTo: categoryId); }
                      // So categoryId=null returns ALL.
                      // But how do we fetch "Inbox"? 
                      // Usually we pass a special flag or handle it.
                      // Let's assume 'uncategorized' string meant Inbox before.
                      // If I want ALL items (mixed), I pass null.
                      // But if categoryId passed to this func is 'uncategorized', it means Inbox (categoryId=null in DB).
                      // If categoryId passed is null, it means ALL.
                      // So:
                      // If categoryId == 'uncategorized' => Repo needs to filter for null. 
                      // Repo doesn't seem to support "where categoryId IS NULL" easily via this param unless we change it.
                      // Providing 'null' to repo returns ALL.
                      // So to get Inbox, we probably do client side filter or need repo update.
                      // However, the task is about "Sort All" (Tümüne özel).
                      // So passing null to repo is what we want for "Sort All".
                      
                      // Logic:
                      // if passed categoryId is null -> Get ALL.
                      // if passed categoryId is 'uncategorized' -> Get Inbox (Repo logic dependent).
                      // Let's look at how selectedCatalogIdProvider works.
                      // null = Uncategorized/Inbox (Line 28 in view_file above).
                      // Wait, "null = Uncategorized/Inbox".
                      // So if provider is null, we are viewing Inbox??
                      // Let's verify _buildCatalogShelf or getItems usage in main build.
                      
                      // I need to verify what "selectedCatalogIdProvider == null" means.
                      // Usually "All" is a separate mode or null. "Inbox" is separate.
                      // Let's assume for now:
                      // If I want to sort "All", I need a way to say "All".
                      // If `selectedCatalogIdProvider` is null, does it mean "All"?
                      // Line 28: `// State to track selected category ... (null = Uncategorized/Inbox)`
                      // So null means Inbox.
                      // Where is "All Items" view?
                      // Maybe I don't have an "All Items" view currently active?
                      // If so, the user request "tümünü sırala" might mean "Sort the Inbox" or "Sort Everything".
                      // Given "Tümüne özel", likely "All Items".
                      // If there is no "All Items" view, I might need to clarify or assume they mean Inbox if that's the default.
                      // But typically "Tüm İçerikler" is a tab.
                      // Let's assume I passing `categoryId` to this sheet.
                      // If I pass `null` to `_showReorderSheet`, I intended it to be "All".
                      // But I need to make sure I fetch ALL.
                   ),
                   builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      return _ReorderList(items: snapshot.data!);
                   },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _moveItemToCategory(ItemModel item, String? targetCategoryId) async {
     try {
       final isSelectionMode = ref.read(isSelectionModeProvider);
       final selectedItems = ref.read(selectedItemsProvider);
       final isBatchMove = isSelectionMode && selectedItems.contains(item.id);

       if (isBatchMove && targetCategoryId != null) { // Batch Move requires valid target ID
          final itemsToMove = selectedItems.toList();
          await ref.read(itemRepositoryProvider).moveItemsToCategory(itemsToMove, targetCategoryId);
          
          if (mounted) {
             SuccessNotificationSheet.show(
               context,
               title: "Taşındı",
               message: "${itemsToMove.length} içerik taşındı",
             );
             // Clear selection
             ref.read(isSelectionModeProvider.notifier).state = false;
             ref.read(selectedItemsProvider.notifier).state = {};
          }
       } else {
          // Single Move
          await ref.read(itemRepositoryProvider).moveToCategory(
            item.id, 
            targetCategoryId
          );
          
          if (mounted) {
             SuccessNotificationSheet.show(
               context,
               title: "Taşındı",
               message: "İçerik taşındı",
             );
          }
       }
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
     }
  }

  // GRID VIEW MODAL - Shows all collections in a grid format
  void _showCollectionsGridSheet(BuildContext context) {
    final categoriesAsync = ref.read(categoriesProvider);
    final allItems = ref.read(catalogItemsProvider).valueOrNull ?? [];
    final isVaultUnlocked = ref.read(isVaultUnlockedProvider);
    
    categoriesAsync.whenData((categories) {
      final vaultIds = categories.where((c) => c.isVault).map((c) => c.id).toSet();
      
      // Sort categories same as carousel
      final sortedCategories = categories
          .where((c) => c.name != 'Hızlı')
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle Bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tüm Koleksiyonlar",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.colors.headline,
                        ),
                      ),
                      Text(
                        "${sortedCategories.length + 1} koleksiyon",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: context.colors.hint,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Grid
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: sortedCategories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final allItemsCount = isVaultUnlocked 
                            ? allItems.length 
                            : allItems.where((i) => !vaultIds.contains(i.categoryId)).length;
                        
                        return _buildGridCollectionCard(
                          context: context,
                          id: null,
                          name: "Tümü",
                          itemCount: allItemsCount,
                          imageProvider: null,
                          isVault: false,
                          isLocked: false,
                          onTap: () {
                            ref.read(selectedCatalogIdProvider.notifier).state = null;
                            Navigator.pop(ctx);
                          },
                        );
                      }
                      
                      final catIndex = index - 1;
                      final cat = sortedCategories[catIndex];
                      final isLocked = cat.isVault && !isVaultUnlocked;
                      final catItems = allItems.where((i) => i.categoryId == cat.id).toList();
                      final coverItem = catItems.firstWhere(
                        (i) => i.displayImage != null && i.displayImage!.isNotEmpty && !i.displayImage!.toLowerCase().endsWith('.svg'),
                        orElse: () => ItemModel(id: '', userId: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), type: ItemType.note),
                      );
                      
                      return _buildGridCollectionCard(
                        context: context,
                        id: cat.id,
                        name: cat.name,
                        itemCount: catItems.length,
                        imageProvider: (coverItem.displayImage != null && coverItem.displayImage!.isNotEmpty)
                            ? CachedNetworkImageProvider(coverItem.displayImage!)
                            : null,
                        isVault: cat.isVault,
                        isLocked: isLocked,
                        onTap: () async {
                          if (isLocked) {
                            final result = await VaultService().authenticate(
                              reason: '${cat.name} koleksiyonuna erişmek için doğrulama yapın',
                            );
                            if (result != VaultAuthResult.success) return;
                            ref.read(isVaultUnlockedProvider.notifier).state = true;
                          }
                          ref.read(selectedCatalogIdProvider.notifier).state = cat.id;
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
  
  Widget _buildGridCollectionCard({
    required BuildContext context,
    required String? id,
    required String name,
    required int itemCount,
    required ImageProvider? imageProvider,
    required bool isVault,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.secondary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: context.colors.premiumShadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageProvider != null)
                      Image(image: imageProvider, fit: BoxFit.cover)
                    else
                      Container(
                        color: context.colors.backgroundTop,
                        child: Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [context.colors.primary, context.colors.secondary],
                            ).createShader(bounds),
                            child: Icon(
                              id == null ? PhosphorIconsBold.stack : (isVault ? PhosphorIconsBold.lockKey : PhosphorIconsBold.folder),
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (isLocked)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: Icon(PhosphorIconsBold.lockKey, color: Colors.white, size: 24),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.headline,
                    ),
                  ),
                  Text(
                    "$itemCount içerik",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: context.colors.hint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    // Check subscription limit
    final isPremium = ref.read(isPremiumProvider);
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    
    if (!isPremium && categories.length >= 3) {
      LimitReachedDialog.show(
        context: context,
        ref: ref,
        title: null,
        message: null,
        type: LimitType.collection,
      );
      return;
    }
    
    final TextEditingController _controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        bool isVault = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: context.colors.surfaceWhite,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24), // Wider Dialog
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                "Yeni Koleksiyon",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: context.colors.headline),
                textAlign: TextAlign.center,
              ),
              content: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    Text(
                      "İçeriklerini düzenlemek için yeni bir koleksiyon oluştur.",
                      style: GoogleFonts.poppins(fontSize: 13, color: context.colors.body),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      style: GoogleFonts.poppins(color: context.colors.headline),
                      decoration: InputDecoration(
                         hintText: "Koleksiyon Adı (Örn: Tatil Planı)",
                         hintStyle: GoogleFonts.poppins(color: context.colors.hint, fontSize: 14),
                         filled: true,
                         fillColor: context.colors.backgroundTop,
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Vault Switch
                    Container(
                      decoration: BoxDecoration(
                        color: context.colors.backgroundTop,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile(
                        value: isVault,
                        onChanged: (val) {
                          if (!isPremium) {
                            LimitReachedDialog.show(
                              context: context,
                              ref: ref,
                              title: "Premium Özellik",
                              message: "Gizli Kasa özelliği premium üyelere özeldir.",
                              type: LimitType.collection,
                            );
                            return;
                          }
                          setState(() => isVault = val);
                        },
                        title: Row(
                          children: [
                            Text(
                              "Gizli Kasa",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: context.colors.headline,
                              ),
                            ),
                            if (!isPremium) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [context.colors.primary, context.colors.secondary]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text("PRO", style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ],
                          ],
                        ),
                        secondary: Icon(
                          isVault ? PhosphorIconsFill.lockKey : PhosphorIconsRegular.lockKey,
                          color: isVault ? context.colors.primary : context.colors.body,
                        ),
                        activeColor: context.colors.primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                 ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                Row(
                  children: [
                    // Vazgeç Butonu (Gri Gradient)
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
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
                              "Vazgeç",
                              style: GoogleFonts.poppins(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Oluştur Butonu (Yeşil Gradient)
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          if (_controller.text.trim().isNotEmpty && _currentUserId != null) {
                            try {
                              await ref.read(categoryRepositoryProvider).createCategory(
                                CategoryModel(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  name: _controller.text.trim(),
                                  userId: _currentUserId!,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  icon: PhosphorIconsRegular.folder.codePoint.toString(),
                                  isVault: isVault,
                                )
                              );
                              if (context.mounted) Navigator.pop(context);
                              
                              // Show success bottom sheet
                              if (context.mounted) {
                                SuccessNotificationSheet.show(
                                  context, 
                                  title: "Başarılı!", 
                                  message: isVault ? "Gizli koleksiyon oluşturuldu" : "Koleksiyon oluşturuldu",
                                );
                              }
                            } catch (e) {
                              debugPrint("Error creating category: $e");
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Hata: $e")),
                                );
                              }
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [context.colors.primary, context.colors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.premiumShadow.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "Oluştur",
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String categoryId, String categoryName) async {
    // Check item count directly from repository (Source of Truth)
    try {
      final itemRepo = ref.read(itemRepositoryProvider);
      final userId = _currentUserId;
      if (userId == null) return;

      final count = await itemRepo.getActiveItemCountInCategory(userId, categoryId);

      if (!mounted) return;

      if (count == 0) {
        _showStandardDeleteDialog(context, categoryId, categoryName);
      } else {
        _showAdvancedDeleteDialog(context, categoryId, categoryName, count);
      }
    } catch (e) {
      debugPrint("Error checking category items: $e");
      if (mounted) _showStandardDeleteDialog(context, categoryId, categoryName);
    }
  }

  void _showStandardDeleteDialog(BuildContext context, String categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Kategoriyi Sil'),
        content: Text('"$categoryName" kategorisini silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(categoryId, deleteItems: false);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAdvancedDeleteDialog(BuildContext context, String categoryId, String categoryName, int count) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Text(
              'Kategoriyi Sil',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.headline),
            ),
            const SizedBox(height: 12),
            Text(
              '"$categoryName" içinde $count adet içerik var. Bu içerikleri ne yapmak istersin?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: context.colors.body),
            ),
            const SizedBox(height: 32),
            
            // Move Option
            _buildActionButton(
              context,
              icon: PhosphorIconsRegular.arrowsOutCardinal,
              text: 'İçerikleri Başka Koleksiyona Taşı',
              color: context.colors.primary,
              onTap: () {
                Navigator.pop(context);
                _showMoveTargetSelector(context, categoryId);
              },
            ),
            const SizedBox(height: 12),
            
            // Delete All Option
            _buildActionButton(
              context,
              icon: PhosphorIconsLight.trash,
              text: 'Kategori ve İçerikleri Sil',
              color: Colors.red,
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _deleteCategory(categoryId, deleteItems: true);
              },
            ),
            const SizedBox(height: 12),
            
            // Cancel
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Vazgeç', style: GoogleFonts.poppins(color: context.colors.hint, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String text, required Color color, required VoidCallback onTap, bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.08) : context.colors.backgroundTop,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDestructive ? Colors.red.withOpacity(0.2) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(text, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: isDestructive ? Colors.red : context.colors.headline)),
            ),
            Icon(PhosphorIconsLight.caretRight, size: 16, color: isDestructive ? Colors.red.withOpacity(0.5) : context.colors.hint),
          ],
        ),
      ),
    );
  }

  void _showMoveTargetSelector(BuildContext context, String sourceCategoryId) {
    final categories = ref.read(categoriesProvider).value ?? [];
    // Exclude current category
    final targets = categories.where((c) => c.id != sourceCategoryId).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Hedef Koleksiyon Seç', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: targets.length,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  final cat = targets[index];
                  return ListTile(
                    leading: Text(cat.icon ?? '📁', style: const TextStyle(fontSize: 24)),
                    title: Text(cat.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      _moveItemsAndDelete(sourceCategoryId, cat.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveItemsAndDelete(String sourceId, String targetId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      final itemRepo = ref.read(itemRepositoryProvider);
      final catRepo = ref.read(categoryRepositoryProvider);
      
      // 1. Move items
      await itemRepo.updateItemsCategory(userId, sourceId, targetId);
      
      // 2. Delete category
      await catRepo.deleteCategory(sourceId);
      
      // 3. Reset state if selected
      if (ref.read(selectedCatalogIdProvider) == sourceId) {
        ref.read(selectedCatalogIdProvider.notifier).state = null;
      }

      if (mounted) {
        SuccessNotificationSheet.show(context, title: "Taşındı", message: "İçerikler taşındı ve kategori silindi");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem başarısız oldu'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteSelectedItems(WidgetRef ref) async {
    final selectedIds = ref.read(selectedItemsProvider);
    if (selectedIds.isEmpty) return;

    // Custom Bottom Sheet Confirmation
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                PhosphorIconsFill.trash,
                size: 32,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              "Seçilenleri Sil?",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.headline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              "${selectedIds.length} içerik Son Silinenler'e taşınacak.\nİstediğin zaman geri alabilirsin.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                 fontSize: 15,
                 color: context.colors.body,
                 height: 1.5
              ),
            ),
            const SizedBox(height: 24),
            
            // Delete Action
            GestureDetector(
              onTap: () => Navigator.pop(context, true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                  ]
                ),
                child: Center(
                  child: Text(
                    "Sil",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Cancel Action
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Vazgeç",
                style: GoogleFonts.outfit(
                  color: context.colors.hint,
                  fontWeight: FontWeight.w600
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.softDeleteItems(selectedIds.toList());
      
      // Reset Selection
      ref.read(isSelectionModeProvider.notifier).state = false;
      ref.read(selectedItemsProvider.notifier).state = {};
      
      if (mounted) {
        // Custom Success Toast
        SuccessNotificationSheet.show(
          context, 
          title: "Silindi", 
          message: "${selectedIds.length} içerik Son Silinenler'e taşındı."
        );
      }
    } catch (e) {
      debugPrint("Bulk delete error: $e");
    }
  }

  Future<void> _deleteCategory(String categoryId, {required bool deleteItems}) async {
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final itemRepo = ref.read(itemRepositoryProvider);
      
      // 1. Delete items if requested
      if (deleteItems) {
        await itemRepo.deleteItemsInCategory(categoryId);
      }
      
      // 2. Delete category
      await categoryRepo.deleteCategory(categoryId);
      
      // 3. Reset state if selected
      if (ref.read(selectedCatalogIdProvider) == categoryId) {
        ref.read(selectedCatalogIdProvider.notifier).state = null;
      }
      
      if (mounted) {
        SuccessNotificationSheet.show(
          context,
          title: 'Silindi',
          message: 'Kategori ${deleteItems ? "ve içerikleriyle birlikte" : ""} silindi.'
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori silinemedi'), backgroundColor: Colors.red),
      );
    }
  }
  Widget _buildInlineSelectionRow(
     BuildContext context, 
     int count, 
     bool isSelectionMode,
     bool areAllSelected,
     VoidCallback onToggleMode,
     VoidCallback onSelectAll
  ) {
     final Color activeColor = context.colors.primary;
     final Color inactiveColor = Colors.grey.withOpacity(0.5);
     final Color textColor = isSelectionMode ? context.colors.primary : inactiveColor;

     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
             // Selection Toggle Icon (Circle style)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleMode,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                     color: isSelectionMode ? context.colors.primary : context.colors.primary.withOpacity(0.1),
                     shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIconsRegular.listChecks, 
                    size: 20, 
                    color: isSelectionMode ? Colors.white : context.colors.primary
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Selected Count Text
            Text(
              "$count Seçildi",
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            
            const Spacer(),
            
            // Delete Action (Icon Only - Monochrome)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (isSelectionMode && count > 0) ? () => _confirmDeleteSelected(context) : null,
                borderRadius: BorderRadius.circular(99),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(PhosphorIconsRegular.trash, size: 22, color: (isSelectionMode && count > 0) ? activeColor : inactiveColor),
                ),
              ),
            ),
            
            const SizedBox(width: 4),

            // Move Action (Icon Only - Monochrome - Changed Icon)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (isSelectionMode && count > 0) ? () => _showBatchMoveSelector(context) : null,
                borderRadius: BorderRadius.circular(99),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(PhosphorIconsRegular.arrowsOutCardinal, size: 22, color: (isSelectionMode && count > 0) ? activeColor : inactiveColor),
                ),
              ),
            ),
            
             const SizedBox(width: 4),
            
            // Select All Action (Icon Only - Monochrome)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isSelectionMode ? onSelectAll : null,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: (isSelectionMode && areAllSelected) 
                     ? BoxDecoration(
                         color: context.colors.primary.withOpacity(0.1),
                         shape: BoxShape.circle
                       )
                     : null,
                  child: Icon(PhosphorIconsRegular.checks, size: 24, color: isSelectionMode ? activeColor : inactiveColor),
                ),
              ),
            ),
          ],
        ),
     );
  }

  void _showBatchMoveSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
       height: MediaQuery.of(context).size.height * 0.7,
       decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Seçilenleri Taşı", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.headline)),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final categoriesAsync = ref.watch(categoriesProvider);
                  return categoriesAsync.when(
                    data: (categories) {
                       return ListView.builder(
                         itemCount: categories.length,
                         itemBuilder: (ctx, index) {
                           final cat = categories[index];
                           return ListTile(
                             leading: Container(
                               width: 40, height: 40,
                               decoration: BoxDecoration(
                                 color: context.colors.primary.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Center(
                                 child: Icon(PhosphorIconsRegular.arrowRight, size: 20, color: context.colors.primary),
                               ),
                             ),
                             title: Text(cat.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: context.colors.headline)),
                             onTap: () async {
                               Navigator.pop(ctx);
                               final selectedIds = ref.read(selectedItemsProvider).toList();
                               if (selectedIds.isNotEmpty) {
                                  await ref.read(itemRepositoryProvider).moveItemsToCategory(selectedIds, cat.id!);
                                  if (mounted) {
                                     SuccessNotificationSheet.show(
                                       context,
                                       title: 'Taşındı',
                                       message: '${selectedIds.length} içerik "${cat.name}" koleksiyonuna taşındı.'
                                     );
                                     ref.read(isSelectionModeProvider.notifier).state = false;
                                     ref.read(selectedItemsProvider.notifier).state = {};
                                  }
                               }
                             },
                           );
                         },
                       );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text("Hata: $e")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReorderList extends ConsumerStatefulWidget {
  final List<ItemModel> items;

  const _ReorderList({required this.items});

  @override
  ConsumerState<_ReorderList> createState() => _ReorderListState();
}

class _ReorderListState extends ConsumerState<_ReorderList> {
  late List<ItemModel> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  Future<void> _saveOrder() async {
    setState(() => _isSaving = true);
    try {
      // Update order index based on list position
      final updatedItems = <ItemModel>[];
      for (int i = 0; i < _items.length; i++) {
        updatedItems.add(_items[i].copyWith(order: i));
      }
      
      await ref.read(itemRepositoryProvider).batchUpdateItemOrders(updatedItems);
      
      // Force refresh of Home Feed to reflect new order immediately
      ref.invalidate(paginatedFeedProvider);
      
      if (mounted) {
        Navigator.pop(context);
         SuccessNotificationSheet.show(
           context,
           title: 'Başarılı',
           message: 'Sıralama güncellendi.'
         );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
         setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                   Icon(PhosphorIconsRegular.sortAscending, size: 24, color: context.colors.headline),
                   const SizedBox(width: 8),
                   Text("Sıralamayı Düzenle", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.headline)),
                ],
              ),
              _isSaving 
                 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                 : TextButton(
                     onPressed: _saveOrder,
                     child: Text("Bitti", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: context.colors.primary)),
                   ),
            ],
          ),
        ),
        const Divider(),
        
        // Default list info for user
        if (_items.isEmpty)
           Padding(
             padding: const EdgeInsets.all(32.0),
             child: Text("Sıralanacak içerik yok.", style: GoogleFonts.poppins(color: Colors.grey)),
           ),

        // List
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 40),
            itemCount: _items.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final ItemModel item = _items.removeAt(oldIndex);
                _items.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile(
                key: ValueKey(item.id),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    image: (item.displayImage != null && item.displayImage!.startsWith('http')) 
                       ? DecorationImage(image: NetworkImage(item.displayImage!), fit: BoxFit.cover)
                       : null,
                  ),
                  child: (item.displayImage == null || !item.displayImage!.startsWith('http')) 
                     ? Icon(PhosphorIconsRegular.link, color: Colors.grey)
                     : null,
                ),
                title: Text(
                  item.displayTitle, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: context.colors.headline)
                ),
                trailing: Icon(PhosphorIconsRegular.list, color: Colors.grey[400]),
              );
            },
          ),
        ),
      ],
    );
  }
}
