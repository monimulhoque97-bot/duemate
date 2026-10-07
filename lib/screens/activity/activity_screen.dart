import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class ActivityScreen extends StatefulWidget {
  final int userId;

  const ActivityScreen({super.key, required this.userId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await ApiService.getTransactions(widget.userId);

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Activity error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == 'All') {
      return _transactions;
    }

    final type = _selectedFilter == 'Income' ? 'income' : 'expense';

    return _transactions
        .where((transaction) => transaction['type'] == type)
        .toList();
  }

  List<Map<String, dynamic>> _transactionsForDate(String section) {
    final now = DateTime.now();

    return _filteredTransactions.where((transaction) {
      final date = DateTime.tryParse(
        transaction['transaction_date']?.toString() ?? '',
      );

      if (date == null) return false;

      final localDate = date.toLocal();

      if (section == 'Today') {
        return localDate.year == now.year &&
            localDate.month == now.month &&
            localDate.day == now.day;
      }

      if (section == 'Yesterday') {
        final yesterday = now.subtract(const Duration(days: 1));

        return localDate.year == yesterday.year &&
            localDate.month == yesterday.month &&
            localDate.day == yesterday.day;
      }

      return !(localDate.year == now.year &&
              localDate.month == now.month &&
              localDate.day == now.day) &&
          !(localDate.year == now.subtract(const Duration(days: 1)).year &&
              localDate.month == now.subtract(const Duration(days: 1)).month &&
              localDate.day == now.subtract(const Duration(days: 1)).day);
    }).toList();
  }

  double _sectionTotal(List<Map<String, dynamic>> transactions) {
    double total = 0;

    for (final transaction in transactions) {
      final amount =
          double.tryParse(transaction['amount']?.toString() ?? '') ?? 0;

      if (transaction['type'] == 'income') {
        total += amount;
      } else {
        total -= amount;
      }
    }

    return total;
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }

    return amount.toStringAsFixed(2);
  }

  String _formatOlderDate(String? value) {
    if (value == null || value.isEmpty) return '';

    final date = DateTime.tryParse(value);

    if (date == null) return '';

    final localDate = date.toLocal();

    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '';

    final date = DateTime.tryParse(value);

    if (date == null) return '';

    final localDate = date.toLocal();

    final hour = localDate.hour;
    final minute = localDate.minute;

    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    final period = hour >= 12 ? 'PM' : 'AM';

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _transactionTitle(Map<String, dynamic> transaction) {
    final note = transaction['note']?.toString();

    if (note != null && note.trim().isNotEmpty) {
      return note;
    }

    return transaction['type'] == 'income' ? 'Income' : 'Expense';
  }

  String _categoryName(Map<String, dynamic> transaction) {
    final categoryId = transaction['category_id'];

    switch (categoryId?.toString()) {
      case '1':
        return 'Food';
      case '2':
        return 'Transport';
      case '3':
        return 'Shopping';
      case '4':
        return 'Bills';
      case '5':
        return 'Entertainment';
      case '6':
        return 'Salary';
      case '7':
        return 'Other';
      default:
        return transaction['type'] == 'income' ? 'Income' : 'Expense';
    }
  }

  IconData _transactionIcon(Map<String, dynamic> transaction) {
    final categoryId = transaction['category_id'];

    switch (categoryId?.toString()) {
      case '1':
        return Icons.restaurant_rounded;
      case '2':
        return Icons.directions_bus_rounded;
      case '3':
        return Icons.shopping_bag_rounded;
      case '4':
        return Icons.receipt_long_rounded;
      case '5':
        return Icons.movie_rounded;
      case '6':
        return Icons.payments_rounded;
      case '7':
        return Icons.category_rounded;
      default:
        return transaction['type'] == 'income'
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;
    }
  }

  Color _transactionIconColor(Map<String, dynamic> transaction) {
    final categoryId = transaction['category_id'];

    switch (categoryId?.toString()) {
      case '1':
        return AppColors.expense;
      case '2':
        return AppColors.info;
      case '3':
        return AppColors.warning;
      case '4':
        return const Color(0xFF8E5AD9);
      case '5':
        return const Color(0xFF45B7A5);
      case '6':
        return AppColors.income;
      default:
        return transaction['type'] == 'income'
            ? AppColors.income
            : AppColors.expense;
    }
  }

  Color _transactionIconBackground(Map<String, dynamic> transaction) {
    final categoryId = transaction['category_id'];

    switch (categoryId?.toString()) {
      case '1':
        return const Color(0xFFFFE9E9);
      case '2':
        return const Color(0xFFE8F0FF);
      case '3':
        return const Color(0xFFFFF3DE);
      case '4':
        return const Color(0xFFF4EAFE);
      case '5':
        return const Color(0xFFE6F7F4);
      case '6':
        return AppColors.primaryLight;
      default:
        return transaction['type'] == 'income'
            ? AppColors.primaryLight
            : const Color(0xFFFFE9E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTransactions,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildFilter()),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredTransactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                ..._buildTransactionSections(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Activity',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          _buildFilterChip('All'),
          const SizedBox(width: 8),
          _buildFilterChip('Expenses'),
          const SizedBox(width: 8),
          _buildFilterChip('Income'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTransactionSections() {
    final today = _transactionsForDate('Today');
    final yesterday = _transactionsForDate('Yesterday');
    final older = _transactionsForDate('Older');

    final sections = <Widget>[];

    if (today.isNotEmpty) {
      sections.add(
        SliverToBoxAdapter(
          child: _buildDateSection(title: 'Today', transactions: today),
        ),
      );
    }

    if (yesterday.isNotEmpty) {
      sections.add(
        SliverToBoxAdapter(
          child: _buildDateSection(title: 'Yesterday', transactions: yesterday),
        ),
      );
    }

    if (older.isNotEmpty) {
      sections.add(SliverToBoxAdapter(child: _buildOlderSection(older)));
    }

    return sections;
  }

  Widget _buildDateSection({
    required String title,
    required List<Map<String, dynamic>> transactions,
  }) {
    final total = _sectionTotal(transactions);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${total >= 0 ? '+' : '-'} ₹${_formatAmount(total.abs())}',
                style: TextStyle(
                  color: total >= 0 ? AppColors.income : AppColors.expense,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...transactions.map(
            (transaction) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildTransactionItem(transaction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOlderSection(List<Map<String, dynamic>> transactions) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final transaction in transactions) {
      final date = _formatOlderDate(
        transaction['transaction_date']?.toString(),
      );

      grouped.putIfAbsent(date, () => []).add(transaction);
    }

    return Column(
      children: grouped.entries.map((entry) {
        return _buildDateSection(title: entry.key, transactions: entry.value);
      }).toList(),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type']?.toString() ?? 'expense';

    final amount =
        double.tryParse(transaction['amount']?.toString() ?? '') ?? 0;

    final title = _transactionTitle(transaction);
    final category = _categoryName(transaction);

    final time = _formatTime(transaction['transaction_date']?.toString());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _transactionIconBackground(transaction),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _transactionIcon(transaction),
              color: _transactionIconColor(transaction),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                  '$category • $time',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${type == 'income' ? '+' : '-'} ₹${_formatAmount(amount)}',
            style: TextStyle(
              color: type == 'income' ? AppColors.income : AppColors.expense,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No transactions found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All'
                  ? 'Your transactions will appear here.'
                  : 'No ${_selectedFilter.toLowerCase()} found.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
