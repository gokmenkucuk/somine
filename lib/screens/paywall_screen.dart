import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/providers/subscription_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: context.colors.backgroundTop,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(PhosphorIconsRegular.x, color: context.colors.headline),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Crown Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.colors.primary, context.colors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(PhosphorIconsBold.crown, size: 40, color: Colors.white),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      "PREMIUM",
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: context.colors.headline,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Premium Üyelik",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: context.colors.hint,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Features List
                    _buildFeatureItem(context, PhosphorIconsRegular.infinity, "Sınırsız Koleksiyon & İçerik"),
                    _buildFeatureItem(context, PhosphorIconsRegular.vault, "Gizli Kasa (FaceID/TouchID)"),
                    _buildFeatureItem(context, PhosphorIconsRegular.palette, "Premium Temalar"),
                    _buildFeatureItem(context, PhosphorIconsRegular.appStoreLogo, "Özel Uygulama İkonları"),
                    _buildFeatureItem(context, PhosphorIconsRegular.magnifyingGlass, "Akıllı Arama"),
                    _buildFeatureItem(context, PhosphorIconsRegular.lightning, "Hızlı Widget Ekleme"),

                    const SizedBox(height: 40),

                    // Packages
                    if (subscriptionState.isLoading)
                      const CircularProgressIndicator()
                    else if (subscriptionState.availablePackages.isNotEmpty)
                      ...subscriptionState.availablePackages.map(
                        (package) => _buildPackageCard(context, ref, package),
                      )
                    else
                      // Fallback: Show placeholder cards when RevenueCat products not configured
                      ...[
                        _buildPlaceholderPackageCard(
                          context,
                          ref,
                          title: "Haftalık Plan",
                          price: "₺29,99",
                          description: "Her hafta otomatik yenilenir",
                          isPopular: false,
                        ),
                        _buildPlaceholderPackageCard(
                          context,
                          ref,
                          title: "Aylık Plan",
                          price: "₺79,99",
                          description: "Her ay otomatik yenilenir",
                          isPopular: false,
                        ),
                        _buildPlaceholderPackageCard(
                          context,
                          ref,
                          title: "Yıllık Plan",
                          price: "₺699,99",
                          description: "%27 indirimli, yılda bir kez ödeme",
                          isPopular: true,
                        ),
                      ],

                    const SizedBox(height: 24),

                    // Restore Button
                    TextButton(
                      onPressed: () async {
                        final success = await ref.read(subscriptionProvider.notifier).restore();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success ? "Satın almalar geri yüklendi!" : "Geri yüklenecek satın alma bulunamadı.",
                              ),
                            ),
                          );
                          if (success) Navigator.pop(context);
                        }
                      },
                      child: Text(
                        "Satın Almaları Geri Yükle",
                        style: GoogleFonts.outfit(
                          color: context.colors.hint,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.colors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.colors.headline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, WidgetRef ref, Package package) {
    final isYearly = package.packageType == PackageType.annual;
    final isLifetime = package.packageType == PackageType.lifetime;

    return GestureDetector(
      onTap: () async {
        final success = await ref.read(subscriptionProvider.notifier).purchase(package);
        if (context.mounted && success) {
          Navigator.pop(context, true);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isYearly ? context.colors.primary : context.colors.hint.withOpacity(0.2),
            width: isYearly ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getPackageTitle(package),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.colors.headline,
                        ),
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "EN POPÜLER",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      if (isLifetime) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "ÖMÜR BOYU",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPackageDescription(package),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: context.colors.hint,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              package.storeProduct.priceString,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.headline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPackageTitle(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return "Aylık Plan";
      case PackageType.annual:
        return "Yıllık Plan";
      case PackageType.lifetime:
        return "Lifetime";
      default:
        return package.storeProduct.title;
    }
  }

  String _getPackageDescription(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return "Her ay otomatik yenilenir";
      case PackageType.annual:
        return "%20 indirimli, yılda bir kez ödeme";
      case PackageType.lifetime:
        return "Tek seferlik ödeme, sonsuza kadar";
      default:
        return package.storeProduct.description;
    }
  }

  /// Placeholder package card (shown when RevenueCat products not configured)
  Widget _buildPlaceholderPackageCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String price,
    required String description,
    bool isPopular = false,
    bool isLifetime = false,
  }) {
    return GestureDetector(
      onTap: () {
        // Show message that purchases will be available soon
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Satın alma yakında aktif olacak!"),
            backgroundColor: context.colors.primary,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular ? context.colors.primary : context.colors.hint.withOpacity(0.2),
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.colors.headline,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "EN POPÜLER",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      if (isLifetime) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "ÖMÜR BOYU",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: context.colors.hint,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.headline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
