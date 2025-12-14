import 'package:flutter/material.dart';
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
    setState(() => _isLoading = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithApple();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş hatası: $e')),
        );
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
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingLG,
              vertical: DesignTokens.spacingXXL,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Crystal Illustration
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/images/onboarding_crystal.png'),
                      fit: BoxFit.contain,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXL),
                
                // Headline
                Text(
                  'Dijital Dünyanı\nTasarla.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.textPrimary,
                    height: 1.2,
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Apple Button (Black)
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

                // Google Button (White with Shadow)
                _SocialButton(
                  onPressed: _signInWithGoogle,
                  icon: Icons.g_mobiledata, // Or custom SVG
                  label: 'Google ile Devam Et',
                  backgroundColor: Colors.white,
                  textColor: Colors.black87,
                  hasShadow: true,
                ),
                
                // Guest Option (if not forced)
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
                
                const SizedBox(height: DesignTokens.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool hasShadow;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.hasShadow = false,
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
        border: hasShadow ? null : Border.all(color: Colors.transparent),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLG),
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
