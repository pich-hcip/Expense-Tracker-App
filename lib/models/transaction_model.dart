// lib/models/transaction_model.dart
class TransactionItem {
  final String id;
  final String kind; // "EXPENSE" or "INCOME"
  final double amount;
  final String title;
  final String transactionDate;

  TransactionItem({
    required this.id,
    required this.kind,
    required this.amount,
    required this.title,
    required this.transactionDate,
  });

  bool get isIncome => kind == 'INCOME';

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'],
      kind: json['kind'],
      amount: double.parse(json['amount'].toString()),
      title: json['title'] ?? '',
      transactionDate: json['transactionDate'],
    );
  }
}