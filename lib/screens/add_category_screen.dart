import 'package:flutter/material.dart';
import '../../core/category_visuals.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';


class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key, this.defaultIsExpense = true});

  final bool defaultIsExpense;

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final CategoryService _categoryService = CategoryService();

  late bool _isExpense = widget.defaultIsExpense;
  int _selectedIcon = 0;
  int _selectedColor = 4;
  bool _isSaving = false;

  static const List<String> _iconKeys = [
    'restaurant',
    'shopping_bag',
    'shopping_bag',
    'health',
    'gift',
    'more',
    'car',
    'wallet',
  ];

  static const List<IconData> _icons = [
    Icons.restaurant,
    Icons.shopping_bag_outlined,
    Icons.local_mall_outlined,
    Icons.favorite_border,
    Icons.card_giftcard,
    Icons.add,
    Icons.directions_car,
    Icons.account_balance_wallet_outlined,
  ];

  static const List<Color> _iconColors = [
    Color(0xFFFF7011),
    Color(0xFFF13C06),
    Color(0xFF2197B8),
    Color(0xFF8318B9),
    Color(0xFFFF7917),
    Color(0xFF8E8E8E),
    Color(0xFF0061B7),
    Color(0xFF22D839),
  ];

  static const List<Color> _colors = [
    Color(0xFFFF6066),
    Color(0xFF24479C),
    Color(0xFF24D62F),
    Color(0xFF128042),
    Color(0xFF0061AF),
    Color(0xFFE50067),
    Color(0xFF0FAFC8),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _categoryService.createCategory(
        name: name,
        kind: _isExpense ? 'EXPENSE' : 'INCOME',
        icon: _iconKeys[_selectedIcon],
        colorHex: CategoryVisuals.hexFromColor(_colors[_selectedColor]),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true); // true = tell CategoryScreen to refresh
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save category. Try again.')),
      );
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
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: _HeaderButton(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop(false)),
        ),
        titleSpacing: 4,
        title: const Text(
          'Add Categories',
          style: TextStyle(color: Color(0xFF171717), fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : _HeaderButton(icon: Icons.check, onTap: _save),
          const SizedBox(width: 22),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFF0061B7),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x28000000), blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Category Name'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide(color: Color(0xFFCAD3DF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide(color: Color(0xFF0061B7), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 23),
                    const _FieldLabel('Type'),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _TypeChoice(label: 'Expense', selected: _isExpense, onTap: () => setState(() => _isExpense = true)),
                        const SizedBox(width: 24),
                        _TypeChoice(label: 'Income', selected: !_isExpense, onTap: () => setState(() => _isExpense = false)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _FieldLabel('Icon'),
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 10,
                      runSpacing: 14,
                      children: List.generate(_icons.length, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIcon = index),
                          child: Container(
                            width: 43,
                            height: 43,
                            decoration: BoxDecoration(
                              color: _iconColors[index],
                              shape: BoxShape.circle,
                              border: _selectedIcon == index ? Border.all(color: Colors.black, width: 2) : null,
                            ),
                            child: Icon(_icons[index], color: Colors.white, size: 22),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Color'),
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 14,
                      runSpacing: 12,
                      children: List.generate(_colors.length, (index) {
                        final selected = _selectedColor == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = index),
                          child: Container(
                            width: 31,
                            height: 31,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: selected ? Border.all(color: _colors[index], width: 2) : null,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: _colors[index], shape: BoxShape.circle),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F8FC),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 38, height: 38, child: Icon(icon, color: const Color(0xFF0061B7), size: 23)),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Color(0xFF65778D), fontSize: 13, fontWeight: FontWeight.w600));
  }
}

class _TypeChoice extends StatelessWidget {
  const _TypeChoice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? const Color(0xFF0061B7) : const Color(0xFF7A8BA0), width: 2),
              ),
              child: selected
                  ? const DecoratedBox(decoration: BoxDecoration(color: Color(0xFF0061B7), shape: BoxShape.circle))
                  : null,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF27364A) : const Color(0xFF65778D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}