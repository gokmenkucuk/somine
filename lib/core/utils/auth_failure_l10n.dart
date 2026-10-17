import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:somine_app/core/repositories/auth_repository.dart';

/// Giriş / yeniden doğrulama hatasını kullanıcıya gösterilecek metne çevirir.
///
/// Kullanıcı iptal ettiyse `null` döner: iptal bir hata değildir, sessizce
/// geçilir. Ham `e.toString()` asla gösterilmez.
String? authFailureMessage(
  Object error,
  AppLocalizations l10n, {
  required String fallback,
}) {
  final failure = AuthFailure.from(error);
  switch (failure.code) {
    case AuthFailureCode.cancelled:
      return null;
    case AuthFailureCode.network:
      return l10n.failureNetwork;
    case AuthFailureCode.accountMismatch:
      return l10n.authErrorAccountMismatch;
    case AuthFailureCode.unknown:
      return fallback;
  }
}
