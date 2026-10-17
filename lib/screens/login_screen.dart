import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/services.dart'; // SystemUiOverlayStyle için gerekli
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/services/analytics_service.dart';
import 'package:somine_app/core/repositories/user_repository.dart';
import 'package:somine_app/widgets/loading_indicator.dart';
import 'package:somine_app/screens/onboarding_name_screen.dart';

import 'package:somine_app/screens/home_screen.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/utils/auth_failure_l10n.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool forceLogin;

  const LoginScreen({super.key, this.forceLogin = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  /// İptal sessizdir; diğer hatalar yerelleştirilmiş metinle gösterilir.
  void _showAuthError(Object error) {
    final l10n = AppLocalizations.of(context)!;
    final message = authFailureMessage(
      error,
      l10n,
      fallback: l10n.authErrorGeneric,
    );
    if (message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openLegal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return; // Prevent double tap
    setState(() => _isLoading = true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.signInWithGoogle();

      if (mounted && result.userCredential?.user != null) {
        final user = result.userCredential!.user!;
        final analytics = ref.read(analyticsServiceProvider);
        if (result.isNewUser) {
          analytics.logSignUp('google');
        } else {
          analytics.logLogin('google');
        }
        final userModel = await UserRepository().getUser(user.uid);
        if (!mounted) return;
        final hasUsername =
            userModel?.username != null && userModel!.username!.isNotEmpty;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) =>
                    hasUsername
                        ? const HomeScreen()
                        : OnboardingNameScreen(userId: user.uid),
          ),
        );
      } else {
        // User canceled or failed without exception
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showAuthError(e);
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (_isLoading) return; // Prevent double tap
    setState(() => _isLoading = true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.signInWithApple();

      if (mounted && result.userCredential?.user != null) {
        final user = result.userCredential!.user!;
        final analytics = ref.read(analyticsServiceProvider);
        if (result.isNewUser) {
          analytics.logSignUp('apple');
        } else {
          analytics.logLogin('apple');
        }
        final userModel = await UserRepository().getUser(user.uid);
        if (!mounted) return;
        final hasUsername =
            userModel?.username != null && userModel!.username!.isNotEmpty;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) =>
                    hasUsername
                        ? const HomeScreen()
                        : OnboardingNameScreen(userId: user.uid),
          ),
        );
      } else {
        // User canceled or failed without exception
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showAuthError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Beyaz zemin üzerinde durum çubuğu ikonlarının (saat, pil) siyah olması için:
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white, // Tam beyaz zemin
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: Stack(
            children: [
              // Arka Plan İllüstrasyonu (En altta, çok hafif opaklık)
              // Arka Plan İllüstrasyonu (Kaldirildi - Asset eksikliği)
              /*
              Positioned(
                bottom: -50,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.3,
                  child: Container(
                    height: 350,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage(
                          'assets/images/onboarding_crystal.png',
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              */

              // Ana İçerik — büyük yazı boyutlarında taşmasın diye kaydırılabilir;
              // kısa içerikte Spacer'lar yine ekranı doldurur.
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingLG,
                        vertical: DesignTokens.spacingXXL,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight -
                                  DesignTokens.spacingXXL * 2)
                              .clamp(0, double.infinity),
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Spacer(flex: 2),

                              // Slogan (Left-aligned, no period)
                              _ShimmerSlogan(l10n: l10n),

                              const SizedBox(height: 48),

                              // Sign in with Apple (iOS/Mac) — HIG: üstte, Google ile
                              // aynı boyut ve köşe yarıçapında.
                              if (Theme.of(context).platform ==
                                      TargetPlatform.iOS ||
                                  Theme.of(context).platform ==
                                      TargetPlatform.macOS) ...[
                                _AppleSignInButton(
                                  onPressed: _signInWithApple,
                                  label: l10n.loginAppleContinue,
                                ),
                                const SizedBox(height: DesignTokens.spacingMD),
                              ],

                              // Google Button
                              // (Beyaz zemin üstünde beyaz buton olduğu için ince bir border ekledik)
                              _SocialButton(
                                onPressed: _signInWithGoogle,
                                icon: Icons.g_mobiledata,
                                label: l10n.loginGoogleContinue,
                                backgroundColor: Colors.white,
                                textColor: Colors.black87,
                                hasShadow: true,
                                useBorderOnWhite: true,
                              ),

                              const SizedBox(height: 24),

                              // Legal Terms Acceptance (≥11pt, ≥4.5:1 kontrast)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    text: l10n.loginLegalPrefix,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: DesignTokens.textSecondary,
                                      height: 1.5,
                                    ),
                                    children: [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: _LegalLink(
                                          label: l10n.legalTermsOfService,
                                          onTap: () => _openLegal(
                                            'https://www.somineapp.com/terms',
                                          ),
                                        ),
                                      ),
                                      TextSpan(text: l10n.loginLegalAnd),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: _LegalLink(
                                          label: l10n.legalPrivacyPolicy,
                                          onTap: () => _openLegal(
                                            'https://www.somineapp.com/privacy',
                                          ),
                                        ),
                                      ),
                                      TextSpan(text: l10n.loginLegalSuffix),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const Spacer(flex: 1),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ... _ShimmerSlogan ve _SloganGradientTransform kısımları aynen kalacak ...
// (Burayı kısaltıyorum, yukarıdaki kodunun aynısı kalabilir)
class _ShimmerSlogan extends StatefulWidget {
  final AppLocalizations l10n;

  const _ShimmerSlogan({required this.l10n});

  @override
  State<_ShimmerSlogan> createState() => _ShimmerSloganState();
}

class _ShimmerSloganState extends State<_ShimmerSlogan>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.l10n.loginSloganLine1,
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: DesignTokens.textPrimary,
            height: 1.2,
          ),
        ),
        Text(
          widget.l10n.loginSloganLine2,
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: DesignTokens.textPrimary,
            height: 1.2,
          ),
        ),
        Text(
          widget.l10n.loginSloganLine3,
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: DesignTokens.textPrimary,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

// GÜNCELLENEN BUTON WIDGET'I
class _SocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool hasShadow;
  final bool useBorderOnWhite; // Yeni özellik

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.hasShadow = false,
    this.useBorderOnWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        boxShadow: hasShadow ? DesignTokens.shadowSM : null,
        // Eğer beyaz zemin üstünde beyaz buton ise, çok hafif gri bir sınır çizgisi ekle
        border:
            useBorderOnWhite
                ? Border.all(color: context.colors.divider)
                : Border.all(color: Colors.transparent),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingLG,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 28),
                const SizedBox(width: DesignTokens.spacingMD),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Yasal bağlantı: metin içinde, okunur kontrastla ve yeterli dokunma alanıyla.
class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textPrimary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Sign in with Apple" düğmesi — Apple'ın kendi çizdiği resmî düğme
/// (sign_in_with_apple). Giriş akışı Firebase üzerinden yürür; paket yalnız
/// HIG'e uygun logo ve oranlar için kullanılır. Yükseklik ve köşe yarıçapı
/// Google düğmesiyle aynıdır.
class _AppleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _AppleSignInButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return SignInWithAppleButton(
      onPressed: onPressed,
      text: label,
      height: 56,
      style: SignInWithAppleButtonStyle.black,
      borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
    );
  }
}
