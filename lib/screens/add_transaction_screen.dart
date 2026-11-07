import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';

import '../core/category_visuals.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import 'add_wallet_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, required this.category});

  final CategoryModel category;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();

  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _titleController = TextEditingController();

  bool _isLoadingWallets = true;
  bool _isSaving = false;
  String? _walletError;

  List<WalletModel> _wallets = [];

  WalletModel? _selectedWallet;

  bool get _isExpense => widget.category.kind.toUpperCase() == 'EXPENSE';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  // ============================================================
  // LOAD WALLETS
  // ============================================================

  Future<void> _loadWallets() async {
    setState(() {
      _isLoadingWallets = true;
      _walletError = null;
    });
    try {
      final wallets = await _walletService.getWallets();

      if (!mounted) return;

      setState(() {
        _wallets = wallets;
        _selectedWallet = wallets.isNotEmpty ? wallets.first : null;

        _isLoadingWallets = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingWallets = false;
        _walletError = 'wallets_load_error';
      });

      _showErrorSnackBar(context.tr('wallets_load_error_short'));
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    if (_isSaving) return;

    final wallet = _selectedWallet;

    // ----------------------------------------------------------
    // Wallet validation
    // ----------------------------------------------------------

    if (wallet == null) {
      _showErrorSnackBar(context.tr('select_wallet'));
      return;
    }

    // ----------------------------------------------------------
    // Amount validation
    // ----------------------------------------------------------

    final text = _amountController.text.trim().replaceAll(',', '');

    final double? amount = double.tryParse(text);

    if (amount == null || !amount.isFinite || amount <= 0) {
      _showErrorSnackBar(context.tr('valid_amount'));
      return;
    }

    // ==========================================================
    // CHECK EXPENSE AGAINST WALLET BALANCE
    // ==========================================================

    if (_isExpense) {
      final double availableBalance = wallet.balance.toDouble();

      // Wallet already has no money
      if (availableBalance <= 0) {
        await _showInsufficientBalanceDialog(
          requestedAmount: amount,
          availableBalance: availableBalance,
        );

        return;
      }

      // Expense is greater than wallet balance
      if (amount > availableBalance) {
        await _showInsufficientBalanceDialog(
          requestedAmount: amount,
          availableBalance: availableBalance,
        );

        return;
      }
    }

    // ----------------------------------------------------------
    // Start loading
    // ----------------------------------------------------------

    setState(() {
      _isSaving = true;
    });

    try {
      await _transactionService.createTransaction(
        walletId: wallet.id,
        categoryId: widget.category.id,
        kind: widget.category.kind,
        amount: amount,
        title: _titleController.text.trim().isEmpty
            ? widget.category.name
            : _titleController.text.trim(),
      );

      if (!mounted) return;

      // Return true so previous screen can refresh.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      final message = e.toString().replaceFirst('Exception: ', '');

      // Backend may also reject insufficient balance.
      if (_isExpense &&
          (message.toLowerCase().contains('insufficient') ||
              message.toLowerCase().contains('balance'))) {
        await _showBackendBalanceError(message);
      } else {
        _showErrorSnackBar(
          message.isNotEmpty
              ? message
              : context.tr('save_transaction_failed'),
        );
      }
    }
  }

  // ============================================================
  // INSUFFICIENT BALANCE DIALOG
  // ============================================================

  Future<void> _showInsufficientBalanceDialog({
    required double requestedAmount,
    required double availableBalance,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),

          contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 10),

          actionsPadding: const EdgeInsets.fromLTRB(24, 5, 24, 20),

          title: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFFFECEE),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFFE53935),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('insufficient_balance'),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                availableBalance <= 0
                    ? context.tr('no_balance_wallet')
                    : context.tr('expense_greater').replaceFirst(
                        '{wallet}',
                        _selectedWallet?.name ?? context.tr('this_wallet'),
                      ),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF5F6670),
                ),
              ),

              const SizedBox(height: 20),

              // Available balance
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('available_balance'),
                        style: const TextStyle(
                          color: Color(0xFF727984),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '\$${availableBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: availableBalance <= 0
                            ? const Color(0xFFE53935)
                            : const Color(0xFF20242A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Expense amount
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('expense_amount'),
                        style: const TextStyle(
                          color: Color(0xFF727984),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '\$${requestedAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0061B7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr('change_amount'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BACKEND BALANCE ERROR
  // ============================================================

  Future<void> _showBackendBalanceError(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFE53935),
            size: 42,
          ),
          title: Text(
            context.tr('insufficient_balance'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF666D77), height: 1.4),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0061B7),
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr('change_amount')),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // NORMAL ERROR
  // ============================================================

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFE53935),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = CategoryVisuals.colorFromHex(widget.category.colorHex);

    return Scaffold(
      backgroundColor: scheme.surface,

      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        title: Text(
          _isExpense ? context.tr('add_expense') : context.tr('add_income'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: _isLoadingWallets
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_walletError != null || _wallets.isEmpty) ...[
                    Text(
                      context.tr(_walletError ?? 'create_wallet_hint'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: Icon(
                        _walletError != null ? Icons.refresh : Icons.add,
                      ),
                      label: Text(
                        _walletError != null
                            ? context.tr('retry')
                            : context.tr('create_wallet'),
                      ),
                      onPressed: () async {
                        if (_walletError != null) {
                          await _loadWallets();
                          return;
                        }
                        final created = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => const AddWalletScreen(),
                          ),
                        );
                        if (mounted && created == true) await _loadWallets();
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ==================================================
                  // CATEGORY
                  // ==================================================
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CategoryVisuals.iconFor(widget.category.icon),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.category.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isExpense
                                  ? context.tr('expense')
                                  : context.tr('income'),
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // WALLET
                  // ==================================================
                  Text(
                    context.tr('wallet'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<WalletModel>(
                    value: _selectedWallet,

                    isExpanded: true,

                    items: _wallets
                        .map(
                          (wallet) => DropdownMenuItem<WalletModel>(
                            value: wallet,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 20,
                                  color: Color(0xFF466B9E),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    wallet.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                Text(
                                  '\$${wallet.balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: wallet.balance < 0
                                        ? const Color(0xFFE53935)
                                        : scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),

                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedWallet = value;
                            });
                          },

                    decoration: InputDecoration(
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCE3EC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCE3EC)),
                      ),
                    ),
                  ),

                  // Show balance
                  if (_selectedWallet != null) ...[
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        context.tr('available_amount').replaceFirst(
                          '{amount}',
                          '\$${_selectedWallet!.balance.toStringAsFixed(2)}',
                        ),
                        style: TextStyle(
                          color: _selectedWallet!.balance <= 0
                              ? const Color(0xFFE53935)
                              : const Color(0xFF7B8490),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ==================================================
                  // AMOUNT
                  // ==================================================
                  Text(
                    context.tr('amount'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    scrollPadding: const EdgeInsets.only(bottom: 32),
                    enabled: !_isSaving,
                    controller: _amountController,

                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),

                    decoration: InputDecoration(
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      prefixText: '\$ ',
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // NOTE
                  // ==================================================
                  Text(
                    context.tr('note_optional'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    scrollPadding: const EdgeInsets.only(bottom: 32),
                    enabled: !_isSaving,
                    controller: _titleController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: widget.category.name,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // SAVE
                  // ==================================================
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isSaving ||
                              _selectedWallet == null ||
                              _walletError != null
                          ? null
                          : _submit,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isExpense
                                  ? context.tr('save_expense')
                                  : context.tr('save_income'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}