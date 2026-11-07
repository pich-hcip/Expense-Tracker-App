import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
import 'package:intl/intl.dart';

import '../models/budget_model.dart';
import '../core/category_visuals.dart';
import '../services/budget_service.dart';
import 'add_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _budgetService = BudgetService();

  bool _isLoading = true;
  String? _error;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  BudgetSummaryModel? _summary;
  List<BudgetModel> _budgets = [];
  int _loadVersion = 0;
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  // =========================================================
  // LOAD BUDGET
  // =========================================================

  Future<void> _loadBudget() async {
    if (!mounted) return;
    final version = ++_loadVersion;
    final month = _selectedMonth;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<Object>([
        _budgetService.getSummary(month: month),
        _budgetService.getBudgets(month: month),
      ]);

      if (!mounted || version != _loadVersion) return;

      setState(() {
        _summary = results[0] as BudgetSummaryModel;
        _budgets = results[1] as List<BudgetModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || version != _loadVersion) return;

      setState(() {
        _error = 'budget_load_error';
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // PREVIOUS MONTH
  // =========================================================

  Future<void> _previousMonth() async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });

    await _loadBudget();
  }

  // =========================================================
  // NEXT MONTH
  // =========================================================

  Future<void> _nextMonth() async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });

    await _loadBudget();
  }

  // =========================================================
  // ADD BUDGET
  // =========================================================

  Future<void> _openAddBudget() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddBudgetScreen(selectedMonth: _selectedMonth),
      ),
    );

    if (!mounted) return;

    await _loadBudget();
  }

  // =========================================================
  // MONEY
  // =========================================================

  String _money(double value) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('budgets'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('set_budget'),
            onPressed: _openAddBudget,
            icon: const Icon(Icons.add_circle, color: Color(0xFF0752EA)),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorState(message: context.tr(_error!), onRetry: _loadBudget);
    }

    final summary = _summary;

    if (summary == null) {
      return _ErrorState(
        message: context.tr('budget_unavailable'),
        onRetry: _loadBudget,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBudget,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          // =================================================
          // MONTH
          // =================================================
          _MonthSelector(
            month: _selectedMonth,
            onPrevious: _previousMonth,
            onNext: _nextMonth,
          ),

          const SizedBox(height: 20),

          // =================================================
          // SUMMARY
          // =================================================
          _BudgetOverviewCard(summary: summary, money: _money),

          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in [
                'all',
                'on_track',
                'over_limit',
              ].asMap().entries)
                ChoiceChip(
                  label: Text(context.tr(entry.value)),
                  selected: _filter == entry.key,
                  onSelected: (_) => setState(() => _filter = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // =================================================
          // CATEGORY TITLE
          // =================================================
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('category_budgets'),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ),

              Text(
                '${summary.activeBudgets}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =================================================
          // CATEGORY BUDGETS
          // =================================================
          if (_budgets.isNotEmpty &&
              !_budgets.any(
                (b) =>
                    _filter == 0 ||
                    (_filter == 1 ? !b.overBudget : b.overBudget),
              ))
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.tr('no_budgets_match'),
                textAlign: TextAlign.center,
              ),
            ),
          if (_budgets.isEmpty)
            _EmptyBudgetState(onAdd: _openAddBudget)
          else
            ..._budgets
                .where(
                  (b) =>
                      _filter == 0 ||
                      (_filter == 1 ? !b.overBudget : b.overBudget),
                )
                .map(
                  (budget) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CategoryBudgetCard(budget: budget, money: _money),
                  ),
                ),
        ],
      ),
    );
  }
}

// ===========================================================
// MONTH SELECTOR
// ===========================================================

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMMM yyyy', context.langCode).format(month),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('monthly_budget'),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// OVERVIEW
// ===========================================================

class _BudgetOverviewCard extends StatelessWidget {
  const _BudgetOverviewCard({required this.summary, required this.money});
  final BudgetSummaryModel summary;
  final String Function(double) money;
  @override
  Widget build(BuildContext context) {
    final ratio = summary.totalBudget > 0
        ? summary.totalSpent / summary.totalBudget
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF087FFF), Color(0xFF0646D7), Color(0xFF06245C)],
        ),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('total_monthly_budget')),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                money(summary.totalBudget),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context
                  .tr('percent_used')
                  .replaceFirst('{n}', '${(ratio * 100).round()}'),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 12,
                color: ratio > 1
                    ? const Color(0xFFFF657D)
                    : const Color(0xFF21E6A2),
                backgroundColor: Colors.white30,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 6,
              children: [
                Text(
                  context
                      .tr('amount_spent')
                      .replaceFirst('{amount}', money(summary.totalSpent)),
                ),
                Text(
                  summary.remaining < 0
                      ? context
                          .tr('amount_over_limit')
                          .replaceFirst('{amount}', money(-summary.remaining))
                      : context
                          .tr('amount_remaining')
                          .replaceFirst('{amount}', money(summary.remaining)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  const _CategoryBudgetCard({required this.budget, required this.money});
  final BudgetModel budget;
  final String Function(double) money;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratio = budget.monthlyLimit > 0
        ? budget.spent / budget.monthlyLimit
        : 0.0;
    final color = CategoryVisuals.colorFromHex(
      budget.categoryColorHex ?? '#0752EA',
    );
    final progressColor = ratio >= 0.9
        ? const Color(0xFFFF4C6A)
        : const Color(0xFF1767FF);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color,
            child: Icon(
              CategoryVisuals.iconFor(budget.categoryIcon ?? 'wallet'),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${money(budget.spent)} / ${money(budget.monthlyLimit)}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          minHeight: 8,
                          color: progressColor,
                          backgroundColor: progressColor.withValues(
                            alpha: 0.10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(ratio * 100).round()}%',
                      style: TextStyle(color: progressColor, fontSize: 12),
                    ),
                  ],
                ),
                if (budget.overBudget)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      context.tr('over_limit'),
                      style: TextStyle(color: colors.error, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBudgetState extends StatelessWidget {
  const _EmptyBudgetState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.track_changes_rounded,
              color: colors.primary,
              size: 30,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            context.tr('no_budgets_month'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 7),

          Text(
            context.tr('no_budgets_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 18),

          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(context.tr('create_budget')),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// ERROR
// ===========================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 50),

            const SizedBox(height: 14),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}