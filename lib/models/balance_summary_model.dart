// lib/models/balance_summary_model.dart
class BalanceSummary {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;

  BalanceSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory BalanceSummary.fromJson(Map<String, dynamic> json) {
    return BalanceSummary(
      totalBalance: double.parse(json['totalBalance'].toString()),
      totalIncome: double.parse(json['totalIncome'].toString()),
      totalExpense: double.parse(json['totalExpense'].toString()),
    );
  }
}