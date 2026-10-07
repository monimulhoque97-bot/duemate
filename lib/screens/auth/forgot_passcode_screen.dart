import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';

class ForgotPasscodeScreen extends StatefulWidget {
  const ForgotPasscodeScreen({super.key});

  @override
  State<ForgotPasscodeScreen> createState() => _ForgotPasscodeScreenState();
}

class _ForgotPasscodeScreenState extends State<ForgotPasscodeScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasscodeController = TextEditingController();
  final TextEditingController _confirmPasscodeController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscureNewPasscode = true;
  bool _obscureConfirmPasscode = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _newPasscodeController.dispose();
    _confirmPasscodeController.dispose();
    super.dispose();
  }

  Future<void> _resetPasscode() async {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final newPasscode = _newPasscodeController.text.trim();
    final confirmPasscode = _confirmPasscodeController.text.trim();

    if (phone.isEmpty && email.isEmpty) {
      _showMessage('Enter your phone number or email.');
      return;
    }

    if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
      _showMessage('Please enter a valid 10-digit phone number.');
      return;
    }

    if (email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(newPasscode)) {
      _showMessage('New passcode must be exactly 6 digits.');
      return;
    }

    if (newPasscode != confirmPasscode) {
      _showMessage('Passcodes do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.forgotPasscode(
        phone: phone.isEmpty ? null : phone,
        email: email.isEmpty ? null : email,
        newPasscode: newPasscode,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Passcode Reset'),
            content: const Text(
              'Your passcode has been reset successfully. You can now log in with your new passcode.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              _buildBackButton(context),
              const SizedBox(height: 42),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildPhoneField(),
              const SizedBox(height: 18),
              _buildEmailField(),
              const SizedBox(height: 8),
              const Text(
                'Enter either your phone number or email address.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 22),
              _buildPasscodeField(
                label: 'New passcode',
                controller: _newPasscodeController,
                obscureText: _obscureNewPasscode,
                onToggle: () {
                  setState(() {
                    _obscureNewPasscode = !_obscureNewPasscode;
                  });
                },
              ),
              const SizedBox(height: 18),
              _buildPasscodeField(
                label: 'Confirm passcode',
                controller: _confirmPasscodeController,
                obscureText: _obscureConfirmPasscode,
                onToggle: () {
                  setState(() {
                    _obscureConfirmPasscode = !_obscureConfirmPasscode;
                  });
                },
              ),
              const SizedBox(height: 28),
              _buildResetButton(),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Back to Login'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
          size: 21,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forgot passcode?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Use your phone number or email to reset your passcode.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone number (optional)',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: const InputDecoration(
            hintText: 'Enter your phone number',
            counterText: '',
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: AppColors.textSecondary,
            ),
            prefixText: '+91  ',
            prefixStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
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
          'Email (optional)',
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
          decoration: const InputDecoration(
            hintText: 'Enter your email address',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasscodeField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
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
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: 'Enter 6-digit passcode',
            counterText: '',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _resetPasscode,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.white,
                ),
              )
            : const Text('Reset Passcode'),
      ),
    );
  }
}
