import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class AddEmiScreen extends StatefulWidget {
  final int userId;

  const AddEmiScreen({super.key, required this.userId});

  @override
  State<AddEmiScreen> createState() => _AddEmiScreenState();
}

class _AddEmiScreenState extends State<AddEmiScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lenderController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _monthlyAmountController =
      TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _installmentsController = TextEditingController();

  DateTime? _selectedStartDate;
  bool _isSaving = false;

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
    final initialDate = _selectedStartDate ?? DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _selectedStartDate = selectedDate;
    });
  }

  Future<void> _saveEmi() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStartDate == null) {
      _showError('Please select a start date.');
      return;
    }

    final name = _nameController.text.trim();
    final lender = _lenderController.text.trim();

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
      _showError('Please enter valid total installments.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.createEmi(
        userId: widget.userId,
        name: name,
        lenderName: lender.isEmpty ? null : lender,
        totalAmount: totalAmount,
        monthlyAmount: monthlyAmount,
        interestRate: interestRate,
        totalInstallments: totalInstallments,
        startDate: _selectedStartDate!,
        dueDay: _selectedStartDate!.day,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('EMI added successfully.')));

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError('Could not save EMI: $error');
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
          'Add EMI',
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
                _buildIntro(),
                const SizedBox(height: 28),
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
                      return null;
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
                  hint: 'e.g. 24',
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
                const SizedBox(height: 30),
                _buildSummary(),
                const SizedBox(height: 30),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add a new EMI',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Keep your loan and monthly payments organized.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
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

  Widget _buildSummary() {
    final totalAmount = double.tryParse(_totalAmountController.text.trim());

    final monthlyAmount = double.tryParse(_monthlyAmountController.text.trim());

    final installments = int.tryParse(_installmentsController.text.trim());

    if (totalAmount == null &&
        monthlyAmount == null &&
        installments == null &&
        _selectedStartDate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EMI summary',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (totalAmount != null)
            _buildSummaryRow(
              'Total amount',
              '₹${totalAmount.toStringAsFixed(2)}',
            ),
          if (monthlyAmount != null) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Monthly EMI',
              '₹${monthlyAmount.toStringAsFixed(2)}',
            ),
          ],
          if (installments != null) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Installments', installments.toString()),
          ],
          if (_selectedStartDate != null) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Due day',
              '${_selectedStartDate!.day}th of every month',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
        onPressed: _isSaving ? null : _saveEmi,
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
                'Save EMI',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
