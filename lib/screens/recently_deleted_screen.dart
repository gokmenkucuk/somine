import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/widgets/success_notification_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class RecentlyDeletedScreen extends ConsumerStatefulWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  ConsumerState<RecentlyDeletedScreen> createState() => _RecentlyDeletedScreenState();
}

class _RecentlyDeletedScreenState extends ConsumerState<RecentlyDeletedScreen> {
  @override
  void initState() {
    super.initState();
    // 30 günden eski kayıtları otomatik temizle
    _cleanupExpiredItems();
  }

  Future<void> _cleanupExpiredItems() async {
    try {
      final authState = ref.read(authStateProvider);
      final user = authState.value;
      if (user != null) {
        final deletedCount = await ItemRepository().cleanupExpiredDeletedItems(user.uid);
        if (deletedCount > 0) {
          ref.invalidate(deletedItemsProvider);
        }
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up expired items: $e');
    }
  }

  Future<void> _deleteAllItems(List<ItemModel> items) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            'Silme Onayı',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: context.colors.headline,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${items.length} öğe kalıcı olarak silinecek. Bu işlem geri alınamaz.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: context.colors.body,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.colors.surfaceWhite,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(context, false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: context.colors.backgroundBottom,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "Vazgeç",
                        style: GoogleFonts.poppins(
                          color: context.colors.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(context, true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFFF5252), const Color(0xFFD32F2F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Sil",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
    );

    if (confirmed == true) {
      try {
        for (final item in items) {
          await ItemRepository().permanentDeleteItem(item.id);
        }
        ref.invalidate(deletedItemsProvider);
        
        if (mounted) {
          SuccessNotificationSheet.show(
            context,
            title: 'Tümü Silindi',
            message: '${items.length} öğe kalıcı olarak silindi.',
          );
        }
      } catch (e) {
        if (mounted) {
          SuccessNotificationSheet.show(
            context,
            title: 'Hata',
            message: 'Silme işlemi sırasında bir hata oluştu.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deletedItemsAsync = ref.watch(deletedItemsProvider);

    return Scaffold(
      backgroundColor: context.colors.backgroundBottom,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundTop,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: context.colors.headline),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Son Silinenler",
          style: GoogleFonts.poppins(
            color: context.colors.headline,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          deletedItemsAsync.when(
            data: (items) => items.isNotEmpty
                ? TextButton(
                    onPressed: () => _deleteAllItems(items),
                    child: Text(
                      'Tümünü Sil',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: deletedItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIconsRegular.trash, size: 64, color: context.colors.iconInactive),
                  const SizedBox(height: 16),
                  Text(
                    "Henüz silinen öğe yok",
                    style: GoogleFonts.poppins(
                      color: context.colors.body,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      "Silinen öğeler burada 30 gün saklanır, sonra otomatik olarak silinir.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: context.colors.body.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Info Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                        'Buradaki öğeler 30 gün sonra otomatik olarak silinecektir.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: context.colors.headline,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _DeletedItemCard(item: item);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Bir hata oluştu',
            style: GoogleFonts.poppins(color: context.colors.body),
          ),
        ),
      ),
    );
  }
}

class _DeletedItemCard extends ConsumerWidget {
  final ItemModel item;

  const _DeletedItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kalan günleri hesapla
    final daysRemaining = _getDaysRemaining();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.backgroundBottom,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForType(item.type),
              color: context.colors.iconActive,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.colors.headline,
                  ),
                ),
                Text(
                  daysRemaining != null 
                    ? '$daysRemaining gün içinde silinecek'
                    : 'Silindi',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: daysRemaining != null && daysRemaining <= 7 
                      ? Colors.orange 
                      : context.colors.body.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                  await _restoreItem(context, ref, item.id);
                },
                icon: Icon(PhosphorIconsRegular.arrowCounterClockwise, color: context.colors.primary),
                tooltip: 'Geri Yükle',
              ),
              IconButton(
                onPressed: () async {
                   await _confirmPermanentDelete(context, ref, item.id);
                },
                icon: Icon(PhosphorIconsRegular.trash, color: Colors.redAccent),
                tooltip: 'Kalıcı Sil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int? _getDaysRemaining() {
    if (item.deletedAt == null) return null;
    final expiryDate = item.deletedAt!.add(const Duration(days: 30));
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  IconData _getIconForType(ItemType type) {
    switch (type) {
      case ItemType.link:
        return PhosphorIconsRegular.link;
      case ItemType.note:
        return PhosphorIconsRegular.note;
      case ItemType.image:
        return PhosphorIconsRegular.image;
    }
  }

  Future<void> _restoreItem(BuildContext context, WidgetRef ref, String itemId) async {
    try {
      await ref.read(categoryRepositoryProvider); // Access repo via provider if needed, or directly
      // Using ItemRepository directly for simplicity as usually done in this codebase for actions
      await ItemRepository().restoreItem(itemId);
      
      // Refresh list
      ref.invalidate(deletedItemsProvider);
      
      // Also refresh main lists
      ref.invalidate(itemsProvider);
      ref.invalidate(catalogItemsProvider);
      
      if (context.mounted) {
        SuccessNotificationSheet.show(
          context,
          title: 'Geri Yüklendi',
          message: 'Öğe başarıyla geri yüklendi.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SuccessNotificationSheet.show(
          context,
          title: 'Hata',
          message: 'Bir hata oluştu.',
        );
      }
    }
  }

  Future<void> _confirmPermanentDelete(BuildContext context, WidgetRef ref, String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            'Silme Onayı',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: context.colors.headline,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bu içeriği silmek istediğinize emin misiniz?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: context.colors.body,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.colors.surfaceWhite,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(context, false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: context.colors.backgroundBottom,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "Vazgeç",
                        style: GoogleFonts.poppins(
                          color: context.colors.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(context, true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFFF5252), const Color(0xFFD32F2F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Sil",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
    );

    if (confirmed == true) {
      try {
        await ItemRepository().permanentDeleteItem(itemId);
        ref.invalidate(deletedItemsProvider);
        
        if (context.mounted) {
          SuccessNotificationSheet.show(
            context,
            title: 'Kalıcı Olarak Silindi',
            message: 'Öğe kalıcı olarak silindi.',
          );
        }
      } catch (e) {
        // Error handling
      }
    }
  }
}
