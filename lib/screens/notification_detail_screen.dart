import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';

class NotificationDetailScreen
    extends StatelessWidget {
  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  final NotificationModel notification;

  IconData _getIcon() {
    switch (notification.type) {
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

  Color _getColor() {
    switch (notification.type) {
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

  String _getTypeLabel(BuildContext context) {
    switch (notification.type) {
      case 'INCOME_ADDED':
        return context.tr('income');

      case 'EXPENSE_ADDED':
        return context.tr('expense');

      case 'LOW_BALANCE':
        return context.tr('wallet_alert');

      case 'BUDGET_WARNING':
      case 'BUDGET_EXCEEDED':
        return context.tr('budget_alert');

      case 'MONTHLY_SUMMARY':
        return context.tr('monthly_summary');

      case 'REMINDER':
        return context.tr('reminder');

      default:
        return context.tr('notification');
    }
  }

  String _getStatus(BuildContext context) {
    switch (notification.type) {
      case 'INCOME_ADDED':
      case 'EXPENSE_ADDED':
        return context.tr('completed');

      case 'LOW_BALANCE':
        return context.tr('attention');

      case 'BUDGET_WARNING':
        return context.tr('warning');

      case 'BUDGET_EXCEEDED':
        return context.tr('exceeded');

      case 'MONTHLY_SUMMARY':
        return context.tr('available_status');

      case 'REMINDER':
        return context.tr('reminder');

      default:
        return context.tr('information');
    }
  }

  String _formatDate(BuildContext context) {
    return DateFormat(
      'MMM d, yyyy',
      context.langCode,
    ).format(
      notification.createdAt.toLocal(),
    );
  }

  String _formatTime(BuildContext context) {
    return DateFormat(
      'h:mm a',
      context.langCode,
    ).format(
      notification.createdAt.toLocal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = _getColor();

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor:
            theme.scaffoldBackgroundColor,
        surfaceTintColor:
            Colors.transparent,
        foregroundColor:
            scheme.onSurface,

        title: Text(
          context.tr('notification_detail'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            30,
          ),
          child: Column(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration:
                    BoxDecoration(
                  color:
                      color.withOpacity(
                    0.12,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(),
                  color: color,
                  size: 39,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                notification.title,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      scheme.onSurface,
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      color.withOpacity(
                    0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  _getTypeLabel(context),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // MESSAGE
              // ==================================================

              _detailCard(
                context,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      context.tr('message'),
                      style: TextStyle(
                        color: scheme
                            .onSurfaceVariant,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      notification.message,
                      style: TextStyle(
                        color:
                            scheme.onSurface,
                        fontSize: 15,
                        height: 1.6,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // DETAILS
              // ==================================================

              _detailCard(
                context,
                child: Column(
                  children: [
                    _DetailRow(
                      icon:
                          Icons.category_outlined,
                      label: context.tr('type'),
                      value:
                          _getTypeLabel(context),
                    ),

                    const _DetailDivider(),

                    _DetailRow(
                      icon:
                          Icons.info_outline_rounded,
                      label: context.tr('status'),
                      value: _getStatus(context),
                      valueColor: color,
                    ),

                    const _DetailDivider(),

                    _DetailRow(
                      icon: Icons
                          .calendar_today_outlined,
                      label: context.tr('date'),
                      value: _formatDate(context),
                    ),

                    const _DetailDivider(),

                    _DetailRow(
                      icon:
                          Icons.access_time_rounded,
                      label: context.tr('time'),
                      value: _formatTime(context),
                    ),

                    const _DetailDivider(),

                    _DetailRow(
                      icon: notification.read
                          ? Icons
                              .mark_email_read_outlined
                          : Icons
                              .mark_email_unread_outlined,
                      label: context.tr('read_status'),
                      value: notification.read
                          ? context.tr('read')
                          : context.tr('unread'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildInfoBox(
                context,
                color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailCard(
    BuildContext context, {
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark =
        theme.brightness ==
            Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black
                    .withOpacity(0.18)
                : const Color(
                    0x0A000000,
                  ),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoBox(
    BuildContext context,
    Color color,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    String text;

    switch (notification.type) {
      case 'INCOME_ADDED':
        text = context.tr('info_income');
        break;

      case 'EXPENSE_ADDED':
        text = context.tr('info_expense');
        break;

      case 'LOW_BALANCE':
        text = context.tr('info_low_balance');
        break;

      case 'BUDGET_WARNING':
        text = context.tr('info_budget_warning');
        break;

      case 'BUDGET_EXCEEDED':
        text = context.tr('info_budget_exceeded');
        break;

      case 'MONTHLY_SUMMARY':
        text = context.tr('info_monthly');
        break;

      case 'REMINDER':
        text = context.tr('info_reminder');
        break;

      default:
        text = context.tr('info_default');
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            color.withOpacity(0.09),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              color.withOpacity(0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: color,
            size: 21,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DETAIL ROW
// ============================================================

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme
                .surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 19,
            color: scheme.primary,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  scheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style: TextStyle(
              color: valueColor ??
                  scheme.onSurface,
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DIVIDER
// ============================================================

class _DetailDivider
    extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 13,
      ),
      child: Divider(
        height: 1,
        color: Theme.of(context)
            .dividerColor,
      ),
    );
  }
}