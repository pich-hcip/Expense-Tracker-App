import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/category_visuals.dart';
import '../core/l10n.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  ReportScreenState createState() => ReportScreenState();
}

class ReportScreenState extends State<ReportScreen> {
  int _requestId = 0;
  Future<void> refresh() => _loadReport();
  static const Color _primary = Color(0xFF0061B7);
  static const Color _income = Color(0xFF0CBF91);
  static const Color _expense = Color(0xFFFF4352);

  final ReportService _service = ReportService();

  late DateTime _selectedMonth;

  bool _loading = true;
  String? _error;

  ReportSummary? _summary;
  List<ExpenseTrendItem> _trend = [];
  List<CategoryExpenseItem> _categories = [];
  List<_MonthCompare> _compare = [];

  // 0 = Spending, 1 = Income vs Expense
  int _tab = 0;

  // Selected slice in the donut chart (-1 = none)
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);

    _loadReport();
  }

  String get _monthParameter {
    // Always English format for the API
    return DateFormat('yyyy-MM', 'en').format(_selectedMonth);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadReport() async {
    if (!mounted) return;
    final requestId = ++_requestId;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final months = List.generate(
        6,
        (i) => DateTime(_selectedMonth.year, _selectedMonth.month - 5 + i),
      );

      final results = await Future.wait([
        _service.getSummary(_monthParameter),
        _service.getExpenseTrend(_monthParameter),
        _service.getExpenseByCategory(_monthParameter),
        ...months.map(
          (m) => _service.getSummary(DateFormat('yyyy-MM', 'en').format(m)),
        ),
      ]);

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _summary = results[0] as ReportSummary;
        _trend = results[1] as List<ExpenseTrendItem>;
        _categories = results[2] as List<CategoryExpenseItem>;

        _compare = [
          for (int i = 0; i < months.length; i++)
            _MonthCompare(
              month: months[i],
              income: (results[3 + i] as ReportSummary).totalIncome,
              expense: (results[3 + i] as ReportSummary).totalExpense,
            ),
        ];

        _touchedIndex = -1;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _loading = false;
        _error = 'report_load_error';
      });
    }
  }

  // ============================================================
  // MONTH
  // ============================================================

  Future<void> _chooseMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: context.tr('select_report_month'),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });

    await _loadReport();
  }

  void _changeMonth(int delta) {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    final now = DateTime.now();

    if (next.isAfter(DateTime(now.year, now.month))) return;

    setState(() => _selectedMonth = next);
    _loadReport();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr('reports'),
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _monthArrow(
                  Icons.chevron_left_rounded,
                  () => _changeMonth(-1),
                ),
                InkWell(
                  onTap: _chooseMonth,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    child: Text(
                      DateFormat('MMM yyyy', context.langCode)
                          .format(_selectedMonth),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _monthArrow(
                  Icons.chevron_right_rounded,
                  _isCurrentMonth ? null : () => _changeMonth(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthArrow(IconData icon, VoidCallback? onTap) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 22,
          color: onTap == null
              ? scheme.onSurface.withOpacity(0.25)
              : scheme.primary,
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _body() {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: scheme.primary),
      );
    }

    if (_error != null || _summary == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: _expense,
              size: 45,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(_error ?? 'report_load_error'),
              style: TextStyle(color: scheme.onSurface),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadReport,
              child: Text(context.tr('retry')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: scheme.primary,
      onRefresh: _loadReport,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        children: [
          _overviewCard(),
          const SizedBox(height: 16),
          _tabs(),
          const SizedBox(height: 16),
          if (_tab == 0)
            _spendingCard()
          else ...[
            _compareCard(),
            const SizedBox(height: 16),
            _trendCard(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // OVERVIEW
  // ============================================================

  Widget _overviewCard() {
    final summary = _summary!;
    final lang = context.langCode;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0061B7), Color(0xFF2E86E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('total_balance'),
                style: const TextStyle(color: Color(0xFFB9DCF8), fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                _money(summary.totalBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${DateFormat('MMM d', lang).format(summary.startDate)}'
                ' - '
                '${DateFormat('MMM d, yyyy', lang).format(summary.endDate)}',
                style: const TextStyle(color: Color(0xFFB9DCF8), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryBox(
                title: context.tr('income'),
                amount: _money(summary.totalIncome),
                icon: Icons.arrow_upward,
                color: _income,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryBox(
                title: context.tr('expense'),
                amount: _money(summary.totalExpense),
                icon: Icons.arrow_downward,
                color: _expense,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _tabs() {
    final scheme = Theme.of(context).colorScheme;

    Widget tab(String label, int index) {
      final selected = _tab == index;

      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? scheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected
                  ? [
                      const BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          tab(context.tr('spending'), 0),
          tab(context.tr('income_vs_expense'), 1),
        ],
      ),
    );
  }

  // ============================================================
  // SPENDING (DONUT CHART)
  // ============================================================

  Widget _spendingCard() {
    final scheme = Theme.of(context).colorScheme;

    if (_categories.isEmpty) {
      return _card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 48,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('no_expenses_month'),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final touched = _touchedIndex >= 0 && _touchedIndex < _categories.length
        ? _categories[_touchedIndex]
        : null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('spending_by_category'),
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('tap_slice'),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 70,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response?.touchedSection == null) {
                          return;
                        }
                        final index =
                            response!.touchedSection!.touchedSectionIndex;
                        setState(() {
                          _touchedIndex = index == _touchedIndex ? -1 : index;
                        });
                      },
                    ),
                    sections: [
                      for (int i = 0; i < _categories.length; i++)
                        PieChartSectionData(
                          value: _categories[i].amount,
                          color: CategoryVisuals.colorFromHex(
                            _categories[i].categoryColorHex,
                          ),
                          radius: i == _touchedIndex ? 36 : 28,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      touched?.categoryName ?? context.tr('total_spent'),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _money(touched?.amount ?? _summary!.totalExpense),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (touched != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${touched.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: CategoryVisuals.colorFromHex(
                            touched.categoryColorHex,
                          ),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < _categories.length; i++)
            _categoryItem(_categories[i], i),
        ],
      ),
    );
  }

  Widget _categoryItem(CategoryExpenseItem item, int index) {
    final scheme = Theme.of(context).colorScheme;
    final color = CategoryVisuals.colorFromHex(item.categoryColorHex);
    final progress = (item.percentage / 100).clamp(0.0, 1.0);
    final selected = index == _touchedIndex;

    return InkWell(
      onTap: () => setState(() {
        _touchedIndex = selected ? -1 : index;
      }),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                CategoryVisuals.iconFor(item.categoryIcon),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.categoryName,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _money(item.amount),
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 38,
                        child: Text(
                          '${item.percentage.toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INCOME VS EXPENSE
  // ============================================================

  Widget _compareCard() {
    final scheme = Theme.of(context).colorScheme;
    final summary = _summary!;
    final net = summary.totalIncome - summary.totalExpense;
    final saved = net >= 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('income_vs_expense'),
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('last_6_months'),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _legendDot(_income, context.tr('income')),
              const SizedBox(width: 16),
              _legendDot(_expense, context.tr('expense')),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(height: 220, child: _buildCompareChart()),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: (saved ? _income : _expense).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  saved ? Icons.savings_outlined : Icons.warning_amber_rounded,
                  color: saved ? _income : _expense,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    saved
                        ? context.tr('you_saved')
                        : context.tr('you_overspent'),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _money(net.abs()),
                  style: TextStyle(
                    color: saved ? _income : _expense,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompareChart() {
    final scheme = Theme.of(context).colorScheme;

    final hasData = _compare.any((m) => m.income > 0 || m.expense > 0);
    if (!hasData) {
      return Center(
        child: Text(
          context.tr('no_income_expense_data'),
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    double maxValue = 0;
    for (final m in _compare) {
      if (m.income > maxValue) maxValue = m.income;
      if (m.expense > maxValue) maxValue = m.expense;
    }

    final incomeLabel = context.tr('income');
    final expenseLabel = context.tr('expense');
    final lang = context.langCode;

    return BarChart(
      BarChartData(
        maxY: maxValue * 1.2,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: scheme.outlineVariant.withOpacity(0.5),
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1E293B),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rodIndex == 0 ? incomeLabel : expenseLabel}\n${_money(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox();
                return Text(
                  NumberFormat.compact(locale: 'en').format(value),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _compare.length) {
                  return const SizedBox();
                }
                final isSelected = index == _compare.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    DateFormat('MMM', lang).format(_compare[index].month),
                    style: TextStyle(
                      color: isSelected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < _compare.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: _compare[i].income,
                  color: _income,
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: _compare[i].expense,
                  color: _expense,
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // TREND
  // ============================================================

  Widget _trendCard() {
    final scheme = Theme.of(context).colorScheme;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('daily_trend'),
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                context.tr('total_spent'),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                _money(_summary!.totalExpense),
                style: const TextStyle(
                  color: _expense,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(height: 200, child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final scheme = Theme.of(context).colorScheme;

    if (_trend.isEmpty) {
      return Center(
        child: Text(
          context.tr('no_expense_data'),
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    final spots = <FlSpot>[
      for (int i = 0; i < _trend.length; i++)
        FlSpot(i.toDouble(), _trend[i].amount),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: scheme.outlineVariant.withOpacity(0.5),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _trend.length > 10 ? 7 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _trend.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    DateFormat('d', 'en').format(_trend[index].date),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _primary.withOpacity(0.10),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({required Widget child}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.20)
                : const Color(0x08000000),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  String _money(double value) {
    // Keep $ format the same in both languages
    return NumberFormat.currency(locale: 'en', symbol: '\$', decimalDigits: 2)
        .format(value);
  }
}

// ============================================================
// MONTH COMPARE DATA
// ============================================================

class _MonthCompare {
  const _MonthCompare({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;
}

// ============================================================
// SUMMARY BOX
// ============================================================

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(isDark ? 0.20 : 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}