import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/providers/subscription_provider.dart';
import 'package:somine_app/core/services/analytics_service.dart';
import 'package:somine_app/core/services/subscription_service.dart';
import 'package:somine_app/core/utils/open_in_app_link.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  /// Paywall'ı açan yüzey (analitik `paywall_view` source parametresi).
  final String source;

  const PaywallScreen({super.key, this.source = 'unknown'});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsServiceProvider).logPaywallView(widget.source);
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final l10n = AppLocalizations.of(context)!;

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
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
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
                      child: Icon(
                        PhosphorIconsBold.crown,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
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
                      l10n.paywallSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: context.colors.body,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Features List
                    _buildFeatureItem(context, PhosphorIconsRegular.infinity, l10n.paywallFeatureUnlimited),
                    _buildFeatureItem(context, PhosphorIconsRegular.vault, l10n.paywallFeatureVault),
                    _buildFeatureItem(context, PhosphorIconsRegular.palette, l10n.paywallFeatureThemes),
                    _buildFeatureItem(context, PhosphorIconsRegular.appStoreLogo, l10n.paywallFeatureAppIcons),
                    // NOT: "Akıllı Arama" ve "Hızlı Widget Ekleme" listeden çıkarıldı —
                    // ikisi de premium'a kilitli DEĞİL (arama herkeste iyileştirildi,
                    // widget herkese açık). Ödenen şeyle verilen şey eşleşmeli.
                    // Gerçekten premium'a kilitlenirlerse geri eklenebilir.

                    const SizedBox(height: 40),

                    // Packages
                    if (subscriptionState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (subscriptionState.availablePackages.isNotEmpty)
                      ...subscriptionState.availablePackages.map(
                        (package) => _buildPackageCard(
                          context,
                          ref,
                          package,
                          l10n,
                          yearlyDiscount: _yearlyDiscountPercent(
                            subscriptionState.availablePackages,
                          ),
                        ),
                      )
                    else
                      // Planlar yüklenemediyse (ağ, StoreKit gecikmesi) sahte fiyat göstermek
                      // yerine dürüst bir hata ve yeniden deneme sunulur.
                      _buildPlansUnavailable(context, ref, l10n),

                    const SizedBox(height: 24),

                    // Restore Button (≥44pt dokunma alanı, okunur kontrast)
                    TextButton(
                      style: _linkButtonStyle(context),
                      onPressed: () async {
                        final success = await ref.read(subscriptionProvider.notifier).restore();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success ? l10n.paywallRestoreSuccess : l10n.paywallRestoreEmpty,
                              ),
                            ),
                          );
                          if (success) Navigator.pop(context);
                        }
                      },
                      child: Text(
                        l10n.paywallRestoreButton,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colors.body,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Legal Disclosure (App Store Required)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        l10n.paywallLegalDisclosure,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: context.colors.body,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Privacy & Terms Links
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          style: _linkButtonStyle(context),
                          onPressed: () => _openUrl('https://www.somineapp.com/terms'),
                          child: Text(
                            l10n.legalTermsOfService,
                            style: _linkTextStyle(context),
                          ),
                        ),
                        ExcludeSemantics(
                          child: Text(
                            "|",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: context.colors.body,
                            ),
                          ),
                        ),
                        TextButton(
                          style: _linkButtonStyle(context),
                          onPressed: () => _openUrl('https://www.somineapp.com/privacy'),
                          child: Text(
                            l10n.legalPrivacyPolicy,
                            style: _linkTextStyle(context),
                          ),
                        ),
                      ],
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

  ButtonStyle _linkButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      foregroundColor: context.colors.body,
    );
  }

  TextStyle _linkTextStyle(BuildContext context) {
    return GoogleFonts.outfit(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: context.colors.body,
      decoration: TextDecoration.underline,
    );
  }

  Future<void> _openUrl(String url) => openInAppLink(url);

  /// Yıllık planın, aylık planın 12 katına göre gerçek indirim yüzdesi
  /// (aşağı yuvarlanır). Hesaplanamıyorsa veya ≤0 ise null — rozet gizlenir.
  int? _yearlyDiscountPercent(List<Package> packages) {
    Package? find(PackageType type) {
      for (final p in packages) {
        if (p.packageType == type) return p;
      }
      return null;
    }

    final annual = find(PackageType.annual);
    final monthly = find(PackageType.monthly);
    if (annual == null || monthly == null) return null;
    if (annual.storeProduct.currencyCode != monthly.storeProduct.currencyCode) {
      return null;
    }
    final yearlyAtMonthly = monthly.storeProduct.price * 12;
    if (yearlyAtMonthly <= 0) return null;
    final percent =
        ((1 - annual.storeProduct.price / yearlyAtMonthly) * 100).floor();
    return percent > 0 ? percent : null;
  }

  String _purchaseErrorMessage(PurchaseFailureCode code, AppLocalizations l10n) {
    switch (code) {
      case PurchaseFailureCode.pending:
        return l10n.paywallPurchasePending;
      case PurchaseFailureCode.network:
        return l10n.failureNetwork;
      case PurchaseFailureCode.notAllowed:
        return l10n.paywallPurchaseNotAllowed;
      case PurchaseFailureCode.storeUnavailable:
      case PurchaseFailureCode.failed:
        return l10n.paywallPurchaseFailed;
    }
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
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.colors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.colors.headline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    WidgetRef ref,
    Package package,
    AppLocalizations l10n, {
    int? yearlyDiscount,
  }) {
    final isYearly = package.packageType == PackageType.annual;
    final isLifetime = package.packageType == PackageType.lifetime;
    final title = _getPackageTitle(package, l10n);
    final description = _getPackageDescription(package, l10n, yearlyDiscount);

    return Semantics(
      button: true,
      label: '$title, $description, ${package.storeProduct.priceString}',
      excludeSemantics: true,
      child: GestureDetector(
      onTap: () async {
        final notifier = ref.read(subscriptionProvider.notifier);
        final success = await notifier.purchase(package);
        if (!context.mounted) return;
        if (success) {
          ref
              .read(analyticsServiceProvider)
              .logPaywallConvert(package.storeProduct.identifier);
          Navigator.pop(context, true);
          return;
        }
        // Kullanıcı iptali sessiz; diğer mağaza hataları gösterilir.
        final error = ref.read(subscriptionProvider).purchaseError;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_purchaseErrorMessage(error, l10n))),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isYearly ? context.colors.primary : context.colors.hint.withValues(alpha: 0.2),
            width: isYearly ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.colors.headline,
                        ),
                      ),
                      if (isYearly) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.paywallMostPopularBadge,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                      if (isLifetime) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.paywallLifetimeBadge,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
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
                      color: context.colors.body,
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
    ),
    );
  }

  String _getPackageTitle(Package package, AppLocalizations l10n) {
    switch (package.packageType) {
      case PackageType.weekly:
        return l10n.paywallPlanWeekly;
      case PackageType.monthly:
        return l10n.paywallPlanMonthly;
      case PackageType.annual:
        return l10n.paywallPlanYearly;
      case PackageType.lifetime:
        return l10n.paywallPlanLifetime;
      default:
        return package.storeProduct.title;
    }
  }

  String _getPackageDescription(
    Package package,
    AppLocalizations l10n,
    int? yearlyDiscount,
  ) {
    switch (package.packageType) {
      case PackageType.weekly:
        return l10n.paywallPlanWeeklyDescription;
      case PackageType.monthly:
        return l10n.paywallPlanMonthlyDescription;
      case PackageType.annual:
        return yearlyDiscount != null
            ? l10n.paywallPlanYearlyDescription(yearlyDiscount)
            : l10n.paywallPlanYearlyDescriptionNoDiscount;
      case PackageType.lifetime:
        return l10n.paywallPlanLifetimeDescription;
      default:
        return package.storeProduct.description;
    }
  }

  /// Shown when the store's plans could not be loaded; never invents prices.
  Widget _buildPlansUnavailable(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.hint.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            l10n.paywallPlansUnavailable,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 15, color: context.colors.headline),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.read(subscriptionProvider.notifier).refresh(),
            child: Text(
              l10n.errorStateRetry,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
