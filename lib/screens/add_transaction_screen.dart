import 'package:flutter/material.dart';
import '../core/category_visuals.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, required this.category});

  final CategoryModel category;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();

  bool _isLoadingWallets = true;
  bool _isSaving = false;
  List<WalletModel> _wallets = [];
  WalletModel? _selectedWallet;

  bool get _isExpense => widget.category.kind == 'EXPENSE';

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletService.getWallets();
      setState(() {
        _wallets = wallets;
        _selectedWallet = wallets.isNotEmpty ? wallets.first : null;
        _isLoadingWallets = false;
      });
    } catch (e) {
      setState(() => _isLoadingWallets = false);
    }
  }

  void _submit() async {
    final amount = double.tryParse(_amountController.text.trim());

    if (_selectedWallet == null) {
      _showError('Please select a wallet');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _transactionService.createTransaction(
        walletId: _selectedWallet!.id,
        categoryId: widget.category.id,
        kind: widget.category.kind,
        amount: amount,
        title: _titleController.text.trim().isEmpty ? widget.category.name : _titleController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Could not save. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = CategoryVisuals.colorFromHex(widget.category.colorHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isExpense ? 'Add Expense' : 'Add Income'),
      ),
      body: _isLoadingWallets
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        child: Icon(CategoryVisuals.iconFor(widget.category.icon), color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.category.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Wallet', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<WalletModel>(
                    value: _selectedWallet,
                    items: _wallets
                        .map((w) => DropdownMenuItem(value: w, child: Text('${w.name} (\$${w.balance.toStringAsFixed(2)})')))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedWallet = value),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(border: OutlineInputBorder(), prefixText: '\$'),
                  ),
                  const SizedBox(height: 20),
                  const Text('Note (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(border: const OutlineInputBorder(), hintText: widget.category.name),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: color),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_isExpense ? 'Save Expense' : 'Save Income', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}