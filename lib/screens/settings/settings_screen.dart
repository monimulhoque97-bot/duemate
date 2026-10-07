import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';

import '../../core/theme/app_colors.dart';
import 'change_passcode_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;

  bool _isSaving = false;

  String _userName = 'User';

  String _email = '';

  String _phone = '';

  String _currency = 'INR';

  bool _paymentReminders = true;

  bool _billReminders = true;

  bool _emiReminders = true;

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();

    _loadSettings();
  }

  // ============================================================

  // LOAD USER SETTINGS

  // ============================================================

  Future<void> _loadSettings() async {
    try {
      final user = await ApiService.getUser(widget.userId);

      if (!mounted) return;

      setState(() {
        _userName = user['full_name']?.toString() ?? 'User';

        _email = user['email']?.toString() ?? '';

        _phone = user['phone']?.toString() ?? '';

        final currency = user['currency']?.toString() ?? 'INR';

        _currency = _currencies.contains(currency) ? currency : 'INR';

        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Settings loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Could not load settings: $error');
    }
  }

  // ============================================================

  // UPDATE CURRENCY

  // ============================================================

  Future<void> _changeCurrency(String? currency) async {
    if (currency == null || currency == _currency || _isSaving) {
      return;
    }

    final oldCurrency = _currency;

    setState(() {
      _currency = currency;

      _isSaving = true;
    });

    try {
      await ApiService.updateUser(
        userId: widget.userId,

        fullName: _userName,

        phone: _phone.isEmpty ? null : _phone,

        email: _email.isEmpty ? null : _email,

        currency: currency,
      );

      if (!mounted) return;

      _showMessage('Currency updated to $currency.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _currency = oldCurrency;
      });

      _showMessage('Could not update currency: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================

  // PROFILE

  // ============================================================

  Future<void> _openProfile() async {
    final result = await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => _SettingsProfileScreen(
          userId: widget.userId,

          userName: _userName,

          phone: _phone,

          email: _email,

          currency: _currency,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadSettings();
    }
  }

  // ============================================================

  // LOGOUT

  // ============================================================

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,

          title: const Text(
            'Log out?',

            style: TextStyle(
              color: AppColors.textPrimary,

              fontWeight: FontWeight.w700,
            ),
          ),

          content: const Text(
            'Are you sure you want to log out of DueMate?',

            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.of(context).popUntil((route) => route.isFirst);
              },

              child: const Text(
                'Log out',

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
  }

  // ============================================================

  // MESSAGE

  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================

  // BUILD

  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,

        elevation: 0,

        title: const Text(
          'Settings',

          style: TextStyle(
            color: AppColors.textPrimary,

            fontSize: 20,

            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadSettings,

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

              onRefresh: _loadSettings,

              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    _buildHeader(),

                    const SizedBox(height: 24),

                    _buildProfileCard(),

                    const SizedBox(height: 28),

                    _buildSectionTitle('Security'),

                    const SizedBox(height: 12),

                    _buildSecurityCard(),

                    const SizedBox(height: 28),

                    _buildSectionTitle('Preferences'),

                    const SizedBox(height: 12),

                    _buildCurrencyCard(),

                    const SizedBox(height: 28),

                    _buildSectionTitle('Reminders'),

                    const SizedBox(height: 12),

                    _buildReminderCard(),

                    const SizedBox(height: 28),

                    _buildSectionTitle('About'),

                    const SizedBox(height: 12),

                    _buildAboutCard(),

                    const SizedBox(height: 28),

                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================

  // HEADER

  // ============================================================

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'App settings',

          style: TextStyle(
            color: AppColors.textPrimary,

            fontSize: 25,

            fontWeight: FontWeight.w700,

            letterSpacing: -0.5,
          ),
        ),

        SizedBox(height: 6),

        Text(
          'Manage your DueMate preferences.',

          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  // ============================================================

  // SECTION TITLE

  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,

      style: const TextStyle(
        color: AppColors.textSecondary,

        fontSize: 12,

        fontWeight: FontWeight.w700,

        letterSpacing: 0.4,
      ),
    );
  }

  // ============================================================

  // PROFILE CARD

  // ============================================================

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: _openProfile,

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: AppColors.surface,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(color: AppColors.border),
        ),

        child: Row(
          children: [
            Container(
              width: 54,

              height: 54,

              decoration: const BoxDecoration(
                color: AppColors.primaryLight,

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.person_rounded,

                color: AppColors.primary,

                size: 28,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    _userName,

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
                    _email.isNotEmpty
                        ? _email
                        : _phone.isNotEmpty
                        ? _phone
                        : 'Manage your profile',

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: AppColors.textSecondary,

                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  // ============================================================

  // SECURITY CARD

  // ============================================================

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: _buildAboutTile(
        icon: Icons.lock_outline_rounded,
        title: 'Change passcode',
        subtitle: 'Update your 6-digit login passcode',
        onTap: _openChangePasscode,
      ),
    );
  }

  Future<void> _openChangePasscode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasscodeScreen(userId: widget.userId),
      ),
    );
  }

  // ============================================================

  // CURRENCY CARD

  // ============================================================

  Widget _buildCurrencyCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

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
              color: AppColors.primaryLight,

              borderRadius: BorderRadius.circular(13),
            ),

            child: const Icon(
              Icons.currency_exchange_rounded,

              color: AppColors.primary,

              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Currency',

                  style: TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: 13,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Default currency for your finances',

                  style: TextStyle(
                    color: AppColors.textSecondary,

                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _currency,

              borderRadius: BorderRadius.circular(14),

              items: _currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency,

                  child: Text(
                    currency,

                    style: const TextStyle(
                      color: AppColors.textPrimary,

                      fontSize: 12,

                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),

              onChanged: _isSaving ? null : _changeCurrency,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================

  // REMINDER CARD

  // ============================================================

  Widget _buildReminderCard() {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.receipt_long_rounded,

            iconBackground: const Color(0xFFE8F0FF),

            iconColor: AppColors.info,

            title: 'Payment reminders',

            subtitle: 'Remind me about upcoming payments',

            value: _paymentReminders,

            onChanged: (value) {
              setState(() {
                _paymentReminders = value;
              });
            },
          ),

          const Divider(height: 1, indent: 72, color: AppColors.border),

          _buildSwitchTile(
            icon: Icons.calendar_month_rounded,

            iconBackground: const Color(0xFFFFF3DE),

            iconColor: AppColors.warning,

            title: 'Bill reminders',

            subtitle: 'Remind me before bills are due',

            value: _billReminders,

            onChanged: (value) {
              setState(() {
                _billReminders = value;
              });
            },
          ),

          const Divider(height: 1, indent: 72, color: AppColors.border),

          _buildSwitchTile(
            icon: Icons.credit_card_rounded,

            iconBackground: const Color(0xFFF4EAFE),

            iconColor: const Color(0xFF8E5AD9),

            title: 'EMI reminders',

            subtitle: 'Remind me about upcoming EMIs',

            value: _emiReminders,

            onChanged: (value) {
              setState(() {
                _emiReminders = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================

  // SWITCH TILE

  // ============================================================

  Widget _buildSwitchTile({
    required IconData icon,

    required Color iconBackground,

    required Color iconColor,

    required String title,

    required String subtitle,

    required bool value,

    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

      child: Row(
        children: [
          Container(
            width: 42,

            height: 42,

            decoration: BoxDecoration(
              color: iconBackground,

              borderRadius: BorderRadius.circular(12),
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

                  style: const TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: 12,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,

                  style: const TextStyle(
                    color: AppColors.textSecondary,

                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          Switch.adaptive(
            value: value,

            activeThumbColor: AppColors.primary,

            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ============================================================

  // ABOUT

  // ============================================================

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        children: [
          _buildAboutTile(
            icon: Icons.info_outline_rounded,

            title: 'About DueMate',

            subtitle: 'Personal finance and payment manager',

            onTap: _showAboutDialog,
          ),

          const Divider(height: 1, indent: 70, color: AppColors.border),

          _buildAboutTile(
            icon: Icons.privacy_tip_outlined,

            title: 'Privacy',

            subtitle: 'Your financial information stays private',

            onTap: _showPrivacyDialog,
          ),

          const Divider(height: 1, indent: 70, color: AppColors.border),

          _buildAboutTile(
            icon: Icons.description_outlined,

            title: 'Terms of use',

            subtitle: 'Review DueMate terms and conditions',

            onTap: _showTermsDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTile({
    required IconData icon,

    required String title,

    required String subtitle,

    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(18),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          children: [
            Container(
              width: 42,

              height: 42,

              decoration: BoxDecoration(
                color: AppColors.background,

                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(icon, color: AppColors.textSecondary, size: 20),
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

                      fontSize: 12,

                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,

                    style: const TextStyle(
                      color: AppColors.textSecondary,

                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,

              color: AppColors.textMuted,

              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================

  // ABOUT DIALOG

  // ============================================================

  void _showAboutDialog() {
    showDialog<void>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,

          title: const Text(
            'DueMate',

            style: TextStyle(
              color: AppColors.textPrimary,

              fontWeight: FontWeight.w700,
            ),
          ),

          content: const Text(
            'DueMate helps you manage your income, expenses, transactions, bills, EMIs, debts and financial reminders in one place.',

            style: TextStyle(
              color: AppColors.textSecondary,

              fontSize: 13,

              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================

  // PRIVACY DIALOG

  // ============================================================

  void _showPrivacyDialog() {
    showDialog<void>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,

          title: const Text(
            'Privacy',

            style: TextStyle(
              color: AppColors.textPrimary,

              fontWeight: FontWeight.w700,
            ),
          ),

          content: const Text(
            'DueMate uses your account information and financial records to provide the features available in the application.',

            style: TextStyle(
              color: AppColors.textSecondary,

              fontSize: 13,

              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================

  // TERMS DIALOG

  // ============================================================

  void _showTermsDialog() {
    showDialog<void>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,

          title: const Text(
            'Terms of use',

            style: TextStyle(
              color: AppColors.textPrimary,

              fontWeight: FontWeight.w700,
            ),
          ),

          content: const Text(
            'DueMate is a personal finance management tool. Always verify important financial information before making payments or financial decisions.',

            style: TextStyle(
              color: AppColors.textSecondary,

              fontSize: 13,

              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================

  // LOGOUT BUTTON

  // ============================================================

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,

      height: 52,

      child: OutlinedButton.icon(
        onPressed: _showLogoutDialog,

        icon: const Icon(
          Icons.logout_rounded,

          color: AppColors.expense,

          size: 19,
        ),

        label: const Text(
          'Log out',

          style: TextStyle(
            color: AppColors.expense,

            fontSize: 14,

            fontWeight: FontWeight.w700,
          ),
        ),

        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,

          side: const BorderSide(color: AppColors.border),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ================================================================

// SETTINGS PROFILE SCREEN

// ================================================================

class _SettingsProfileScreen extends StatefulWidget {
  final int userId;

  final String userName;

  final String phone;

  final String email;

  final String currency;

  const _SettingsProfileScreen({
    required this.userId,

    required this.userName,

    required this.phone,

    required this.email,

    required this.currency,
  });

  @override
  State<_SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends State<_SettingsProfileScreen> {
  late final TextEditingController _nameController;

  late final TextEditingController _phoneController;

  late final TextEditingController _emailController;

  late String _currency;

  bool _isSaving = false;

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.userName);

    _phoneController = TextEditingController(text: widget.phone);

    _emailController = TextEditingController(text: widget.email);

    _currency = _currencies.contains(widget.currency) ? widget.currency : 'INR';
  }

  @override
  void dispose() {
    _nameController.dispose();

    _phoneController.dispose();

    _emailController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter your name.');

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.updateUser(
        userId: widget.userId,

        fullName: name,

        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),

        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),

        currency: _currency,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Could not update profile: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

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

        title: const Text(
          'Edit Profile',

          style: TextStyle(
            color: AppColors.textPrimary,

            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),

          child: Column(
            children: [
              Container(
                width: 96,

                height: 96,

                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,

                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.person_rounded,

                  color: AppColors.primary,

                  size: 48,
                ),
              ),

              const SizedBox(height: 30),

              _buildField(
                controller: _nameController,

                label: 'Full name',

                hint: 'Enter your name',

                icon: Icons.person_outline_rounded,
              ),

              const SizedBox(height: 18),

              _buildField(
                controller: _phoneController,

                label: 'Phone number',

                hint: 'Enter your phone number',

                icon: Icons.phone_outlined,

                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 18),

              _buildField(
                controller: _emailController,

                label: 'Email address',

                hint: 'Enter your email',

                icon: Icons.email_outlined,

                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 18),

              _buildCurrency(),

              const SizedBox(height: 30),

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
                      : const Text('Save Changes'),
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

  Widget _buildCurrency() {
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
          initialValue: _currency,

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
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _currency = value;
                  });
                },
        ),
      ],
    );
  }
}
