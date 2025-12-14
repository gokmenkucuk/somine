import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemUiOverlayStyle için gerekli
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/widgets/loading_indicator.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool forceLogin;

  const LoginScreen({super.key, this.forceLogin = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Giriş hatası: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithApple();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Giriş hatası: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueAsGuest() {
    final guestNotifier = ref.read(guestUserStateProvider.notifier);
    guestNotifier.setGuestMode(true);
  }

  @override
  Widget build(BuildContext context) {
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
      
              // Ana İçerik
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingLG,
                    vertical: DesignTokens.spacingXXL,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Spacer(flex: 1), 
                      
                      // Logo
                      Image.asset(
                        'assets/images/logo_v2.png', 
                        height: 180,
                        fit: BoxFit.contain,
                      ),
      
                      const Spacer(flex: 2), 
                      
                      // Slogan
                      const _ShimmerSlogan(),
      
                      const SizedBox(height: 48), 
                      
                      // Apple Button (iOS/Mac için)
                      if (Theme.of(context).platform == TargetPlatform.iOS ||
                          Theme.of(context).platform == TargetPlatform.macOS) ...[
                        _SocialButton(
                          onPressed: _signInWithApple,
                          icon: Icons.apple,
                          label: 'Apple ile Devam Et',
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: DesignTokens.spacingMD),
                      ],
      
                      // Google Button 
                      // (Beyaz zemin üstünde beyaz buton olduğu için ince bir border ekledik)
                      _SocialButton(
                        onPressed: _signInWithGoogle,
                        icon: Icons.g_mobiledata,
                        label: 'Google ile Devam Et',
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        hasShadow: true,
                        useBorderOnWhite: true, // Yeni parametre
                      ),
      
                      // Misafir Girişi
                      if (!widget.forceLogin) ...[
                        const SizedBox(height: DesignTokens.spacingLG),
                        TextButton(
                          onPressed: _continueAsGuest,
                          child: Text(
                            'Üyelik olmadan devam et',
                            style: GoogleFonts.poppins(
                              color: DesignTokens.textTertiary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
      
                      const Spacer(flex: 1),
                    ],
                  ),
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
  const _ShimmerSlogan();

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
    final textStyle = GoogleFonts.poppins(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      color: DesignTokens.textPrimary, 
      height: 1.2,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'Dijital Dünyanı\nTasarla.',
          textAlign: TextAlign.center,
          style: textStyle,
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.55, 1.0],
                  transform: _SloganGradientTransform(_controller.value),
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: child,
            );
          },
          child: ShaderMask(
            shaderCallback:
                (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF2563EB), 
                    Color(0xFF06B6D4), 
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              'Dijital Dünyanı\nTasarla.',
              textAlign: TextAlign.center,
              style: textStyle.copyWith(color: Colors.white), 
            ),
          ),
        ),
      ],
    );
  }
}

class _SloganGradientTransform extends GradientTransform {
  final double value;
  const _SloganGradientTransform(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final double dist = bounds.width * 2.5;
    return Matrix4.translationValues(-bounds.width + (dist * value), 0, 0);
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
        border: useBorderOnWhite 
            ? Border.all(color: Colors.grey.shade200) 
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