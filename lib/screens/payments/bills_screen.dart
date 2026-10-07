import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class BillsScreen extends StatefulWidget {
  final int userId;

  const BillsScreen({super.key, required this.userId});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<Map<String, dynamic>> _bills = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      final bills = await ApiService.getBills(widget.userId);

      if (!mounted) return;

      setState(() {
        _bills = bills;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      debugPrint('Bills error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  List<Map<String, dynamic>> get _activeBills {
    return _bills.where((bill) {
      final status = bill['status']?.toString().toLowerCase();
      return status == 'active';
    }).toList();
  }

  List<Map<String, dynamic>> get _paidBills {
    return _bills.where((bill) {
      final status = bill['status']?.toString().toLowerCase();
      return status == 'paid';
    }).toList();
  }

  double get _monthlyTotal {
    double total = 0;

    for (final bill in _activeBills) {
      final amount = _number(bill['amount']);
      final frequency = bill['frequency']?.toString().toLowerCase();

      if (frequency == 'weekly') {
        total += amount * 4.33;
      } else if (frequency == 'yearly') {
        total += amount / 12;
      } else {
        total += amount;
      }
    }

    return total;
  }

  double _number(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }

    return amount.toStringAsFixed(2);
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _frequencyLabel(dynamic value) {
    final frequency = value?.toString().toLowerCase() ?? 'monthly';

    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'yearly':
        return 'Yearly';
      case 'one-time':
      case 'once':
        return 'One-time';
      default:
        return 'Monthly';
    }
  }

  IconData _billIcon(String? name) {
    final value = name?.toLowerCase() ?? '';

    if (value.contains('electric')) {
      return Icons.bolt_rounded;
    }

    if (value.contains('water')) {
      return Icons.water_drop_rounded;
    }

    if (value.contains('internet') || value.contains('wifi')) {
      return Icons.wifi_rounded;
    }

    if (value.contains('mobile') || value.contains('phone')) {
      return Icons.phone_android_rounded;
    }

    if (value.contains('rent')) {
      return Icons.home_rounded;
    }

    if (value.contains('insurance')) {
      return Icons.health_and_safety_rounded;
    }

    if (value.contains('subscription') ||
        value.contains('netflix') ||
        value.contains('spotify')) {
      return Icons.subscriptions_rounded;
    }

    return Icons.receipt_long_rounded;
  }

  Color _billIconColor(String? name) {
    final value = name?.toLowerCase() ?? '';

    if (value.contains('electric')) {
      return const Color(0xFFFFA000);
    }

    if (value.contains('water')) {
      return AppColors.info;
    }

    if (value.contains('internet') || value.contains('wifi')) {
      return const Color(0xFF7E57C2);
    }

    if (value.contains('mobile') || value.contains('phone')) {
      return AppColors.primary;
    }

    if (value.contains('rent')) {
      return const Color(0xFF8E5AD9);
    }

    return AppColors.info;
  }

  Color _billIconBackground(String? name) {
    final color = _billIconColor(name);

    return color.withValues(alpha: 0.12);
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return AppColors.income;
      case 'cancelled':
        return AppColors.textMuted;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _openAddBill() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddBillScreen(userId: widget.userId)),
    );

    if (result == true) {
      await _loadBills();
    }
  }

  Future<void> _openEditBill(Map<String, dynamic> bill) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddBillScreen(userId: widget.userId, bill: bill),
      ),
    );

    if (result == true) {
      await _loadBills();
    }
  }

  Future<void> _markPaid(Map<String, dynamic> bill) async {
    final billId = int.tryParse(bill['id']?.toString() ?? '');

    if (billId == null) return;

    try {
      await ApiService.markBillAsPaid(billId);

      if (!mounted) return;

      await _loadBills();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bill marked as paid.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not mark bill as paid: $error')),
      );
    }
  }

  Future<void> _deleteBill(Map<String, dynamic> bill) async {
    final billId = int.tryParse(bill['id']?.toString() ?? '');

    if (billId == null) return;

    final name = bill['name']?.toString() ?? 'this bill';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete bill?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text('Are you sure you want to delete "$name"?'),
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

    if (confirmed != true) return;

    try {
      await ApiService.deleteBill(billId);

      if (!mounted) return;

      await _loadBills();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bill deleted.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete bill: $error')));
    }
  }

  void _showBillOptions(Map<String, dynamic> bill) {
    final status = bill['status']?.toString().toLowerCase() ?? 'active';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Edit Bill'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openEditBill(bill);
                  },
                ),
                if (status == 'active')
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.income,
                    ),
                    title: const Text('Mark as Paid'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _markPaid(bill);
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.expense,
                  ),
                  title: const Text('Delete Bill'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _deleteBill(bill);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bills & Payments',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBills,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorState()
            : _buildContent(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddBill,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your Bills',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${_activeBills.length} active',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_bills.isEmpty)
          _buildEmptyState()
        else
          ..._bills.map(
            (bill) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBillCard(bill),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Bills',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${_formatAmount(_monthlyTotal)}',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Active Bills',
                  value: '${_activeBills.length}',
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Paid',
                  value: '${_paidBills.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.72),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final name = bill['name']?.toString() ?? 'Bill';

    final provider = bill['provider']?.toString() ?? '';

    final amount = _number(bill['amount']);

    final frequency = _frequencyLabel(bill['frequency']);

    final dueDate = _formatDate(bill['due_date']);

    final status = bill['status']?.toString() ?? 'active';

    final autoRepeat =
        bill['auto_repeat'] == true || bill['auto_repeat']?.toString() == '1';

    final icon = _billIcon(name);
    final iconColor = _billIconColor(name);

    return GestureDetector(
      onTap: () => _showBillOptions(bill),
      child: Container(
        padding: const EdgeInsets.all(15),
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
                    color: _billIconBackground(name),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 23),
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
                      if (provider.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          provider,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(status),
                const SizedBox(width: 4),
                const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildBillInfo('Amount', '₹${_formatAmount(amount)}'),
                ),
                Expanded(child: _buildBillInfo('Frequency', frequency)),
                Expanded(child: _buildBillInfo('Due', dueDate)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Icon(
                  autoRepeat ? Icons.repeat_rounded : Icons.event_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    autoRepeat ? 'Auto repeat enabled' : 'One-time payment',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (status.toLowerCase() == 'active')
                  GestureDetector(
                    onTap: () => _markPaid(bill),
                    child: const Text(
                      'Mark paid',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty
            ? 'Active'
            : '${status[0].toUpperCase()}${status.substring(1)}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBillInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 45),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
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
            'No bills yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your electricity, rent, internet, subscriptions and other recurring payments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openAddBill,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Add Bill'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.expense,
                    size: 50,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Could not load bills',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'Something went wrong.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadBills,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// ADD / EDIT BILL SCREEN
// =============================================================

class AddBillScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? bill;

  const AddBillScreen({super.key, required this.userId, this.bill});

  bool get isEditing => bill != null;

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _providerController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  String _frequency = 'monthly';
  String _status = 'active';
  DateTime _dueDate = DateTime.now();
  bool _autoRepeat = true;
  bool _isSaving = false;

  final List<String> _frequencies = ['once', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();

    final bill = widget.bill;

    _nameController = TextEditingController(
      text: bill?['name']?.toString() ?? '',
    );

    _providerController = TextEditingController(
      text: bill?['provider']?.toString() ?? '',
    );

    _amountController = TextEditingController(
      text: bill?['amount']?.toString() ?? '',
    );

    _notesController = TextEditingController(
      text: bill?['notes']?.toString() ?? bill?['note']?.toString() ?? '',
    );

    if (bill != null) {
      final frequency = bill['frequency']?.toString().toLowerCase();

      if (_frequencies.contains(frequency)) {
        _frequency = frequency!;
      }

      final status = bill['status']?.toString().toLowerCase();

      if (status == 'active' || status == 'paid' || status == 'cancelled') {
        _status = status!;
      }

      final parsedDate = DateTime.tryParse(bill['due_date']?.toString() ?? '');

      if (parsedDate != null) {
        _dueDate = parsedDate;
      }

      _autoRepeat =
          bill['auto_repeat'] == true || bill['auto_repeat']?.toString() == '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _providerController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    if (_isSaving) return;

    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _dueDate = selected;
    });
  }

  Future<void> _saveBill() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (name.isEmpty) {
      _showMessage('Please enter the bill name.');
      return;
    }

    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing) {
        final billId = int.tryParse(widget.bill?['id']?.toString() ?? '');

        if (billId == null) {
          throw Exception('Invalid bill ID.');
        }

        await ApiService.updateBill(
          billId: billId,
          name: name,
          provider: _providerController.text.trim().isEmpty
              ? null
              : _providerController.text.trim(),
          amount: amount,
          frequency: _frequency,
          dueDate: _dueDate,
          autoRepeat: _autoRepeat,
          status: _status,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      } else {
        await ApiService.createBill(
          userId: widget.userId,
          name: name,
          provider: _providerController.text.trim().isEmpty
              ? null
              : _providerController.text.trim(),
          amount: amount,
          frequency: _frequency,
          dueDate: _dueDate,
          autoRepeat: _autoRepeat,
          status: _status,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Could not save bill: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _displayDate() {
    return '${_dueDate.day.toString().padLeft(2, '0')}/'
        '${_dueDate.month.toString().padLeft(2, '0')}/'
        '${_dueDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Bill' : 'Add Bill',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                controller: _nameController,
                label: 'Bill name',
                hint: 'e.g. Electricity',
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(height: 18),
              _buildField(
                controller: _providerController,
                label: 'Provider',
                hint: 'e.g. APDCL',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 18),
              _buildField(
                controller: _amountController,
                label: 'Amount',
                hint: 'Enter amount',
                icon: Icons.currency_rupee_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 18),
              _buildFrequencyField(),
              const SizedBox(height: 18),
              _buildDateField(),
              const SizedBox(height: 18),
              _buildAutoRepeatField(),
              const SizedBox(height: 18),
              _buildNotesField(),
              if (widget.isEditing) ...[
                const SizedBox(height: 18),
                _buildStatusField(),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBill,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : Text(widget.isEditing ? 'Save Changes' : 'Add Bill'),
                ),
              ),
            ],
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
        TextField(
          controller: controller,
          enabled: !_isSaving,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          initialValue: _frequency,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.repeat_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          items: _frequencies.map((value) {
            String label;

            switch (value) {
              case 'once':
                label = 'One-time';
                break;
              case 'weekly':
                label = 'Weekly';
                break;
              case 'yearly':
                label = 'Yearly';
                break;
              default:
                label = 'Monthly';
            }

            return DropdownMenuItem(value: value, child: Text(label));
          }).toList(),
          onChanged: _isSaving
              ? null
              : (value) {
                  if (value == null) return;

                  setState(() {
                    _frequency = value;
                  });
                },
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
          onTap: _selectDueDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _displayDate(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
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

  Widget _buildAutoRepeatField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Auto repeat',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text(
          'Repeat this payment automatically',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        value: _autoRepeat,
        activeThumbColor: AppColors.primary,
        onChanged: _isSaving
            ? null
            : (value) {
                setState(() {
                  _autoRepeat = value;
                });
              },
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _notesController,
          enabled: !_isSaving,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Add optional notes',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 55),
              child: Icon(Icons.notes_rounded, color: AppColors.textSecondary),
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
          initialValue: _status,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.flag_outlined,
              color: AppColors.textSecondary,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'paid', child: Text('Paid')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
          onChanged: _isSaving
              ? null
              : (value) {
                  if (value == null) return;

                  setState(() {
                    _status = value;
                  });
                },
        ),
      ],
    );
  }
}
