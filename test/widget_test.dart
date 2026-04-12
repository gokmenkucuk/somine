// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:somine_app/main.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/screens/login_screen.dart';
import 'mock.dart';

void main() {
  setupFirebaseAuthMocks();

  testWidgets('App renders and navigates to LoginScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Wrap with ProviderScope as required by the app, overriding auth state to be null (not logged in)
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: AuthWrapper()),
      ),
    );

    await tester.pump();

    // Verify LoginScreen is present
    expect(find.byType(LoginScreen), findsOneWidget);
    
    // Check for Google login button
    expect(find.text('Google ile Devam Et'), findsOneWidget);
    // Note: Depends on platform. On test environment formatted as iOS might show Apple button.
    // Let's just check for the slogan.
  });
}
