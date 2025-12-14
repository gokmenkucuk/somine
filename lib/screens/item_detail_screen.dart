import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemDetailScreen extends ConsumerWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  Future<void> _launchUrl(BuildContext context) async {
    if (item.url != null) {
      final uri = Uri.parse(item.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Link açılamadı: ${item.url}')),
          );
        }
      }
    }
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sil?'),
        content: const Text('Bu öğeyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(itemRepositoryProvider).deleteItem(item.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.asData?.value ?? [];
    final category = categories.cast<CategoryModel?>().firstWhere(
      (c) => c?.id == item.categoryId,
      orElse: () => null,
    );
    final categoryName = category?.name ?? 'Genel';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Hero Image Header with AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white, // For back button on image
            flexibleSpace: FlexibleSpaceBar(
              background: item.displayImage != null
                  ? Hero(
                      tag: item.id,
                      child: Image.network(
                        item.displayImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(Icons.image, size: 64, color: DesignTokens.textTertiary),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26, 
                    shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.delete, size: 20),
                ),
                onPressed: () => _deleteItem(context, ref),
              ),
              const SizedBox(width: 8),
            ],
            leading: IconButton(
               icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26, 
                    shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.arrow_back, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
            ),
          ),

          // 2. Info Content
          SliverToBoxAdapter(
            child: Padding(
               padding: const EdgeInsets.all(DesignTokens.spacingLG),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // Metadata
                   Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                         decoration: BoxDecoration(
                           color: DesignTokens.primary.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                         ),
                         child: Text(
                           categoryName, // TODO: Get actual category name safely
                           style: GoogleFonts.poppins(
                             color: DesignTokens.primary,
                             fontSize: 12,
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                       ),
                       const Spacer(),
                       // Date
                       Text(
                         'Added recently', // Placeholder for relative time
                         style: GoogleFonts.poppins(
                           color: DesignTokens.textTertiary,
                           fontSize: 12,
                         ),
                       ),
                     ],
                   ),
                   
                   const SizedBox(height: DesignTokens.spacingMD),
                   
                   // Title (H1)
                   Text(
                     item.displayTitle,
                     style: GoogleFonts.poppins(
                       fontSize: 24,
                       fontWeight: FontWeight.bold,
                       color: DesignTokens.textPrimary,
                       height: 1.3,
                     ),
                   ),
                   
                   if (item.url != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.url!,
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textTertiary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                   ],

                   const SizedBox(height: DesignTokens.spacingLG),
                   const Divider(color: DesignTokens.border),
                   const SizedBox(height: DesignTokens.spacingLG),

                   // Note Section
                   if (item.note != null && item.note!.isNotEmpty)
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(DesignTokens.spacingMD),
                       decoration: BoxDecoration(
                         color: DesignTokens.background,
                         borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                         border: Border.all(color: DesignTokens.border),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'Notun:',
                             style: GoogleFonts.poppins(
                               fontSize: 12,
                               fontWeight: FontWeight.bold,
                               color: DesignTokens.textSecondary,
                             ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             item.note!,
                             style: GoogleFonts.kalam( // Handwritten style if available, or italic poppins
                               fontSize: 16,
                               color: DesignTokens.textPrimary,
                               height: 1.5,
                             ),
                           ),
                         ],
                       ),
                     )
                   else
                      GestureDetector(
                        onTap: () {
                          // TODO: Open edit modal
                        },
                        child: Text(
                           'Bir not ekle...',
                           style: GoogleFonts.kalam(
                             fontSize: 16,
                             color: DesignTokens.textTertiary,
                           ),
                        ),
                      ),
                      
                   const SizedBox(height: 100), // Spacing for sticky button
                 ],
               ),
            ),
          ),
        ],
      ),
      
      // 3. Sticky Bottom Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingLG),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            )
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => _launchUrl(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.transparent, 
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
              ),
            ).copyWith(
               // Gradient trick for button
               backgroundColor: WidgetStateProperty.all(Colors.transparent), 
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: DesignTokens.primaryGradient,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
              ),
              child: Container(
                alignment: Alignment.center,
                height: 56,
                child: Text(
                  'Kaynağa Git',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
