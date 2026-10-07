import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class ChangePasscodeScreen extends StatefulWidget {
  final int userId;

  const ChangePasscodeScreen({super.key, required this.userId});

  @override
  State<ChangePasscodeScreen> createState() => _ChangePasscodeScreenState();
}

class _ChangePasscodeScreenState extends State<ChangePasscodeScreen> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isSaving = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePasscode() async {
    final currentPasscode = _currentController.text.trim();
    final newPasscode = _newController.text.trim();
    final confirmPasscode = _confirmController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(currentPasscode)) {
      _showMessage('Enter your current 6-digit passcode.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(newPasscode)) {
      _showMessage('New passcode must contain exactly 6 digits.');
      return;
    }

    if (newPasscode != confirmPasscode) {
      _showMessage('New passcodes do not match.');
      return;
    }

    if (currentPasscode == newPasscode) {
      _showMessage('New passcode must be different from the current passcode.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.changePasscode(
        userId: widget.userId,
        currentPasscode: currentPasscode,
        newPasscode: newPasscode,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passcode changed successfully.')),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Change Passcode',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update your DueMate passcode.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _buildPasscodeField(
                label: 'Current passcode',
                hint: 'Enter current passcode',
                controller: _currentController,
                obscureText: _hideCurrent,
                onToggle: () {
                  setState(() {
                    _hideCurrent = !_hideCurrent;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildPasscodeField(
                label: 'New passcode',
                hint: 'Enter new 6-digit passcode',
                controller: _newController,
                obscureText: _hideNew,
                onToggle: () {
                  setState(() {
                    _hideNew = !_hideNew;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildPasscodeField(
                label: 'Confirm new passcode',
                hint: 'Re-enter new passcode',
                controller: _confirmController,
                obscureText: _hideConfirm,
                onToggle: () {
                  setState(() {
                    _hideConfirm = !_hideConfirm;
                  });
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _changePasscode,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Change Passcode'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasscodeField({
    required String label,
    required String hint,
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
          enabled: !_isSaving,
          decoration: InputDecoration(
            hintText: hint,
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
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
