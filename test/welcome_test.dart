import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_app/providers/auth_provider.dart';
import 'package:expense_tracker_app/screens/welcome_screen.dart';
import 'package:expense_tracker_app/screens/auth/login_screen.dart';
import 'package:expense_tracker_app/screens/auth/register_screen.dart';

void main() {
  for (final action in ['Login', 'Skip', 'Create Account']) {
    testWidgets('welcome opens $action on a small screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: WelcomeScreen()),
      ));
      expect(find.text('Welcome to'), findsOneWidget);
      await tester.ensureVisible(find.text(action));
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      expect(find.byType(action == 'Create Account' ? RegisterScreen : LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('restored session offers Continue', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AuthProvider()..isAuthenticated = true,
      child: const MaterialApp(home: WelcomeScreen()),
    ));
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Create Account'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
