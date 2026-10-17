sealed class AppException implements Exception {
  final String message;
  final String userMessage;
  final bool retryable;

  /// Language-independent, machine-readable reason for the failure.
  ///
  /// Repositories have no [BuildContext], so they cannot localize. Instead of
  /// baking a Turkish sentence into [userMessage] — which then leaks verbatim
  /// onto an English device — they set a [code] here and let
  /// `FailureMapper.toUserMessage` translate it. When [code] is null the
  /// mapper falls back to its type-based mapping.
  final String? code;

  const AppException(
    this.message, {
    required this.userMessage,
    this.retryable = false,
    this.code,
  });

  @override
  String toString() => 'AppException: $message';
}

class TimeoutException extends AppException {
  const TimeoutException(super.message, {required super.userMessage, super.code})
      : super(retryable: true);
}

class NetworkFailure extends AppException {
  const NetworkFailure(super.message, {required super.userMessage, super.code})
      : super(retryable: true);
}

class ServerException extends AppException {
  const ServerException(super.message, {required super.userMessage, super.code})
      : super(retryable: true);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(
    super.message, {
    required super.userMessage,
    super.code,
  }) : super(retryable: false);
}

class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    required super.userMessage,
    super.code,
  }) : super(retryable: false);
}

/// The backend endpoint for this feature is not available yet (HTTP 404).
class FeatureUnavailableException extends AppException {
  const FeatureUnavailableException(
    super.message, {
    required super.userMessage,
    super.code,
  }) : super(retryable: false);
}

class ConflictException extends AppException {
  const ConflictException(
    super.message, {
    required super.userMessage,
    super.code,
  }) : super(retryable: false);
}

/// Machine-readable [AppException.code] values understood by `FailureMapper`.
abstract final class AppErrorCodes {
  static const shareUserNotFound = 'share.userNotFound';
  static const shareAlreadyShared = 'share.alreadyShared';
  static const shareCreateFailed = 'share.createFailed';
}
