import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../main_screen.dart';
import 'register_screen.dart';
import 'forgot_passcode_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePasscode = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _continueWithPhone() async {
    final phone = _phoneController.text.trim();
    final passcode = _passcodeController.text.trim();

    if (phone.isEmpty) {
      _showMessage('Please enter your phone number.');
      return;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      _showMessage('Please enter a valid 10-digit phone number.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(passcode)) {
      _showMessage('Please enter your 6-digit passcode.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await ApiService.loginWithPhone(phone, passcode);

      final userId = user['id'];

      if (userId == null) {
        throw Exception('User ID was not returned by the server.');
      }

      final parsedUserId = int.parse(userId.toString());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', parsedUserId);
      await prefs.setBool('isLoggedIn', true);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainScreen(userId: parsedUserId)),
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

  void _createAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _forgotPasscode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasscodeScreen()),
    );
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
              const SizedBox(height: 38),
              _buildPhoneField(),
              const SizedBox(height: 18),
              _buildPasscodeField(),
              const SizedBox(height: 10),
              _buildForgotPasscode(),
              const SizedBox(height: 22),
              _buildContinueButton(),
              const SizedBox(height: 24),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildGoogleButton(),
              const SizedBox(height: 30),
              _buildRegisterText(),
              const SizedBox(height: 28),
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
          'Welcome back 👋',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Log in with your phone number and passcode.',
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
          'Phone number',
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
          textInputAction: TextInputAction.next,
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

  Widget _buildPasscodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Passcode',
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
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _continueWithPhone(),
          decoration: InputDecoration(
            hintText: 'Enter your 6-digit passcode',
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

  Widget _buildForgotPasscode() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _forgotPasscode,
        child: const Text(
          'Forgot passcode?',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _continueWithPhone,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.white,
                ),
              )
            : const Text('Login'),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(
          Icons.g_mobiledata_rounded,
          color: AppColors.textPrimary,
          size: 27,
        ),
        label: const Text(
          'Continue with Google',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterText() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          children: [
            const TextSpan(text: "Don't have an account? "),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: _createAccount,
                child: const Text(
                  'Create one',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
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
}
