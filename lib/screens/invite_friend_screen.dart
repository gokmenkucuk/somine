import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';

class InviteFriendScreen extends StatelessWidget {
  const InviteFriendScreen({super.key});

  static const String appStoreLink = 'https://apps.apple.com/app/somine';
  static const String shareMessage = 'So Mine\'ı dene! Tüm kaydettiğin içerikleri tek yerde topla. 📌✨ $appStoreLink';

  @override
  Widget build(BuildContext context) {
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
          'Arkadaşını Davet Et',
          style: GoogleFonts.poppins(
            color: context.colors.headline,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Illustration
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withOpacity(0.2),
                    context.colors.secondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  PhosphorIconsFill.gift,
                  size: 80,
                  color: context.colors.primary,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Arkadaşlarınla Paylaş!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.colors.headline,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'So Mine\'ı sevdiğin kişilerle paylaş.\nOnlar da içeriklerini kolayca organize etsin!',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: context.colors.body,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // Link Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      appStoreLink,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: context.colors.body,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: appStoreLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Link kopyalandı!',
                            style: GoogleFonts.poppins(),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.copy,
                            size: 16,
                            color: context.colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kopyala',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Share.share(shareMessage);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(PhosphorIconsRegular.shareFat, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Paylaş',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Social Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  context,
                  icon: PhosphorIconsRegular.whatsappLogo,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => Share.share(shareMessage),
                ),
                const SizedBox(width: 16),
                _buildSocialButton(
                  context,
                  icon: PhosphorIconsRegular.telegramLogo,
                  label: 'Telegram',
                  color: const Color(0xFF0088CC),
                  onTap: () => Share.share(shareMessage),
                ),
                const SizedBox(width: 16),
                _buildSocialButton(
                  context,
                  icon: PhosphorIconsRegular.messengerLogo,
                  label: 'Messenger',
                  color: const Color(0xFF0084FF),
                  onTap: () => Share.share(shareMessage),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: context.colors.body,
            ),
          ),
        ],
      ),
    );
  }
}
