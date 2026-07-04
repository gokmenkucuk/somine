sealed class AppException implements Exception {
  final String message;
  final String userMessage;
  final bool retryable;

  const AppException(
    this.message, {
    required this.userMessage,
    this.retryable = false,
  });

  @override
  String toString() => 'AppException: $message';
}

class TimeoutException extends AppException {
  const TimeoutException(super.message, {required super.userMessage})
      : super(retryable: true);
}

class NetworkFailure extends AppException {
  const NetworkFailure(super.message, {required super.userMessage})
      : super(retryable: true);
}

class ServerException extends AppException {
  const ServerException(super.message, {required super.userMessage})
      : super(retryable: true);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {required super.userMessage})
      : super(retryable: false);
}

class ValidationException extends AppException {
  const ValidationException(super.message, {required super.userMessage})
      : super(retryable: false);
}

class ConflictException extends AppException {
  const ConflictException(super.message, {required super.userMessage})
      : super(retryable: false);
}
