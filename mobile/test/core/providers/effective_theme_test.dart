import 'package:flutter_test/flutter_test.dart';
import 'package:somine_app/core/providers/subscription_provider.dart';
import 'package:somine_app/core/providers/theme_provider.dart';

void main() {
  test('premium theme falls back to system once a free plan is confirmed', () {
    for (final theme in [AppThemeEnum.midnight, AppThemeEnum.vibe]) {
      expect(
        resolveEffectiveTheme(
          theme,
          subscriptionLoaded: true,
          isPremium: false,
        ),
        AppThemeEnum.system,
      );
    }
  });

  test('premium theme is kept for premium users', () {
    expect(
      resolveEffectiveTheme(
        AppThemeEnum.vibe,
        subscriptionLoaded: true,
        isPremium: true,
      ),
      AppThemeEnum.vibe,
    );
  });

  test('stored theme is kept while the subscription is still loading', () {
    expect(
      resolveEffectiveTheme(
        AppThemeEnum.midnight,
        subscriptionLoaded: false,
        isPremium: false,
      ),
      AppThemeEnum.midnight,
    );
  });

  test('free themes are never changed', () {
    for (final theme in [AppThemeEnum.system, AppThemeEnum.air]) {
      expect(
        resolveEffectiveTheme(
          theme,
          subscriptionLoaded: true,
          isPremium: false,
        ),
        theme,
      );
    }
  });
}
