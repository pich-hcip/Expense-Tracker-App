import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

import 'notification_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {
  final NotificationService _service =
      NotificationService();

  bool _loading = true;
  String? _error;

  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
          await _service.getNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'notifications_load_error';
      });
    }
  }

  // ============================================================
  // OPEN DETAIL
  // ============================================================

  Future<void> _openNotification(
    NotificationModel item,
  ) async {
    if (!item.read) {
      try {
        await _service.markAsRead(item.id);
      } catch (_) {
        if (!mounted) return;

        _showError(
          context.tr('notification_update_failed'),
        );

        return;
      }
    }

    if (!mounted) return;

    // Create an updated copy for Detail so it shows "Read".
    final detailItem = NotificationModel(
      id: item.id,
      type: item.type,
      title: item.title,
      message: item.message,
      read: true,
      createdAt: item.createdAt,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NotificationDetailScreen(
          notification: detailItem,
        ),
      ),
    );

    if (!mounted) return;

    await _load();
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllAsRead();

      if (!mounted) return;

      await _load();
    } catch (_) {
      if (!mounted) return;

      _showError(
        context.tr('mark_read_failed'),
      );
    }
  }

  Future<void> _delete(
    NotificationModel item,
  ) async {
    try {
      await _service.deleteNotification(
        item.id,
      );

      if (!mounted) return;

      setState(() {
        _notifications.removeWhere(
          (notification) =>
              notification.id == item.id,
        );
      });
    } catch (_) {
      if (!mounted) return;

      _showError(
        context.tr('delete_notification_failed'),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'INCOME_ADDED':
        return Icons.savings_outlined;

      case 'EXPENSE_ADDED':
        return Icons.payments_outlined;

      case 'LOW_BALANCE':
        return Icons
            .account_balance_wallet_outlined;

      case 'BUDGET_WARNING':
        return Icons.warning_amber_rounded;

      case 'BUDGET_EXCEEDED':
        return Icons.error_outline_rounded;

      case 'MONTHLY_SUMMARY':
        return Icons.bar_chart_rounded;

      case 'REMINDER':
        return Icons
            .notifications_active_outlined;

      default:
        return Icons
            .notifications_none_rounded;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'INCOME_ADDED':
        return const Color(0xFF13B889);

      case 'EXPENSE_ADDED':
        return const Color(0xFFFF4352);

      case 'LOW_BALANCE':
      case 'BUDGET_WARNING':
        return const Color(0xFFF59E0B);

      case 'BUDGET_EXCEEDED':
        return const Color(0xFFE53935);

      case 'MONTHLY_SUMMARY':
      case 'REMINDER':
      default:
        return const Color(0xFF0061B7);
    }
  }

  String _time(DateTime value) {
    final now = DateTime.now();
    final local = value.toLocal();
    final difference = now.difference(local);

    if (difference.isNegative ||
        difference.inMinutes < 1) {
      return context.tr('just_now');
    }

    if (difference.inMinutes < 60) {
      return context
          .tr('min_ago')
          .replaceFirst('{n}', '${difference.inMinutes}');
    }

    if (difference.inHours < 24) {
      return context
          .tr('hr_ago')
          .replaceFirst('{n}', '${difference.inHours}');
    }

    if (difference.inDays == 1) {
      return context.tr('yesterday');
    }

    if (difference.inDays < 7) {
      return context
          .tr('days_ago')
          .replaceFirst('{n}', '${difference.inDays}');
    }

    return '${local.day}/${local.month}/${local.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final unread = _notifications
        .where((item) => !item.read)
        .length;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor:
            theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,

        title: Text(
          context.tr('notifications'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                context.tr('mark_all_read'),
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          const SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        children: [
          const SizedBox(height: 170),

          const Icon(
            Icons.error_outline_rounded,
            size: 58,
            color: Color(0xFFFF4352),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              context.tr(_error!),
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
                fontSize: 15,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Center(
            child: ElevatedButton(
              onPressed: _load,
              child: Text(context.tr('retry')),
            ),
          ),
        ],
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        children: [
          const SizedBox(height: 170),

          Icon(
            Icons.notifications_none_rounded,
            size: 68,
            color: scheme.onSurfaceVariant
                .withOpacity(0.55),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              context.tr('no_notifications'),
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 7),

          Center(
            child: Text(
              context.tr('no_notifications_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        30,
      ),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _notificationCard(
          _notifications[index],
        );
      },
    );
  }

  Widget _notificationCard(
    NotificationModel item,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark =
        theme.brightness == Brightness.dark;

    final color = _iconColor(item.type);

    final cardColor = item.read
        ? scheme.surface
        : isDark
            ? scheme.primary
                .withOpacity(0.12)
            : const Color(0xFFF0F6FF);

    final borderColor = item.read
        ? scheme.outlineVariant
        : isDark
            ? scheme.primary
                .withOpacity(0.30)
            : const Color(0xFFD5E5FA);

    return Dismissible(
      key: ValueKey(item.id),
      direction:
          DismissDirection.endToStart,

      background: Container(
        alignment: Alignment.centerRight,
        padding:
            const EdgeInsets.only(
          right: 24,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 25,
        ),
      ),

      confirmDismiss: (_) async {
        await _delete(item);
        return false;
      },

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap: () =>
              _openNotification(item),

          child: Container(
            padding:
                const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black
                          .withOpacity(0.15)
                      : const Color(
                          0x08000000,
                        ),
                  blurRadius: 8,
                  offset:
                      const Offset(0, 2),
                ),
              ],
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:
                        color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon(item.type),
                    color: color,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: TextStyle(
                                color:
                                    scheme.onSurface,
                                fontSize: 15,
                                fontWeight:
                                    item.read
                                        ? FontWeight
                                            .w600
                                        : FontWeight
                                            .w700,
                              ),
                            ),
                          ),

                          if (!item.read) ...[
                            const SizedBox(
                              width: 8,
                            ),

                            Container(
                              width: 8,
                              height: 8,
                              decoration:
                                  BoxDecoration(
                                color:
                                    scheme.primary,
                                shape:
                                    BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        item.message,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme
                              .onSurfaceVariant,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 9),

                      Text(
                        _time(
                          item.createdAt,
                        ),
                        style: TextStyle(
                          color: scheme
                              .onSurfaceVariant
                              .withOpacity(0.75),
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 12,
                  ),
                  child: Icon(
                    Icons
                        .chevron_right_rounded,
                    color: scheme
                        .onSurfaceVariant
                        .withOpacity(0.60),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}