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
      floatingActionButton: ref.watch(isSelectionModeProvider) 
        ? FloatingActionButton.extended(
            onPressed: () {
               final selectedCount = ref.read(selectedItemsProvider).length;
               if (selectedCount > 0) {
                 _deleteSelectedItems(ref);
               } else {
                 // Exit Selection Mode
                 ref.read(isSelectionModeProvider.notifier).state = false;
                 HapticFeedback.lightImpact();
               }
            },
            backgroundColor: ref.watch(selectedItemsProvider).isNotEmpty ? Colors.red : context.colors.primary,
            icon: Icon(
              ref.watch(selectedItemsProvider).isNotEmpty ? PhosphorIconsFill.trash : PhosphorIconsBold.x, 
              color: Colors.white
            ),
            label: Text(
              ref.watch(selectedItemsProvider).isNotEmpty 
                ? "Sil (${ref.watch(selectedItemsProvider).length})"
                : "Vazgeç",
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        : null,
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
                       // SELECTION MODE TOGGLE (Trash Icon)
                       GestureDetector(
                        onTap: () {
                          final isSelection = ref.read(isSelectionModeProvider);
                          final selectedItems = ref.read(selectedItemsProvider);

                          if (isSelection) {
                             if (selectedItems.isNotEmpty) {
                                // If items selected -> Trigger Delete Logic
                                _deleteSelectedItems(ref);
                             } else {
                                // If empty -> Cancel selection mode
                                ref.read(isSelectionModeProvider.notifier).state = false;
                                ref.read(selectedItemsProvider.notifier).state = {};
                             }
                          } else {
                             // Start selection
                             ref.read(isSelectionModeProvider.notifier).state = true;
                          }
                        },
                        child: Container(
                           padding: const EdgeInsets.all(8),
                           margin: const EdgeInsets.only(right: 12),
                           decoration: BoxDecoration(
                             color: ref.watch(isSelectionModeProvider) 
                                ? Colors.red.withOpacity(0.1) 
                                : context.colors.primary.withOpacity(0.1),
                             shape: BoxShape.circle,
                           ),
                           child: Icon(
                             ref.watch(isSelectionModeProvider) ? PhosphorIconsFill.trash : PhosphorIconsRegular.trash, 
                             size: 20, 
                             color: ref.watch(isSelectionModeProvider) ? Colors.red : context.colors.primary
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
            
            SizedBox(
              height: 140, // Height increased for new cards
              child: itemsAsync.when(
                 data: (items) => _buildCatalogShelf(categoriesAsync, selectedId, items, isReordering),
                 loading: () => const Center(child: SizedBox()),
                 error: (_,__) => const SizedBox(),
              ),
            ),

            const SizedBox(height: 24), // Increased spacing per user request

            // Explanation Capsule
            if (!isReordering)
            Center(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.colors.primary.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.handGrabbing, size: 16, color: context.colors.primary.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "İçerikleri basılı tutup istediğin koleksiyona taşıyabilirsin",
                          maxLines: 1,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.colors.primary.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Divider (Subtle)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: context.colors.hint.withOpacity(0.2)),
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
          child: Row(
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
              
              // 2. Reorderable user categories OR Static ListView
              Expanded(
                child: isReordering 
                ? ReorderableListView.builder(
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
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 8, right: 20),
                    itemCount: sortedCategories.length,
                    itemBuilder: (context, index) {
                      final cat = sortedCategories[index];
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
              ),
            ],
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
                colorFilter: isSelected 
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
            angle: 0.1,
            child: SizedBox(
               width: 90, 
               height: 90, // Smaller feedback (User Request)
               child: Material(
                 color: Colors.transparent,
                 borderRadius: BorderRadius.circular(16),
                 elevation: 8,
                 shadowColor: Colors.black.withOpacity(0.2),
                 child: ClipRRect(
                   borderRadius: BorderRadius.circular(16),
                   child: _buildSquareImageOnly(item), // New helper
                 ),
               )
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3, 
            child: _buildItemCard(item, categories) // Placeholder
          ),
          child: _buildItemCard(item, categories),
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

  Widget _buildItemCard(ItemModel item, List<CategoryModel> categories, {bool isFeedback = false}) {
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
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, size: 14, color: iconColor)),
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
          
          Positioned(top: 8, right: 8, child: buildPlatformIcon()),
        ],
      );
    } else {
      // No Image: Use buildFallbackView directly (already has AspectRatio inside)
      contentHeader = buildFallbackView();
    }

    // Wrap with Consumer for selection state
    final isSelectionMode = ref.watch(isSelectionModeProvider);
    final selectedItems = ref.watch(selectedItemsProvider);
    final isSelected = selectedItems.contains(item.id);

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
      child: Stack(
        children: [
          Container(
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
              // 1. Image / Fallback Header
              contentHeader,
  
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
      
      // Selection Checkbox Overlay
      if (isSelectionMode)
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? context.colors.primary : Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.primary, width: 2),
            ),
            child: isSelected 
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
          ),
        ),
      ],
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

  // --- LOGIC: CREATE, MOVE, DELETE ---

  void _moveItemToCategory(ItemModel item, String? targetCategoryId) async {
     try {
       await ref.read(itemRepositoryProvider).moveToCategory(
         item.id, 
         targetCategoryId
       );
       
       // Optional: Haptic feedback here
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text("İçerik taşındı", style: GoogleFonts.poppins()), 
           backgroundColor: context.colors.primary,
           duration: const Duration(milliseconds: 1000),
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
         ),
       );
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
     }
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
              icon: PhosphorIconsLight.folderPlus,
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori ${deleteItems ? "ve içerikler" : ""} silindi'), backgroundColor: context.colors.primary),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori silinemedi'), backgroundColor: Colors.red),
      );
    }
  }
}
