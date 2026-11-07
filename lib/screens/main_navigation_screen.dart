import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';

import '../../screens/dashboard_screen.dart';
import '../../screens/transactions_screen.dart';
import '../../screens/wallet_screen.dart';
import '../../screens/report_screen.dart';
import '../../screens/category_screen.dart';
import '../../screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // ============================================================
  // SCREEN KEYS
  // ============================================================

  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();

  final GlobalKey<TransactionsScreenState> _transactionsKey =
      GlobalKey<TransactionsScreenState>();

  final GlobalKey<WalletScreenState> _walletKey =
      GlobalKey<WalletScreenState>();

  final GlobalKey<CategoryScreenState> _categoryKey =
      GlobalKey<CategoryScreenState>();
  final GlobalKey<ReportScreenState> _reportKey = GlobalKey<ReportScreenState>();

  // ============================================================
  // PAGES
  // ============================================================

  late final List<Widget> _pages = [
    DashboardScreen(
      key: _dashboardKey,
    ),

    TransactionsScreen(
      key: _transactionsKey,
    ),

    WalletScreen(
      key: _walletKey,
    ),

    ReportScreen(key: _reportKey),

    const ProfileScreen(),

    CategoryScreen(
      key: _categoryKey,
    ),
  ];

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _onNavSelected(int index) {
    // Change page first
    setState(() {
      _selectedIndex = index;
    });

    // Wait until IndexedStack finishes displaying the page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (index) {
        // ======================================================
        // HOME / DASHBOARD
        // ======================================================
        case 0:
          _dashboardKey.currentState?.refreshDashboard();
          break;

        // ======================================================
        // TRANSACTIONS
        // ======================================================
        case 1:
          _transactionsKey.currentState?.refresh();
          break;

        // ======================================================
        // WALLET
        // ======================================================
        case 2:
          _walletKey.currentState?.refresh();
          break;

        // ======================================================
        // REPORT
        // ======================================================
        case 3:
          _reportKey.currentState?.refresh();
          break;

        // ======================================================
        // PROFILE
        // ======================================================
        case 4:
          break;

        // ======================================================
        // CATEGORY
        // ======================================================
        case 5:
          _categoryKey.currentState?.refresh();
          break;
      }
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,

      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),

      bottomNavigationBar: _BottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _onNavSelected,
      ),
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    const items = [
      (
        Icons.home_outlined,
        'home',
      ),
      (
        Icons.list_alt_outlined,
        'nav_transaction',
      ),
      (
        Icons.account_balance_wallet_outlined,
        'wallet',
      ),
      (
        Icons.receipt_long_outlined,
        'nav_report',
      ),
    ];

    final isCategorySelected =
        selectedIndex == 5;

    return Container(
      height: 72,

      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),

      decoration: BoxDecoration(
        color: colorScheme.surface,

        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant
                .withOpacity(0.5),
          ),
        ),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,

        children: [
          // ====================================================
          // HOME
          // ====================================================

          _NavItem(
            icon: items[0].$1,
            label: context.tr(items[0].$2),
            selected:
                selectedIndex == 0,
            onTap: () {
              onSelected(0);
            },
          ),

          // ====================================================
          // TRANSACTION
          // ====================================================

          _NavItem(
            icon: items[1].$1,
            label: context.tr(items[1].$2),
            selected:
                selectedIndex == 1,
            onTap: () {
              onSelected(1);
            },
          ),

          // ====================================================
          // CATEGORY +
          // ====================================================

          Material(
            color: isCategorySelected
                ? colorScheme.primaryContainer
                : colorScheme.primary,

            shape: const CircleBorder(),

            child: InkWell(
              onTap: () {
                onSelected(5);
              },

              customBorder:
                  const CircleBorder(),

              child: SizedBox(
                width: 52,
                height: 52,

                child: Icon(
                  Icons.add_rounded,

                  color: isCategorySelected
                      ? colorScheme
                          .onPrimaryContainer
                      : colorScheme.onPrimary,

                  size: 31,
                ),
              ),
            ),
          ),

          // ====================================================
          // WALLET
          // ====================================================

          _NavItem(
            icon: items[2].$1,
            label: context.tr(items[2].$2),
            selected:
                selectedIndex == 2,
            onTap: () {
              onSelected(2);
            },
          ),

          // ====================================================
          // REPORT
          // ====================================================

          _NavItem(
            icon: items[3].$1,
            label: context.tr(items[3].$2),
            selected:
                selectedIndex == 3,
            onTap: () {
              onSelected(3);
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NAVIGATION ITEM
// ============================================================

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final activeColor =
        colorScheme.primary;

    final inactiveColor =
        colorScheme.onSurface
            .withOpacity(0.5);

    final color = selected
        ? activeColor
        : inactiveColor;

    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(12),

      child: SizedBox(
        width: 54,

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),

            const SizedBox(
              height: 2,
            ),

            // Shrinks long Khmer words so they fit
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}