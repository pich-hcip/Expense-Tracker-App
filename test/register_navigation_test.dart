import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_app/providers/auth_provider.dart';
import 'package:expense_tracker_app/screens/auth/register_screen.dart';
import 'package:expense_tracker_app/screens/auth/otp_verification_screen.dart';

class _RegisteredAuth extends AuthProvider {
  @override
  Future<bool> register(String fullName, String email, String password) async => true;
}

void main() {
  for (final systemBack in [false, true]) {
    testWidgets('OTP back preserves registration, systemBack=$systemBack', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
        create: (_) => _RegisteredAuth(),
        child: const MaterialApp(home: RegisterScreen()),
      ));
      final fields = find.byType(TextFormField);
      for (final entry in ['Test User', 'test@example.com', 'Secret123!', 'Secret123!'].asMap().entries) {
        await tester.enterText(fields.at(entry.key), entry.value);
      }
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      if (systemBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      }
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
