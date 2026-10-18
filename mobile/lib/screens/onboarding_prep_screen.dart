import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/services/onboarding_content_preparer.dart';
import 'package:somine_app/screens/home_screen.dart';
import 'package:somine_app/widgets/brand_gradient.dart';

/// Ad adımından sonraki ekran: örnek içerik arka planda hazırlanırken
/// kullanıcıya uygulamanın neler yapabildiğini anlatan kısa bir tur gösterir.
///
/// Hazırlık ([onboardingContentPreparerProvider]) `initState`'te başlatılan
/// sıradan bir Future'dır; ekrana bağlı değildir. Kullanıcı "Hemen başla"ya
/// erken dokunursa ana ekrana geçilir ve hazırlık arkada sürer. Bittiğinde
/// (başarı ya da hata) önceden yakalanan [ProviderContainer] üzerinden
/// onboarding durumu sıfırlanır ve akış/kategori provider'ları tazelenir;
/// arada kaydedilen öğeler zaten `items_changed` (SignalR) ile akışa düşer.
class OnboardingPrepScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? displayName;

  const OnboardingPrepScreen({
    super.key,
    required this.userId,
    this.displayName,
  });

  @override
  ConsumerState<OnboardingPrepScreen> createState() =>
      _OnboardingPrepScreenState();
}

/// Turdaki kart sayısı.
const int _kTourPageCount = 5;

/// Otomatik ilerleme aralığı.
const Duration _kAutoAdvanceInterval = Duration(seconds: 5);

class _OnboardingPrepScreenState extends ConsumerState<OnboardingPrepScreen> {
  /// Ekran kapandıktan sonra da provider'lara erişebilmek için `initState`'te
  /// yakalanır (dispose sonrası `ref` kullanılamaz).
  late final ProviderContainer _container;

  final PageController _pageController = PageController();
  Timer? _autoAdvanceTimer;
  bool _userTookControl = false;
  bool _reduceMotion = false;
  int _currentPage = 0;

  double _progress = 0.0;
  bool _isComplete = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    final preparer = ref.read(onboardingContentPreparerProvider);
    // Bilerek beklenmiyor: ekran kapansa da tamamlanmalı.
    unawaited(_runPreparation(preparer));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Arka plan hazırlığı
  // ---------------------------------------------------------------------------

  Future<void> _runPreparation(OnboardingContentPreparer preparer) async {
    try {
      await preparer(
        userId: widget.userId,
        displayName: widget.displayName,
        onProgress: _onProgress,
      );
    } catch (e) {
      // Hata olsa da kullanıcı devam edebilmeli ("zorla tamamla").
      debugPrint('❌ [Onboarding] Error preparing content: $e');
    }
    _onPreparationFinished();
  }

  void _onProgress(double value) {
    if (!mounted) return;
    setState(() => _progress = value.clamp(0.0, 1.0));
  }

  void _onPreparationFinished() {
    try {
      // AuthWrapper'ın normal akışa dönmesi için.
      _container.read(onboardingStateProvider.notifier).state = false;
      // Kullanıcı erken geçtiyse ana ekran açık: son öğeler realtime olayını
      // kaçırmış olsa bile akış ve kategoriler bir kez tazelensin.
      _container.invalidate(categoriesProvider);
      _container.invalidate(paginatedFeedProvider);
      _container.invalidate(itemCountProvider);
    } catch (e) {
      // Uygulama kapanırken container dispose edilmiş olabilir.
      if (kDebugMode) debugPrint('[Onboarding] refresh skipped: $e');
    }

    if (!mounted) return;
    setState(() {
      _progress = 1.0;
      _isComplete = true;
    });
  }

  // ---------------------------------------------------------------------------
  // Tur: otomatik ilerleme
  // ---------------------------------------------------------------------------

  bool get _shouldAutoAdvance =>
      !_reduceMotion && !_userTookControl && _currentPage < _kTourPageCount - 1;

