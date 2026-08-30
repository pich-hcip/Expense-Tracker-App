import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/balance_summary_model.dart';
import '../../models/transaction_model.dart';
import '../../services/dashboard_service.dart';
// import 'category.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final DashboardService _dashboardService = DashboardService();

  bool _isLoading = true;
  String? _error;
  BalanceSummary? _summary;
  List<TransactionItem> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _dashboardService.getSummary(),
        _dashboardService.getRecentTransactions(),
      ]);

      setState(() {
        _summary = results[0] as BalanceSummary;
        _transactions = results[1] as List<TransactionItem>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load dashboard. Pull down to retry.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorView()
                      : RefreshIndicator(
                          onRefresh: _loadDashboard,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 28),
                              _BalanceCard(summary: _summary!),
                              const SizedBox(height: 22),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Recent Transactions',
                                    style: TextStyle(
                                      color: Color(0xFF211F20),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF0061B7),
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                    ),
                                    child: const Text(
                                      'See All',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              if (_transactions.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No transactions yet',
                                      style: TextStyle(color: Colors.black45),
                                    ),
                                  ),
                                )
                              else
                                for (final transaction in _transactions)
                                  _TransactionTile(transaction: transaction),
                            ],
                          ),
                        ),
            ),
            _BottomNavigation(
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error ?? 'Something went wrong'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _SquareButton(icon: Icons.menu, onTap: () {}),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
              SizedBox(height: 2),
              Text(
                'Welcome back',
                style: TextStyle(
                  color: Color(0xFF201E1F),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _SquareButton(icon: Icons.notifications_none, showBadge: true, onTap: () {}),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final BalanceSummary summary;

  String _formatCurrency(double value) {
    return NumberFormat.currency(symbol: '\$').format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0061B7),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x330061B7), blurRadius: 9, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance', style: TextStyle(color: Color(0xFF8FC5F3), fontSize: 13)),
          const SizedBox(height: 3),
          Text(
            _formatCurrency(summary.totalBalance),
            style: const TextStyle(color: Colors.white, fontSize: 31, height: 1.2, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0x337FC0F5), height: 1),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _BalanceSummary(
                  label: 'Income',
                  amount: _formatCurrency(summary.totalIncome),
                  icon: Icons.arrow_upward,
                  iconColor: const Color(0xFF11C89D),
                ),
              ),
              Container(width: 1, height: 31, color: const Color(0x337FC0F5)),
              const SizedBox(width: 20),
              Expanded(
                child: _BalanceSummary(
                  label: 'Expenses',
                  amount: _formatCurrency(summary.totalExpense),
                  icon: Icons.arrow_downward,
                  iconColor: const Color(0xFFFF4360),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: const BoxDecoration(color: Color(0xFF1674C5), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF9FCBF0), fontSize: 11)),
            Text(
              amount,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionItem transaction;

  static const _iconMap = {
    'Salary': (Icons.business_center_outlined, Color(0xFF0061B7), Color(0xFFE4F4FC)),
  };

  @override
  Widget build(BuildContext context) {
    final formattedAmount = NumberFormat.currency(symbol: '\$').format(transaction.amount.abs());
    final sign = transaction.isIncome ? '+' : '-';
    final displayDate = DateFormat('MMM d, yyyy').format(DateTime.parse(transaction.transactionDate));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: transaction.isIncome ? const Color(0xFFE4F4FC) : const Color(0xFFFFE5E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transaction.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: const Color(0xFF0061B7),
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF333031), fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(displayDate, style: const TextStyle(color: Color(0xFF999999), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign$formattedAmount',
            style: TextStyle(
              color: transaction.isIncome ? const Color(0xFF0CBF91) : const Color(0xFFFF4352),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
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

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, 'Home'),
      (Icons.list_alt_outlined, 'Transactions'),
      (Icons.account_balance_wallet_outlined, 'Wallet'),
      (Icons.person_outline, 'Profile'),
    ];

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: items[0].$1, label: items[0].$2, selected: selectedIndex == 0, onTap: () => onSelected(0)),
          _NavItem(icon: items[1].$1, label: items[1].$2, selected: selectedIndex == 1, onTap: () => onSelected(1)),
          Material(
            color: const Color(0xFF0061B7),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                // Navigator.of(context).push(
                //   MaterialPageRoute<void>(builder: (_) => const CategoryScreen()),
                // );
              },
              customBorder: const CircleBorder(),
              child: const SizedBox(width: 52, height: 52, child: Icon(Icons.add, color: Colors.white, size: 31)),
            ),
          ),
          _NavItem(icon: items[2].$1, label: items[2].$2, selected: selectedIndex == 2, onTap: () => onSelected(2)),
          _NavItem(icon: items[3].$1, label: items[3].$2, selected: selectedIndex == 3, onTap: () => onSelected(3)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0061B7) : const Color(0xFF969696);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}