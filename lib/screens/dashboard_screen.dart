import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
import 'package:intl/intl.dart';

import '../core/category_visuals.dart';

import '../models/balance_summary_model.dart';
import '../models/transaction_model.dart';
import '../models/user_profile_model.dart';

import '../services/dashboard_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';

import 'profile_screen.dart';
import 'transaction_detail_screen.dart';
import 'transactions_screen.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

// ============================================================
// DASHBOARD STATE
// ============================================================

class DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final UserService _userService = UserService();

  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _error;

  BalanceSummary? _summary;
  UserProfile? _userProfile;

  List<TransactionItem> _transactions = [];

  // Notification unread count
  int _unreadNotifications = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDashboard();
  }

  // ============================================================
  // PUBLIC REFRESH
  // ============================================================

  /// Called by MainNavigationScreen whenever user
  /// returns to Dashboard.
  Future<void> refreshDashboard() async {
    await _loadDashboard(showLoading: false);
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> _loadDashboard({bool showLoading = true}) async {
    if (!mounted || _isRefreshing) return;

    _isRefreshing = true;

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _dashboardService.getSummary(),
        _dashboardService.getRecentTransactions(),
        _userService.getProfile(),
      ]);

      if (!mounted) return;

      setState(() {
        _summary = results[0] as BalanceSummary;

        _transactions = results[1] as List<TransactionItem>;

        _userProfile = results[2] as UserProfile;

        _error = null;
        _isLoading = false;
      });

      // Notification failure should not break Dashboard.
      await _loadUnreadNotifications();
    } catch (e) {
      if (!mounted) return;

      if (_summary == null) {
        setState(() {
          _error = 'dashboard_load_error';

          _isLoading = false;
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  // ============================================================
  // LOAD UNREAD NOTIFICATION COUNT
  // ============================================================

  Future<void> _loadUnreadNotifications() async {
    try {
      final count = await _notificationService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        _unreadNotifications = count;
      });
    } catch (_) {
      // Do not break Dashboard when notification API fails.
    }
  }

  // ============================================================
  // OPEN NOTIFICATIONS
  // ============================================================

  Future<void> _openNotifications() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationScreen()));

    if (!mounted) return;

    // User may have opened/read notifications.
    await _loadUnreadNotifications();
  }

  // ============================================================
  // OPEN TRANSACTION DETAIL
  // ============================================================

  Future<void> _openDetail(TransactionItem item) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            TransactionDetailScreen.fromTransaction(transaction: item),
      ),
    );

    if (!mounted) return;

    if (deleted == true) {
      await refreshDashboard();
    }
  }

  // ============================================================
  // NAVIGATE TO TRANSACTIONS
  // ============================================================

  void _navigateToTransactions() {
    if (widget.onSelectTab != null) {
      widget.onSelectTab!(1);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const Expanded(child: TransactionsScreen()),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        refreshDashboard();
      }
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _summary == null) {
      return _buildErrorView();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 28),

          // Balance
          _BalanceCard(summary: _summary!),

          const SizedBox(height: 22),

          // ====================================================
          // RECENT TRANSACTIONS TITLE
          // ====================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('recent_transactions'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              TextButton(
                onPressed: _navigateToTransactions,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0061B7),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                ),
                child: Text(
                  context.tr('see_all'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          // ====================================================
          // TRANSACTION LIST
          // ====================================================
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshDashboard,

              child: _transactions.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              context.tr('no_transactions'),
                              style: const TextStyle(color: Colors.black45),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemBuilder: (context, index) {
                        final item = _transactions[index];

                        return _TransactionTile(
                          transaction: item,
                          onTap: () => _openDetail(item),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),

          const SizedBox(height: 12),

          Text(context.tr(_error ?? 'error_generic')),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: () => _loadDashboard(),
            child: Text(context.tr('retry')),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final String displayName = _userProfile?.fullName.isNotEmpty == true
        ? _userProfile!.fullName
        : context.tr('user');

    final String? profileImageUrl = _userProfile?.avatarUrl;

    return Row(
      children: [
        // ======================================================
        // PROFILE
        // ======================================================
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );

                if (!mounted) return;

                await refreshDashboard();
              },
              child: Row(
                children: [
                  // PROFILE IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: const Color(0xFFF4F7FD),
                      child:
                          profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? Image.network(
                              profileImageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28,
                                );
                              },
                            )
                          : Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // NAME
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('good_morning'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // ======================================================
        // NOTIFICATION BELL
        // ======================================================
        _NotificationButton(
          unreadCount: _unreadNotifications,
          onTap: _openNotifications,
        ),
      ],
    );
  }
}

// ============================================================
// BALANCE CARD
// ============================================================

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
          BoxShadow(
            color: Color(0x330061B7),
            blurRadius: 9,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('total_balance'),
            style: const TextStyle(color: Color(0xFF8FC5F3), fontSize: 13),
          ),

          const SizedBox(height: 3),

          Text(
            _formatCurrency(summary.totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          const Divider(color: Color(0x337FC0F5), height: 1),

          const SizedBox(height: 17),

          Row(
            children: [
              Expanded(
                child: _BalanceSummaryItem(
                  label: context.tr('income'),
                  amount: _formatCurrency(summary.totalIncome),
                  icon: Icons.arrow_upward,
                  iconColor: const Color(0xFF11C89D),
                ),
              ),

              Container(width: 1, height: 31, color: const Color(0x337FC0F5)),

              const SizedBox(width: 20),

              Expanded(
                child: _BalanceSummaryItem(
                  label: context.tr('expenses'),
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

// ============================================================
// BALANCE SUMMARY ITEM
// ============================================================

class _BalanceSummaryItem extends StatelessWidget {
  const _BalanceSummaryItem({
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
          decoration: const BoxDecoration(
            color: Color(0xFF1674C5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8FC5F3),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TRANSACTION TILE
// ============================================================

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.onTap});

  final TransactionItem transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = CategoryVisuals.colorFromHex(transaction.displayColorHex);

    final icon = CategoryVisuals.iconFor(transaction.displayIcon);

    final formattedAmount = NumberFormat.currency(
      symbol: '\$',
    ).format(transaction.amount.abs());

    final sign = transaction.isIncome ? '+' : '-';

    final displayDate = DateFormat(
      'MMM d, yyyy',
      context.langCode,
    ).format(DateTime.parse(transaction.transactionDate));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : const Color(0xFF292929);

    final subtitleColor = isDark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF777777);

    final expenseAmountColor = isDark
        ? Colors.redAccent
        : const Color(0xFFFF4352);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 23),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    displayDate,
                    style: TextStyle(color: subtitleColor, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              '$sign$formattedAmount',
              style: TextStyle(
                color: transaction.isIncome
                    ? const Color(0xFF0CBF91)
                    : expenseAmountColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATION BUTTON
// ============================================================

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap, required this.unreadCount});

  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F9FD),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF0061B7),
                size: 23,
              ),

              // ==================================================
              // UNREAD BADGE
              // ==================================================
              if (unreadCount > 0)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4352),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}