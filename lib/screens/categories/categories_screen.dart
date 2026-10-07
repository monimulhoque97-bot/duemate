import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class CategoriesScreen extends StatefulWidget {
  final int userId;

  const CategoriesScreen({super.key, required this.userId});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _categories = [];

  int _selectedType = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // ============================================================
  // LOAD CATEGORIES
  // ============================================================

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.getCategories(widget.userId);

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Categories error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load categories: $error')),
      );
    }
  }

  // ============================================================
  // FILTERED CATEGORIES
  // ============================================================

  List<Map<String, dynamic>> get _filteredCategories {
    final type = _selectedType == 0 ? 'expense' : 'income';

    return _categories
        .where((category) => category['type']?.toString().toLowerCase() == type)
        .toList();
  }

  // ============================================================
  // ADD CATEGORY
  // ============================================================

  void _showAddCategory() {
    _showCategoryDialog();
  }

  // ============================================================
  // EDIT CATEGORY
  // ============================================================

  void _showEditCategory(Map<String, dynamic> category) {
    _showCategoryDialog(category: category);
  }

  // ============================================================
  // CATEGORY DIALOG
  // ============================================================

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final nameController = TextEditingController(
      text: category?['name']?.toString() ?? '',
    );

    final isEditing = category != null;

    String selectedType =
        category?['type']?.toString() ??
        (_selectedType == 0 ? 'expense' : 'income');

    String selectedIcon = category?['icon']?.toString() ?? 'category';

    String selectedColor = category?['color']?.toString() ?? '19A974';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        isEditing ? 'Edit category' : 'New category',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        isEditing
                            ? 'Update your category details.'
                            : 'Create a category to organize your money.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Category name',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 9),

                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Food & Dining',
                          prefixIcon: Icon(Icons.label_outline_rounded),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Type',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 9),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeChoice(
                              label: 'Expense',
                              icon: Icons.arrow_downward_rounded,
                              selected: selectedType == 'expense',
                              color: AppColors.expense,
                              onTap: () {
                                setModalState(() {
                                  selectedType = 'expense';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTypeChoice(
                              label: 'Income',
                              icon: Icons.arrow_upward_rounded,
                              selected: selectedType == 'income',
                              color: AppColors.income,
                              onTap: () {
                                setModalState(() {
                                  selectedType = 'income';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Icon',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _buildIconSelector(selectedIcon, (icon) {
                        setModalState(() {
                          selectedIcon = icon;
                        });
                      }),

                      const SizedBox(height: 20),

                      const Text(
                        'Color',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _buildColorSelector(selectedColor, (color) {
                        setModalState(() {
                          selectedColor = color;
                        });
                      }),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  final name = nameController.text.trim();

                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter a category name.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.pop(sheetContext);

                                  await _saveCategory(
                                    category: category,
                                    name: name,
                                    type: selectedType,
                                    icon: selectedIcon,
                                    color: selectedColor,
                                  );
                                },
                          child: Text(
                            isEditing ? 'Save Changes' : 'Create Category',
                          ),
                        ),
                      ),

                      if (isEditing) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    Navigator.pop(sheetContext);

                                    _confirmDelete(category);
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.expense,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Delete Category',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(nameController.dispose);
  }

  // ============================================================
  // SAVE CATEGORY
  // ============================================================

  Future<void> _saveCategory({
    Map<String, dynamic>? category,
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (category == null) {
        await ApiService.createCategory(
          userId: widget.userId,
          name: name,
          icon: icon,
          color: color,
          type: type,
        );
      } else {
        final categoryId = int.tryParse(category['id'].toString());

        if (categoryId == null) {
          throw Exception('Invalid category ID.');
        }

        await ApiService.updateCategory(
          categoryId: categoryId,
          name: name,
          icon: icon,
          color: color,
          type: type,
        );
      }

      await _loadCategories();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category == null
                ? 'Category created successfully.'
                : 'Category updated successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save category: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  void _confirmDelete(Map<String, dynamic> category) {
    final name = category['name']?.toString() ?? 'this category';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Delete category?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$name"?',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _deleteCategory(category);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.expense,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DELETE CATEGORY
  // ============================================================

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final categoryId = int.tryParse(category['id'].toString());

    if (categoryId == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.deleteCategory(categoryId);

      await _loadCategories();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete category: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Categories',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _showAddCategory,
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSection(),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _buildCategoryList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategory,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Category',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ============================================================
  // TOP SECTION
  // ============================================================

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Organize your money',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Create categories that make tracking your spending easier.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterButton(
                    title: 'Expenses',
                    selected: _selectedType == 0,
                    onTap: () {
                      setState(() {
                        _selectedType = 0;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _buildFilterButton(
                    title: 'Income',
                    selected: _selectedType == 1,
                    onTap: () {
                      setState(() {
                        _selectedType = 1;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget _buildFilterButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY LIST
  // ============================================================

  Widget _buildCategoryList() {
    final categories = _filteredCategories;

    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadCategories,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCategoryItem(category),
          );
        },
      ),
    );
  }

  // ============================================================
  // CATEGORY ITEM
  // ============================================================

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final name = category['name']?.toString() ?? 'Category';

    final iconName = category['icon']?.toString() ?? 'category';

    final color = _parseColor(category['color']?.toString());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          _showEditCategory(category);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFromName(iconName), color: color, size: 23),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      category['type']?.toString().toLowerCase() == 'income'
                          ? 'Income category'
                          : 'Expense category',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final isExpense = _selectedType == 0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 120),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExpense
                      ? Icons.shopping_bag_outlined
                      : Icons.payments_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                isExpense ? 'No expense categories' : 'No income categories',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Add your first category to start organizing your transactions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _showAddCategory,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Category'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TYPE CHOICE
  // ============================================================

  Widget _buildTypeChoice({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.10)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ICON SELECTOR
  // ============================================================

  Widget _buildIconSelector(String selected, ValueChanged<String> onChanged) {
    final icons = [
      'category',
      'food',
      'shopping',
      'transport',
      'home',
      'health',
      'education',
      'entertainment',
      'travel',
      'salary',
      'business',
      'gift',
    ];

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: icons.map((icon) {
        final isSelected = selected == icon;

        return GestureDetector(
          onTap: () {
            onChanged(icon);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : AppColors.background,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Icon(
              _iconFromName(icon),
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 21,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // COLOR SELECTOR
  // ============================================================

  Widget _buildColorSelector(String selected, ValueChanged<String> onChanged) {
    final colors = [
      '19A974',
      '4C8DFF',
      '8E5AD9',
      'F2A93B',
      'E85D5D',
      '00A6A6',
      'E56B6F',
      '6C757D',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: colors.map((color) {
        final isSelected = selected.toUpperCase() == color.toUpperCase();

        return GestureDetector(
          onTap: () {
            onChanged(color);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _parseColor(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check_rounded,
                    color: AppColors.white,
                    size: 19,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // ICON MAPPING
  // ============================================================

  IconData _iconFromName(String name) {
    switch (name.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;

      case 'shopping':
        return Icons.shopping_bag_rounded;

      case 'transport':
        return Icons.directions_car_rounded;

      case 'home':
        return Icons.home_rounded;

      case 'health':
        return Icons.medical_services_rounded;

      case 'education':
        return Icons.school_rounded;

      case 'entertainment':
        return Icons.movie_rounded;

      case 'travel':
        return Icons.flight_rounded;

      case 'salary':
        return Icons.payments_rounded;

      case 'business':
        return Icons.business_center_rounded;

      case 'gift':
        return Icons.card_giftcard_rounded;

      default:
        return Icons.category_rounded;
    }
  }

  // ============================================================
  // COLOR PARSER
  // ============================================================

  Color _parseColor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppColors.primary;
    }

    var hex = value.trim().replaceAll('#', '');

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    final parsed = int.tryParse(hex, radix: 16);

    if (parsed == null) {
      return AppColors.primary;
    }

    return Color(parsed);
  }
}
