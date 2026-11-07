class TransactionItem {
  final String id;
  final String kind;
  final double amount;
  final String title;
  final String transactionDate;
  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;
  final String? walletId;
  final String? walletName;
  final String? note;

  TransactionItem({
    required this.id,
    required this.kind,
    required this.amount,
    required this.title,
    required this.transactionDate,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    this.walletId,
    this.walletName,
    this.note,
  });

  bool get isIncome => kind.trim().toUpperCase() == 'INCOME';

  bool get _hasNoCategory =>
      categoryName.trim().isEmpty || categoryName == 'Uncategorized';

  bool get isWalletIncome =>
      isIncome &&
      _hasNoCategory &&
      (title.startsWith('Starting balance - ') ||
          title.startsWith('Balance added - '));

  String get displayNote {
    final explicit = note?.trim();
    if (explicit != null) return explicit;
    // The transaction form stores the optional note in title, or the category
    // name when the note was left empty.
    if (!isWalletIncome &&
        (kind.trim().toUpperCase() == 'EXPENSE' || isIncome) &&
        title.trim().isNotEmpty &&
        title.trim() != categoryName.trim()) {
      return title.trim();
    }
    return '';
  }

  String get displayWalletName {
    final name = walletName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    if (isWalletIncome) {
      return title.substring(title.indexOf(' - ') + 3).trim();
    }
    return '';
  }

  String get displayTitle {
    if (isWalletIncome) {
      final name = title.substring(title.indexOf(' - ') + 3).trim();
      return name.isEmpty ? 'Income' : name;
    }
    if (title.trim().isNotEmpty) return title;
    return isIncome && _hasNoCategory ? 'Income' : categoryName;
  }

  String get displayCategory =>
      isIncome && _hasNoCategory ? 'Income' : categoryName;

  String get displayIcon =>
      isIncome && _hasNoCategory ? 'trending_up' : categoryIcon;

  String get displayColorHex =>
      isIncome && _hasNoCategory ? '#11BC91' : categoryColorHex;

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'];
    final nestedWallet = wallet is Map ? wallet : null;
    return TransactionItem(
      id: json['id'],
      note: json['note']?.toString(),
      kind: json['kind'],
      amount: double.parse(json['amount'].toString()),
      title: json['title'] ?? json['categoryName'] ?? '',
      transactionDate: json['transactionDate'],
      categoryName: json['categoryName'] ?? 'Uncategorized',
      categoryIcon: json['categoryIcon'] ?? 'more',
      categoryColorHex: json['categoryColorHex'] ?? '#929292',
      walletId: (json['walletId'] ?? nestedWallet?['id'])?.toString(),
      walletName: (json['walletName'] ?? nestedWallet?['name'])?.toString(),
    );
  }
}
