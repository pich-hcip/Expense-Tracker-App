import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/screens/transaction_detail_screen.dart';

void main() {
  testWidgets('transaction without a description remains visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionDetailScreen(
          title: 'Food',
          category: 'Food',
          type: 'EXPENSE',
          amount: 25,
          walletName: 'Cash',
          date: DateTime(2026, 9, 29),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('-\$25.00'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Description'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No description'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final income in [true, false]) {
    for (final dark in [true, false]) {
      testWidgets(
        '${income ? 'Income' : 'Expense'} details in ${dark ? 'dark' : 'light'} mode',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final item = TransactionItem.fromJson({
            'id': '1',
            'kind': income ? 'INCOME' : 'EXPENSE',
            'amount': income ? 800 : -500,
            'title': income ? 'September salary' : 'Taxi home',
            'transactionDate': '2026-09-29',
            'walletName': 'AC',
            'categoryName': income ? 'Salary' : 'Transport',
            'categoryIcon': income ? 'business' : 'car',
            'categoryColorHex': '#2979FF',
          });
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              home: TransactionDetailScreen.fromTransaction(transaction: item),
            ),
          );
          await tester.pumpAndSettle();
          final amount = tester.widget<Text>(
            find.text(income ? '+\$800.00' : '-\$500.00'),
          );
          expect(
            amount.style!.color,
            income
                ? (dark ? const Color(0xFF51DBAF) : const Color(0xFF07865F))
                : (dark ? const Color(0xFFFF7884) : const Color(0xFFEA3044)),
          );
          expect(find.text('AC'), findsOneWidget);
          expect(find.text('Category'), income ? findsNothing : findsOneWidget);
          expect(
            find.byIcon(income ? Icons.attach_money : Icons.directions_car),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.text('Sep 29, 2026'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          if (!income) {
            await tester.scrollUntilVisible(
              find.text('Description'),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            expect(
              find.byWidgetPredicate(
                (widget) =>
                    widget is SelectableText && widget.data == 'Taxi home',
              ),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
