import 'package:flutter/material.dart';
import '../core/category_visuals.dart';
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
  final CategoryService _categoryService = CategoryService();

  bool _showExpenses = true;
  bool _isLoading = true;
  String? _error;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final kind = _showExpenses ? 'EXPENSE' : 'INCOME';
      final categories = await _categoryService.getCategories(kind);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load categories.';
        _isLoading = false;
      });
    }
  }

  /// Public so MainNavigationScreen can force a reload when this tab
  /// is re-selected (IndexedStack keeps it alive otherwise, so category
  /// transaction counts wouldn't refresh after actions elsewhere).
  Future<void> refresh() => _loadCategories();

  void _onToggleChanged(bool showExpenses) {
    setState(() => _showExpenses = showExpenses);
    _loadCategories();
  }

  Future<void> _openAddCategory() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddCategoryScreen(defaultIsExpense: _showExpenses),
      ),
    );

    if (created == true) {
      _loadCategories();
    }
  }

  Future<void> _openAddTransaction(CategoryModel category) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddTransactionScreen(category: category),
      ),
    );

    if (saved == true) {
      _loadCategories(); // refresh transaction counts
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text(
          'Categories',
          style: TextStyle(color: Color(0xFF171717), fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Add category',
            onPressed: _openAddCategory,
            icon: const Icon(Icons.add, size: 27),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: _CategoryToggle(
              showExpenses: _showExpenses,
              onChanged: _onToggleChanged,
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F1)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadCategories, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCategories,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            if (_categories.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(child: Text('No categories yet', style: TextStyle(color: Colors.black45))),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFD8D8D8)),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Column(
                                  children: [
                                    for (final category in _categories)
                                      _CategoryTile(
                                        category: category,
                                        onTap: () => _openAddTransaction(category),
                                      ),
                                  ],
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
}

class _CategoryToggle extends StatelessWidget {
  const _CategoryToggle({required this.showExpenses, required this.onChanged});

  final bool showExpenses;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          Expanded(child: _ToggleButton(label: 'Expense', selected: showExpenses, onTap: () => onChanged(true))),
          Expanded(child: _ToggleButton(label: 'Income', selected: !showExpenses, onTap: () => onChanged(false))),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF0565BA) : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF292929),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: CategoryVisuals.colorFromHex(category.colorHex),
                shape: BoxShape.circle,
              ),
              child: Icon(CategoryVisuals.iconFor(category.icon), color: Colors.white, size: 25),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(color: Color(0xFF242424), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${category.transactionCount} Transaction${category.transactionCount == 1 ? '' : 's'}',
                    style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF272727), size: 25),
          ],
        ),
      ),
    );
  }
}