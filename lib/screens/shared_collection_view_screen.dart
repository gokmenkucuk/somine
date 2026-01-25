import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/share_model.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/widgets/success_notification_sheet.dart';

class SharedCollectionViewScreen extends ConsumerStatefulWidget {
  final ShareModel share;

  const SharedCollectionViewScreen({super.key, required this.share});

  @override
  ConsumerState<SharedCollectionViewScreen> createState() => _SharedCollectionViewScreenState();
}

class _SharedCollectionViewScreenState extends ConsumerState<SharedCollectionViewScreen> {
  List<ItemModel> _items = [];
  bool _isLoading = true;
  Set<String> _selectedItemIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await ItemRepository().getItemsByCategory(
        widget.share.fromUserId,
        widget.share.categoryId,
      );
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading shared items: $e');
    }
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
      _isSelectionMode = _selectedItemIds.isNotEmpty;
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedItemIds.length == _items.length) {
        _selectedItemIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedItemIds = _items.map((i) => i.id).toSet();
        _isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundBottom,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundTop,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: context.colors.headline),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.share.categoryName,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: context.colors.headline,
                fontSize: 18,
              ),
            ),
            Text(
              '${widget.share.fromUserName} tarafından',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: context.colors.hint,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _selectAll,
              child: Text(
                _selectedItemIds.length == _items.length ? 'Hiçbiri' : 'Tümü',
                style: GoogleFonts.poppins(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmptyState()
              : _buildItemsGrid(),
      bottomNavigationBar: _isSelectionMode ? _buildCopyBar() : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.folderOpen,
            size: 64,
            color: context.colors.iconInactive,
          ),
          const SizedBox(height: 16),
          Text(
            'Koleksiyon Boş',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.headline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu koleksiyonda henüz içerik yok.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: context.colors.body.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final isSelected = _selectedItemIds.contains(item.id);
        
        return GestureDetector(
          onTap: () => _toggleSelection(item.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: context.colors.primary, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isSelected ? 13 : 16),
              child: Stack(
                children: [
                  // Content
                  Container(
                    color: context.colors.surfaceWhite,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: item.displayImage != null
                              ? CachedNetworkImage(
                                  imageUrl: item.displayImage!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey[100],
                                    child: Center(
                                      child: Icon(
                                        PhosphorIconsLight.image,
                                        size: 32,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: context.colors.backgroundTop,
                                    child: Center(
                                      child: Icon(
                                        PhosphorIconsBold.link,
                                        size: 32,
                                        color: context.colors.primary,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: context.colors.backgroundTop,
                                  child: Center(
                                    child: Icon(
                                      item.type == ItemType.note
                                          ? PhosphorIconsBold.note
                                          : PhosphorIconsBold.link,
                                      size: 32,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            item.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.colors.headline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Selection Indicator
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCopyBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '${_selectedItemIds.length} seçili',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.headline,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _showCopyDialog,
            icon: const Icon(PhosphorIconsRegular.copy, size: 20),
            label: Text(
              'Koleksiyonuma Kopyala',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _showCopyDialog() {
    final categoriesAsync = ref.read(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
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
              child: Text(
                'Koleksiyon Seçin',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.headline,
                ),
              ),
            ),
            
            // Category List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length + 1, // +1 for "Create New"
                itemBuilder: (context, index) {
                  if (index == categories.length) {
                    // Create new option
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          PhosphorIconsRegular.plus,
                          color: context.colors.primary,
                        ),
                      ),
                      title: Text(
                        'Aynı isimle yeni koleksiyon oluştur',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: context.colors.headline,
                        ),
                      ),
                      subtitle: Text(
                        '"${widget.share.categoryName}"',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: context.colors.hint,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _createNewCollectionAndCopy();
                      },
                    );
                  }
                  
                  final category = categories[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.colors.primary, context.colors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.cards,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: context.colors.headline,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _copyToCollection(category.id!);
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

  Future<void> _copyToCollection(String categoryId) async {
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;
      
      final copiedCount = await ItemRepository().copyItemsToCollection(
        itemIds: _selectedItemIds.toList(),
        targetUserId: user.uid,
        targetCategoryId: categoryId,
      );
      
      ref.invalidate(itemsProvider);
      ref.invalidate(catalogItemsProvider);
      
      setState(() {
        _selectedItemIds.clear();
        _isSelectionMode = false;
      });
      
      if (mounted) {
        SuccessNotificationSheet.show(
          context,
          title: 'Kopyalandı',
          message: '$copiedCount içerik koleksiyonunuza eklendi.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _createNewCollectionAndCopy() async {
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;
      
      // Create new category with same name
      final newCategory = CategoryModel(
        id: '', // Will be generated by Firestore
        name: widget.share.categoryName,
        userId: user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final createdCategory = await categoryRepo.createCategory(newCategory);
      
      // Copy items to new category
      final copiedCount = await ItemRepository().copyItemsToCollection(
        itemIds: _selectedItemIds.toList(),
        targetUserId: user.uid,
        targetCategoryId: createdCategory.id!,
      );
      
      ref.invalidate(categoriesProvider);
      ref.invalidate(itemsProvider);
      ref.invalidate(catalogItemsProvider);
      
      setState(() {
        _selectedItemIds.clear();
        _isSelectionMode = false;
      });
      
      if (mounted) {
        SuccessNotificationSheet.show(
          context,
          title: 'Kopyalandı',
          message: '"${widget.share.categoryName}" koleksiyonu oluşturuldu ve $copiedCount içerik eklendi.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}
