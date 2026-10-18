import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somine_app/core/design/app_theme.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/theme_provider.dart';
import 'package:somine_app/core/services/onboarding_content_preparer.dart';
import 'package:somine_app/screens/onboarding_prep_screen.dart';

/// Testin kontrol ettiği sahte hazırlık işi.
class _FakePreparer {
  final Completer<void> completer = Completer<void>();
  OnboardingPrepProgress? onProgress;
  String? userId;
  String? displayName;
  int calls = 0;

  Future<void> call({
    required String userId,
    String? displayName,
    required OnboardingPrepProgress onProgress,
  }) {
    calls++;
    this.userId = userId;
    this.displayName = displayName;
    this.onProgress = onProgress;
    return completer.future;
  }
}

const _titles = [
  'Her yerden kaydet',
  'Düzenle ve paylaş',
  'Hiçbir şeyi unutma',
  'Gizli Kasa',
  'Her gün ana ekranında',
];

void main() {
  late _FakePreparer fake;
  late ProviderContainer container;

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool disableAnimations = false,
    Size logicalSize = const Size(393, 852),
    double textScale = 1.0,
    AppThemeEnum theme = AppThemeEnum.air,
  }) async {
    tester.view.physicalSize = logicalSize * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Test bölgesinde (FakeAsync) yaratılmalı ki tamamlanması pump ile işlesin.
    fake = _FakePreparer();

    container = ProviderContainer(
      overrides: [
        onboardingContentPreparerProvider.overrideWithValue(fake.call),
        onboardingStateProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.getTheme(theme),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: disableAnimations,
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child!,
              ),
          home: const OnboardingPrepScreen(userId: 'u1', displayName: 'Ada'),
        ),
      ),
    );
    await tester.pump();
  }

  /// Ağaç sökülsün ki periyodik zamanlayıcı test sonunda asılı kalmasın.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('starts preparation once and renders all five tour pages', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(fake.calls, 1);
    expect(fake.userId, 'u1');
    expect(fake.displayName, 'Ada');

    for (var i = 0; i < _titles.length; i++) {
      expect(find.text(_titles[i]), findsOneWidget);
      // Yalnız Gizli Kasa kartında Premium etiketi var.
      expect(find.text('Premium'), i == 3 ? findsOneWidget : findsNothing);
      if (i < _titles.length - 1) {
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('Sayfa 5 / 5'), findsNothing); // dots: tek etiket
    expect(find.bySemanticsLabel('Sayfa 5 / 5'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('button label switches when preparation completes', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Koleksiyonların hazırlanıyor…'), findsOneWidget);
    expect(find.text('Hemen başla'), findsOneWidget);
    expect(find.text('Başlayalım'), findsNothing);

    fake.onProgress!(0.5);
    await tester.pump(const Duration(milliseconds: 400));
    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.semanticsValue, '%50');

    fake.completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Hazır!'), findsOneWidget);
    expect(find.text('Başlayalım'), findsOneWidget);
    expect(find.text('Hemen başla'), findsNothing);
    expect(container.read(onboardingStateProvider), isFalse);

    await unmount(tester);
  });

  testWidgets('failed preparation still completes so the user can continue', (
    tester,
  ) async {
    await pumpScreen(tester);

    fake.completer.completeError(Exception('network down'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Başlayalım'), findsOneWidget);
    expect(container.read(onboardingStateProvider), isFalse);

    await unmount(tester);
  });

  testWidgets('auto-advances every few seconds', (tester) async {
    await pumpScreen(tester);

    expect(find.text(_titles[0]), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(_titles[1]), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('does not auto-advance with Reduce Motion', (tester) async {
    await pumpScreen(tester, disableAnimations: true);

    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.text(_titles[0]), findsOneWidget);
    expect(find.text(_titles[1]), findsNothing);

    await unmount(tester);
  });

  testWidgets('stops auto-advancing once the user touches the tour', (
    tester,
  ) async {
    await pumpScreen(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.up();
    await tester.pump(const Duration(seconds: 9));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(_titles[0]), findsOneWidget);

    await unmount(tester);
  });
  testWidgets('preparation keeps running after the screen is gone', (
    tester,
  ) async {
    await pumpScreen(tester);

    // Kullanıcı erken geçti: ekran ağaçtan çıkar, container yaşar.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SizedBox.shrink(),
      ),
    );
    expect(container.read(onboardingStateProvider), isTrue);

    fake.onProgress!(0.8); // dispose sonrası setState yapılmamalı
    fake.completer.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(container.read(onboardingStateProvider), isFalse);
  });
  testWidgets('lays out on a small phone at the largest text size (dark)', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      logicalSize: const Size(375, 667),
      textScale: 2.0,
      theme: AppThemeEnum.midnight,
    );

    for (var i = 0; i < _titles.length; i++) {
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
    }
    fake.completer.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await unmount(tester);
  });
}
