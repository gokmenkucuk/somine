import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:intl/intl.dart';

class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final creationTime = user?.metadata.creationTime;
    
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
          'Hesap Bilgileri',
          style: GoogleFonts.poppins(
            color: context.colors.headline,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Avatar
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [context.colors.primary, context.colors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  (user?.email != null && user!.email!.isNotEmpty) 
                      ? user!.email!.substring(0, 1).toUpperCase() 
                      : 'U',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Info Cards
          _buildInfoCard(
            context,
            icon: CupertinoIcons.mail,
            label: 'E-posta',
            value: user?.email ?? 'Bilinmiyor',
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoCard(
            context,
            icon: CupertinoIcons.calendar,
            label: 'Hesap Oluşturma',
            value: creationTime != null 
                ? DateFormat('d MMMM yyyy', 'tr').format(creationTime)
                : 'Bilinmiyor',
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoCard(
            context,
            icon: CupertinoIcons.checkmark_shield,
            label: 'E-posta Doğrulama',
            value: user?.emailVerified == true ? 'Doğrulandı' : 'Doğrulanmadı',
            valueColor: user?.emailVerified == true ? Colors.green : Colors.orange,
          ),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          _buildActionButton(
            context,
            icon: PhosphorIconsRegular.lock,
            label: 'Şifre Değiştir',
            onTap: () => _showPasswordChangeDialog(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildActionButton(
            context,
            icon: PhosphorIconsRegular.trash,
            label: 'Hesabı Sil',
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.colors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.colors.body,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? context.colors.headline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : context.colors.headline;
    
    return Material(
      color: context.colors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(CupertinoIcons.chevron_right, color: color.withOpacity(0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordChangeDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Şifre Değiştir'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('E-posta adresinize şifre sıfırlama bağlantısı gönderilecek.'),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final user = FirebaseAuth.instance.currentUser;
              if (user?.email != null) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifre sıfırlama e-postası gönderildi')),
                  );
                }
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Bu işlem geri alınamaz. Tüm verileriniz silinecektir.'),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              // Show re-auth required message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Güvenlik nedeniyle yeniden giriş yapmanız gerekiyor')),
              );
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
