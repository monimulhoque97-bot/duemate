import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User';
  String _currency = 'INR';

  double _totalIncome = 0;
  double _totalExpense = 0;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _upcomingItems = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final results = await Future.wait([
        ApiService.getUser(widget.userId),
        ApiService.getTransactions(widget.userId),
        ApiService.getBills(widget.userId),
        ApiService.getEmis(widget.userId),
        ApiService.getDebts(widget.userId),
      ]);

      final user = results[0] as Map<String, dynamic>;
      final transactions = results[1] as List<Map<String, dynamic>>;
      final bills = results[2] as List<Map<String, dynamic>>;
      final emis = results[3] as List<Map<String, dynamic>>;
      final debts = results[4] as List<Map<String, dynamic>>;

      final upcomingItems = _buildUpcomingItems(
        bills: bills,
        emis: emis,
        debts: debts,
      );

      double income = 0;
      double expense = 0;

      for (final transaction in transactions) {
        final amount = double.tryParse(transaction['amount'].toString()) ?? 0;

        final type = transaction['type']?.toString();

        if (type == 'income') {
          income += amount;
        } else if (type == 'expense') {
          expense += amount;
        }
      }

      if (!mounted) return;

      setState(() {
        _userName = user['full_name']?.toString() ?? 'User';
        _currency = user['currency']?.toString() ?? 'INR';
        _transactions = transactions;
        _totalIncome = income;
        _totalExpense = expense;
        _upcomingItems = upcomingItems;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Dashboard error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  String get _currencySymbol {
    switch (_currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '₹';
    }
  }

  double get _balance {
    return _totalIncome - _totalExpense;
  }

  double get _thisWeekExpense {
    final now = DateTime.now();

    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    double total = 0;

    for (final transaction in _transactions) {
      if (transaction['type'] != 'expense') continue;

      final date = DateTime.tryParse(
        transaction['transaction_date'].toString(),
      );

      if (date == null) continue;

      if (!date.isBefore(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      )) {
        total += double.tryParse(transaction['amount'].toString()) ?? 0;
      }
    }

    return total;
  }

  double get _thisMonthExpense {
    final now = DateTime.now();

    double total = 0;

    for (final transaction in _transactions) {
      if (transaction['type'] != 'expense') continue;

      final date = DateTime.tryParse(
        transaction['transaction_date'].toString(),
      );

      if (date == null) continue;

      if (date.year == now.year && date.month == now.month) {
        total += double.tryParse(transaction['amount'].toString()) ?? 0;
      }
    }

    return total;
  }

  List<Map<String, dynamic>> _buildUpcomingItems({
    required List<Map<String, dynamic>> bills,
    required List<Map<String, dynamic>> emis,
    required List<Map<String, dynamic>> debts,
  }) {
    final now = DateTime.now();
    final items = <Map<String, dynamic>>[];

    for (final bill in bills) {
      final status = bill['status']?.toString().toLowerCase() ?? 'active';
      if (status != 'active' && status != 'pending' && status != 'unpaid') {
        continue;
      }

      final date = _parseDate(bill['due_date']?.toString());
      if (date == null ||
          date.isBefore(DateTime(now.year, now.month, now.day))) {
        continue;
      }

      final name = bill['name']?.toString().trim();
      final provider = bill['provider']?.toString().trim();

      items.add({
        'date': date,
        'icon': Icons.receipt_long_rounded,
        'iconBackground': const Color(0xFFE8F0FF),
        'iconColor': AppColors.info,
        'title': (name == null || name.isEmpty) ? 'Bill' : name,
        'subtitle': provider == null || provider.isEmpty
            ? 'Due ${_shortDate(date)}'
            : '$provider • Due ${_shortDate(date)}',
        'amount': _toDouble(bill['amount']),
      });
    }

    for (final emi in emis) {
      final status = emi['status']?.toString().toLowerCase() ?? 'active';
      if (status != 'active' && status != 'pending') {
        continue;
      }

      final dueDay = int.tryParse(emi['due_day']?.toString() ?? '');
      if (dueDay == null || dueDay < 1 || dueDay > 31) {
        continue;
      }

      DateTime dueDate = DateTime(now.year, now.month, dueDay);
      if (dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
        dueDate = DateTime(now.year, now.month + 1, dueDay);
      }

      final name = emi['name']?.toString().trim();
      final lender = emi['lender_name']?.toString().trim();

      items.add({
        'date': dueDate,
        'icon': Icons.credit_card_rounded,
        'iconBackground': const Color(0xFFF4EAFE),
        'iconColor': const Color(0xFF8E5AD9),
        'title': (name == null || name.isEmpty) ? 'EMI' : name,
        'subtitle': lender == null || lender.isEmpty
            ? 'Due ${_shortDate(dueDate)}'
            : '$lender • Due ${_shortDate(dueDate)}',
        'amount': _toDouble(emi['monthly_amount'] ?? emi['amount']),
      });
    }

    for (final debt in debts) {
      final status = debt['status']?.toString().toLowerCase() ?? 'active';
      if (status != 'active' && status != 'pending') {
        continue;
      }

      final date = _parseDate(debt['due_date']?.toString());
      if (date == null ||
          date.isBefore(DateTime(now.year, now.month, now.day))) {
        continue;
      }

      final remaining =
          _toDouble(debt['total_amount']) - _toDouble(debt['paid_amount']);
      if (remaining <= 0) {
        continue;
      }

      final type = debt['type']?.toString().toLowerCase() ?? '';
      final personName = debt['person_name']?.toString().trim();

      items.add({
        'date': date,
        'icon': Icons.person_rounded,
        'iconBackground': const Color(0xFFFFF3DE),
        'iconColor': AppColors.warning,
        'title': (personName == null || personName.isEmpty)
            ? (type == 'borrow' ? 'Borrowed money' : 'Lent money')
            : personName,
        'subtitle': type == 'borrow'
            ? 'Repayment • ${_shortDate(date)}'
            : 'Receive • ${_shortDate(date)}',
        'amount': remaining,
      });
    }

    items.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    return items.take(3).toList();
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  String _shortDate(DateTime date) => '${date.day}/${date.month}';

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }

    return amount.toStringAsFixed(2);
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return '';
    }

    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _transactionIcon(String? note) {
    final value = note?.toLowerCase() ?? '';

    if (value.contains('food') || value.contains('lunch')) {
      return Icons.restaurant_rounded;
    }

    if (value.contains('bus') ||
        value.contains('transport') ||
        value.contains('travel')) {
      return Icons.directions_bus_rounded;
    }

    if (value.contains('rent') || value.contains('home')) {
      return Icons.home_rounded;
    }

    if (value.contains('salary')) {
      return Icons.payments_rounded;
    }

    if (value.contains('shop')) {
      return Icons.shopping_bag_rounded;
    }

    return Icons.receipt_long_rounded;
  }

  Color _transactionIconColor(String type) {
    return type == 'income' ? AppColors.income : AppColors.expense;
  }

  Color _transactionIconBackground(String type) {
    return type == 'income' ? AppColors.primaryLight : const Color(0xFFFFE9E9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildBalanceCard()),
              SliverToBoxAdapter(child: _buildQuickSummary()),
              SliverToBoxAdapter(child: _buildUpcomingSection()),
              SliverToBoxAdapter(child: _buildRecentActivity()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning 👋',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isLoading ? 'Loading...' : _userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderButton(icon: Icons.notifications_none_rounded),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 22),
    );
  }

  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.20),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Available balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'On track',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$_currencySymbol${_formatAmount(_balance)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceStat(
                    icon: Icons.arrow_downward_rounded,
                    title: 'Income',
                    amount: '$_currencySymbol${_formatAmount(_totalIncome)}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 42,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                Expanded(
                  child: _buildBalanceStat(
                    icon: Icons.arrow_upward_rounded,
                    title: 'Spent',
                    amount: '$_currencySymbol${_formatAmount(_totalExpense)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceStat({
    required IconData icon,
    required String title,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'This week',
              amount: '$_currencySymbol${_formatAmount(_thisWeekExpense)}',
              subtitle: 'spent',
              icon: Icons.calendar_view_week_rounded,
              iconBackground: AppColors.primaryLight,
              iconColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'This month',
              amount: '$_currencySymbol${_formatAmount(_thisMonthExpense)}',
              subtitle: 'spent',
              icon: Icons.calendar_month_rounded,
              iconBackground: const Color(0xFFFFF3DE),
              iconColor: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      child: Column(
        children: [
          _buildSectionHeader(title: 'Upcoming', action: 'See all'),
          const SizedBox(height: 12),
          if (_upcomingItems.isEmpty)
            _buildEmptyUpcoming()
          else
            ..._upcomingItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildUpcomingItem(
                  icon: item['icon'] as IconData,
                  iconBackground: item['iconBackground'] as Color,
                  iconColor: item['iconColor'] as Color,
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                  amount:
                      '$_currencySymbol${_formatAmount(item['amount'] as double)}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyUpcoming() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
            'Nothing upcoming',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your upcoming bills, EMIs and repayments will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String action}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingItem({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
  }) {
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      child: Column(
        children: [
          _buildSectionHeader(title: 'Recent activity', action: 'See all'),
          const SizedBox(height: 12),
          if (_transactions.isEmpty)
            _buildEmptyActivity()
          else
            ..._transactions.take(5).map((transaction) {
              final type = transaction['type']?.toString() ?? 'expense';
              final amount =
                  double.tryParse(transaction['amount'].toString()) ?? 0;
              final note = transaction['note']?.toString();

              final title = note == null || note.isEmpty
                  ? type == 'income'
                        ? 'Income'
                        : 'Expense'
                  : note;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildActivityItem(
                  icon: _transactionIcon(note),
                  iconBackground: _transactionIconBackground(type),
                  iconColor: _transactionIconColor(type),
                  title: title,
                  subtitle: _formatDate(
                    transaction['transaction_date']?.toString(),
                  ),
                  amount:
                      '${type == 'income' ? '+' : '-'} $_currencySymbol${_formatAmount(amount)}',
                  amountColor: _transactionIconColor(type),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
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
            Icons.receipt_long_rounded,
            color: AppColors.textMuted,
            size: 32,
          ),
          SizedBox(height: 10),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add your first transaction to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
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
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
