class ReportSummary {
  final DateTime startDate;
  final DateTime endDate;

  final double totalIncome;
  final double totalExpense;
  final double totalBalance;

  const ReportSummary({
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
  });

  factory ReportSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReportSummary(
      startDate: DateTime.parse(
        json['startDate'].toString(),
      ),
      endDate: DateTime.parse(
        json['endDate'].toString(),
      ),
      totalIncome:
          (json['totalIncome'] as num?)
                  ?.toDouble() ??
              0,
      totalExpense:
          (json['totalExpense'] as num?)
                  ?.toDouble() ??
              0,
      totalBalance:
          (json['totalBalance'] as num?)
                  ?.toDouble() ??
              0,
    );
  }
}

class ExpenseTrendItem {
  final DateTime date;
  final double amount;

  const ExpenseTrendItem({
    required this.date,
    required this.amount,
  });

  factory ExpenseTrendItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExpenseTrendItem(
      date: DateTime.parse(
        json['date'].toString(),
      ),
      amount:
          (json['amount'] as num?)
                  ?.toDouble() ??
              0,
    );
  }
}

class CategoryExpenseItem {
  final String? categoryId;

  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;

  final double amount;
  final double percentage;

  const CategoryExpenseItem({
    this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    required this.amount,
    required this.percentage,
  });

  factory CategoryExpenseItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return CategoryExpenseItem(
      categoryId:
          json['categoryId']?.toString(),

      categoryName:
          json['categoryName']?.toString() ??
              'Uncategorized',

      categoryIcon:
          json['categoryIcon']?.toString() ??
              'more',

      categoryColorHex:
          json['categoryColorHex']
                  ?.toString() ??
              '#929292',

      amount:
          (json['amount'] as num?)
                  ?.toDouble() ??
              0,

      percentage:
          (json['percentage'] as num?)
                  ?.toDouble() ??
              0,
    );
  }
}