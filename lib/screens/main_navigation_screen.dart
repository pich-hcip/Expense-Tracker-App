import 'package:flutter/material.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/transactions_screen.dart';
import '../../screens/wallet_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/category_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Index 4 (CategoryScreen) has no bottom-nav icon of its own —
  // it's only reached via the center "+" button, but stays inside
  // the same IndexedStack so the footer keeps showing.
  final List<Widget> _pages = const [
    DashboardScreen(),
    TransactionsScreen(),
    WalletScreen(),
    ProfileScreen(),
    CategoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _BottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
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
      (Icons.list_alt_outlined, 'Transaction'),
      (Icons.account_balance_wallet_outlined, 'Wallet'),
      (Icons.person_outline, 'Profile'),
    ];

    final isCategorySelected = selectedIndex == 4;

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
          _NavItem(
            icon: items[0].$1,
            label: items[0].$2,
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _NavItem(
            icon: items[1].$1,
            label: items[1].$2,
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          // Center button — switches to the Category page (index 4)
          // instead of pushing a new screen, so the footer stays visible.
          Material(
            color: isCategorySelected ? const Color(0xFF17427A) : const Color(0xFF0061B7),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => onSelected(4),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.add, color: Colors.white, size: 31),
              ),
            ),
          ),
          _NavItem(
            icon: items[2].$1,
            label: items[2].$2,
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
          _NavItem(
            icon: items[3].$1,
            label: items[3].$2,
            selected: selectedIndex == 3,
            onTap: () => onSelected(3),
          ),
        ],
      ),
    );
  }
}

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
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}