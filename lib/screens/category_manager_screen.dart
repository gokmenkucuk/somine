import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/design/design_tokens.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  ConsumerState<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final allItems = ref.watch(itemsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: context.colors.backgroundTop,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(SoMineTokens.spacingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kategoriler',
                      style: GoogleFonts.outfit(
                          fontSize: 24, fontWeight: FontWeight.bold, color: context.colors.headline),
                    ),
                    _AddCategoryButton(
                      onTap: () => _showAddCategorySheet(context),
                    ),
                  ],
                ),
              ),
            ),

            // Boş durum veya liste
            if (categories.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(context),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SoMineTokens.spacingL,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      final itemCount = allItems
                          .where((i) => i.categoryId == category.id)
                          .length;
                      // Use context colors or keep as is if showcase gradients are fine
                      // But better to use primary/secondary logic if possible, or just keep variety
                      final gradient = SoMineTokens.showcaseGradients[
                        index % SoMineTokens.showcaseGradients.length
                      ];

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: SoMineTokens.spacingM,
                        ),
                        child: _CategoryTile(
                          category: category,
                          itemCount: itemCount,
                          gradient: gradient,
                          onTap: () => _openCategoryDetail(category),
                          onEdit: () => _showEditCategorySheet(context, category),
                          onDelete: () => _confirmDelete(context, category),
                        ),
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
              ),

            // Alt boşluk
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SoMineTokens.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [context.colors.primary, context.colors.secondary]),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: Colors.white, // Icon on primary color should remain white or high contrast
              ),
            ),
            const SizedBox(height: SoMineTokens.spacingXXL),
            Text(
              'Henüz kategori yok',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.headline),
            ),
            const SizedBox(height: SoMineTokens.spacingS),
            Text(
              'İçeriklerini düzenlemek için\nkategoriler oluştur',
              style: GoogleFonts.poppins(color: context.colors.body, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SoMineTokens.spacingXXL),
            ElevatedButton.icon(
              onPressed: () => _showAddCategorySheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Kategori Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFormSheet(
        onSave: (name, emoji) => _createCategory(name, emoji),
      ),
    );
  }

  void _showEditCategorySheet(BuildContext context, CategoryModel category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFormSheet(
        initialName: category.name,
        initialEmoji: category.emoji,
        isEditing: true,
        onSave: (name, emoji) => _updateCategory(category, name, emoji),
      ),
    );
  }

  Future<void> _createCategory(String name, String? emoji) async {
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      await categoryRepo.createCategory(
        CategoryModel(
          id: '',
          name: name,
          emoji: emoji,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackbar('Kategori oluşturuldu');
      }
    } catch (e) {
      _showErrorSnackbar('Kategori oluşturulamadı');
    }
  }

  Future<void> _updateCategory(
    CategoryModel category,
    String name,
    String? emoji,
  ) async {
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      await categoryRepo.updateCategory(
        category.copyWith(name: name, emoji: emoji),
      );
      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackbar('Kategori güncellendi');
      }
    } catch (e) {
      _showErrorSnackbar('Kategori güncellenemedi');
    }
  }

  Future<void> _confirmDelete(BuildContext context, CategoryModel category) async {
    // Check item count directly from repository (Source of Truth)
    // Providers might be filtered or not listening
    try {
      final itemRepo = ref.read(itemRepositoryProvider);
      final count = await itemRepo.getActiveItemCountInCategory(category.userId, category.id);

      debugPrint("Delete check for ${category.name}: found $count items (Direct Repo)");

      if (!mounted) return;

      if (count == 0) {
        // Empty category - Standard delete
        _showStandardDeleteDialog(context, category);
      } else {
        // Non-empty category - Advanced actions
        _showAdvancedDeleteDialog(context, category, count);
      }
    } catch (e) {
      debugPrint("Error checking category items: $e");
      // Fallback to standard dialog if check fails, but maybe warn
      if (mounted) _showStandardDeleteDialog(context, category);
    }
  }

  void _showStandardDeleteDialog(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kategoriyi Sil'),
        content: Text('"${category.name}" kategorisini silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category, deleteItems: false); // Empty anyway
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAdvancedDeleteDialog(BuildContext context, CategoryModel category, int count) {
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
              '"${category.name}" içinde $count adet içerik var. Bu içerikleri ne yapmak istersin?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: context.colors.body),
            ),
            const SizedBox(height: 32),
            
            // Move Option
            _buildActionButton(
              context,
              icon: PhosphorIconsLight.folderNotchPlus,
              text: 'İçerikleri Başka Koleksiyona Taşı',
              color: context.colors.primary,
              onTap: () {
                Navigator.pop(context);
                _showMoveTargetSelector(context, category);
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
                _deleteCategory(category, deleteItems: true);
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

  void _showMoveTargetSelector(BuildContext context, CategoryModel sourceCategory) {
    final categories = ref.read(categoriesProvider).value ?? [];
    // Exclude current category
    final targets = categories.where((c) => c.id != sourceCategory.id).toList();

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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
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
                    leading: Text(cat.emoji ?? '📁', style: const TextStyle(fontSize: 24)),
                    title: Text(cat.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      _moveItemsAndDelete(sourceCategory, cat.id);
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

  Future<void> _moveItemsAndDelete(CategoryModel source, String targetId) async {
    try {
      final itemRepo = ref.read(itemRepositoryProvider);
      final catRepo = ref.read(categoryRepositoryProvider);
      
      // 1. Move items
      await itemRepo.updateItemsCategory(source.userId, source.id, targetId);
      
      // 2. Delete category
      await catRepo.deleteCategory(source.id);
      
      _showSuccessSnackbar('İçerikler taşındı ve kategori silindi');
    } catch (e) {
      _showErrorSnackbar('İşlem başarısız oldu');
    }
  }

  Future<void> _deleteCategory(CategoryModel category, {required bool deleteItems}) async {
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final itemRepo = ref.read(itemRepositoryProvider);
      
      // 1. Delete items if requested
      if (deleteItems) {
        await itemRepo.deleteItemsInCategory(category.id);
      }
      
      // 2. Delete category
      await categoryRepo.deleteCategory(category.id);
      
      _showSuccessSnackbar('Kategori ${deleteItems ? "ve içerikler" : ""} silindi');
    } catch (e) {
      _showErrorSnackbar('Kategori silinemedi');
    }
  }

  void _openCategoryDetail(CategoryModel category) {
    // Kategori detay sayfasına git (ileride eklenebilir)
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
        ),
      ),
    );
  }
}

/// Kategori ekleme butonu
class _AddCategoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCategoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SoMineTokens.spacingL,
          vertical: SoMineTokens.spacingS,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [context.colors.primary, context.colors.secondary]),
          borderRadius: BorderRadius.circular(SoMineTokens.radiusRound),
          boxShadow: [
            BoxShadow(
              color: context.colors.premiumShadow.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: SoMineTokens.spacingXS),
            Text(
              'Yeni',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kategori listesi öğesi
class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final int itemCount;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CategoryTile({
    required this.category,
    required this.itemCount,
    required this.gradient,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SoMineTokens.spacingL),
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
          boxShadow: [
             BoxShadow(
               color: context.colors.premiumShadow.withOpacity(0.05),
               offset: const Offset(0, 4),
               blurRadius: 12,
             )
          ],
        ),
        child: Row(
          children: [
            // Gradient ikon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
              ),
              child: Center(
                child: Text(
                  category.emoji ?? '📁',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            const SizedBox(width: SoMineTokens.spacingL),

            // Bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 16, color: context.colors.headline),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$itemCount içerik',
                    style: GoogleFonts.poppins(fontSize: 12, color: context.colors.hint),
                  ),
                ],
              ),
            ),

            // Aksiyon butonları
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconButton(
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                ),
                const SizedBox(width: SoMineTokens.spacingS),
                _IconButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: onDelete,
                  color: Colors.red.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _IconButton({
    required this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.colors.backgroundTop, // Slightly different bg for icon button
          borderRadius: BorderRadius.circular(SoMineTokens.radiusSmall),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color ?? context.colors.body,
        ),
      ),
    );
  }
}

