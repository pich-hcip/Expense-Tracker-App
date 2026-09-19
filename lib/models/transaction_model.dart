class TransactionItem {
  final String id;
  final String kind;
  final double amount;
  final String title;
  final String transactionDate;
  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;

  TransactionItem({
    required this.id,
    required this.kind,
    required this.amount,
    required this.title,
    required this.transactionDate,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
  });

  bool get isIncome => kind == 'INCOME';

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'],
      kind: json['kind'],
      amount: double.parse(json['amount'].toString()),
      title: json['title'] ?? json['categoryName'] ?? '',
      transactionDate: json['transactionDate'],
      categoryName: json['categoryName'] ?? 'Uncategorized',
      categoryIcon: json['categoryIcon'] ?? 'more',
      categoryColorHex: json['categoryColorHex'] ?? '#929292',
    );
  }
}