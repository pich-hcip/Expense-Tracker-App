class BudgetModel {
  final String id;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;
  final double monthlyLimit;
  final double spentSoFar;
  final double remaining;
  final double percentUsed;

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    required this.monthlyLimit,
    required this.spentSoFar,
    required this.remaining,
    required this.percentUsed,
  });

  bool get isOverBudget => spentSoFar > monthlyLimit;

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      categoryIcon: json['categoryIcon'] ?? 'more',
      categoryColorHex: json['categoryColorHex'] ?? '#929292',
      monthlyLimit: double.parse(json['monthlyLimit'].toString()),
      spentSoFar: double.parse(json['spentSoFar'].toString()),
      remaining: double.parse(json['remaining'].toString()),
      percentUsed: double.parse(json['percentUsed'].toString()),
    );
  }
}