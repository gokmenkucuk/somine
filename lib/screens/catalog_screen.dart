import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/core/design/app_colors.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/widgets/item_detail_bottom_sheet.dart';
import 'dart:ui';

// State to track selected category in Catalog Screen (null = Uncategorized/Inbox)
final selectedCatalogIdProvider = StateProvider.autoDispose<String?>((ref) => null);

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  // Get current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  final ScrollController _scrollController = ScrollController();

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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Soft background
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
                      color: AppColors.headline
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddCategoryDialog,
                    child: Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: AppColors.primary.withOpacity(0.1),
                         shape: BoxShape.circle,
                       ),
                       child: Icon(PhosphorIconsRegular.plus, size: 20, color: AppColors.primary),
                    ),
                  )
                ],
              ),
            ),
            
            SizedBox(
              height: 140, // Height increased for new cards
              child: itemsAsync.when(
                 data: (items) => _buildCatalogShelf(categoriesAsync, selectedId, items),
                 loading: () => const Center(child: SizedBox()),
                 error: (_,__) => const SizedBox(),
              ),
            ),

            const SizedBox(height: 24), // Increased spacing per user request

            // Explanation Capsule
            Center(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.handGrabbing, size: 16, color: AppColors.primary.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text(
                      "İçerikleri basılı tutup istediğin koleksiyona taşıyabilirsin",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Divider (Subtle)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Colors.grey.shade200),
            ),

            // 3. Main Content
            Expanded(
              child: itemsAsync.when(
                 data: (items) => categoriesAsync.when(
                    data: (categories) => _buildBody(selectedId, items, categories),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_,__) => _buildBody(selectedId, items, []), // Fallback
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
  // Helper
  Widget _buildBody(String? selectedId, List<ItemModel> allItems, List<CategoryModel> categories) {
     final filteredItems = allItems.where((item) {
       if (selectedId == null) {
         return true; // Show ALL items
       }
       if (selectedId == 'uncategorized') {
         return item.categoryId == null || item.categoryId!.isEmpty;
       }
       return item.categoryId == selectedId;
     }).toList();
     
     return _buildItemGrid(filteredItems, categories);
  }

  // --- CATALOG SHELF ---

  Widget _buildCatalogShelf(AsyncValue<List<CategoryModel>> categoriesAsync, String? selectedId, List<ItemModel> allItems) {
    return categoriesAsync.when(
      data: (categories) {
        final uncategorizedCount = allItems.where((i) => i.categoryId == null || i.categoryId!.isEmpty).length;

        return ListView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          children: [
            // 1. All Items (Tümü) - Oil Green -> White Gradient
            _buildImageCatalogCard(
              id: null, // null = All
              name: "Tümü",
              imageProvider: null, 
              isSelected: selectedId == null,
              isSystem: true,
              itemCount: allItems.length,
            ),
            
            // 2. Quick Saves (Inbox) - Show ONLY if has items
            if (uncategorizedCount > 0)
              _buildImageCatalogCard(
                id: 'uncategorized',
                name: "HIZLI", 
                imageProvider: null, 
                isSelected: selectedId == 'uncategorized',
                isSystem: true,
                itemCount: uncategorizedCount,
              ),
            
            // 3. User Categories
            ...categories.map((cat) {
              // Find latest image for this category
              final catItems = allItems.where((i) => i.categoryId == cat.id).toList();
              final coverItem = catItems.firstWhere(
                (i) => i.displayImage != null && i.displayImage!.isNotEmpty,
                orElse: () => ItemModel(id: '', userId: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), type: ItemType.note), 
              );
              
              return _buildImageCatalogCard(
                id: cat.id,
                name: cat.name,
                imageProvider: (coverItem.displayImage != null && coverItem.displayImage!.isNotEmpty) 
                    ? CachedNetworkImageProvider(coverItem.displayImage!) 
                    : null,
                isSelected: selectedId == cat.id,
                onLongPress: () => _showEditCategoryOptions(context, cat.id!, cat.name), // New Options
                // We are passing 'count' here but signature likely still expects 'itemCount'. This is risky if signature not updated.
                // Assuming next step updates signature. I'll use itemCount here to be safe if next step fails, but next step WILL update signature.
                // Actually, let's keep it as I intended: update signature to accept 'count' or 'itemCount' (keeping original name is safer).
                // I'll stick to 'itemCount' here to match existing signature, then update logic to use onLongPress.
                itemCount: catItems.length,
              );
            }),
          ],
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
    required int itemCount,
    VoidCallback? onLongPress, // New param
  }) {
    return DragTarget<ItemModel>(
      onWillAccept: (item) => item != null && item.categoryId != id,
      onAccept: (item) => _moveItemToCategory(item, id),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        
        // --- SHELF CARD DECORATION LOGIC ---
        BoxDecoration boxDecoration;
        Widget? childContent;

        // Hover Effect: Stronger Border & Glow
        final hoverBorder = Border.all(color: AppColors.primary, width: 3);
        final hoverShadow = BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4));

        if (imageProvider != null) {
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
                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 8))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))]),
              border: isHovered 
                  ? hoverBorder // Accent Border on Hover
                  : (isSelected 
                      ? Border.all(color: AppColors.primary, width: 2) 
                      : Border.all(color: Colors.white.withOpacity(0.2), width: 1)),
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
              
              const primaryGradient = LinearGradient(
                  colors: [AppColors.primary, Color(0xFF6FBFAC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
              );

              if (isSelected) {
                 return GestureDetector(
                   onTap: () => ref.read(selectedCatalogIdProvider.notifier).state = id,
                   child: AnimatedContainer(
                     duration: const Duration(milliseconds: 300),
                     width: 120,
                     margin: const EdgeInsets.only(right: 12),
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(24), // Outer radius
                       gradient: primaryGradient, // Border Gradient
                       boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 6))],
                     ),
                     padding: const EdgeInsets.all(2.5), // Border Width
                     child: Container(
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(21),
                         color: Colors.white, // Gap color
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
                   onTap: () => ref.read(selectedCatalogIdProvider.notifier).state = id,
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
                   onTap: () => ref.read(selectedCatalogIdProvider.notifier).state = id,
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
                         color: Colors.white, // Contrast Gap
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
                   onTap: () => ref.read(selectedCatalogIdProvider.notifier).state = id,
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
             onTap: () => ref.read(selectedCatalogIdProvider.notifier).state = id,
             onLongPress: onLongPress ?? (() => _showDeleteConfirmationDialog(id!, name)), // Use override or default
             child: AnimatedContainer(
               duration: const Duration(milliseconds: 300),
               width: 120,
               margin: const EdgeInsets.only(right: 12),
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(20),
                 gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6FBFAC)], // Oil Green Gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                 ),
                 boxShadow: isHovered
                    ? [hoverShadow]
                    : (isSelected 
                        ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 6))]
                        : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
                 // Make border appear thicker on hover by increasing padding
               ),
               padding: EdgeInsets.all(isHovered ? 4 : 2), 
               child: Container(
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(18), 
                 ),
                 child: _buildShelfLabel(name, itemCount, isDarkBg: false, isSystem: false, isSelected: isSelected),
               ),
             ),
           );
        }

        return GestureDetector(
          onTap: () => ref.read(selectedCatalogIdProvider.notifier).state = id,
          onLongPress: isSystem 
              ? null 
              : (onLongPress ?? () => _showDeleteConfirmationDialog(id!, name)), // Use override or default
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
     Color textColor = isDarkBg ? Colors.white : AppColors.headline;
     Color badgeBg = isDarkBg ? Colors.white.withOpacity(0.9) : const Color(0xFFF3F4F6);
     Color badgeText = isDarkBg ? Colors.black : AppColors.headline;
     
     return Stack(
       children: [
          // Badge Label (Top Left)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
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
              ],
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
                color: isDarkBg ? Colors.white.withOpacity(0.9) : AppColors.primary,
              ),
            ),
          ),
          
          if (isSelected && !isSystem)
            Positioned(
               bottom: 10,
               left: 12,
               child: Icon(PhosphorIconsFill.checkCircle, color: AppColors.primary, size: 16),
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
               color: Colors.white,
               shape: BoxShape.circle,
               border: Border.all(color: Colors.grey.shade200, width: 1.5),
               boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0,2))
               ]
             ),
             child: Center(
               child: Icon(PhosphorIconsRegular.plus, size: 24, color: AppColors.primary),
             ),
           ),
           Padding(
             padding: const EdgeInsets.only(right: 20),
             child: Text(
               "Yeni +",
               style: GoogleFonts.outfit(
                 fontSize: 12,
                 fontWeight: FontWeight.w600,
                 color: AppColors.headline.withOpacity(0.7)
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
                         color: AppColors.primary.withOpacity(0.05),
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
                   Icon(PhosphorIconsDuotone.plant, size: 56, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Bu Alan Yeşermeyi Bekliyor", 
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.headline
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
                  color: AppColors.body.withOpacity(0.7)
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

  void _showEditCategoryOptions(BuildContext context, String categoryId, String currentName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: PhosphorIconsRegular.pencilSimple,
              title: "Koleksiyon Adını Düzenle",
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(categoryId, currentName);
              },
            ),
            Divider(color: Colors.grey[100]),
            _buildOptionTile(
              icon: PhosphorIconsRegular.trash,
              title: "Koleksiyonu Sil",
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(categoryId, currentName);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required String title, Color? color, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (color ?? AppColors.primary).withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: color ?? AppColors.headline)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showRenameDialog(String categoryId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24), // Wider Dialog
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Koleksiyon Adı", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Yeni isim girin",
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Vazgeç", style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _renameCategory(categoryId, controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Kaydet", style: GoogleFonts.outfit(color: Colors.white)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Koleksiyon adı güncellendi", style: GoogleFonts.poppins()), backgroundColor: AppColors.primary),
      );
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
      Color iconColor = AppColors.primary; // Default Green for ALL icons to match Home
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
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, size: 14, color: iconColor)),
      );
    }
    
    // --- FALLBACK VIEW For Grid (Matches ItemFeedScreen exactly) ---
    Widget buildFallbackView() {
       IconData icon = PhosphorIconsBold.link;
       List<Color> gradientColors = [AppColors.primary, const Color(0xFF6FBFAC)]; // Oil Green Gradient
       final s = source.toLowerCase();
       
       if (s.contains('twitter') || s.contains('x.com')) {
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
       }

       return Container(
          color: Colors.white,
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

    Widget contentHeader;
    
    if (hasImage) {
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
                 errorWidget: (context, url, error) => const SizedBox.shrink(),
               )
             : Image.asset(item.displayImage!, fit: BoxFit.fitWidth),
          
          Positioned(top: 8, right: 8, child: buildPlatformIcon()),
        ],
      );
    } else {
      // No Image: AspectRatio wrapper for Fallback View
      contentHeader = AspectRatio(
        aspectRatio: 1.0, 
        child: Stack(
          children: [
             Positioned.fill(child: buildFallbackView()),
             // We DO NOT add the small platform icon here as the big one is enough/cleaner
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        if (isFeedback) return; // Don't tap drag feedback
        await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            enableDrag: true, 
            builder: (context) => ItemDetailBottomSheet(item: item, categoryName: categoryName, categories: categories),
        );
        // Catalog uses StreamProvider, so updates propagate automatically.
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: isFeedback 
             ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
             : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Image / Fallback Header
              contentHeader,
  
              // 2. Footer Info (Text Below)
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
                       style: GoogleFonts.poppins(
                         fontSize: 12, 
                         fontWeight: FontWeight.w600, 
                         color: Colors.grey.shade800
                       ),
                     ),
                     Text(
                       categoryName, // Restored Category Name
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                       style: GoogleFonts.poppins(
                         fontSize: 10, 
                         fontWeight: FontWeight.w400, 
                         color: Colors.grey.shade500
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
           decoration: const BoxDecoration(
             gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF6FBFAC)],
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
           backgroundColor: AppColors.primary,
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
    final TextEditingController _controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24), // Wider Dialog
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Yeni Koleksiyon",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.headline),
          textAlign: TextAlign.center,
        ),
        content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
              Text(
                "İçeriklerini düzenlemek için yeni bir koleksiyon oluştur.",
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.body),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                autofocus: true,
                style: GoogleFonts.poppins(color: AppColors.headline),
                decoration: InputDecoration(
                   hintText: "Koleksiyon Adı (Örn: Tatil Planı)",
                   hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                   filled: true,
                   fillColor: Colors.grey.shade50,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
           ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Vazgeç", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
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
                           )
                         );
                         if (context.mounted) Navigator.pop(context);
                       } catch (e) {
                         // Error handling
                       }
                     }
                  },
                  child: Text("Oluştur", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Koleksiyonu Sil?",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.headline),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "'$categoryName' silinecek.",
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.headline, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                   Icon(PhosphorIconsFill.info, color: Colors.amber.shade700, size: 20),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       "İçerikler silinmez, 'Gelen Kutusu'na taşınır.",
                       style: GoogleFonts.poppins(fontSize: 12, color: Colors.amber.shade900),
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("İptal", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                     final userId = _currentUserId;
                     if (userId == null) return;
                     
                     try {
                       // 1. Safe Move
                       await ref.read(itemRepositoryProvider).updateItemsCategory(userId, categoryId, null);
                       // 2. Delete
                       await ref.read(categoryRepositoryProvider).deleteCategory(categoryId);
                       // 3. Reset State
                       if (ref.read(selectedCatalogIdProvider) == categoryId) {
                         ref.read(selectedCatalogIdProvider.notifier).state = null;
                       }
                       if (context.mounted) Navigator.pop(context);
                     } catch (e) {
                       // Error
                     }
                  },
                  child: Text("Sil", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}