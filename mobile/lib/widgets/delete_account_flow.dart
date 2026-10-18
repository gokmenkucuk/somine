import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/providers/navigation_providers.dart';
import 'package:somine_app/core/providers/theme_provider.dart';
import 'package:somine_app/core/repositories/auth_repository.dart';
import 'package:somine_app/core/utils/auth_failure_l10n.dart';
import 'package:somine_app/screens/login_screen.dart';

/// Hesap silme akışı — Profil ve Hesap Bilgileri ekranları aynı akışı kullanır.
///
/// 1. Onay (geri alınamaz + App Store aboneliğinin ayrıca iptal edilmesi notu)
/// 2. Yeniden doğrulama + silme (AuthRepository.deleteAccount)
/// 3. Başarıda Login'e döner; iptalde sessiz kalır; hatada yerelleştirilmiş
///    snackbar gösterir.
///
/// Navigator ve ScaffoldMessenger, async boşluklardan ÖNCE yakalanır: onay
/// diyaloğunun context'i kapandıktan sonra kullanılmaz.
Future<void> runDeleteAccountFlow(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  final shouldDelete = await showCupertinoDialog<bool>(
    context: context,
    builder:
        (dialogContext) => CupertinoAlertDialog(
          title: Text(l10n.profileDeleteAccount),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${l10n.profileDeleteAccountMessage}\n\n'
              '${l10n.deleteAccountSubscriptionNote}',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.profileCancel),
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(l10n.profileDeleteAccount),
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
  );

  if (shouldDelete != true || !context.mounted) return;

  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);

  // Opak arka plan: silme sırasında boş akışın görünmesini engeller.
  showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: Colors.black,
    builder:
        (_) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
  );

  try {
    // Sonraki giriş akıştan başlasın.
    container.read(homeTabIndexProvider.notifier).state = 0;

    await AuthRepository().deleteAccount();
    // Silinen hesabın kişiselleştirmesi sonraki hesaba taşınmasın.
    await container.read(themeProvider.notifier).setTheme(AppThemeEnum.system);

    navigator.pop(); // loading
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  } catch (e) {
    navigator.pop(); // loading

    final message = authFailureMessage(
      e,
      l10n,
      fallback: l10n.deleteAccountErrorGeneric,
    );
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
