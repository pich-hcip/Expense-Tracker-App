import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
import 'package:intl/intl.dart';

import '../core/category_visuals.dart';
import '../models/wallet_model.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';
import '../services/wallet_service.dart';
import 'add_wallet_screen.dart';
import 'budget_screen.dart';
import 'add_budget_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  bool _isLoading = true;
  String? _error;

  List<WalletModel> _wallets = [];

  double _totalBalance = 0;

  bool _balanceHidden = false;
  BudgetSummaryModel? _budget;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  // =========================================================
  // LOAD WALLETS
  // =========================================================

  Future<void> _loadWallets() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _walletService.getWallets(),
        _walletService.getSummary(),
        BudgetService()
            .getSummary()
            .then<BudgetSummaryModel?>((value) => value)
            .catchError((Object _) => null),
      ]);

      final wallets = results[0] as List<WalletModel>;

      final summary = results[1] as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        _wallets = wallets;
        _budget = results[2] as BudgetSummaryModel?;

        _totalBalance =
            double.tryParse(summary['totalBalance'].toString()) ?? 0;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'wallets_load_error_short';
        _isLoading = false;
      });
    }
  }

  /// Used by MainNavigationScreen to refresh the
  /// Wallet tab after another screen changes balances.
  Future<void> refresh() => _loadWallets();

  // =========================================================
  // ADD WALLET
  // =========================================================

  Future<void> _openAddWallet() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddWalletScreen()),
    );

    if (!mounted) return;

    if (created == true) {
      await _loadWallets();
    }
  }

  // =========================================================
  // EDIT WALLET
  // =========================================================

  Future<void> _openEditWallet(WalletModel wallet) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddWalletScreen(existingWallet: wallet),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadWallets();
    }
  }

  // =========================================================
  // WALLET MENU
  // =========================================================

  void _showWalletMenu(WalletModel wallet) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(context.tr('edit_wallet')),
                onTap: () {
                  Navigator.pop(bottomSheetContext);

                  _openEditWallet(wallet);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: Text(
                  context.tr('delete_wallet'),
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);

                  _confirmDelete(wallet);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // DELETE WALLET
  // =========================================================

  Future<void> _confirmDelete(WalletModel wallet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('delete_wallet_q')),
          content: Text(
            context.tr('delete_confirm').replaceFirst('{name}', wallet.name),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(context.tr('cancel')),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text(context.tr('delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _walletService.deleteWallet(wallet.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('wallet_deleted'))),
      );

      await _loadWallets();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('delete_wallet_failed'))));
    }
  }

  // =========================================================
  // BUDGET
  // =========================================================

  Future<void> _openSetBudget() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddBudgetScreen(selectedMonth: DateTime.now()),
      ),
    );
    if (mounted && created == true) await _loadWallets();
  }

  Future<void> _openBudget() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const BudgetScreen()),
    );

    if (!mounted) return;

    await _loadWallets();
  }

  // =========================================================
  // FORMAT CURRENCY
  // =========================================================

  String _formatCurrency(double value) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 48),
            const SizedBox(height: 16),
            Text(context.tr(_error!)),
            TextButton.icon(
              onPressed: _loadWallets,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('retry')),
            ),
          ],
        ),
      );
    }
    final over = _budget?.overBudgetCount ?? 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [colors.surface, colors.surface]
              : [const Color(0xFFF8FBFF), const Color(0xFFEDF4FF)],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadWallets,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                context.tr('wallets'),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 16, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color(0xFF0828B8),
                    Color(0xFF0752FF),
                    Color(0xFF35B7FF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1453EF).withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              context.tr('total_balance'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              tooltip: _balanceHidden
                                  ? context.tr('show_balances')
                                  : context.tr('hide_balances'),
                              onPressed: () => setState(
                                () => _balanceHidden = !_balanceHidden,
                              ),
                              icon: Icon(
                                _balanceHidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _balanceHidden
                                ? '\u2022\u2022\u2022\u2022\u2022\u2022'
                                : _formatCurrency(_totalBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context
                              .tr(_wallets.length == 1
                                  ? 'across_one_wallet'
                                  : 'across_wallets')
                              .replaceFirst('{n}', '${_wallets.length}'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _WalletArtwork(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SurfaceCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const _RoundIcon(
                          icon: Icons.savings_outlined,
                          color: Color(0xFFFFB41E),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('budgets'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _budget == null
                                    ? context.tr('manage_spending')
                                    : over > 0
                                    ? context
                                        .tr(over == 1
                                            ? 'budgets_over_one'
                                            : 'budgets_over')
                                        .replaceFirst('{n}', '$over')
                                    : context
                                        .tr('active_budgets')
                                        .replaceFirst(
                                          '{n}',
                                          '${_budget!.activeBudgets}',
                                        ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: over > 0
                                      ? const Color(0xFFFF4266)
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final buttons = [
                          OutlinedButton.icon(
                            onPressed: _openBudget,
                            icon: const Icon(Icons.pie_chart_outline, size: 18),
                            label: Text(context.tr('view_budget')),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _openSetBudget,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(context.tr('set_budget')),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ];
                        if (constraints.maxWidth < 310 ||
                            MediaQuery.textScalerOf(context).scale(14) > 18) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buttons[0],
                              const SizedBox(height: 10),
                              buttons[1],
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: buttons[0]),
                            const SizedBox(width: 10),
                            Expanded(child: buttons[1]),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('my_wallets'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: _openAddWallet,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0752EA),
                  ),
                  icon: const Icon(Icons.add_circle, size: 20),
                  label: Text(
                    context.tr('add_wallet'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            if (_wallets.isEmpty)
              _SurfaceCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 40,
                        color: Color(0xFF0752EA),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('no_wallets'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('no_wallets_desc'),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: _openAddWallet,
                        child: Text(context.tr('add_wallet')),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final wallet in _wallets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: _WalletTile(
                    wallet: wallet,
                    hidden: _balanceHidden,
                    onMenuTap: () => _showWalletMenu(wallet),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.outlineVariant
            : const Color(0xFFE1EAF8),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.55), color],
      ),
    ),
    child: Icon(icon, color: Colors.white, size: 25),
  );
}

class _WalletArtwork extends StatelessWidget {
  const _WalletArtwork();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 82,
    height: 86,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.45,
          child: Container(
            width: 49,
            height: 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFA3DEFF), width: 4),
            ),
          ),
        ),
        Transform.rotate(
          angle: 0.12,
          child: Container(
            width: 76,
            height: 53,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE2F2FF),
                  Color(0xFF78A7FF),
                  Color(0xFF3671ED),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            alignment: Alignment.centerRight,
            child: Container(
              width: 23,
              height: 17,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0951D8),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.circle,
                size: 6,
                color: Color(0xFF80B7FF),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.wallet,
    required this.hidden,
    required this.onMenuTap,
  });
  final WalletModel wallet;
  final bool hidden;
  final VoidCallback onMenuTap;
  @override
  Widget build(BuildContext context) {
    final name = wallet.name.toLowerCase();
    final cash = name.contains('cash');
    final color = cash
        ? const Color(0xFF12BE83)
        : name.contains('wing')
        ? const Color(0xFF99CD12)
        : name.contains('aba')
        ? const Color(0xFF00758D)
        : name.contains('acleda')
        ? const Color(0xFF064B85)
        : CategoryVisuals.colorFromHex(wallet.colorHex ?? '#0752EA');
    final amount = NumberFormat.currency(
      symbol: wallet.currencyCode.toUpperCase() == 'KHR'
          ? '\u17DB'
          : wallet.currencyCode.toUpperCase() == 'USD'
          ? '\$'
          : '${wallet.currencyCode} ',
      decimalDigits: wallet.currencyCode.toUpperCase() == 'KHR' ? 0 : 2,
    ).format(wallet.balance);
    return _SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
        child: Row(
          children: [
            _RoundIcon(
              icon: cash ? Icons.account_balance_wallet : Icons.account_balance,
              color: color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cash
                        ? context.tr('cash_in_hand')
                        : '${context.tr('currency_account').replaceFirst('{c}', wallet.currencyCode)}'
                              '${wallet.isDefault ? ' \u00B7 ${context.tr('default_label')}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hidden ? '\u2022\u2022\u2022\u2022\u2022\u2022' : amount,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: !hidden && wallet.balance < 0
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
            ),
            IconButton(
              tooltip: context.tr('options_for').replaceFirst('{name}', wallet.name),
              onPressed: onMenuTap,
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFF0752EA),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}