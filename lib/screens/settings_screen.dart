import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../services/export_service.dart';
import 'auth/login_screen.dart';
import 'notification_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('settings'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
        children: [
          // =====================================================
          // GENERAL
          // =====================================================
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.attach_money_rounded,
                title: context.tr('currency'),
                trailing: const Text('USD (\$)'),
                onTap: () {
                  _showCurrencyInfo(context);
                },
              ),

              const _SettingsDivider(),

              _SettingsTile(
                icon: Icons.language_rounded,
                title: context.tr('language'),
                trailing: Text(languageProvider.isKhmer ? 'ខ្មែរ' : 'English'),
                onTap: () {
                  _showLanguageInfo(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          // =====================================================
          // FINANCIAL / APPEARANCE
          // =====================================================
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: context.tr('budget_settings'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  _showBudgetInfo(context);
                },
              ),

              const _SettingsDivider(),

              _SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: context.tr('notifications'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
              ),

              const _SettingsDivider(),

              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: context.tr('dark_mode'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
                onTap: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          // =====================================================
          // DATA / ABOUT
          // =====================================================
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.file_download_outlined,
                title: context.tr('export_data'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  _showExportData(context);
                },
              ),

              const _SettingsDivider(),

              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: context.tr('about_app'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  _showAboutApp(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          // =====================================================
          // LOGOUT
          // =====================================================
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _confirmLogout(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          context.tr('logout'),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // EXPORT TRANSACTIONS
  // ===========================================================

  Future<void> _exportTransactions(BuildContext context) async {
    bool dialogOpen = false;

    try {
      dialogOpen = true;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),

                      const SizedBox(height: 18),

                      Text(
                        context.tr('exporting_transactions'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      final fileName = await ExportService().exportTransactions();

      if (!context.mounted) {
        return;
      }

      if (dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();

        dialogOpen = false;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    context
                        .tr('exported_success')
                        .replaceFirst('{file}', fileName),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      if (dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();

        dialogOpen = false;
      }

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),

                const SizedBox(width: 10),

                Expanded(child: Text(message)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ===========================================================
  // EXPORT MONTHLY REPORT
  // ===========================================================

  Future<void> _exportMonthlyReport(BuildContext context) async {
    final selectedMonth = await _showMonthPicker(context);

    if (selectedMonth == null || !context.mounted) {
      return;
    }

    bool dialogOpen = false;

    try {
      dialogOpen = true;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),

                      const SizedBox(height: 18),

                      Text(
                        context.tr('generating_report'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      final fileName = await ExportService().exportMonthlyReport(selectedMonth);

      if (!context.mounted) {
        return;
      }

      if (dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();

        dialogOpen = false;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    context
                        .tr('exported_success')
                        .replaceFirst('{file}', fileName),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      if (dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();

        dialogOpen = false;
      }

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),

                const SizedBox(width: 10),

                Expanded(child: Text(message)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ===========================================================
  // MONTH PICKER
  // ===========================================================

  Future<DateTime?> _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();

    int selectedMonth = now.month;
    int selectedYear = now.year;

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = Theme.of(context).colorScheme;

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined),
                  const SizedBox(width: 10),
                  Expanded(child: Text(context.tr('select_report_month'))),
                ],
              ),
              content: SizedBox(
                width: 330,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==========================================
                    // MONTH
                    // ==========================================
                    DropdownButtonFormField<int>(
                      value: selectedMonth,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('month'),
                        prefixIcon: const Icon(Icons.calendar_month_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: List.generate(12, (index) {
                        final month = index + 1;

                        return DropdownMenuItem<int>(
                          value: month,
                          child: Text(_monthName(context, month)),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedMonth = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==========================================
                    // YEAR
                    // ==========================================
                    DropdownButtonFormField<int>(
                      value: selectedYear,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('year'),
                        prefixIcon: const Icon(Icons.date_range_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: List.generate(6, (index) {
                        final year = now.year - index;

                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedYear = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    // ==========================================
                    // SELECTED MONTH PREVIEW
                    // ==========================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: colors.primary,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('monthly_report'),
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_monthName(context, selectedMonth)} '
                                  '$selectedYear',
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(context.tr('cancel')),
                ),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      DateTime(selectedYear, selectedMonth),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(context.tr('export')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Month name in the selected language (January / មករា)
  String _monthName(BuildContext context, int month) {
    return DateFormat.MMMM(context.langCode).format(DateTime(2000, month));
  }

  // ===========================================================
  // LOGOUT
  // ===========================================================

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('logout')),
          content: Text(context.tr('logout_confirm')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(context.tr('logout')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ===========================================================
  // CURRENCY
  // ===========================================================

  void _showCurrencyInfo(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TopIcon(icon: Icons.attach_money_rounded),

              const SizedBox(height: 14),

              Text(
                context.tr('currency'),
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                context.tr('currency_info'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: colors.primary),

                    const SizedBox(width: 12),

                    Text(
                      'USD (\$)',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================
  // LANGUAGE
  // ===========================================================

  void _showLanguageInfo(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: colors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget option(String code, String flag, String label) {
          final selected = languageProvider.locale.languageCode == code;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: selected
                  ? colors.primary.withValues(alpha: 0.08)
                  : colors.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  languageProvider.setLanguage(code);
                  Navigator.pop(sheetContext);
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? colors.primary : colors.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 24)),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      if (selected)
                        Icon(Icons.check_circle_rounded, color: colors.primary),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TopIcon(icon: Icons.language_rounded),

              const SizedBox(height: 14),

              Text(
                context.tr('choose_language'),
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 20),

              option('en', '🇬🇧', 'English'),
              option('km', '🇰🇭', 'ខ្មែរ (Khmer)'),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================
  // BUDGET SETTINGS
  // ===========================================================

  void _showBudgetInfo(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.82),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _TopIcon(icon: Icons.account_balance_wallet_outlined),

                const SizedBox(height: 14),

                Text(
                  context.tr('budget_settings'),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  context.tr('budget_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _InfoRow(
                        icon: Icons.pie_chart_outline_rounded,
                        title: context.tr('monthly_budget'),
                        subtitle: context.tr('monthly_budget_desc'),
                      ),

                      const SizedBox(height: 18),

                      _InfoRow(
                        icon: Icons.warning_amber_rounded,
                        title: context.tr('budget_warning'),
                        subtitle: context.tr('budget_warning_desc'),
                      ),

                      const SizedBox(height: 18),

                      _InfoRow(
                        icon: Icons.error_outline_rounded,
                        title: context.tr('over_budget'),
                        subtitle: context.tr('over_budget_desc'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================
  // EXPORT DATA
  // ===========================================================

  void _showExportData(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.82),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _TopIcon(icon: Icons.file_download_outlined),

                const SizedBox(height: 14),

                Text(
                  context.tr('export_data'),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  context.tr('export_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 22),

                // =============================================
                // TRANSACTIONS
                // =============================================
                _ExportOption(
                  icon: Icons.table_chart_outlined,
                  title: context.tr('export_transactions'),
                  subtitle: context.tr('export_transactions_desc'),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await Future<void>.delayed(
                      const Duration(milliseconds: 200),
                    );

                    if (!context.mounted) {
                      return;
                    }

                    await _exportTransactions(context);
                  },
                ),

                const SizedBox(height: 12),

                // =============================================
                // MONTHLY REPORT
                // =============================================
                _ExportOption(
                  icon: Icons.analytics_outlined,
                  title: context.tr('export_monthly'),
                  subtitle: context.tr('export_monthly_desc'),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await Future<void>.delayed(
                      const Duration(milliseconds: 200),
                    );

                    if (!context.mounted) {
                      return;
                    }

                    await _exportMonthlyReport(context);
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================
  // ABOUT APP
  // ===========================================================

  void _showAboutApp(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =============================================
                // APP ICON
                // =============================================
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: colors.primary,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 18),

                // =============================================
                // APP NAME
                // =============================================
                Text(
                  context.tr('app_name'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                // =============================================
                // VERSION
                // =============================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.tr('version'),
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // =============================================
                // DESCRIPTION
                // =============================================
                Text(
                  context.tr('about_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),

                const SizedBox(height: 24),

                // =============================================
                // MAIN FEATURES
                // =============================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('main_features'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 18),

                      _AboutFeature(
                        icon: Icons.swap_horiz_rounded,
                        title: context.tr('feat_income_expense'),
                        subtitle: context.tr('feat_income_expense_desc'),
                      ),

                      const SizedBox(height: 17),

                      _AboutFeature(
                        icon: Icons.account_balance_wallet_outlined,
                        title: context.tr('feat_wallet'),
                        subtitle: context.tr('feat_wallet_desc'),
                      ),

                      const SizedBox(height: 17),

                      _AboutFeature(
                        icon: Icons.savings_outlined,
                        title: context.tr('feat_budget'),
                        subtitle: context.tr('feat_budget_desc'),
                      ),

                      const SizedBox(height: 17),

                      _AboutFeature(
                        icon: Icons.notifications_none_rounded,
                        title: context.tr('feat_notifications'),
                        subtitle: context.tr('feat_notifications_desc'),
                      ),

                      const SizedBox(height: 17),

                      _AboutFeature(
                        icon: Icons.analytics_outlined,
                        title: context.tr('feat_reports'),
                        subtitle: context.tr('feat_reports_desc'),
                      ),

                      const SizedBox(height: 17),

                      _AboutFeature(
                        icon: Icons.file_download_outlined,
                        title: context.tr('export_data'),
                        subtitle: context.tr('feat_export_desc'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // =============================================
                // PROJECT INFORMATION
                // =============================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: colors.primary,
                        size: 30,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        context.tr('course_name'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        context.tr('project_name'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =============================================
                // CLOSE BUTTON
                // =============================================
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.tr('close'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  '© 2026 Expense Tracker',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================
// ABOUT FEATURE
// =============================================================

class _AboutFeature extends StatelessWidget {
  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: colors.primary, size: 21),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================
// TOP ICON
// =============================================================

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: colors.primary, size: 30),
    );
  }
}

// =============================================================
// TOP ICON 2
// =============================================================

class _TopIcon2 extends StatelessWidget {
  const _TopIcon2({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: colors.primary, size: 30),
    );
  }
}

// =============================================================
// SETTINGS CARD
// =============================================================

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

// =============================================================
// SETTINGS TILE
// =============================================================

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colors.primary, size: 22),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                DefaultTextStyle.merge(
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  child: IconTheme(
                    data: IconThemeData(
                      color: colors.onSurfaceVariant,
                      size: 22,
                    ),
                    child: trailing,
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

// =============================================================
// SETTINGS DIVIDER
// =============================================================

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

// =============================================================
// BUDGET INFO ROW
// =============================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: colors.primary, size: 21),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================
// EXPORT OPTION
// =============================================================

class _ExportOption extends StatelessWidget {
  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: colors.primary, size: 21),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}