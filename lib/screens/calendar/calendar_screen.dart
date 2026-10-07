import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  final int userId;

  const CalendarScreen({super.key, required this.userId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

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
      debugPrint('Calendar error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _transactionsForDate(DateTime date) {
    return _transactions.where((transaction) {
      final value = transaction['transaction_date']?.toString();

      if (value == null) return false;

      final transactionDate = DateTime.tryParse(value)?.toLocal();

      if (transactionDate == null) return false;

      return transactionDate.year == date.year &&
          transactionDate.month == date.month &&
          transactionDate.day == date.day;
    }).toList();
  }

  bool _hasTransactions(DateTime date) {
    return _transactionsForDate(date).isNotEmpty;
  }

  double _dayTotal() {
    double total = 0;

    for (final transaction in _transactionsForDate(_selectedDate)) {
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

  double _incomeForDate(DateTime date) {
    double total = 0;

    for (final transaction in _transactionsForDate(date)) {
      if (transaction['type'] != 'income') continue;

      total += double.tryParse(transaction['amount']?.toString() ?? '') ?? 0;
    }

    return total;
  }

  double _expenseForDate(DateTime date) {
    double total = 0;

    for (final transaction in _transactionsForDate(date)) {
      if (transaction['type'] != 'expense') continue;

      total += double.tryParse(transaction['amount']?.toString() ?? '') ?? 0;
    }

    return total;
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }

    return amount.toStringAsFixed(2);
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '';

    final date = DateTime.tryParse(value)?.toLocal();

    if (date == null) return '';

    final hour = date.hour;

    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    final period = hour >= 12 ? 'PM' : 'AM';

    return '$displayHour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  String _transactionTitle(Map<String, dynamic> transaction) {
    final note = transaction['note']?.toString();

    if (note != null && note.trim().isNotEmpty) {
      return note;
    }

    return transaction['type'] == 'income' ? 'Income' : 'Expense';
  }

  IconData _transactionIcon(Map<String, dynamic> transaction) {
    switch (transaction['category_id']?.toString()) {
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

  Color _transactionColor(Map<String, dynamic> transaction) {
    switch (transaction['category_id']?.toString()) {
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

  Color _transactionBackground(Map<String, dynamic> transaction) {
    final color = _transactionColor(transaction);

    return color.withValues(alpha: 0.12);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);

      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);

      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTransactions = _transactionsForDate(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTransactions,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildMonthSelector()),
              SliverToBoxAdapter(child: _buildCalendar()),
              SliverToBoxAdapter(child: _buildDaySummary()),
              SliverToBoxAdapter(
                child: _buildTransactionsHeader(selectedTransactions.length),
              ),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (selectedTransactions.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                      child: _buildTransactionItem(selectedTransactions[index]),
                    );
                  }, childCount: selectedTransactions.length),
                ),
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
              'Calendar',
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
              Icons.filter_list_rounded,
              color: AppColors.textPrimary,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Row(
        children: [
          _buildMonthButton(
            icon: Icons.chevron_left_rounded,
            onTap: _previousMonth,
          ),
          Expanded(
            child: Center(
              child: Text(
                '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _buildMonthButton(
            icon: Icons.chevron_right_rounded,
            onTap: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildCalendar() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);

    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;

    final leadingDays = firstDay.weekday - 1;

    final totalCells = leadingDays + daysInMonth;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: days.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 7,
                crossAxisSpacing: 3,
              ),
              itemBuilder: (context, index) {
                if (index < leadingDays) {
                  return const SizedBox();
                }

                final day = index - leadingDays + 1;

                final date = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  day,
                );

                final isSelected =
                    date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;

                final hasTransaction = _hasTransactions(date);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        if (hasTransaction && !isSelected)
                          Positioned(
                            bottom: 5,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySummary() {
    final income = _incomeForDate(_selectedDate);
    final expense = _expenseForDate(_selectedDate);
    final total = _dayTotal();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryValue(
                title: 'Income',
                value: '₹${_formatAmount(income)}',
                color: AppColors.income,
              ),
            ),
            Container(width: 1, height: 35, color: AppColors.border),
            Expanded(
              child: _buildSummaryValue(
                title: 'Expense',
                value: '₹${_formatAmount(expense)}',
                color: AppColors.expense,
              ),
            ),
            Container(width: 1, height: 35, color: AppColors.border),
            Expanded(
              child: _buildSummaryValue(
                title: 'Net',
                value:
                    '${total >= 0 ? '+' : '-'}₹${_formatAmount(total.abs())}',
                color: total >= 0 ? AppColors.income : AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryValue({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Transactions',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$count transaction${count == 1 ? '' : 's'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type']?.toString() ?? 'expense';

    final amount =
        double.tryParse(transaction['amount']?.toString() ?? '') ?? 0;

    final color = _transactionColor(transaction);

    final note = _transactionTitle(transaction);

    return Container(
      padding: const EdgeInsets.all(15),
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
              color: _transactionBackground(transaction),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_transactionIcon(transaction), color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note,
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
                  _formatTime(transaction['transaction_date']?.toString()),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${type == 'income' ? '+' : '-'} ₹${_formatAmount(amount)}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              color: AppColors.textMuted,
              size: 32,
            ),
            SizedBox(height: 10),
            Text(
              'No transactions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'No transactions were recorded for this day.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
