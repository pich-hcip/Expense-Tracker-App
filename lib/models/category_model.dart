class CategoryModel {
  final String id;
  final String name;
  final String kind;
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
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      kind: (json['kind'] ?? 'EXPENSE').toString(),
      icon: (json['icon'] ?? 'category').toString(),
      colorHex: (json['colorHex'] ?? '#929292').toString(),
      transactionCount:
          int.tryParse('${json['transactionCount'] ?? 0}') ?? 0,
    );
  }
}