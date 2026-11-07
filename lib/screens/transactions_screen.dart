import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
import 'package:intl/intl.dart';
import '../core/category_visuals.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  TransactionsScreenState createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();

  bool _isLoading = true;
  String? _error;
  List<TransactionItem> _transactions = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions = await _transactionService.getTransactions();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'transactions_load_error';
        _isLoading = false;
      });
    }
  }

  Future<void> refresh() => _loadTransactions();

  Future<void> _openDetail(TransactionItem item) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            TransactionDetailScreen.fromTransaction(transaction: item),
      ),
    );
    if (deleted == true) _loadTransactions();
  }

  List<TransactionItem> get _filtered {
    if (_filter == 'All') return _transactions;
    final wantsIncome = _filter == 'Income';
    return _transactions.where((t) => t.isIncome == wantsIncome).toList();
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return context.tr('today');
    if (diff == 1) return context.tr('yesterday');
    return DateFormat('MMMM d, yyyy', context.langCode).format(date);
  }

  Map<String, List<TransactionItem>> get _groupedTransactions {
    final grouped = <String, List<TransactionItem>>{};
    for (final t in _filtered) {
      final label = _dateLabel(DateTime.parse(t.transactionDate));
      grouped.putIfAbsent(label, () => []).add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr(_error!)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadTransactions,
              child: Text(context.tr('retry')),
            ),
          ],
        ),
      );
    }

    final grouped = _groupedTransactions;

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            children: [
              Text(
                context.tr('transactions'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _FilterBar(
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const Divider(height: 1, color: Color(0xFFEFEFEF)),
        Expanded(
          child: grouped.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Text(
                          context.tr('no_transactions'),
                          style: const TextStyle(color: Colors.black45),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: grouped.entries.length,
                    itemBuilder: (context, index) {
                      final entry = grouped.entries.elementAt(index);
                      return _TransactionGroup(
                        label: entry.key,
                        items: entry.value,
                        onTapItem: _openDetail,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final label in const ['All', 'Income', 'Expense'])
            _FilterButton(
              label: label,
              selected: selected == label,
              onTap: () => onSelected(label),
            ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF0865B9) : Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 27 : 20,
            vertical: 10,
          ),
          child: Text(
            context.tr(label.toLowerCase()),
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionGroup extends StatelessWidget {
  const _TransactionGroup({
    required this.label,
    required this.items,
    required this.onTapItem,
  });

  final String label;
  final List<TransactionItem> items;
  final ValueChanged<TransactionItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 17, 24, 7),
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF4D4D4D),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final item in items)
          _TransactionRow(item: item, onTap: () => onTapItem(item)),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item, required this.onTap});

  final TransactionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = CategoryVisuals.colorFromHex(item.displayColorHex);
    final icon = CategoryVisuals.iconFor(item.displayIcon);
    final sign = item.isIncome ? '+' : '-';
    final formattedAmount = NumberFormat.currency(
      symbol: '\$',
    ).format(item.amount.abs());
    final displayDate = DateFormat(
      'MMM d, yyyy',
      context.langCode,
    ).format(DateTime.parse(item.transactionDate));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF292929);
    final subtitleColor = isDark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF777777);
    final expenseAmountColor = isDark
        ? Colors.redAccent
        : const Color(0xFFD32F2F);

    return Container(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayDate,
                      style: TextStyle(color: subtitleColor, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '$sign$formattedAmount',
                style: TextStyle(
                  color: item.isIncome
                      ? const Color(0xFF16B98B)
                      : expenseAmountColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}