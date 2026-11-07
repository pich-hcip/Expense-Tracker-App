import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../models/report_model.dart';
import 'report_service.dart';
import 'transaction_service.dart';

class ExportService {
  final TransactionService _transactionService = TransactionService();

  final ReportService _reportService = ReportService();

  // ============================================================
  // EXPORT TRANSACTIONS
  // ============================================================

  Future<String> exportTransactions() async {
    final transactions = await _transactionService.getTransactions();

    if (transactions.isEmpty) {
      throw Exception('No transactions available to export.');
    }

    final List<List<dynamic>> rows = [
      ['Date', 'Type', 'Category', 'Wallet', 'Title', 'Note', 'Amount'],
    ];

    for (final transaction in transactions) {
      rows.add([
        _formatTransactionDate(transaction.transactionDate),
        transaction.kind.trim().toUpperCase(),
        transaction.displayCategory,
        transaction.displayWalletName,
        transaction.displayTitle,
        transaction.displayNote,
        transaction.amount.toStringAsFixed(2),
      ]);
    }

    final totalIncome = transactions
        .where((item) => item.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final totalExpense = transactions
        .where((item) => !item.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);

    rows.add([]);

    rows.add([
      '',
      '',
      '',
      '',
      '',
      'Total Income',
      totalIncome.toStringAsFixed(2),
    ]);

    rows.add([
      '',
      '',
      '',
      '',
      '',
      'Total Expense',
      totalExpense.toStringAsFixed(2),
    ]);

    rows.add([
      '',
      '',
      '',
      '',
      '',
      'Net',
      (totalIncome - totalExpense).toStringAsFixed(2),
    ]);

    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final fileName = 'expense_transactions_$date';

    await _saveCsv(fileName: fileName, rows: rows);

    return '$fileName.csv';
  }

  // ============================================================
  // EXPORT MONTHLY REPORT
  // ============================================================

  Future<String> exportMonthlyReport(DateTime month) async {
    final monthParameter = DateFormat('yyyy-MM').format(month);

    // ============================================================
    // GET SUMMARY
    // ============================================================

    final ReportSummary summary = await _reportService.getSummary(
      monthParameter,
    );

    // ============================================================
    // GET EXPENSE BY CATEGORY
    // ============================================================

    final List<CategoryExpenseItem> categories = await _reportService
        .getExpenseByCategory(monthParameter);

    final List<List<dynamic>> rows = [];

    // ============================================================
    // TITLE
    // ============================================================

    rows.add(['MONTHLY FINANCIAL REPORT']);

    rows.add(['Month', DateFormat('MMMM yyyy').format(month)]);

    rows.add([
      'Period',
      '${DateFormat('yyyy-MM-dd').format(summary.startDate)} '
          'to '
          '${DateFormat('yyyy-MM-dd').format(summary.endDate)}',
    ]);

    rows.add([]);

    // ============================================================
    // SUMMARY
    // ============================================================

    rows.add(['SUMMARY']);

    rows.add(['Item', 'Amount']);

    rows.add(['Total Income', summary.totalIncome.toStringAsFixed(2)]);

    rows.add(['Total Expense', summary.totalExpense.toStringAsFixed(2)]);

    rows.add([
      'Net Income',
      (summary.totalIncome - summary.totalExpense).toStringAsFixed(2),
    ]);

    rows.add(['Total Balance', summary.totalBalance.toStringAsFixed(2)]);

    rows.add([]);

    // ============================================================
    // EXPENSE BY CATEGORY
    // ============================================================

    rows.add(['EXPENSE BY CATEGORY']);

    rows.add(['Category', 'Amount', 'Percentage']);

    if (categories.isEmpty) {
      rows.add(['No expense data', '0.00', '0.00%']);
    } else {
      for (final category in categories) {
        rows.add([
          category.categoryName,
          category.amount.toStringAsFixed(2),

          // API already returns 42.55, 23.40, etc.
          '${category.percentage.toStringAsFixed(2)}%',
        ]);
      }
    }

    // ============================================================
    // SAVE
    // ============================================================

    final fileName = 'expense_report_$monthParameter';

    await _saveCsv(fileName: fileName, rows: rows);

    return '$fileName.csv';
  }

  // ============================================================
  // SAVE CSV
  // ============================================================

  Future<void> _saveCsv({
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    final csv = const ListToCsvConverter().convert(rows);

    final Uint8List bytes = Uint8List.fromList(utf8.encode('\uFEFF$csv'));

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatTransactionDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return DateFormat('yyyy-MM-dd').format(date);
  }
}
