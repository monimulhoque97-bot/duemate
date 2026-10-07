import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final int userId;

  const AddTransactionScreen({super.key, required this.userId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isExpense = true;
  bool _isSaving = false;
  int _selectedCategoryId = 1;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 1,
      'name': 'Food',
      'icon': Icons.restaurant_rounded,
      'color': AppColors.expense,
      'type': 'expense',
    },
    {
      'id': 2,
      'name': 'Transport',
      'icon': Icons.directions_bus_rounded,
      'color': AppColors.info,
      'type': 'expense',
    },
    {
      'id': 3,
      'name': 'Shopping',
      'icon': Icons.shopping_bag_rounded,
      'color': AppColors.warning,
      'type': 'expense',
    },
    {
      'id': 4,
      'name': 'Bills',
      'icon': Icons.receipt_long_rounded,
      'color': Color(0xFF8E5AD9),
      'type': 'expense',
    },
    {
      'id': 5,
      'name': 'Entertainment',
      'icon': Icons.movie_rounded,
      'color': Color(0xFF45B7A5),
      'type': 'expense',
    },
    {
      'id': 7,
      'name': 'Other',
      'icon': Icons.more_horiz_rounded,
      'color': AppColors.textSecondary,
      'type': 'expense',
    },
    {
      'id': 6,
      'name': 'Salary',
      'icon': Icons.payments_rounded,
      'color': AppColors.income,
      'type': 'income',
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _visibleCategories {
    final type = _isExpense ? 'expense' : 'income';

    return _categories.where((category) => category['type'] == type).toList();
  }

  void _changeTransactionType(bool isExpense) {
    if (_isSaving) return;

    final visibleCategories = _categories
        .where(
          (category) => category['type'] == (isExpense ? 'expense' : 'income'),
        )
        .toList();

    if (visibleCategories.isEmpty) return;

    setState(() {
      _isExpense = isExpense;
      _selectedCategoryId = visibleCategories.first['id'] as int;
    });
  }

  Future<void> _saveTransaction() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    final note = _noteController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final categoryExists = _categories.any(
      (category) => category['id'] == _selectedCategoryId,
    );

    if (!categoryExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.createTransaction(
        userId: widget.userId,
        categoryId: _selectedCategoryId,
        type: _isExpense ? 'expense' : 'income',
        amount: amount,
        note: note.isEmpty ? null : note,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save transaction: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Add Transaction',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 28),
              _buildAmountField(),
              const SizedBox(height: 28),
              _buildCategorySection(),
              const SizedBox(height: 28),
              _buildNoteField(),
              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              title: 'Expense',
              icon: Icons.arrow_upward_rounded,
              selected: _isExpense,
              onTap: () => _changeTransactionType(true),
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              title: 'Income',
              icon: Icons.arrow_downward_rounded,
              selected: !_isExpense,
              onTap: () => _changeTransactionType(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isSaving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Text(
                '₹',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  enabled: !_isSaving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    final visibleCategories = _visibleCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final category = visibleCategories[index];
            final categoryId = category['id'] as int;
            final selected = _selectedCategoryId == categoryId;
            final categoryColor = category['color'] as Color;

            return GestureDetector(
              onTap: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _selectedCategoryId = categoryId;
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        color: categoryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      category['name'] as String,
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Note',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _noteController,
          enabled: !_isSaving,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a note (optional)',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 42),
              child: Icon(Icons.notes_rounded, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveTransaction,
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.white,
                ),
              )
            : Text(_isExpense ? 'Save Expense' : 'Save Income'),
      ),
    );
  }
}
