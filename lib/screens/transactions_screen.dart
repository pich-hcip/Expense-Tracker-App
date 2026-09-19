import 'package:flutter/material.dart';
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
        _error = 'Could not load transactions.';
        _isLoading = false;
      });
    }
  }

  Future<void> refresh() => _loadTransactions();

  Future<void> _openDetail(TransactionItem item) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => TransactionDetailScreen(transaction: item)),
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

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
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
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadTransactions, child: const Text('Retry')),
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
            children: const [
              Text(
                'Transactions',
                style: TextStyle(color: Color(0xFF1D1D1F), fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        _FilterBar(selected: _filter, onSelected: (value) => setState(() => _filter = value)),
        const Divider(height: 1, color: Color(0xFFEFEFEF)),
        Expanded(
          child: grouped.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text('No transactions yet', style: TextStyle(color: Colors.black45)),
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
            _FilterButton(label: label, selected: selected == label, onTap: () => onSelected(label)),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.selected, required this.onTap});

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
          padding: EdgeInsets.symmetric(horizontal: selected ? 27 : 20, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF5F5F5F),
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionGroup extends StatelessWidget {
  const _TransactionGroup({required this.label, required this.items, required this.onTapItem});

  final String label;
  final List<TransactionItem> items;
  final ValueChanged<TransactionItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 17, 24, 7),
          child: Text(label, style: const TextStyle(color: Color(0xFF4D4D4D), fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        for (final item in items) _TransactionRow(item: item, onTap: () => onTapItem(item)),
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
    final color = CategoryVisuals.colorFromHex(item.categoryColorHex);
    final icon = CategoryVisuals.iconFor(item.categoryIcon);
    final sign = item.isIncome ? '+' : '-';
    final formattedAmount = NumberFormat.currency(symbol: '\$').format(item.amount.abs());
    final displayDate = DateFormat('MMMM d, yyyy').format(DateTime.parse(item.transactionDate));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
          child: Row(
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
                      item.title.isEmpty ? item.categoryName : item.title,
                      style: const TextStyle(color: Color(0xFF292929), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(item.categoryName, style: const TextStyle(color: Color(0xFF777777), fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign$formattedAmount',
                    style: TextStyle(
                      color: item.isIncome ? const Color(0xFF16B98B) : const Color(0xFF242424),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(displayDate, style: const TextStyle(color: Color(0xFF777777), fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}