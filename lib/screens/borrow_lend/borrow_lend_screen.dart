import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class BorrowLendScreen extends StatefulWidget {
  final int userId;

  const BorrowLendScreen({super.key, required this.userId});

  @override
  State<BorrowLendScreen> createState() => _BorrowLendScreenState();
}

class _BorrowLendScreenState extends State<BorrowLendScreen> {
  List<Map<String, dynamic>> _debts = [];

  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    try {
      final debts = await ApiService.getDebts(widget.userId);

      if (!mounted) return;

      setState(() {
        _debts = debts;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Borrow & Lend error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load debts: $error')));
    }
  }

  List<Map<String, dynamic>> get _filteredDebts {
    if (_selectedFilter == 'All') {
      return _debts;
    }

    if (_selectedFilter == 'Borrowed') {
      return _debts.where((debt) => debt['type'] == 'borrowed').toList();
    }

    return _debts.where((debt) => debt['type'] == 'lent').toList();
  }

  double _number(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }

  double get _totalBorrowed {
    return _debts
        .where((debt) => debt['type'] == 'borrowed')
        .fold<double>(
          0.0,
          (sum, debt) => sum + _number(debt['remaining_amount']),
        );
  }

  double get _totalLent {
    return _debts
        .where((debt) => debt['type'] == 'lent')
        .fold<double>(
          0.0,
          (sum, debt) => sum + _number(debt['remaining_amount']),
        );
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }

    return amount.toStringAsFixed(2);
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'No due date';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return 'No due date';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Color _typeColor(String type) {
    return type == 'lent' ? AppColors.income : AppColors.expense;
  }

  Color _typeBackground(String type) {
    return type == 'lent' ? AppColors.primaryLight : const Color(0xFFFFE9E9);
  }

  IconData _typeIcon(String type) {
    return type == 'lent'
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
  }

  String _typeLabel(String type) {
    return type == 'lent' ? 'You lent' : 'You borrowed';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'settled':
        return 'Settled';
      case 'overdue':
        return 'Overdue';
      default:
        return 'Active';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'settled':
        return AppColors.income;
      case 'overdue':
        return AppColors.expense;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDebts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSummary()),
              SliverToBoxAdapter(child: _buildFilters()),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredDebts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final debt = _filteredDebts[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildDebtItem(debt),
                      );
                    }, childCount: _filteredDebts.length),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDebtSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
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
              'Borrow & Lend',
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
              Icons.handshake_rounded,
              color: AppColors.primary,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'You borrowed',
              amount: '₹${_formatAmount(_totalBorrowed)}',
              icon: Icons.arrow_downward_rounded,
              color: AppColors.expense,
              background: const Color(0xFFFFE9E9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'You lent',
              amount: '₹${_formatAmount(_totalLent)}',
              icon: Icons.arrow_upward_rounded,
              color: AppColors.income,
              background: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required Color background,
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
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Row(
        children: [
          _buildFilterChip('All'),
          const SizedBox(width: 8),
          _buildFilterChip('Borrowed'),
          const SizedBox(width: 8),
          _buildFilterChip('Lent'),
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

  Widget _buildDebtItem(Map<String, dynamic> debt) {
    final type = debt['type']?.toString() ?? 'borrowed';

    final status = debt['status']?.toString() ?? 'active';

    final remainingAmount = _number(debt['remaining_amount']);

    final personName = debt['person_name']?.toString() ?? 'Unknown';

    final note = debt['note']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _showDebtDetails(debt),
      child: Container(
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
                color: _typeBackground(type),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_typeIcon(type), color: _typeColor(type), size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    personName,
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
                    '${_typeLabel(type)} • Due ${_formatDate(debt['due_date'])}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${_formatAmount(remainingAmount)}',
                  style: TextStyle(
                    color: _typeColor(type),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.handshake_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No records yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All'
                  ? 'Add money you borrowed or lent.'
                  : 'No ${_selectedFilter.toLowerCase()} records found.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddDebtSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Record'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDebtSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _DebtFormSheet(userId: widget.userId, onSaved: _loadDebts);
      },
    );
  }

  void _showDebtDetails(Map<String, dynamic> debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _DebtDetailsSheet(debt: debt, onChanged: _loadDebts);
      },
    );
  }
}

class _DebtFormSheet extends StatefulWidget {
  final int userId;
  final Future<void> Function() onSaved;

  const _DebtFormSheet({required this.userId, required this.onSaved});

  @override
  State<_DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<_DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _personController = TextEditingController();

  final _amountController = TextEditingController();

  final _paidController = TextEditingController();

  final _noteController = TextEditingController();

  String _type = 'borrowed';

  DateTime? _dueDate;

