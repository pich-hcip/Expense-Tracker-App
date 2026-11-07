import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_app/core/api_client.dart';
import 'package:expense_tracker_app/screens/report_screen.dart';
import 'package:expense_tracker_app/services/report_service.dart';

void main() {
  setUp(() {
    final original = ApiClient.dio.interceptors.toList();
    ApiClient.dio.interceptors.clear();
    ApiClient.dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final dynamic data = options.path == '/reports/summary'
          ? {'startDate': '2026-10-01', 'endDate': '2026-10-31', 'totalIncome': 500, 'totalExpense': 30, 'totalBalance': 470}
          : options.path == '/transactions'
              ? [
                  for (final amount in [10, 20])
                    {'id': '$amount', 'kind': 'EXPENSE', 'amount': amount, 'transactionDate': '2026-10-02'},
                  {'id': 'income', 'kind': 'INCOME', 'amount': 500, 'transactionDate': '2026-10-02'},
                  {'id': 'previous', 'kind': 'EXPENSE', 'amount': 90, 'transactionDate': '2026-09-30'},
                ]
              : [{'categoryName': 'Food', 'amount': 30, 'percentage': 100}];
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: data));
    }));
    addTearDown(() {
      ApiClient.dio.interceptors.clear();
      ApiClient.dio.interceptors.addAll(original);
    });
  });

  test('daily trend sums only expenses in the selected month', () async {
    final trend = await ReportService().getExpenseTrend('2026-10');
    expect(trend.length, 31);
    expect(trend[1].amount, 30);
    expect(trend.fold<double>(0, (sum, item) => sum + item.amount), 30);
  });

  testWidgets('report displays successful responses instead of load error', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Could not load report.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
