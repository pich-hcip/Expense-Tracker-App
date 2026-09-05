class CategoryModel {
  final String id;
  final String name;
  final String kind; // "EXPENSE" or "INCOME"
  final String icon;
  final String colorHex;
  final int transactionCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    required this.colorHex,
    required this.transactionCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      kind: json['kind'],
      icon: json['icon'] ?? 'category',
      colorHex: json['colorHex'] ?? '#929292',
      transactionCount: json['transactionCount'] ?? 0,
    );
  }
}