import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/category_visuals.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final TransactionItem transaction;

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final TransactionService _transactionService = TransactionService();
  bool _isDeleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This will remove it permanently and adjust the wallet balance back.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _transactionService.deleteTransaction(widget.transaction.id);
      if (!mounted) return;
      Navigator.of(context).pop(true); // tell the list screen to refresh
    } catch (e) {
      setState(() => _isDeleting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete transaction.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final color = CategoryVisuals.colorFromHex(t.categoryColorHex);
    final icon = CategoryVisuals.iconFor(t.categoryIcon);
    final sign = t.isIncome ? '+' : '-';
    final formattedAmount = NumberFormat.currency(symbol: '\$').format(t.amount.abs());
    final displayDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(t.transactionDate));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Transaction Detail', style: TextStyle(color: Color(0xFF171717), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _isDeleting ? null : _confirmDelete,
            icon: _isDeleting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              '$sign$formattedAmount',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: t.isIncome ? const Color(0xFF16B98B) : const Color(0xFF242424),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.title.isEmpty ? t.categoryName : t.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF292929)),
            ),
            const SizedBox(height: 32),
            const Divider(height: 1, color: Color(0xFFEFEFEF)),
            _DetailRow(label: 'Category', value: t.categoryName),
            _DetailRow(label: 'Type', value: t.isIncome ? 'Income' : 'Expense'),
            _DetailRow(label: 'Date', value: displayDate),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF777777), fontSize: 14)),
          Text(value, style: const TextStyle(color: Color(0xFF292929), fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}