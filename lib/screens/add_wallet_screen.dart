import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
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
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.existingWallet != null;

  void _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final balance = double.parse(_balanceController.text.trim());

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
        SnackBar(
          content: Text(context.tr('save_wallet_failed')),
        ),
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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = widget.existingWallet?.currencyCode ?? 'USD';
    final background = isDark ? const Color(0xFF101318) : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isEditing ? context.tr('edit_wallet') : context.tr('add_wallet'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              Text(
                context.tr('wallet_details'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isEditing
                    ? context.tr('update_wallet_desc')
                    : context.tr('new_wallet_desc'),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                scrollPadding: const EdgeInsets.only(bottom: 32),
                controller: _nameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  context.tr('wallet_name'),
                  context.tr('wallet_name_hint'),
                  Icons.wallet_outlined,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.tr('enter_wallet_name')
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                scrollPadding: const EdgeInsets.only(bottom: 32),
                controller: _balanceController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: _fieldDecoration(
                  _isEditing
                      ? context.tr('balance')
                      : context.tr('starting_balance'),
                  '0.00',
                  Icons.payments_outlined,
                ).copyWith(suffixText: currency),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  return amount == null || !amount.isFinite
                      ? context.tr('enter_valid_amount')
                      : null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('wallet_currency').replaceFirst('{c}', currency),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                      semanticsLabel: context.tr('saving_wallet'),
                    ),
                  )
                : Text(
                    _isEditing
                        ? context.tr('save_changes')
                        : context.tr('create_wallet'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, String hint, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hint,
      prefixIcon: Icon(icon, size: 21),
      filled: true,
      fillColor: colors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );
  }
}