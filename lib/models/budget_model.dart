class BudgetModel {
  final String id;

  final String categoryId;
  final String categoryName;

  final String? categoryIcon;
  final String? categoryColorHex;

  final double monthlyLimit;
  final double spent;
  final double remaining;
  final double percentage;

  final bool overBudget;

  final DateTime periodMonth;

  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColorHex,
    required this.monthlyLimit,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.overBudget,
    required this.periodMonth,
  });

  factory BudgetModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return BudgetModel(
      id: json['id'].toString(),

      categoryId:
          json['categoryId'].toString(),

      categoryName:
          json['categoryName']?.toString() ??
              'Category',

      categoryIcon:
          json['categoryIcon']?.toString(),

      categoryColorHex:
          json['categoryColorHex']?.toString(),

      monthlyLimit:
          _toDouble(
        json['monthlyLimit'],
      ),

      spent:
          _toDouble(
        json['spent'],
      ),

      remaining:
          _toDouble(
        json['remaining'],
      ),

      percentage:
          _toDouble(
        json['percentage'],
      ),

      overBudget:
          json['overBudget'] == true,

      periodMonth:
          DateTime.parse(
        json['periodMonth'].toString(),
      ),
    );
  }

  static double _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }
}

class BudgetSummaryModel {
  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final double percentage;

  final int activeBudgets;
  final int overBudgetCount;

  const BudgetSummaryModel({
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.percentage,
    required this.activeBudgets,
    required this.overBudgetCount,
  });

  factory BudgetSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return BudgetSummaryModel(
      totalBudget:
          _toDouble(
        json['totalBudget'],
      ),

      totalSpent:
          _toDouble(
        json['totalSpent'],
      ),

      remaining:
          _toDouble(
        json['remaining'],
      ),

      percentage:
          _toDouble(
        json['percentage'],
      ),

      activeBudgets:
          int.tryParse(
                json['activeBudgets']
                    .toString(),
              ) ??
              0,

      overBudgetCount:
          int.tryParse(
                json['overBudgetCount']
                    .toString(),
              ) ??
              0,
    );
  }

  static double _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }
}