  bool _isSaving = false;

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _paidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _dueDate = selected;
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final totalAmount = double.tryParse(_amountController.text.trim());

    final paidAmount = _paidController.text.trim().isEmpty
        ? 0.0
        : double.tryParse(_paidController.text.trim());

    if (totalAmount == null || totalAmount <= 0) {
      return;
    }

    if (paidAmount == null || paidAmount < 0) {
      return;
    }

    if (paidAmount > totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paid amount cannot be greater than total amount.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.createDebt(
        userId: widget.userId,
        personName: _personController.text.trim(),
        type: _type,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        dueDate: _dueDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      await widget.onSaved();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save record: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 22, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add Borrow / Lend',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTypeSelector(),
              const SizedBox(height: 20),
              _buildField(
                controller: _personController,
                label: 'Person name',
                hint: 'e.g. Rahul',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter person name';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _amountController,
                label: 'Total amount',
                hint: '0.00',
                icon: Icons.currency_rupee_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');

                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _paidController,
                label: 'Already paid',
                hint: '0.00',
                icon: Icons.check_circle_outline_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }

                  final amount = double.tryParse(value.trim());

                  if (amount == null || amount < 0) {
                    return 'Enter a valid amount';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDateField(),
              const SizedBox(height: 16),
              _buildField(
                controller: _noteController,
                label: 'Note',
                hint: 'Optional note',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Save Record'),
                ),
              ),
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
              title: 'Borrowed',
              icon: Icons.arrow_downward_rounded,
              selected: _type == 'borrowed',
              onTap: () {
                setState(() {
                  _type = 'borrowed';
                });
              },
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              title: 'Lent',
              icon: Icons.arrow_upward_rounded,
              selected: _type == 'lent',
              onTap: () {
                setState(() {
                  _type = 'lent';
                });
              },
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
        duration: const Duration(milliseconds: 180),
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
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
    int maxLines = 1,
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
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: maxLines > 1 ? 42 : 0),
              child: Icon(icon, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due date',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        GestureDetector(
          onTap: _isSaving ? null : _selectDate,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    _dueDate == null
                        ? 'Select due date'
                        : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                    style: TextStyle(
                      color: _dueDate == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontSize: 14,
                    ),
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
      ],
    );
  }
}

class _DebtDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> debt;
  final Future<void> Function() onChanged;

  const _DebtDetailsSheet({required this.debt, required this.onChanged});

  @override
  State<_DebtDetailsSheet> createState() => _DebtDetailsSheetState();
}

class _DebtDetailsSheetState extends State<_DebtDetailsSheet> {
  bool _isWorking = false;

  double _number(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }

    return amount.toStringAsFixed(2);
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'No due date';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return 'No due date';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _settle() async {
    if (_isWorking) return;

    setState(() {
      _isWorking = true;
    });

    try {
      final debtId = int.parse(widget.debt['id'].toString());

      await ApiService.settleDebt(debtId);

      if (!mounted) return;

      Navigator.pop(context);

      await widget.onChanged();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isWorking = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not settle debt: $error')));
    }
  }

  Future<void> _delete() async {
    if (_isWorking) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete record?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('This record will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      final debtId = int.parse(widget.debt['id'].toString());

      await ApiService.deleteDebt(debtId);

      if (!mounted) return;

      Navigator.pop(context);

      await widget.onChanged();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isWorking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete record: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.debt['type']?.toString() ?? 'borrowed';

    final status = widget.debt['status']?.toString() ?? 'active';

    final personName = widget.debt['person_name']?.toString() ?? 'Unknown';

    final total = _number(widget.debt['total_amount']);

    final paid = _number(widget.debt['paid_amount']);

    final remaining = _number(widget.debt['remaining_amount']);

    final note = widget.debt['note']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    personName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isWorking ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              type == 'borrowed' ? 'You borrowed' : 'You lent',
              style: TextStyle(
                color: type == 'borrowed'
                    ? AppColors.expense
                    : AppColors.income,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetail('Total amount', '₹${_formatAmount(total)}'),
            _buildDetail('Paid amount', '₹${_formatAmount(paid)}'),
            _buildDetail('Remaining', '₹${_formatAmount(remaining)}'),
            _buildDetail('Due date', _formatDate(widget.debt['due_date'])),
            _buildDetail('Status', status.toUpperCase()),
            if (note.isNotEmpty) _buildDetail('Note', note),
            const SizedBox(height: 20),
            if (status != 'settled')
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isWorking ? null : _settle,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Mark as Settled'),
                ),
              ),
            if (status != 'settled') const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isWorking ? null : _delete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.expense,
                ),
                label: const Text(
                  'Delete Record',
                  style: TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
