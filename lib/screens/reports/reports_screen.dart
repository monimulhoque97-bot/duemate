import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';

import '../../core/theme/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  final int userId;

  const ReportsScreen({super.key, required this.userId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  String _currency = 'INR';

  Map<String, dynamic> _summary = {};

  List<Map<String, dynamic>> _categories = [];

  List<Map<String, dynamic>> _monthly = [];

  List<Map<String, dynamic>> _weekly = [];

  List<Map<String, dynamic>> _topCategories = [];

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();

    _loadReports();
  }

  // ============================================================

  // LOAD ALL REPORT DATA*

  // ============================================================

  Future<void> _loadReports() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.getReportSummary(widget.userId),

        ApiService.getCategoryReport(widget.userId),

        ApiService.getMonthlyReport(widget.userId),

        ApiService.getWeeklyReport(widget.userId),

        ApiService.getTopSpendingCategories(widget.userId),
        ApiService.getUser(widget.userId),
      ]);

      if (!mounted) return;

      setState(() {
        _summary = Map<String, dynamic>.from(results[0] as Map);

        _categories = List<Map<String, dynamic>>.from(results[1] as List);

        _monthly = List<Map<String, dynamic>>.from(results[2] as List);

        _weekly = List<Map<String, dynamic>>.from(results[3] as List);

        _topCategories = List<Map<String, dynamic>>.from(results[4] as List);
        final user = Map<String, dynamic>.from(results[5] as Map);
        _currency = (user['currency']?.toString().trim().isNotEmpty ?? false)
            ? user['currency'].toString().trim().toUpperCase()
            : 'INR';

        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Reports error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load reports: $error')));
    }
  }

  // ============================================================

  // NUMBER HELPERS*

  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // ============================================================

  // SUMMARY VALUES*

  // ============================================================

  double get _totalIncome {
    return _toDouble(_summary['total_income']);
  }

  double get _totalExpense {
    return _toDouble(_summary['total_expense']);
  }

  double get _balance {
    if (_summary.containsKey('balance')) {
      return _toDouble(_summary['balance']);
    }

    return _totalIncome - _totalExpense;
  }

  int get _totalTransactions {
    return _toInt(_summary['total_transactions']);
  }

  // ============================================================

  // MONEY FORMAT*

  // ============================================================

  String _money(double value) {
    String symbol;

    switch (_currency) {
      case 'USD':
        symbol = r'$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'GBP':
        symbol = '£';
        break;
      case 'INR':
      default:
        symbol = '₹';
    }

    return '$symbol${value.toStringAsFixed(2)}';
  }

  // ============================================================

  // BUILD*

  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,

        elevation: 0,

        title: const Text(
          'Reports',

          style: TextStyle(
            color: AppColors.textPrimary,

            fontSize: 20,

            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: false,

        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadReports,

            icon: const Icon(
              Icons.refresh_rounded,

              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,

              onRefresh: _loadReports,

              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    _buildHeader(),

                    const SizedBox(height: 22),

                    _buildSummaryCard(),

                    const SizedBox(height: 24),

                    _buildTabs(),

                    const SizedBox(height: 22),

                    _buildSelectedSection(),

                    const SizedBox(height: 24),

                    _buildTopSpending(),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================

  // HEADER*

  // ============================================================

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'Financial overview',

          style: TextStyle(
            color: AppColors.textPrimary,

            fontSize: 25,

            fontWeight: FontWeight.w700,

            letterSpacing: -0.5,
          ),
        ),

        SizedBox(height: 6),

        Text(
          'Understand where your money is going.',

          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  // ============================================================

  // SUMMARY CARD*

  // ============================================================

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.primary,

        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Net balance',

            style: TextStyle(
              color: Colors.white70,

              fontSize: 12,

              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            _money(_balance),

            style: const TextStyle(
              color: Colors.white,

              fontSize: 28,

              fontWeight: FontWeight.w800,

              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  title: 'Income',

                  value: _money(_totalIncome),

                  icon: Icons.arrow_downward_rounded,
                ),
              ),

              Container(width: 1, height: 44, color: Colors.white24),

              Expanded(
                child: _buildSummaryItem(
                  title: 'Expenses',

                  value: _money(_totalExpense),

                  icon: Icons.arrow_upward_rounded,
                ),
              ),

              Container(width: 1, height: 44, color: Colors.white24),

              Expanded(
                child: _buildSummaryItem(
                  title: 'Transactions',

                  value: _totalTransactions.toString(),

                  icon: Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================

  // SUMMARY ITEM*

  // ============================================================

  Widget _buildSummaryItem({
    required String title,

    required String value,

    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),

      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 17),

          const SizedBox(height: 5),

          Text(
            value,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 11,

              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,

            textAlign: TextAlign.center,

            style: const TextStyle(color: Colors.white60, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ============================================================

  // TABS*

  // ============================================================

  Widget _buildTabs() {
    return Container(
      height: 48,

      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(color: AppColors.border),
      ),

      child: Row(
        children: [
          Expanded(child: _buildTabButton(title: 'Categories', index: 0)),

          Expanded(child: _buildTabButton(title: 'Monthly', index: 1)),

          Expanded(child: _buildTabButton(title: 'Weekly', index: 2)),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String title, required int index}) {
    final selected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },

      child: Container(
        alignment: Alignment.center,

        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,

          borderRadius: BorderRadius.circular(11),
        ),

        child: Text(
          title,

          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,

            fontSize: 11,

            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================

  // SELECTED SECTION*

  // ============================================================

  Widget _buildSelectedSection() {
    switch (_selectedTab) {
      case 1:
        return _buildMonthlyReport();

      case 2:
        return _buildWeeklyReport();

      default:
        return _buildCategoryReport();
    }
  }

  // ============================================================

  // CATEGORY REPORT*

  // ============================================================

  Widget _buildCategoryReport() {
    final total = _categories.fold<double>(0, (sum, category) {
      return sum + _toDouble(category['total_amount']);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _buildSectionTitle('Spending by category'),

        const SizedBox(height: 13),

        if (_categories.isEmpty)
          _buildEmptyCard('No category spending data available.')
        else
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: AppColors.surface,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: AppColors.border),
            ),

            child: Column(
              children: _categories.map((category) {
                final amount = _toDouble(category['total_amount']);

                final percentage = total > 0 ? amount / total : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 17),

                  child: _buildCategoryRow(category, amount, percentage),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ============================================================

  // CATEGORY ROW*

  // ============================================================

  Widget _buildCategoryRow(
    Map<String, dynamic> category,

    double amount,

    double percentage,
  ) {
    final color = _parseColor(category['color']?.toString());

    final name = category['category_name']?.toString() ?? 'Other';

    final icon = _iconFromName(category['icon']?.toString());

    return Row(
      children: [
        Container(
          width: 42,

          height: 42,

          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),

            borderRadius: BorderRadius.circular(12),
          ),

          child: Icon(icon, color: color, size: 20),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: AppColors.textPrimary,

                        fontSize: 12,

                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    _money(amount),

                    style: const TextStyle(
                      color: AppColors.textPrimary,

                      fontSize: 11,

                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),

                child: LinearProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),

                  minHeight: 5,

                  backgroundColor: AppColors.background,

                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================

  // MONTHLY REPORT*

  // ============================================================

  Widget _buildMonthlyReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _buildSectionTitle('Monthly overview'),

        const SizedBox(height: 13),

        if (_monthly.isEmpty)
          _buildEmptyCard('No monthly report data available.')
        else
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: AppColors.surface,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: AppColors.border),
            ),

            child: Column(
              children: _monthly.reversed.take(12).map((month) {
                return _buildMonthRow(month);
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ============================================================

  // MONTH ROW*

  // ============================================================

  Widget _buildMonthRow(Map<String, dynamic> month) {
    final income = _toDouble(month['income']);

    final expense = _toDouble(month['expense']);

    final balance = month.containsKey('balance')
        ? _toDouble(month['balance'])
        : income - expense;

    final total = income + expense;

    final expenseRatio = total > 0 ? expense / total : 0.0;

    final monthName = _formatMonth(month['month']?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthName,

                  style: const TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: 12,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                _money(balance),

                style: TextStyle(
                  color: balance >= 0 ? AppColors.income : AppColors.expense,

                  fontSize: 11,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Income  ${_money(income)}',

                  style: const TextStyle(
                    color: AppColors.income,

                    fontSize: 10,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Expanded(
                child: Text(
                  'Expense  ${_money(expense)}',

                  textAlign: TextAlign.end,

                  style: const TextStyle(
                    color: AppColors.expense,

                    fontSize: 10,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),

            child: LinearProgressIndicator(
              value: expenseRatio.clamp(0.0, 1.0),

              minHeight: 5,

              backgroundColor: AppColors.income.withValues(alpha: 0.15),

              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================

  // WEEKLY REPORT*

  // ============================================================

  Widget _buildWeeklyReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _buildSectionTitle('Weekly overview'),

        const SizedBox(height: 13),

        if (_weekly.isEmpty)
          _buildEmptyCard('No weekly report data available.')
        else
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: AppColors.surface,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: AppColors.border),
            ),

            child: Column(
              children: _weekly.reversed.take(12).map((week) {
                return _buildWeekRow(week);
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ============================================================

  // WEEK ROW*

  // ============================================================

  Widget _buildWeekRow(Map<String, dynamic> week) {
    final income = _toDouble(week['income']);

    final expense = _toDouble(week['expense']);

    final balance = week.containsKey('balance')
        ? _toDouble(week['balance'])
        : income - expense;

    final total = income + expense;

    final expenseRatio = total > 0 ? expense / total : 0.0;

    final weekStart = week['week_start']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  weekStart.isEmpty ? 'Week' : 'Week of $weekStart',

                  style: const TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: 12,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                _money(balance),

                style: TextStyle(
                  color: balance >= 0 ? AppColors.income : AppColors.expense,

                  fontSize: 11,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Income  ${_money(income)}',

                  style: const TextStyle(
                    color: AppColors.income,

                    fontSize: 10,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Expanded(
                child: Text(
                  'Expense  ${_money(expense)}',

                  textAlign: TextAlign.end,

                  style: const TextStyle(
                    color: AppColors.expense,

                    fontSize: 10,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),

            child: LinearProgressIndicator(
              value: expenseRatio.clamp(0.0, 1.0),

              minHeight: 5,

              backgroundColor: AppColors.income.withValues(alpha: 0.15),

              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================

  // TOP SPENDING*

  // ============================================================

  Widget _buildTopSpending() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _buildSectionTitle('Top spending categories'),

        const SizedBox(height: 13),

        if (_topCategories.isEmpty)
          _buildEmptyCard('No spending data available.')
        else
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: AppColors.surface,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: AppColors.border),
            ),

            child: Column(
              children: _topCategories.asMap().entries.map((entry) {
                return _buildTopCategoryRow(entry.key + 1, entry.value);
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ============================================================

  // TOP CATEGORY ROW*

  // ============================================================

  Widget _buildTopCategoryRow(int rank, Map<String, dynamic> category) {
    final color = _parseColor(category['color']?.toString());

    final name = category['category_name']?.toString() ?? 'Other';

    final amount = _toDouble(category['total_amount']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),

      child: Row(
        children: [
          SizedBox(
            width: 25,

            child: Text(
              '#$rank',

              style: const TextStyle(
                color: AppColors.textMuted,

                fontSize: 10,

                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Container(
            width: 38,

            height: 38,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(11),
            ),

            child: Icon(
              _iconFromName(category['icon']?.toString()),

              color: color,

              size: 18,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              name,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                color: AppColors.textPrimary,

                fontSize: 12,

                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Text(
            _money(amount),

            style: const TextStyle(
              color: AppColors.textPrimary,

              fontSize: 11,

              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================

  // SECTION TITLE*

  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,

      style: const TextStyle(
        color: AppColors.textPrimary,

        fontSize: 16,

        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ============================================================

  // EMPTY CARD*

  // ============================================================

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        children: [
          Container(
            width: 54,

            height: 54,

            decoration: const BoxDecoration(
              color: AppColors.primaryLight,

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.analytics_outlined,

              color: AppColors.primary,

              size: 26,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            message,

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: AppColors.textSecondary,

              fontSize: 12,

              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================

  // MONTH FORMAT*

  // ============================================================

  String _formatMonth(String value) {
    if (value.length != 7 || !value.contains('-')) {
      return value;
    }

    final parts = value.split('-');

    if (parts.length != 2) {
      return value;
    }

    final year = parts[0];

    final month = int.tryParse(parts[1]) ?? 0;

    const months = [
      '',

      'Jan',

      'Feb',

      'Mar',

      'Apr',

      'May',

      'Jun',

      'Jul',

      'Aug',

      'Sep',

      'Oct',

      'Nov',

      'Dec',
    ];

    if (month < 1 || month > 12) {
      return value;
    }

    return '${months[month]} $year';
  }

  // ============================================================

  // ICON MAPPING*

  // ============================================================

  IconData _iconFromName(String? name) {
    switch (name?.toLowerCase()) {
      case 'food':
      case 'restaurant':
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

  // COLOR PARSER*

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
