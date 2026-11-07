import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
import 'package:intl/intl.dart';
import '../core/category_visuals.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';
import '../services/category_service.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key, required this.selectedMonth});
  final DateTime selectedMonth;
  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _total = TextEditingController();
  final _amounts = <String, TextEditingController>{};
  final _service = BudgetService();
  List<CategoryModel> _categories = [];
  late DateTime _month = DateTime(
    widget.selectedMonth.year,
    widget.selectedMonth.month,
  );
  bool _loading = true, _saving = false, _allocate = false;
  String? _error;
  double? _previousTotal;
  double get _limit => double.tryParse(_total.text) ?? 0;
  int get _allocatedCents =>
      _amounts.values.fold(0, (sum, c) => sum + _cents(c.text));
  int _cents(String text) {
    final value = double.tryParse(text);
    return value == null || !value.isFinite ? 0 : (value * 100).round();
  }

  String _money(double value) =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait<Object>([
        CategoryService().getCategories('EXPENSE'),
        _service.getBudgets(month: _month),
      ]);
      if (!mounted) return;
      final categories = result[0] as List<CategoryModel>;
      final budgets = result[1] as List<BudgetModel>;
      for (final controller in _amounts.values) {
        controller.dispose();
      }
      _amounts.clear();
      for (final category in categories) {
        final existing = budgets.where((b) => b.categoryId == category.id);
        _amounts[category.id] = TextEditingController(
          text: existing.isEmpty
              ? ''
              : existing.first.monthlyLimit.toStringAsFixed(2),
        );
      }
      // Preserve budgets whose categories are no longer in the category list.
      for (final budget in budgets) {
        if (_amounts.containsKey(budget.categoryId)) continue;
        categories.add(
          CategoryModel(
            id: budget.categoryId,
            name: budget.categoryName,
            kind: 'EXPENSE',
            icon: budget.categoryIcon ?? 'more',
            colorHex: budget.categoryColorHex ?? '#929292',
            transactionCount: 0,
          ),
        );
        _amounts[budget.categoryId] = TextEditingController(
          text: budget.monthlyLimit.toStringAsFixed(2),
        );
      }
      _categories = categories;
      _total.text = budgets
          .fold<double>(0, (sum, b) => sum + b.monthlyLimit)
          .toStringAsFixed(2);
      setState(() => _loading = false);
      try {
        final previous = await _service.getSummary(
          month: DateTime(_month.year, _month.month - 1),
        );
        if (mounted) setState(() => _previousTotal = previous.totalBudget);
      } catch (_) {
        /* Comparison is optional. */
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = context.tr('budgets_load_error_retry');
        });
      }
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    for (final controller in _amounts.values) {
      if (controller.text.trim().isEmpty) continue;
      final value = double.tryParse(controller.text);
      if (value == null ||
          !value.isFinite ||
          value < 0 ||
          !RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(controller.text.trim())) {
        setState(
          () => _error = context.tr('valid_amounts_2dp'),
        );
        return;
      }
    }
    if (_allocatedCents != (_limit * 100).round()) {
      setState(
        () => _error = context
            .tr('allocate_full')
            .replaceFirst('{amount}', _money(_limit)),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Reload before each attempt so retries update successful writes instead of duplicating them.
      final existing = await _service.getBudgets(month: _month);
      for (final category in _categories) {
        final amount = double.tryParse(_amounts[category.id]!.text) ?? 0;
        final matches = existing.where((b) => b.categoryId == category.id);
        final current = matches.isEmpty ? null : matches.first;
        if (current != null && amount == current.monthlyLimit) continue;
        if (amount == 0) {
          if (current != null) await _service.deleteBudget(current.id);
        } else if (current != null) {
          await _service.updateBudget(
            id: current.id,
            categoryId: category.id,
            monthlyLimit: amount,
            month: _month,
          );
        } else {
          await _service.createBudget(
            categoryId: category.id,
            monthlyLimit: amount,
            month: _month,
          );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = context.tr('partial_saved'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _total.dispose();
    for (final c in _amounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final allocated = _allocatedCents / 100;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? colors.surface
            : const Color(0xFFF2F7FF),
        appBar: AppBar(
          title: Text(
            _allocate
                ? context.tr('set_category_budgets')
                : context.tr('set_monthly_budget'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: BackButton(
            onPressed: _saving
                ? null
                : () {
                    if (_allocate) {
                      setState(() {
                        _allocate = false;
                        _error = null;
                      });
                    } else {
                      Navigator.pop(context, true);
                    }
                  },
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_categories.isEmpty) ...[
                      Text(
                        _error ?? context.tr('create_category_first'),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: Text(context.tr('retry')),
                      ),
                    ] else if (!_allocate) ...[
                      _card(
                        Column(
                          children: [
                            Text(
                              context.tr('budget_question'),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              scrollPadding: const EdgeInsets.only(bottom: 32),
                              controller: _total,
                              textAlign: TextAlign.center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: InputDecoration(
                                prefixText: '\$ ',
                                labelText: context.tr('monthly_budget'),
                                border: InputBorder.none,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            Slider(
                              value: _limit.isFinite
                                  ? _limit
                                        .clamp(0, _limit > 5000 ? _limit : 5000)
                                        .toDouble()
                                  : 0,
                              max: _limit.isFinite && _limit > 5000
                                  ? _limit
                                  : 5000,
                              onChanged: (value) => setState(
                                () => _total.text = value
                                    .round()
                                    .toStringAsFixed(2),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('\$0'),
                                Text(
                                  _money(
                                    _limit.isFinite && _limit > 5000
                                        ? _limit
                                        : 5000,
                                  ),
                                ),
                              ],
                            ),
                            if (_previousTotal != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Text(
                                  context
                                      .tr('last_month')
                                      .replaceFirst(
                                        '{amount}',
                                        _money(_previousTotal!),
                                      ),
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _card(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('budget_period'),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.calendar_month),
                              title: Text(
                                DateFormat('MMMM yyyy', context.langCode)
                                    .format(_month),
                              ),
                              subtitle: Text(
                                '${DateFormat('MMM d', context.langCode).format(_month)} - '
                                '${DateFormat('MMM d, yyyy', context.langCode).format(DateTime(_month.year, _month.month + 1, 0))}',
                              ),
                              trailing: const Icon(Icons.expand_more),
                              onTap: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: _month,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100, 12, 31),
                                );
                                if (selected != null && mounted) {
                                  _month = DateTime(
                                    selected.year,
                                    selected.month,
                                  );
                                  _previousTotal = null;
                                  await _load();
                                }
                              },
                            ),
                            Text(
                              context.tr('budget_sum_note'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      _card(
                        Text(
                          context
                              .tr('allocate_hint')
                              .replaceFirst('{amount}', _money(_limit)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final category in _categories)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _card(
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: CategoryVisuals.colorFromHex(
                                    category.colorHex,
                                  ),
                                  child: Icon(
                                    CategoryVisuals.iconFor(category.icon),
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 110,
                                  child: TextField(
                                    scrollPadding: const EdgeInsets.only(
                                      bottom: 32,
                                    ),
                                    controller: _amounts[category.id],
                                    enabled: !_saving,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      prefixText: '\$ ',
                                      hintText: '0.00',
                                      labelText: category.name,
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      _card(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context
                                  .tr('total_category_budget')
                                  .replaceFirst('{amount}', _money(allocated)),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              allocated > _limit
                                  ? context
                                      .tr('amount_over_budget')
                                      .replaceFirst(
                                        '{amount}',
                                        _money(allocated - _limit),
                                      )
                                  : context
                                      .tr('left_to_allocate')
                                      .replaceFirst(
                                        '{amount}',
                                        _money(_limit - allocated),
                                      ),
                              style: TextStyle(
                                color: allocated > _limit
                                    ? colors.error
                                    : colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_error != null && _categories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_categories.isNotEmpty)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                        onPressed: _saving
                            ? null
                            : _allocate
                            ? _save
                            : () {
                                if (!_limit.isFinite ||
                                    _limit <= 0 ||
                                    !RegExp(
                                      r'^\d+(\.\d{0,2})?$',
                                    ).hasMatch(_total.text.trim())) {
                                  setState(
                                    () => _error = context.tr('positive_budget'),
                                  );
                                  return;
                                }
                                setState(() {
                                  _allocate = true;
                                  _error = null;
                                });
                              },
                        child: Text(
                          _saving
                              ? context.tr('saving')
                              : _allocate
                              ? context.tr('save_category_budgets')
                              : context.tr('set_budget'),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}