/// Kategori ekleme/düzenleme formu
class _CategoryFormSheet extends StatefulWidget {
  final String? initialName;
  final String? initialEmoji;
  final bool isEditing;
  final Function(String name, String? emoji) onSave;

  const _CategoryFormSheet({
    this.initialName,
    this.initialEmoji,
    this.isEditing = false,
    required this.onSave,
  });

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _nameController;
  String? _selectedEmoji;

  final List<String> _emojis = [
    '📁', '🎬', '🎵', '📚', '🍕', '✈️', '🛍️', '💡',
    '🎨', '🏠', '👗', '💪', '🎮', '📷', '🌿', '💼',
    '🎯', '⭐', '❤️', '🔥', '💎', '🌈', '🎁', '🏆',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedEmoji = widget.initialEmoji ?? _emojis.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.onSave(name, _selectedEmoji);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(SoMineTokens.spacingL),
      decoration: BoxDecoration(
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
        boxShadow: [
          BoxShadow(
             color: context.colors.premiumShadow.withOpacity(0.1),
             offset: const Offset(0, -4),
             blurRadius: 20
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: SoMineTokens.spacingXXL,
          right: SoMineTokens.spacingXXL,
          top: SoMineTokens.spacingXXL,
          bottom: SoMineTokens.spacingXXL + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.hint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: SoMineTokens.spacingXXL),

            // Başlık
            Text(
              widget.isEditing ? 'Kategoriyi Düzenle' : 'Yeni Kategori',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.headline),
            ),

            const SizedBox(height: SoMineTokens.spacingXXL),

            // Emoji seçici
            Text(
              'İkon Seç',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: context.colors.headline),
            ),
            const SizedBox(height: SoMineTokens.spacingM),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                separatorBuilder: (_, __) => const SizedBox(
                  width: SoMineTokens.spacingS,
                ),
                itemBuilder: (context, index) {
                  final emoji = _emojis[index];
                  final isSelected = emoji == _selectedEmoji;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedEmoji = emoji);
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: SoMineTokens.animationFast,
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: [context.colors.primary, context.colors.secondary])
                            : null,
                        color: isSelected ? null : context.colors.backgroundTop,
                        borderRadius: BorderRadius.circular(
                          SoMineTokens.radiusMedium,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: SoMineTokens.spacingXXL),

