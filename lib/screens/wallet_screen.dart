import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/category_visuals.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';
import 'add_wallet_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _walletService.getWallets(),
        _walletService.getSummary(),
      ]);

      final wallets = results[0] as List<WalletModel>;
      final summary = results[1] as Map<String, dynamic>;

      setState(() {
        _wallets = wallets;
        _totalBalance = double.parse(summary['totalBalance'].toString());
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load wallets.';
        _isLoading = false;
      });
    }
  }

  /// Public entry point so MainNavigationScreen can force a reload
  /// when this tab is re-selected (IndexedStack keeps it alive otherwise,
  /// so balances would look stale after adding a transaction elsewhere).
  Future<void> refresh() => _loadWallets();

  Future<void> _openAddWallet() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddWalletScreen()),
    );
    if (created == true) _loadWallets();
  }

  Future<void> _openEditWallet(WalletModel wallet) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddWalletScreen(existingWallet: wallet),
      ),
    );
    if (updated == true) _loadWallets();
  }

  void _showWalletMenu(WalletModel wallet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Color(0xFF0061B7)),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _openEditWallet(wallet);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await _confirmDelete(wallet);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(WalletModel wallet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete wallet?'),
        content: Text('This will remove "${wallet.name}" permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _walletService.deleteWallet(wallet.id);
        _loadWallets();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete wallet.')),
        );
      }
    }
  }

  String _formatCurrency(double value) => NumberFormat.currency(symbol: '\$').format(value);

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
            ElevatedButton(onPressed: _loadWallets, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWallets,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wallets', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              _SquareButton(icon: Icons.notifications_none, showBadge: true, onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          _TotalBalanceCard(
            totalBalance: _totalBalance,
            walletCount: _wallets.length,
            hidden: _balanceHidden,
            onToggleHidden: () => setState(() => _balanceHidden = !_balanceHidden),
            formatCurrency: _formatCurrency,
          ),
          const SizedBox(height: 24),
          const Text('My Wallets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (_wallets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No wallets yet', style: TextStyle(color: Colors.black45))),
            )
          else
            for (final wallet in _wallets) _WalletTile(wallet: wallet, onMenuTap: () => _showWalletMenu(wallet)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openAddWallet,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              side: const BorderSide(color: Color(0xFFD8D8D8)),
            ),
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0061B7)),
            label: const Text('Add Wallets', style: TextStyle(color: Color(0xFF0061B7), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({
    required this.totalBalance,
    required this.walletCount,
    required this.hidden,
    required this.onToggleHidden,
    required this.formatCurrency,
  });

  final double totalBalance;
  final int walletCount;
  final bool hidden;
  final VoidCallback onToggleHidden;
  final String Function(double) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0061B7), Color(0xFF17427A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Total Balance', style: TextStyle(color: Color(0xFF8FC5F3), fontSize: 13)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onToggleHidden,
                      child: Icon(
                        hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF8FC5F3),
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hidden ? '••••••' : formatCurrency(totalBalance),
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Across $walletCount wallet${walletCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: Color(0xFF8FC5F3), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.account_balance_wallet, color: Colors.white24, size: 48),
        ],
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.wallet, required this.onMenuTap});

  final WalletModel wallet;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final color = wallet.colorHex != null
        ? CategoryVisuals.colorFromHex(wallet.colorHex!)
        : const Color(0xFF0061B7);
    final icon = wallet.icon != null ? CategoryVisuals.iconFor(wallet.icon!) : Icons.account_balance_wallet;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(wallet.currencyCode, style: const TextStyle(color: Colors.black45, fontSize: 11)),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(symbol: '\$').format(wallet.balance),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: onMenuTap),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.onTap, this.showBadge = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F9FD),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: const Color(0xFF0061B7), size: 22),
              if (showBadge)
                Positioned(
                  right: 9,
                  top: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: Color(0xFFFF4352), shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}