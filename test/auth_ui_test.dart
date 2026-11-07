import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_app/providers/auth_provider.dart';
import 'package:expense_tracker_app/screens/auth/login_screen.dart';
import 'package:expense_tracker_app/screens/auth/register_screen.dart';

void main() {
  for (final register in [false, true]) {
    testWidgets(
      '${register ? 'Register' : 'Login'} fields stay above keyboard',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(() {
          tester.view.resetViewInsets();
          tester.binding.setSurfaceSize(null);
        });
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: MaterialApp(
              home: register ? const RegisterScreen() : const LoginScreen(),
            ),
          ),
        );
        final password = find.byType(TextFormField).last;
        await tester.ensureVisible(password);
        await tester.tap(password);
        await tester.pumpAndSettle();
        final keyboardTop = 844 - 320 / tester.view.devicePixelRatio;
        expect(
          tester.getBottomLeft(password).dy,
          lessThanOrEqualTo(keyboardTop),
        );
        await tester.ensureVisible(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final register in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets(
        '${register ? 'Register' : 'Login'} narrow layout, dark=$dark',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final theme = dark ? ThemeData.dark() : ThemeData.light();
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => AuthProvider(),
              child: MaterialApp(
                theme: theme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: child!,
                ),
                home: register ? const RegisterScreen() : const LoginScreen(),
              ),
            ),
          );
          expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
          expect(find.text('Please enter your email'), findsNothing);
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(register ? 1 : 0), 'invalid@');
          expect(find.text('Please enter a valid email'), findsNothing);
          await tester.ensureVisible(find.byType(ElevatedButton));
          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();
          expect(find.text('Please enter a valid email'), findsOneWidget);
          await tester.ensureVisible(find.byType(TextButton).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
