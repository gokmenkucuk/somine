import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:timeago/timeago.dart' as timeago;

class RecentlyDeletedScreen extends ConsumerWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Text(
                    "Silinen öğeler burada 30 gün saklanır.",
                    style: GoogleFonts.poppins(
                      color: context.colors.body.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _DeletedItemCard(item: item);
            },
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
                  item.deletedAt != null 
                    ? '${timeago.format(item.deletedAt!, locale: 'tr')} silindi'
                    : 'Silindi',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.colors.body.withOpacity(0.6),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Öğe geri yüklendi', style: GoogleFonts.poppins())),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu', style: GoogleFonts.poppins())),
        );
      }
    }
  }

  Future<void> _confirmPermanentDelete(BuildContext context, WidgetRef ref, String itemId) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Kalıcı Olarak Sil'),
        content: const Text('Bu işlem geri alınamaz. Emin misiniz?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ItemRepository().permanentDeleteItem(itemId);
        ref.invalidate(deletedItemsProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Öğe kalıcı olarak silindi', style: GoogleFonts.poppins())),
          );
        }
      } catch (e) {
        // Error handling
      }
    }
  }
}
