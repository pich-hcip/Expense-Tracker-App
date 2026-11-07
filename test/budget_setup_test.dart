import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_app/core/api_client.dart';
import 'package:expense_tracker_app/screens/add_budget_screen.dart';

void main() {
  testWidgets('validates allocation and saves the selected category amount', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final original = ApiClient.dio.interceptors.toList();
    final writes = <Map<String, dynamic>>[];
    ApiClient.dio.interceptors.clear();
    ApiClient.dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      dynamic data;
      if (options.path == '/categories') {
        data = [{'id': 'food', 'name': 'Food', 'kind': 'EXPENSE', 'icon': 'restaurant', 'colorHex': '#FF6600'}];
      } else if (options.method == 'POST') {
        writes.add(Map<String, dynamic>.from(options.data as Map));
        data = {'id': 'budget-1', 'categoryId': 'food', 'categoryName': 'Food', 'monthlyLimit': 100,
          'periodMonth': '2026-09-01'};
      } else if (options.path == '/budgets/summary') {
        data = <String, dynamic>{};
      } else {
        data = [];
      }
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: data));
    }));
    addTearDown(() { ApiClient.dio.interceptors.clear(); ApiClient.dio.interceptors.addAll(original); });
    await tester.pumpWidget(MaterialApp(home: AddBudgetScreen(selectedMonth: DateTime(2026, 9))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.ensureVisible(find.text('Set Budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Budget'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Category Budgets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Category Budgets'));
    await tester.pumpAndSettle();
    expect(writes, isEmpty);
    expect(find.textContaining('Allocate the full'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.ensureVisible(find.text('Save Category Budgets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Category Budgets'));
    await tester.pumpAndSettle();
    expect(writes, hasLength(1));
    expect(writes.single['monthlyLimit'], 100);
    expect(writes.single['categoryId'], 'food');
    expect(writes.single['periodMonth'], '2026-09-01');
    expect(tester.takeException(), isNull);
  });
}