            // İsim input
            Text(
              'Kategori Adı',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: context.colors.headline),
            ),
            const SizedBox(height: SoMineTokens.spacingS),
            Container(
              decoration: BoxDecoration(
                color: context.colors.backgroundTop,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
              ),
              child: TextField(
                controller: _nameController,
                autofocus: true,
                style: GoogleFonts.poppins(color: context.colors.headline),
                decoration: InputDecoration(
                  hintText: 'Örn: Tatil Fikirleri',
                  hintStyle: GoogleFonts.poppins(color: context.colors.hint),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SoMineTokens.spacingL,
                    vertical: SoMineTokens.spacingM,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onSave(),
              ),
            ),

            const SizedBox(height: SoMineTokens.spacingXXL),

            // Butonlar
            Row(
              children: [
                // Vazgeç Butonu (Gri Gradient)
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade100,
                            Colors.grey.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
                      ),
                      child: Center(
                        child: Text(
                          'Vazgeç',
                          style: TextStyle(
                            color: context.colors.body,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: SoMineTokens.spacingM),

                // Oluştur/Güncelle Butonu (Yeşil Gradient)
                Expanded(
                  child: InkWell(
                    onTap: _onSave,
                    borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.colors.primary,
                            context.colors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.isEditing ? 'Güncelle' : 'Oluştur',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
