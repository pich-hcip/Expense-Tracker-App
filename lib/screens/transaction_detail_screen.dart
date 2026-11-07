import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../core/category_visuals.dart';
import '../services/wallet_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String title;
  final String note;
  final String category;
  final String type;
  final String categoryIcon;
  final String categoryColorHex;
  final double amount;
  final String walletName;
  final String? walletId;
  final DateTime date;

  const TransactionDetailScreen({
    super.key,
    required this.title,
    this.note = '',
    required this.category,
    required this.type,
    this.categoryIcon = 'more',
    this.categoryColorHex = '#929292',
    required this.amount,
    required this.walletName,
    this.walletId,
    required this.date,
  });

  TransactionDetailScreen.fromTransaction({
    super.key,
    required TransactionItem transaction,
  }) : title = transaction.displayTitle,
       note = transaction.displayNote,
       category = transaction.displayCategory,
       type = transaction.kind,
       categoryIcon = transaction.displayIcon,
       categoryColorHex = transaction.displayColorHex,
       amount = transaction.amount.abs(),
       walletName = transaction.displayWalletName,
       walletId = transaction.walletId,
       date = DateTime.parse(transaction.transactionDate);

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  String? _resolvedWalletName;
  bool _loadingWallet = false;

  String get title => widget.title;
  String get category => widget.category;
  String get type => widget.type;
  double get amount => widget.amount.abs();
  DateTime get date => widget.date;
  String get walletName => _resolvedWalletName ?? widget.walletName.trim();

  @override
  void initState() {
    super.initState();
    if (walletName.isEmpty && widget.walletId?.isNotEmpty == true) {
      _loadingWallet = true;
      _loadWalletName();
    }
  }

  Future<void> _loadWalletName() async {
    try {
      final wallets = await WalletService().getWallets();
      if (!mounted) return;
      for (final wallet in wallets) {
        if (wallet.id == widget.walletId) {
          _resolvedWalletName = wallet.name;
          break;
        }
      }
    } catch (_) {
      // Keep the transaction visible if its wallet cannot be loaded.
    } finally {
      if (mounted) setState(() => _loadingWallet = false);
    }
  }

  bool get _isExpense => type.trim().toUpperCase() == 'EXPENSE';

  String get _formattedAmount {
    final sign = _isExpense ? '-' : '+';
    return '$sign${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount)}';
  }

  String get _formattedDate {
    return DateFormat('MMM d, yyyy', context.langCode).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = _isExpense
        ? (dark ? const Color(0xFFFF7884) : const Color(0xFFEA3044))
        : (dark ? const Color(0xFF51DBAF) : const Color(0xFF07865F));
    final heading = category.trim().isNotEmpty && category != 'Uncategorized'
        ? category
        : (_isExpense ? context.tr('expense') : context.tr('income'));
    final description = widget.note.trim().isNotEmpty
        ? widget.note.trim()
        : title.trim() != heading
        ? title.trim()
        : '';
    final account = _loadingWallet
        ? context.tr('loading')
        : walletName.isEmpty
        ? context.tr('account_unavailable')
        : walletName;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF168DFA).withValues(alpha: 0.07),
            ),
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF087BE0),
              size: 22,
            ),
          ),
        ),
        title: Text(
          context.tr('detail_title').replaceFirst('{name}', heading),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 560,
                    minHeight: (constraints.maxHeight - 24).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF1199FA),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.22),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                            ),
                            child: Icon(
                              _isExpense
                                  ? CategoryVisuals.iconFor(widget.categoryIcon)
                                  : Icons.attach_money,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          heading,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formattedAmount,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isExpense)
                          _row(
                            context,
                            icon: Icons.category_outlined,
                            label: context.tr('category'),
                            value: category,
                          ),
                        _row(
                          context,
                          icon: _isExpense
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          label: context.tr('transaction_type'),
                          value: _isExpense
                              ? context.tr('expense')
                              : context.tr('income'),
                          iconColor: accent,
                        ),
                        _row(
                          context,
                          icon: Icons.calendar_today_outlined,
                          label: context.tr('date'),
                          value: _formattedDate,
                        ),
                        _row(
                          context,
                          icon: Icons.account_balance_wallet_outlined,
                          label: context.tr('payment_method'),
                          value: account,
                        ),
                        _row(
                          context,
                          icon: Icons.description_outlined,
                          label: context.tr('description'),
                          value: description.isEmpty
                              ? context.tr('no_description')
                              : description,
                          selectable: true,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    bool selectable = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final tint = iconColor ?? const Color(0xFF168DFA);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(13) > 18;
          final labelWidget = Text(
            label,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          );
          final style = TextStyle(
            fontSize: 14,
            height: 1.4,
            color: colors.onSurface,
          );
          final valueWidget = selectable
              ? SelectableText(value, style: style)
              : Text(value, style: style);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: tint),
              ),
              const SizedBox(width: 8),
              if (stacked)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      labelWidget,
                      const SizedBox(height: 6),
                      valueWidget,
                    ],
                  ),
                )
              else ...[
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: labelWidget,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: valueWidget,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}