import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_app/core/api_client.dart';
import 'package:expense_tracker_app/screens/personal_information_screen.dart';

void main() {
  for (final scenario in ['update', 'clear', 'ignored']) {
    final clear = scenario == 'clear';
    testWidgets('phone save: $scenario', (tester) async {
      final original = ApiClient.dio.interceptors.toList();
      final profile = <String, dynamic>{
        'id': 'user-1',
        'fullName': 'Test User',
        'email': 'test@example.com',
        'phoneNumber': '+85512345678',
      };
      final writes = <Map<String, dynamic>>[];
      ApiClient.dio.interceptors.clear();
      ApiClient.dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        if (options.method == 'PUT') {
          final data = Map<String, dynamic>.from(options.data as Map);
          writes.add(data);
          if (scenario != 'ignored') profile.addAll(data);
        }
        handler.resolve(Response(requestOptions: options, statusCode: 200, data: profile));
      }));
      addTearDown(() {
        ApiClient.dio.interceptors.clear();
        ApiClient.dio.interceptors.addAll(original);
      });
      await tester.pumpWidget(const MaterialApp(home: PersonalInformationScreen()));
      await tester.pumpAndSettle();
      expect(find.text('+85512345678'), findsOneWidget);
      await tester.ensureVisible(find.text('Edit Profile'));
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      final phone = find.byWidgetPredicate((widget) =>
          widget is TextField && widget.keyboardType == TextInputType.phone);
      expect(find.text('+85512345678'), findsOneWidget);
      await tester.enterText(phone, 'invalid');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      expect(find.textContaining('Enter 7–15 digits'), findsOneWidget);
      await tester.enterText(phone, clear ? '' : '+855 (98) 765-432');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(writes.single['phoneNumber'], clear ? null : '+85598765432');
      if (scenario == 'ignored') {
        expect(find.textContaining('The server did not retain'), findsOneWidget);
        expect(find.text('Save Changes'), findsOneWidget);
        expect(find.text('Profile updated'), findsNothing);
        expect(tester.takeException(), isNull);
        return;
      }
      expect(find.text(clear ? 'Not added' : '+85598765432'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
