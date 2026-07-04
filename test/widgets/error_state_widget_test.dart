import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_theme.dart';
import 'package:somine_app/core/providers/theme_provider.dart';
import 'package:somine_app/widgets/error_state_widget.dart';

void main() {
  testWidgets('renders message and retry button', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(AppThemeEnum.air),
        home: Scaffold(
          body: ErrorStateWidget(
            message: 'Bir hata oluştu',
            onRetry: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Bir şeyler ters gitti'), findsOneWidget);
    expect(find.text('Bir hata oluştu'), findsOneWidget);
    expect(find.text('Tekrar Dene'), findsOneWidget);

    await tester.tap(find.text('Tekrar Dene'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('does not show retry button when callback is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(AppThemeEnum.air),
        home: const Scaffold(body: ErrorStateWidget(message: 'Salt mesaj')),
      ),
    );

    expect(find.text('Salt mesaj'), findsOneWidget);
    expect(find.text('Tekrar Dene'), findsNothing);
  });

  testWidgets('renders custom icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(AppThemeEnum.air),
        home: const Scaffold(
          body: ErrorStateWidget(
            message: 'İkon testi',
            icon: PhosphorIconsLight.lock,
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon).first);
    expect(icon.icon, PhosphorIconsLight.lock);
  });
}
