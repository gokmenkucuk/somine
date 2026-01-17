import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/screens/paywall_screen.dart';

/// Type of limit reached
enum LimitType {
  collection,
  item,
}

/// Show limit reached dialog
Future<bool?> showLimitReachedDialog(
  BuildContext context, {
  required LimitType type,
  required int currentCount,
  required int maxCount,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => LimitReachedDialog(
      type: type,
      currentCount: currentCount,
      maxCount: maxCount,
    ),
  );
}

class LimitReachedDialog extends StatelessWidget {
  final LimitType type;
  final int currentCount;
  final int maxCount;

  const LimitReachedDialog({
    super.key,
    required this.type,
    required this.currentCount,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final isCollection = type == LimitType.collection;

    return Container(
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
              color: context.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isCollection ? PhosphorIconsRegular.folderLock : PhosphorIconsRegular.fileLock,
              size: 32,
              color: context.colors.primary,
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            isCollection ? "Koleksiyon Sınırına Ulaştın" : "İçerik Sınırına Ulaştın",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.colors.headline,
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            isCollection
                ? "Ücretsiz planda en fazla $maxCount koleksiyon oluşturabilirsin."
                : "Her koleksiyonda en fazla $maxCount içerik ekleyebilirsin.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: context.colors.body,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 8),

          // Current status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.hint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$currentCount / $maxCount",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.hint,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Premium CTA
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
              if (result == true && context.mounted) {
                // User upgraded, can proceed
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.colors.primary, context.colors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsBold.crown, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "PREMIUM'a Yükselt",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Şimdilik Değil",
              style: GoogleFonts.outfit(
                color: context.colors.hint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
