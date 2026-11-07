import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_app/models/transaction_model.dart';

void main() {
  TransactionItem transaction(String title, {String? walletName}) =>
      TransactionItem.fromJson({
        'id': 'transaction-1',
        'kind': 'INCOME',
        'amount': 800,
        'title': title,
        'transactionDate': '2026-09-30',
        'walletName': walletName,
      });

  test('uses account name returned by the API', () {
    expect(transaction('Salary', walletName: 'ABA').displayWalletName, 'ABA');
  });

  test('older wallet income entries retain the account name', () {
    expect(transaction('Balance added - AC').displayWalletName, 'AC');
    expect(transaction('Starting balance - ABA').displayWalletName, 'ABA');
  });

  test('current account name takes precedence after a rename', () {
    expect(
      transaction('Balance added - AC', walletName: 'ABA').displayWalletName,
      'ABA',
    );
  });

  test('does not mistake an ordinary transaction title for an account', () {
    expect(transaction('Salary').displayWalletName, isEmpty);
  });
  test('income notes are retained without exposing generated wallet titles', () {
    final income = TransactionItem.fromJson({
      'id': 'income-1',
      'kind': 'INCOME',
      'amount': 200,
      'title': 'September bonus',
      'categoryName': 'Salary',
      'transactionDate': '2026-09-30',
    });
    expect(income.displayNote, 'September bonus');
    expect(transaction('Starting balance - ABA').displayNote, isEmpty);
    expect(transaction('Balance added - ABA').displayNote, isEmpty);
  });
  test('expense notes support legacy titles and explicit notes', () {
    TransactionItem expense(String title, {String? note}) =>
        TransactionItem.fromJson({
          'id': '1',
          'kind': 'EXPENSE',
          'amount': 50,
          'title': title,
          'categoryName': 'Food',
          'transactionDate': '2026-09-30',
          if (note != null) 'note': note,
        });
    expect(expense('Food').displayNote, isEmpty);
    expect(expense('Lunch with friends').displayNote, 'Lunch with friends');
    expect(
      expense('Food', note: 'Lunch\nPaid in cash').displayNote,
      'Lunch\nPaid in cash',
    );
    expect(expense('Old title', note: '').displayNote, isEmpty);
  });
}
