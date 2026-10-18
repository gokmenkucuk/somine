import 'package:flutter_test/flutter_test.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart';
import 'package:somine_app/core/utils/failure_mapper.dart';

void main() {
  group('AppException hierarchy', () {
    test('retryable flags match expected behavior', () {
      expect(
        const TimeoutException('timeout', userMessage: 'timeout').retryable,
        isTrue,
      );
      expect(
        const NetworkFailure('network', userMessage: 'network').retryable,
        isTrue,
      );
      expect(
        const ServerException('server', userMessage: 'server').retryable,
        isTrue,
      );
      expect(
        const UnauthorizedException(
          'unauthorized',
          userMessage: 'unauthorized',
        ).retryable,
        isFalse,
      );
      expect(
        const ValidationException(
          'validation',
          userMessage: 'validation',
        ).retryable,
        isFalse,
      );
      expect(
        const ConflictException('conflict', userMessage: 'conflict').retryable,
        isFalse,
      );
    });

    test('FailureMapper maps known exceptions to Turkish messages', () {
      expect(
        FailureMapper.toUserMessage(
          const TimeoutException('timeout', userMessage: 'ignored'),
        ),
        'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.',
      );
      expect(
        FailureMapper.toUserMessage(
          const NetworkFailure('network', userMessage: 'ignored'),
        ),
        'İnternet bağlantınızı kontrol edin.',
      );
      expect(
        FailureMapper.toUserMessage(
          const UnauthorizedException('unauthorized', userMessage: 'ignored'),
        ),
        'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      );
      expect(
        FailureMapper.toUserMessage(
          const ServerException('server', userMessage: 'ignored'),
        ),
        'Sunucu hatası oluştu. Lütfen biraz sonra tekrar deneyin.',
      );
      expect(
        FailureMapper.toUserMessage(
          const ValidationException('validation', userMessage: 'Özel mesaj'),
        ),
        'Özel mesaj',
      );
      expect(
        FailureMapper.toUserMessage(
          const ConflictException('conflict', userMessage: 'ignored'),
        ),
        'Bu işlem zaten yapıldı.',
      );
      expect(
        FailureMapper.toUserMessage(Exception('unknown')),
        'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
      );
    });

    test('FailureMapper.isRetryable follows exception metadata', () {
      expect(
        FailureMapper.isRetryable(
          const TimeoutException('timeout', userMessage: 'timeout'),
        ),
        isTrue,
      );
      expect(
        FailureMapper.isRetryable(
          const ConflictException('conflict', userMessage: 'conflict'),
        ),
        isFalse,
      );
      expect(FailureMapper.isRetryable(Exception('unknown')), isFalse);
    });
  });
}
