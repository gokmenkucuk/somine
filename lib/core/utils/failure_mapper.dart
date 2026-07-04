import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart';

class FailureMapper {
  /// Maps a caught [error] to a user-facing message.
  ///
  /// [l10n] should be passed whenever available (i.e. from any call site
  /// that has a [BuildContext], via `AppLocalizations.of(context)`) so the
  /// message is localized. Call sites without access to localization (e.g.
  /// background/repository layers not yet wired for locale-aware infra) may
  /// omit it; a Turkish fallback is used in that case pending their own
  /// migration.
  static String toUserMessage(Object error, [AppLocalizations? l10n]) {
    return switch (error) {
      TimeoutException() =>
        l10n?.failureTimeout ??
            'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.',
      NetworkFailure() =>
        l10n?.failureNetwork ?? 'İnternet bağlantınızı kontrol edin.',
      UnauthorizedException() =>
        l10n?.failureUnauthorized ??
            'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      ServerException() =>
        l10n?.failureServer ??
            'Sunucu hatası oluştu. Lütfen biraz sonra tekrar deneyin.',
      ValidationException e => e.userMessage,
      ConflictException() => l10n?.failureConflict ?? 'Bu işlem zaten yapıldı.',
      _ => l10n?.failureUnknown ??
          'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
    };
  }

  static bool isRetryable(Object error) {
    return error is AppException && error.retryable;
  }
}
