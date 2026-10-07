import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'add_emi_screen.dart';

class EmiScreen extends StatefulWidget {
  final int userId;

  const EmiScreen({super.key, required this.userId});

  @override
  State<EmiScreen> createState() => _EmiScreenState();
}

class _EmiScreenState extends State<EmiScreen> {
  List<Map<String, dynamic>> _emis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmis();
  }

  Future<void> _loadEmis() async {
    try {
      final emis = await ApiService.getEmis(widget.userId);

      if (!mounted) return;

      setState(() {
        _emis = emis;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('EMI loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load EMIs: $error')));
    }
  }

  Future<void> _openAddEmi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEmiScreen(userId: widget.userId)),
    );

    if (result == true && mounted) {
      await _loadEmis();
    }
  }

  Future<void> _openEditEmi(Map<String, dynamic> emi) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _EditEmiScreen(emi: emi)),
    );

    if (result == true && mounted) {
      await _loadEmis();
    }
  }

  Future<void> _deleteEmi(Map<String, dynamic> emi) async {
    final emiId = int.tryParse(emi['id']?.toString() ?? '');

    if (emiId == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete EMI?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete "${emi['name'] ?? 'this EMI'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
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

    if (shouldDelete != true) return;

    try {
      await ApiService.deleteEmi(emiId);

      if (!mounted) return;

      setState(() {
        _emis.removeWhere((item) => item['id'].toString() == emiId.toString());
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('EMI deleted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete EMI: $error')));
    }
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatAmount(dynamic value) {
    final amount = _toDouble(value);

    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }

    return amount.toStringAsFixed(2);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.income;
      case 'paused':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFE8F5E9);
      case 'paused':
        return const Color(0xFFFFF3DE);
      default:
        return AppColors.primaryLight;
    }
  }

  String _statusText(String status) {
    if (status.isEmpty) return 'Active';

    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'EMIs & Loans',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadEmis,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _loadEmis, child: _buildBody()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddEmi,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_emis.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      children: [
        _buildOverview(),
        const SizedBox(height: 24),
        const Text(
          'Your EMIs',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._emis.map(
          (emi) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildEmiCard(emi),
          ),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    double monthlyTotal = 0;
    double remainingTotal = 0;
    int activeCount = 0;

    for (final emi in _emis) {
      final status = emi['status']?.toString() ?? 'active';

      final totalAmount = _toDouble(emi['total_amount']);

      final monthlyAmount = _toDouble(emi['monthly_amount']);

      final totalInstallments = _toInt(emi['total_installments']);

      final paidInstallments = _toInt(emi['paid_installments']);

      if (status.toLowerCase() == 'active') {
        activeCount++;
        monthlyTotal += monthlyAmount;

        final remainingInstallments = totalInstallments - paidInstallments;

        if (remainingInstallments > 0) {
          remainingTotal += remainingInstallments * monthlyAmount;
        } else {
          remainingTotal += totalAmount;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly EMI',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${_formatAmount(monthlyTotal)}',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.credit_card_rounded,
                  label: 'Active EMIs',
                  value: activeCount.toString(),
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Remaining',
                  value: '₹${_formatAmount(remainingTotal)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.white, size: 17),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.75),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmiCard(Map<String, dynamic> emi) {
    final name = emi['name']?.toString() ?? 'EMI';
    final lender = emi['lender_name']?.toString() ?? '';
    final status = emi['status']?.toString() ?? 'active';

    final monthlyAmount = emi['monthly_amount'];
    final totalAmount = emi['total_amount'];

    final totalInstallments = _toInt(emi['total_installments']);

    final paidInstallments = _toInt(emi['paid_installments']);

    final dueDay = _toInt(emi['due_day']);

    final remainingInstallments = totalInstallments - paidInstallments;

    final progress = totalInstallments > 0
        ? (paidInstallments / totalInstallments).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => _openEditEmi(emi),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EAFE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    color: Color(0xFF8E5AD9),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (lender.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          lender,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusBadge(status),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEditEmi(emi);
                    }

                    if (value == 'delete') {
                      _deleteEmi(emi);
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.expense,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildDetail(
                    label: 'Monthly',
                    value: '₹${_formatAmount(monthlyAmount)}',
                  ),
                ),
                Expanded(
                  child: _buildDetail(
                    label: 'Total',
                    value: '₹${_formatAmount(totalAmount)}',
                  ),
                ),
                Expanded(
                  child: _buildDetail(
                    label: 'Due day',
                    value: dueDay > 0 ? '$dueDay' : '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Payment progress',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(_statusColor(status)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$paidInstallments / $totalInstallments paid',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (remainingInstallments > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$remainingInstallments payments remaining',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetail({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusText(status),
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.credit_card_rounded,
            color: AppColors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No EMIs yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add your first EMI to keep track of your monthly payments and loan progress.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _openAddEmi,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add EMI',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditEmiScreen extends StatefulWidget {
  final Map<String, dynamic> emi;

  const _EditEmiScreen({required this.emi});

  @override
  State<_EditEmiScreen> createState() => _EditEmiScreenState();
}

class _EditEmiScreenState extends State<_EditEmiScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _lenderController;
  late final TextEditingController _totalAmountController;
  late final TextEditingController _monthlyAmountController;
  late final TextEditingController _interestController;
  late final TextEditingController _installmentsController;

  DateTime? _selectedStartDate;
  String _selectedStatus = 'active';

  bool _isSaving = false;

  final List<String> _statuses = ['active', 'paused', 'completed'];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.emi['name']?.toString() ?? '',
    );

    _lenderController = TextEditingController(
      text: widget.emi['lender_name']?.toString() ?? '',
    );

    _totalAmountController = TextEditingController(
      text: widget.emi['total_amount']?.toString() ?? '',
    );

    _monthlyAmountController = TextEditingController(
      text: widget.emi['monthly_amount']?.toString() ?? '',
    );

    _interestController = TextEditingController(
      text: widget.emi['interest_rate']?.toString() ?? '0',
    );

    _installmentsController = TextEditingController(
      text: widget.emi['total_installments']?.toString() ?? '',
    );

    _selectedStartDate = DateTime.tryParse(
      widget.emi['start_date']?.toString() ?? '',
    );

    final status = widget.emi['status']?.toString() ?? 'active';

    _selectedStatus = _statuses.contains(status) ? status : 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lenderController.dispose();
    _totalAmountController.dispose();
    _monthlyAmountController.dispose();
    _interestController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _selectedStartDate = selectedDate;
    });
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStartDate == null) {
      _showError('Please select a start date.');
      return;
    }

    final emiId = int.tryParse(widget.emi['id']?.toString() ?? '');

    if (emiId == null) {
      _showError('Invalid EMI ID.');
      return;
    }

    final totalAmount = double.tryParse(_totalAmountController.text.trim());

    final monthlyAmount = double.tryParse(_monthlyAmountController.text.trim());

    final interestRate = double.tryParse(_interestController.text.trim()) ?? 0;

    final totalInstallments = int.tryParse(_installmentsController.text.trim());

    if (totalAmount == null || totalAmount <= 0) {
      _showError('Please enter a valid total amount.');
      return;
    }

    if (monthlyAmount == null || monthlyAmount <= 0) {
      _showError('Please enter a valid monthly amount.');
      return;
    }

    if (interestRate < 0) {
      _showError('Interest rate cannot be negative.');
      return;
    }

    if (totalInstallments == null || totalInstallments <= 0) {
      _showError('Please enter valid installments.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.updateEmi(
        emiId: emiId,
        name: _nameController.text.trim(),
        lenderName: _lenderController.text.trim().isEmpty
            ? null
            : _lenderController.text.trim(),
        totalAmount: totalAmount,
        monthlyAmount: monthlyAmount,
        interestRate: interestRate,
        totalInstallments: totalInstallments,
        startDate: _selectedStartDate!,
        dueDay: _selectedStartDate!.day,
        status: _selectedStatus,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError('Could not update EMI: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit EMI',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  controller: _nameController,
                  label: 'EMI name',
                  hint: 'e.g. Phone EMI',
                  icon: Icons.credit_card_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter EMI name';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _buildField(
                  controller: _lenderController,
                  label: 'Lender name',
                  hint: 'e.g. HDFC Bank',
                  icon: Icons.account_balance_rounded,
                ),
                const SizedBox(height: 18),
                _buildField(
                  controller: _totalAmountController,
                  label: 'Total amount',
                  hint: 'Enter total loan amount',
                  icon: Icons.currency_rupee_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter total amount';
                    }

                    final amount = double.tryParse(value.trim());

                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _buildField(
                  controller: _monthlyAmountController,
                  label: 'Monthly EMI',
                  hint: 'Enter monthly payment',
                  icon: Icons.payments_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter monthly EMI';
                    }

                    final amount = double.tryParse(value.trim());

                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _buildField(
                  controller: _interestController,
                  label: 'Interest rate',
                  hint: 'e.g. 10.5',
                  icon: Icons.percent_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter interest rate';
                    }

                    final rate = double.tryParse(value.trim());

                    if (rate == null || rate < 0) {
                      return 'Enter a valid interest rate';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _buildField(
                  controller: _installmentsController,
                  label: 'Total installments',
                  hint: 'e.g. 12',
                  icon: Icons.calendar_view_month_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter installments';
                    }

                    final installments = int.tryParse(value.trim());

                    if (installments == null || installments <= 0) {
                      return 'Enter a valid number';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _buildDateField(),
                const SizedBox(height: 18),
                _buildStatusField(),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          enabled: !_isSaving,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final hasDate = _selectedStartDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Start date',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        GestureDetector(
          onTap: _isSaving ? null : _selectStartDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasDate
                        ? _formatDate(_selectedStartDate!)
                        : 'Select start date',
                    style: TextStyle(
                      color: hasDate
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          initialValue: _selectedStatus,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.toggle_on_outlined,
              color: AppColors.textSecondary,
            ),
          ),
          items: _statuses.map((status) {
            final title = status[0].toUpperCase() + status.substring(1);

            return DropdownMenuItem<String>(value: status, child: Text(title));
          }).toList(),
          onChanged: _isSaving
              ? null
              : (value) {
                  if (value == null) return;

                  setState(() {
                    _selectedStatus = value;
                  });
                },
        ),
      ],
    );
  }
}
