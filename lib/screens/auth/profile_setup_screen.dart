import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../main_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String? phone;
  final String? initialName;

  const ProfileSetupScreen({super.key, this.phone, this.initialName});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final TextEditingController _nameController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _confirmPasscodeController =
      TextEditingController();

  String _selectedCurrency = 'INR (₹)';
  bool _isSaving = false;
  bool _obscurePasscode = true;
  bool _obscureConfirmPasscode = true;

  final List<String> _currencies = [
    'INR (₹)',
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passcodeController.dispose();
    _confirmPasscodeController.dispose();
    super.dispose();
  }

  String _getCurrencyCode() {
    switch (_selectedCurrency) {
      case 'USD (\$)':
        return 'USD';
      case 'EUR (€)':
        return 'EUR';
      case 'GBP (£)':
        return 'GBP';
      default:
        return 'INR';
    }
  }

  Future<void> _continue() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final passcode = _passcodeController.text.trim();
    final confirmPasscode = _confirmPasscodeController.text.trim();
    final phone = widget.phone?.trim();

    if (name.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    if (phone == null || phone.isEmpty) {
      _showMessage('Phone number is missing. Please register again.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(passcode)) {
      _showMessage('Passcode must contain exactly 6 digits.');
      return;
    }

    if (passcode != confirmPasscode) {
      _showMessage('Passcodes do not match.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await ApiService.createUser(
        fullName: name,
        phone: phone,
        email: email.isEmpty ? null : email,
        currency: _getCurrencyCode(),
        passcode: passcode,
      );

      final userId = result['user_id'];

      if (userId == null) {
        throw Exception('User ID was not returned by the server.');
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(userId: int.parse(userId.toString())),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Could not save profile: '
        '${error.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildProfilePhoto(),
              const SizedBox(height: 34),
              _buildNameField(),
              const SizedBox(height: 18),
              _buildPhoneDisplay(),
              const SizedBox(height: 18),
              _buildEmailField(),
              const SizedBox(height: 18),
              _buildPasscodeField(),
              const SizedBox(height: 18),
              _buildConfirmPasscodeField(),
              const SizedBox(height: 18),
              _buildCurrencyField(),
              const SizedBox(height: 30),
              _buildContinueButton(),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'You can change these details later.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set up your profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Create your profile and set a secure passcode for DueMate.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 4),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 52,
            ),
          ),
          Positioned(
            right: -2,
            bottom: 0,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Full name',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneDisplay() {
    final phone = widget.phone ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone number',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: TextEditingController(
            text: phone.isEmpty ? '' : '+91 $phone',
          ),
          readOnly: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: AppColors.textSecondary,
            ),
            suffixIcon: Icon(Icons.verified_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email address',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Enter your email (optional)',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasscodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create passcode',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _passcodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: _obscurePasscode,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Create a 6-digit passcode',
            counterText: '',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePasscode = !_obscurePasscode;
                });
              },
              icon: Icon(
                _obscurePasscode
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasscodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm passcode',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _confirmPasscodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: _obscureConfirmPasscode,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _continue(),
          decoration: InputDecoration(
            hintText: 'Re-enter your 6-digit passcode',
            counterText: '',
            prefixIcon: const Icon(
              Icons.lock_reset_rounded,
              color: AppColors.textSecondary,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPasscode = !_obscureConfirmPasscode;
                });
              },
              icon: Icon(
                _obscureConfirmPasscode
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Currency',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          initialValue: _selectedCurrency,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.currency_exchange_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          items: _currencies.map((currency) {
            return DropdownMenuItem<String>(
              value: currency,
              child: Text(currency),
            );
          }).toList(),
          onChanged: _isSaving
              ? null
              : (value) {
                  if (value == null) return;

                  setState(() {
                    _selectedCurrency = value;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _continue,
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.white,
                ),
              )
            : const Text('Create Account'),
      ),
    );
  }
}