  void _syncAutoAdvance() {
    if (!_shouldAutoAdvance) {
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = null;
      return;
    }
    _autoAdvanceTimer ??= Timer.periodic(_kAutoAdvanceInterval, (_) {
      if (!mounted || !_pageController.hasClients || !_shouldAutoAdvance) {
        _syncAutoAdvance();
        return;
      }
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  /// Kullanıcı karta dokunduğu/kaydırdığı anda kontrol ondadır: otomatik
  /// ilerleme kalıcı olarak durur.
  void _onUserInteraction() {
    if (_userTookControl) return;
    _userTookControl = true;
    _syncAutoAdvance();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _syncAutoAdvance();
  }

  // ---------------------------------------------------------------------------
  // Navigasyon
  // ---------------------------------------------------------------------------

  void _continueToHome() {
    if (_navigated) return;
    _navigated = true;
    _autoAdvanceTimer?.cancel();

    // Erken geçişte de onboarding bayrağı kapatılır; hazırlık arkada sürer.
    if (!_isComplete) {
      ref.read(onboardingStateProvider.notifier).state = false;
    }

    final transition =
        _reduceMotion ? Duration.zero : const Duration(milliseconds: 400);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: transition,
        reverseTransitionDuration: transition,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    final pages = <_TourPageData>[
      _TourPageData(
        illustration: const _ShareSheetIllustration(),
        title: l10n.onboardingTourSaveTitle,
        body: l10n.onboardingTourSaveBody,
        tip: l10n.onboardingTourSaveTip,
      ),
      _TourPageData(
        illustration: const _CollectionsIllustration(),
        title: l10n.onboardingTourOrganizeTitle,
        body: l10n.onboardingTourOrganizeBody,
      ),
      _TourPageData(
        illustration: const _ReminderIllustration(),
        title: l10n.onboardingTourRemindTitle,
        body: l10n.onboardingTourRemindBody,
      ),
      _TourPageData(
        illustration: const _VaultIllustration(),
        title: l10n.onboardingTourVaultTitle,
        body: l10n.onboardingTourVaultBody,
        premiumLabel: l10n.onboardingTourPremiumChip,
      ),
      _TourPageData(
        illustration: const _WidgetIllustration(),
        title: l10n.onboardingTourWidgetTitle,
        body: l10n.onboardingTourWidgetBody,
      ),
    ];
    assert(pages.length == _kTourPageCount);

    return Scaffold(
      backgroundColor: colors.backgroundTop,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.backgroundTop, colors.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: Listener(
                  onPointerDown: (_) => _onUserInteraction(),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder:
                        (context, index) => _TourPage(
                          data: pages[index],
                          isActive: index == _currentPage,
                          reduceMotion: _reduceMotion,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _PageDots(
                count: pages.length,
                current: _currentPage,
                reduceMotion: _reduceMotion,
                semanticsLabel: l10n.onboardingTourPageIndicator(
                  _currentPage + 1,
                  pages.length,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _PrepFooter(
                  progress: _progress,
                  isComplete: _isComplete,
                  reduceMotion: _reduceMotion,
                  onContinue: _continueToHome,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Tur sayfası
// =============================================================================

class _TourPageData {
  final Widget illustration;
  final String title;
  final String body;
  final String? tip;
  final String? premiumLabel;

  const _TourPageData({
    required this.illustration,
    required this.title,
    required this.body,
    this.tip,
    this.premiumLabel,
  });
}

class _TourPage extends StatelessWidget {
  final _TourPageData data;
  final bool isActive;
  final bool reduceMotion;

  const _TourPage({
    required this.data,
    required this.isActive,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Büyük yazı boyutlarında metne yer açılsın diye çizim alanı esner;
        // gerekirse sayfa dikeyde kayar.
        final illustrationHeight = (constraints.maxHeight * 0.5).clamp(
          120.0,
          280.0,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: illustrationHeight,
                  child: ExcludeSemantics(
                    // Dekoratif çizim: sistem yazı boyutu çizimdeki minik
                    // etiketleri büyütüp taşırmasın.
                    child: MediaQuery.withNoTextScaling(
                      child: AnimatedScale(
                        scale: isActive || reduceMotion ? 1.0 : 0.92,
                        duration:
                            reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        child: FittedBox(child: data.illustration),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (data.premiumLabel != null) ...[
                  _PremiumChip(label: data.premiumLabel!),
                  const SizedBox(height: 12),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: colors.headline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.5,
                    color: colors.body,
                  ),
                ),
                if (data.tip != null) ...[
                  const SizedBox(height: 20),
                  _TipLine(text: data.tip!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PremiumChip extends StatelessWidget {
  final String label;

  const _PremiumChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsFill.crown, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              // Metin rengi başlık tonunda: marka rengi açık zeminde 4.5:1'i
              // tutturmuyor.
              color: colors.headline,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  final String text;

  const _TipLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceWhite.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              PhosphorIconsRegular.lightbulbFilament,
              size: 18,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.4,
                color: colors.hint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final bool reduceMotion;
  final String semanticsLabel;

  const _PageDots({
    required this.count,
    required this.current,
    required this.reduceMotion,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration:
                  reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == current ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    i == current
                        ? colors.primary
                        : colors.iconInactive.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Alt alan: ilerleme + birincil düğme
// =============================================================================

class _PrepFooter extends StatelessWidget {
  final double progress;
  final bool isComplete;
  final bool reduceMotion;
  final VoidCallback onContinue;

  const _PrepFooter({
    required this.progress,
    required this.isComplete,
    required this.reduceMotion,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final percent = (progress * 100).round();
    final statusText =
        isComplete ? l10n.onboardingTourReady : l10n.onboardingTourPreparing;
    final buttonLabel =
        isComplete ? l10n.onboardingTourStart : l10n.onboardingTourStartNow;
    final foreground = BrandGradient.foreground(context);
    final switchDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 250);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              if (isComplete) ...[
                ExcludeSemantics(
                  child: Icon(
                    PhosphorIconsBold.checkCircle,
                    size: 18,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isComplete ? FontWeight.w600 : FontWeight.w500,
                    color: isComplete ? colors.headline : colors.hint,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: progress),
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: colors.iconInactive.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                semanticsLabel: statusText,
                semanticsValue: l10n.onboardingTourProgressValue(percent),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Semantics(
          button: true,
          label: buttonLabel,
          excludeSemantics: true,
          child: ConstrainedBox(
            // ≥44pt dokunma alanı; büyük yazıda yükselebilsin.
            constraints: const BoxConstraints(minHeight: 56),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: BrandGradient.linear(
                  context,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const ValueKey('onboardingTourPrimaryButton'),
                  onTap: onContinue,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: switchDuration,
                        child: Text(
                          buttonLabel,
                          key: ValueKey(buttonLabel),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Çizimler (yalnız widget'larla; tema renklerinde)
// =============================================================================

/// Kartların ortak zemini.
class _MockSurface extends StatelessWidget {
  final double width;
  final double? height;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _MockSurface({
    required this.width,
    this.height,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: colors.premiumShadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Metin yerine geçen yuvarlak çubuk.
class _Bar extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;

  const _Bar({required this.width, this.height = 8, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? context.colors.iconInactive.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  /// Paylaş menüsündeki uygulama simgeleri gibi yuvarlatılmış kare çizer.
  final bool appShape;

  const _IconBubble({
    required this.icon,
    this.size = 44,
    this.background,
    this.foreground,
    this.appShape = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? colors.secondary.withValues(alpha: 0.22),
        shape: appShape ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: appShape ? BorderRadius.circular(size * 0.24) : null,
      ),
      child: Icon(icon, size: size * 0.5, color: foreground ?? colors.primary),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final double size;

  const _AppIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/images/appicon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder:
            (context, _, __) => Container(
              width: size,
              height: size,
              color: context.colors.primary,
            ),
      ),
    );
  }
}

/// 1. Paylaş sayfası: kendi kendine oynayan küçük bir kayıt anı.
/// Kaynak uygulama öne çıkar → paylaşım menüsü açılır → somine seçilir →
/// "Kaydedildi" belirir. Her turda farklı kaynak (Instagram, YouTube, Safari).
/// Hareketi Azalt açıkken son kare sabit gösterilir.
class _ShareSheetIllustration extends StatefulWidget {
  const _ShareSheetIllustration();

  @override
  State<_ShareSheetIllustration> createState() =>
      _ShareSheetIllustrationState();
}

class _ShareSheetIllustrationState extends State<_ShareSheetIllustration>
    with SingleTickerProviderStateMixin {
  static const _cycle = Duration(milliseconds: 4500);
  static const _sources = [
    PhosphorIconsRegular.instagramLogo,
    PhosphorIconsRegular.youtubeLogo,
    PhosphorIconsRegular.compass,
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
  );
  int _sourceIndex = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_reduceMotion) {
        setState(() => _sourceIndex = (_sourceIndex + 1) % _sources.length);
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // t'nin [from, to] aralığındaki ilerlemesi (0–1), yumuşatılmış.
  double _phase(double t, double from, double to) =>
      Curves.easeOutCubic.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final neutral = colors.iconInactive.withValues(alpha: 0.14);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final sourcePop = _phase(t, 0.0, 0.18) * (1 - _phase(t, 0.30, 0.42));
        final sheetIn = _phase(t, 0.18, 0.40);
        final select = _phase(t, 0.48, 0.62);
        final saved = _phase(t, 0.66, 0.78) * (1 - _phase(t, 0.94, 1.0));
        final pulse = select * (1 - _phase(t, 0.62, 0.78));

        Widget source(int i) {
          final active = i == _sourceIndex;
          return Transform.scale(
            scale: active ? 1 + 0.18 * sourcePop : 1,
            child: _IconBubble(
              icon: _sources[i],
              size: 38,
              appShape: true,
              background:
                  active
                      ? colors.primary.withValues(
                        alpha: 0.16 + 0.14 * sourcePop,
                      )
                      : null,
            ),
          );
        }

        Widget target(Widget icon, {bool somine = false}) {
          final ring = somine ? select : 0.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: somine ? 1 + 0.10 * pulse : 1,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: ring),
                      width: 2.5,
                    ),
                  ),
                  child: icon,
                ),
              ),
              const SizedBox(height: 6),
              if (somine)
                Text(
                  'somine',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.headline,
                  ),
                )
              else
                const _Bar(width: 30, height: 6),
            ],
          );
        }

        return SizedBox(
          width: 300,
          height: 250,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      source(0),
                      const SizedBox(width: 12),
                      source(1),
                      const SizedBox(width: 12),
                      source(2),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Transform.translate(
                    offset: Offset(0, 4 * sourcePop),
                    child: Icon(
                      PhosphorIconsBold.arrowDown,
                      size: 18,
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: 0.35 + 0.65 * sheetIn,
                    child: Transform.translate(
                      offset: Offset(0, 28 * (1 - sheetIn)),
                      child: _MockSurface(
                        width: 290,
                        radius: 24,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _Bar(width: 36, height: 4),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: colors.secondary.withValues(
                                      alpha: 0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _sources[_sourceIndex],
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Bar(width: 120),
                                    SizedBox(height: 6),
                                    _Bar(width: 80, height: 6),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: colors.divider),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                target(const _AppIcon(size: 44), somine: true),
                                for (final icon in const [
                                  PhosphorIconsRegular.chatCircleDots,
                                  PhosphorIconsRegular.envelopeSimple,
                                  PhosphorIconsRegular.notePencil,
                                ])
                                  target(
                                    _IconBubble(
                                      icon: icon,
                                      background: neutral,
                                      foreground: colors.iconInactive,
                                      appShape: true,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // "Kaydedildi" etiketi
              Positioned(
                top: 44,
                child: Opacity(
                  opacity: saved,
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * saved,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.headline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsBold.check,
                            size: 14,
                            color: colors.surfaceWhite,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.onboardingTourSavedChip,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.surfaceWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 2. Koleksiyonlar + arkadaşlarla paylaşım.
class _CollectionsIllustration extends StatelessWidget {
  const _CollectionsIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = BrandGradient.foreground(context);

    Widget tile(IconData icon) {
      return Container(
        width: 122,
        height: 88,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBubble(icon: icon, size: 30),
            const Spacer(),
            const _Bar(width: 70),
            const SizedBox(height: 5),
            const _Bar(width: 40, height: 6),
          ],
        ),
      );
    }

    Widget avatar(Color color) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: colors.surfaceWhite, width: 2),
        ),
        child: Icon(PhosphorIconsFill.user, size: 14, color: foreground),
      );
    }

    return SizedBox(
      width: 300,
      height: 250,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 10,
            top: 0,
            child: _MockSurface(
              width: 280,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      tile(PhosphorIconsRegular.musicNotes),
                      tile(PhosphorIconsRegular.mapPin),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      tile(PhosphorIconsRegular.forkKnife),
                      tile(PhosphorIconsRegular.lightbulb),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
              decoration: BoxDecoration(
                gradient: BrandGradient.linear(context),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 64,
                    height: 28,
                    child: Stack(
                      children: [
                        Positioned(left: 0, child: avatar(colors.secondary)),
                        Positioned(left: 18, child: avatar(colors.primary)),
                        Positioned(left: 36, child: avatar(colors.iconActive)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    PhosphorIconsBold.shareNetwork,
                    size: 20,
                    color: foreground,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. Hatırlatıcı: bildirim + çanlı içerik kartı.
class _ReminderIllustration extends StatelessWidget {
  const _ReminderIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = BrandGradient.foreground(context);

    return SizedBox(
      width: 300,
      height: 250,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // İçerik kartı
          Positioned(
            left: 30,
            top: 70,
            child: _MockSurface(
              width: 240,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.secondary.withValues(alpha: 0.45),
                          colors.primary.withValues(alpha: 0.25),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        PhosphorIconsRegular.image,
                        size: 32,
                        color: colors.surfaceWhite.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _Bar(width: 150),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.clock,
                        size: 14,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      _Bar(
                        width: 60,
                        height: 6,
                        color: colors.primary.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bildirim
          Positioned(
            left: 6,
            right: 6,
            top: 0,
            child: _MockSurface(
              width: 288,
              radius: 18,
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  _AppIcon(size: 34),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bar(width: 110),
                        SizedBox(height: 6),
                        _Bar(width: 170, height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Çan rozeti
          Positioned(
            right: 18,
            top: 150,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: BrandGradient.linear(context),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                PhosphorIconsFill.bellRinging,
                size: 24,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. Gizli Kasa: örtülü koleksiyon + Face ID çerçevesi.
class _VaultIllustration extends StatelessWidget {
  const _VaultIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 300,
      height: 250,
      child: Center(
        child: _MockSurface(
          width: 240,
          height: 240,
          padding: const EdgeInsets.all(14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < 9; i++)
                    Container(
                      decoration: BoxDecoration(
                        color: colors.iconInactive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                ],
              ),
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: colors.surfaceWhite,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: colors.premiumShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      PhosphorIconsLight.scan,
                      size: 100,
                      color: colors.secondary,
                    ),
                    Icon(
                      PhosphorIconsFill.lockSimple,
                      size: 38,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 5. Ana ekran widget'ı: kayıtlardan biri her gün geri döner.
class _WidgetIllustration extends StatelessWidget {
  const _WidgetIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final appSquare = colors.iconInactive.withValues(alpha: 0.16);

    Widget appRow() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: appSquare,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
      ],
    );

    return SizedBox(
      width: 300,
      height: 250,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          _MockSurface(
            width: 210,
            height: 250,
            radius: 34,
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            child: Column(
              children: [
                // Widget
                Container(
                  height: 104,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.secondary.withValues(alpha: 0.55),
                        colors.primary.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [_AppIcon(size: 22), Spacer()]),
                      const Spacer(),
                      _Bar(
                        width: 110,
                        color: colors.surfaceWhite.withValues(alpha: 0.85),
                      ),
                      const SizedBox(height: 6),
                      _Bar(
                        width: 70,
                        height: 6,
                        color: colors.surfaceWhite.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                appRow(),
                const SizedBox(height: 12),
                appRow(),
              ],
            ),
          ),
          Positioned(
            right: 22,
            top: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.premiumShadow,
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _IconBubble(
                icon: PhosphorIconsFill.sun,
                size: 44,
                background: colors.surfaceWhite,
                foreground: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
