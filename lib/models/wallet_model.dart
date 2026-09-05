class WalletModel {
  final String id;
  final String name;
  final String currencyCode;
  final double balance;
  final String? icon;
  final String? colorHex;
  final bool isDefault;

  WalletModel({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.balance,
    this.icon,
    this.colorHex,
    required this.isDefault,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'],
      name: json['name'],
      currencyCode: json['currencyCode'] ?? 'USD',
      balance: double.parse(json['balance'].toString()),
      icon: json['icon'],
      colorHex: json['colorHex'],
      isDefault: json['isDefault'] ?? false,
    );
  }
}