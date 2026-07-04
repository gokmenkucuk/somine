import 'package:somine_app/core/exceptions/network_exceptions.dart';

class FailureMapper {
  static String toUserMessage(Object error) {
    return switch (error) {
      TimeoutException() => 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.',
      NetworkFailure() => 'İnternet bağlantınızı kontrol edin.',
      UnauthorizedException() =>
        'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      ServerException() =>
        'Sunucu hatası oluştu. Lütfen biraz sonra tekrar deneyin.',
      ValidationException e => e.userMessage,
      ConflictException() => 'Bu işlem zaten yapıldı.',
      _ => 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
    };
  }

  static bool isRetryable(Object error) {
    return error is AppException && error.retryable;
  }
}
