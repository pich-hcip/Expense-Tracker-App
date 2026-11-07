import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
import 'package:dio/dio.dart'; // Added to use your ApiClient's Dio instance

import '../core/api_client.dart'; // Your API client
import '../models/category_model.dart';
import '../services/category_service.dart';
import 'add_category_screen.dart';
import 'add_transaction_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({
    super.key,
    this.onCategorySelected,
  });

  final ValueChanged<String>? onCategorySelected;

  @override
  CategoryScreenState createState() => CategoryScreenState();
}

class CategoryScreenState extends State<CategoryScreen> {
  final CategoryService _service = CategoryService();

  static const Color _blue = Color(0xFF0061B7);
  static const Color _background = Color(0xFFF7F9FC);

  bool _showExpenses = true;
  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _error;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories({
    bool showLoading = true,
  }) async {
    if (!mounted || _isRefreshing) return;

    _isRefreshing = true;

    final kind = _showExpenses ? 'EXPENSE' : 'INCOME';

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final allCategories = await _service.getCategories(kind);

      if (!mounted) return;

      if (kind != (_showExpenses ? 'EXPENSE' : 'INCOME')) {
        return;
      }

      // Filter out "Uncategorized"
      final visibleCategories = allCategories
          .where((c) => c.name.toLowerCase() != 'uncategorized')
          .toList();

      setState(() {
        _categories = visibleCategories;
        _error = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'categories_load_error';
        _isLoading = false;
      });
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> refresh() async {
    await _loadCategories(showLoading: false);
  }

  Future<void> _changeKind(bool expense) async {
    if (_showExpenses == expense) return;

    while (_isRefreshing) {
      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );
      if (!mounted) return;
    }

    setState(() {
      _showExpenses = expense;
    });

    await _loadCategories();
  }

  Future<void> _openAddCategory() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddCategoryScreen(
          defaultIsExpense: _showExpenses,
        ),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _loadCategories(showLoading: false);
    }
  }

  Future<void> _openTransaction(CategoryModel category) async {
    widget.onCategorySelected?.call(category.id);

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddTransactionScreen(
          category: category,
        ),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      await _loadCategories(showLoading: false);
    }
  }

  Future<void> _editCategory(CategoryModel category) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditCategorySheet(
        category: category,
        service: _service,
        isExpense: _showExpenses,
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      _showMessage(context.tr('category_updated'));
      await _loadCategories(showLoading: false);
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final count = category.transactionCount;
    final extra = count > 0
        ? '\n\n${context.tr(count == 1 ? 'moved_uncategorized_one' : 'moved_uncategorized').replaceFirst('{n}', '$count')}'
        : '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('delete_category_q')),
        content: Text(
          '${context.tr('delete_confirm').replaceFirst('{name}', category.name)}'
          '$extra\n\n${context.tr('cannot_undo')}',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteCategory(category.id);

      if (!mounted) return;

      _showMessage(context.tr('category_deleted'));
      await _loadCategories(showLoading: false);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _service.getErrorMessage(e),
        error: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : _blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          dark ? theme.scaffoldBackgroundColor : _background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('categories'),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: context.tr('add_category'),
                    onPressed: _openAddCategory,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: dark
                      ? theme.colorScheme.surfaceContainerHighest
                      : const Color(0xFFEFF3F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _KindButton(
                        label: context.tr('expense'),
                        selected: _showExpenses,
                        onTap: () => _changeKind(true),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _KindButton(
                        label: context.tr('income'),
                        selected: !_showExpenses,
                        onTap: () => _changeKind(false),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _buildBody(theme, dark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool dark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(_error!),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _loadCategories(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showExpenses
                          ? Icons.receipt_long_outlined
                          : Icons.savings_outlined,
                      size: 56,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _showExpenses
                          ? context.tr('no_expense_categories')
                          : context.tr('no_income_categories'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('tap_plus_create'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _CategoryTile(
            category: category,
            dark: dark,
            onTap: () => _openTransaction(category),
            onEdit: () => _editCategory(category),
            onDelete: () => _deleteCategory(category),
          );
        },
      ),
    );
  }
}

class _KindButton extends StatelessWidget {
  const _KindButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (dark ? theme.colorScheme.surface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected && !dark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? CategoryScreenState._blue
                  : theme.colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.dark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryModel category;
  final bool dark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blue;
    try {
      final cleanHex = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'bag': return Icons.shopping_bag;
      case 'invoice': return Icons.receipt;
      case 'movie': return Icons.movie;
      case 'food': return Icons.fastfood;
      case 'transport': return Icons.directions_car;
      case 'shopping': return Icons.shopping_bag;
      case 'home': return Icons.home;
      case 'bills': return Icons.receipt;
      case 'health': return Icons.medical_services;
      case 'salary': return Icons.attach_money;
      case 'more': return Icons.more_horiz;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final iconColor = _parseColor(category.colorHex);
    final iconData = _getIconData(category.icon);

    return Material(
      color: dark
          ? theme.colorScheme.surfaceContainerHighest
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (category.transactionCount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        context
                            .tr(category.transactionCount == 1
                                ? 'transaction_count_one'
                                : 'transaction_count')
                            .replaceFirst('{n}', '${category.transactionCount}'),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: theme.colorScheme.outline,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(context.tr('edit')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.tr('delete')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditCategorySheet extends StatefulWidget {
  const _EditCategorySheet({
    required this.category,
    required this.service,
    required this.isExpense,
  });

  final CategoryModel category;
  final CategoryService service;
  final bool isExpense;

  @override
  State<_EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<_EditCategorySheet> {
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // We use your pre-configured ApiClient.dio which automatically
      // attaches the JWT token from SecureStorage.
      final response = await ApiClient.dio.put(
        '/categories/${widget.category.id}',
        data: {
          'name': name,
          'kind': widget.category.kind,
          'icon': widget.category.icon,
          'colorHex': widget.category.colorHex,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Server returned ${response.statusCode}');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      String errorMsg = context.tr('update_category_failed');
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('message')) {
          errorMsg = data['message'].toString();
        }
      } else if (e.response?.data != null && e.response?.data is String) {
          errorMsg = e.response!.data.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      String errorMsg = context.tr('update_category_failed');
      try {
        errorMsg = widget.service.getErrorMessage(e);
      } catch (_) {
        errorMsg = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('edit_category'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: context.tr('category_name'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.pop(context, false),
                  child: Text(context.tr('cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(context.tr('save')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}