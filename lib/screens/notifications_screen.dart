import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/providers/item_providers.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart'; // Added
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/screens/catalog_screen.dart'; // Added
import 'package:somine_app/core/providers/navigation_providers.dart'; // Added
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {

  @override
  void initState() {
    super.initState();
    // Set locale messages for Turkish timeago if needed, 
    // usually done in main.dart but good to remember.
    timeago.setLocaleMessages('tr', timeago.TrMessages());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final userId = user?.uid;

    if (userId == null) return const SizedBox.shrink();

    // 1. Uncategorized Count Provider (We need a specialized future/stream for this)
    final pendingCountAsync = ref.watch(uncategorizedCountProvider(userId));
    
    // 2. Recent Items for Activity Feed
    final recentItemsAsync = ref.watch(recentItemsProvider(userId));

    return Scaffold(
      backgroundColor: context.colors.backgroundTop,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundTop,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.headline, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Bilgilendirme Merkezi",
          style: GoogleFonts.poppins(
            color: context.colors.headline,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(uncategorizedCountProvider(userId));
          ref.invalidate(recentItemsProvider(userId));
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // --- SECTION 1: PENDING ACTIONS (Dynamic) ---
            pendingCountAsync.when(
              data: (count) {
                if (count > 0) {
                  return Column(
                    children: [
                      _buildPendingActionCard(context, count),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => _buildPendingActionSkeleton(context),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // --- SECTION 2: RECENT ACTIVITY (Dynamic/Mock Hybrid) ---
            Text(
              "Son Hareketler",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.headline.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            
            recentItemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyActivityState(context);
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildActivityItem(context, item);
                  },
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CupertinoActivityIndicator())),
              error: (err, stack) {
                debugPrint("Activity Feed Error: $err");
                return _buildEmptyActivityState(context, error: err.toString());
              },
            ),

            const SizedBox(height: 32),

            // --- SECTION 3: TIPS & GUIDES (Static) ---
            Text(
              "İpuçları & Rehber",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.headline.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            _buildTipCard(
              context,
              icon: PhosphorIconsFill.instagramLogo,
              color: const Color(0xFFE1306C),
              title: "Instagram'dan Kaydet",
              subtitle: "Beğendiğiniz Reels veya gönderileri 'Paylaş > SoMine' diyerek anında buraya taşıyın.",
            ),
            const SizedBox(height: 12),
            _buildTipCard(
              context,
              icon: PhosphorIconsFill.folders,
              color: const Color(0xFF3B82F6),
              title: "Düzenli Olun",
              subtitle: "Kategorilerinizi ihtiyaçlarınıza göre özelleştirin ve içeriklerinizi kolayca bulun.",
            ),
             const SizedBox(height: 12),
            _buildTipCard(
              context,
              icon: PhosphorIconsFill.magicWand,
              color: const Color(0xFF8B5CF6),
              title: "Akıllı Notlar",
              subtitle: "Link eklerken düşüncelerinizi de not alın, daha sonra hatırlamak kolay olsun.",
            ),
             const SizedBox(height: 48), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildPendingActionCard(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.colors.primary, const Color(0xFF6FBFAC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsFill.tray, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Düzenlenmeyi Bekleyenler",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Koleksiyonunuza eklenmeyi bekleyen $count içerik var.",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              // 1. Find 'Hızlı' category ID
              final categories = ref.read(categoriesProvider).value ?? [];
              final quickCat = categories.where((c) => c.name == 'Hızlı').firstOrNull;
              
              if (quickCat != null) {
                // 2. Set Selected Category for Catalog Screen
                // Note: using selectedCatalogIdProvider from catalog_screen.dart
                ref.read(selectedCatalogIdProvider.notifier).state = quickCat.id;
              } else {
                 // Fallback: Default view
                 ref.read(selectedCatalogIdProvider.notifier).state = null;
              }

              // 3. Switch Main Tab to Catalog (Index 2)
              ref.read(homeTabIndexProvider.notifier).state = 2;

              // 4. Return to HomeScreen
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "İncele",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, ItemModel item) {
    // Determine detailed message based on item type/context if we had more implementation
    // For now, simple "Added" message
    String actionText = "Yeni içerik eklendi";
    if (item.categoryId == null) {
      actionText = "Hızlı kayıtlara eklendi";
    } else {
      // If we had category name mapped, we'd say "Added to X"
      // Since mapping is complex here without fetching all cats, we keep it simple or generic
      actionText = "Koleksiyona eklendi";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.hint.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForType(item.type),
              color: context.colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle.isNotEmpty ? item.displayTitle : "İsimsiz İçerik",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.colors.headline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  actionText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.colors.body,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeago.format(item.createdAt, locale: 'tr', allowFromNow: true),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: context.colors.hint,
            ),
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

  Widget _buildTipCard(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.hint.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.headline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: context.colors.body,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivityState(BuildContext context, {String? error}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.hint.withOpacity(0.2), style: BorderStyle.none),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.clockCounterClockwise, color: context.colors.hint, size: 20),
              const SizedBox(width: 8),
              Text(
                "Hareket yok",
                style: GoogleFonts.poppins(fontSize: 13, color: context.colors.hint),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              "Hata: $error", // Expose error for debugging
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ]
        ],
      ),
    );
  }

  // Skeleton Loader to prevent layout shift
  Widget _buildPendingActionSkeleton(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colors.surfaceWhite.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.hint.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: context.colors.hint.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150, height: 16,
                      decoration: BoxDecoration(
                        color: context.colors.hint.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200, height: 12,
                      decoration: BoxDecoration(
                        color: context.colors.hint.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
