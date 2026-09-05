import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key, this.existingWallet});

  final WalletModel? existingWallet;

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  late final _nameController = TextEditingController(
    text: widget.existingWallet?.name ?? '',
  );
  late final _balanceController = TextEditingController(
    text: widget.existingWallet?.balance.toString() ?? '0',
  );
  final WalletService _walletService = WalletService();
  bool _isSaving = false;

  bool get _isEditing => widget.existingWallet != null;

  void _save() async {
    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a wallet name.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await _walletService.updateWallet(
          id: widget.existingWallet!.id,
          name: name,
          currencyCode: widget.existingWallet!.currencyCode,
          balance: balance,
          icon: widget.existingWallet!.icon ?? 'wallet',
          colorHex: widget.existingWallet!.colorHex ?? '#0061B7',
          isDefault: widget.existingWallet!.isDefault,
        );
      } else {
        await _walletService.createWallet(
          name: name,
          currencyCode: 'USD',
          balance: balance,
          icon: 'wallet',
          colorHex: '#0061B7',
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save wallet.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Wallet' : 'Add Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Wallet name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _balanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isEditing ? 'Balance' : 'Starting balance',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEditing ? 'Save Changes' : 'Save Wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}