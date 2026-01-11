import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/design/app_colors.dart';

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
                      style: Theme.of(context).textTheme.headlineMedium,
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
                gradient: SoMineTokens.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: SoMineTokens.spacingXXL),
            Text(
              'Henüz kategori yok',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: SoMineTokens.spacingS),
            Text(
              'İçeriklerini düzenlemek için\nkategoriler oluştur',
              style: Theme.of(context).textTheme.bodyMedium,
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

  void _confirmDelete(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        ),
        title: const Text('Kategoriyi Sil'),
        content: Text(
          '"${category.name}" kategorisini silmek istediğine emin misin?\n\nBu kategorideki içerikler silinmeyecek, sadece kategorisiz kalacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      await categoryRepo.deleteCategory(category.id);
      _showSuccessSnackbar('Kategori silindi');
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
        backgroundColor: SoMineTokens.accentEnd,
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
          gradient: SoMineTokens.primaryGradient,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusRound),
          boxShadow: [
            BoxShadow(
              color: SoMineTokens.accentEnd.withValues(alpha: 0.3),
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
          color: SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
          boxShadow: SoMineTokens.cardShadow,
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$itemCount içerik',
                    style: Theme.of(context).textTheme.bodySmall,
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
          color: SoMineTokens.background,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusSmall),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color ?? SoMineTokens.textSecondary,
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
        color: SoMineTokens.cardBackground,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
        boxShadow: SoMineTokens.cardShadowElevated,
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
                  color: SoMineTokens.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: SoMineTokens.spacingXXL),

            // Başlık
            Text(
              widget.isEditing ? 'Kategoriyi Düzenle' : 'Yeni Kategori',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: SoMineTokens.spacingXXL),

            // Emoji seçici
            Text(
              'İkon Seç',
              style: Theme.of(context).textTheme.labelLarge,
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
                            ? SoMineTokens.primaryGradient
                            : null,
                        color: isSelected ? null : SoMineTokens.background,
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
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: SoMineTokens.spacingS),
            Container(
              decoration: BoxDecoration(
                color: SoMineTokens.background,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
              ),
              child: TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Örn: Tatil Fikirleri',
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
                            Colors.grey.shade300,
                            Colors.grey.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
                      ),
                      child: Center(
                        child: Text(
                          'Vazgeç',
                          style: TextStyle(
                            color: Colors.grey.shade800,
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
                            AppColors.primary,
                            const Color(0xFF6FBFAC),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
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
