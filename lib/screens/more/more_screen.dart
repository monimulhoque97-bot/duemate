import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';

import '../../core/theme/app_colors.dart';

import '../auth/login_screen.dart';

import '../emi/emi_screen.dart';

import '../borrow_lend/borrow_lend_screen.dart';

import '../payments/bills_screen.dart';

import '../categories/categories_screen.dart';

import '../reports/reports_screen.dart';

import '../notifications/notifications_screen.dart';

import '../settings/settings_screen.dart';

import '../help/help_support_screen.dart';

class MoreScreen extends StatefulWidget {
  final int userId;

  const MoreScreen({super.key, required this.userId});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _userName = 'User';

  String _phone = '';

  String _email = '';

  String _currency = 'INR';

  bool _isLoading = true;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    _loadUser();
  }

  // ============================================================*

  // LOAD USER*

  // ============================================================*

  Future<void> _loadUser() async {
    try {
      final user = await ApiService.getUser(widget.userId);

      if (!mounted) return;

      setState(() {
        _userName = user['full_name']?.toString() ?? 'User';

        _phone = user['phone']?.toString() ?? '';

        _email = user['email']?.toString() ?? '';

        _currency = user['currency']?.toString() ?? 'INR';

        _isLoading = false;
      });
    } catch (error) {
      debugPrint('More screen user error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================*

  // PROFILE*

  // ============================================================*

  Future<void> _openProfile() async {
    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => _EditProfileScreen(
          userId: widget.userId,

          userName: _userName,

          phone: _phone,

          email: _email,

          currency: _currency,
        ),
      ),
    );

    if (!mounted) return;

    await _loadUser();
  }

  // ============================================================*

  // EMI*

  // ============================================================*

  void _openEmiScreen() {
    Navigator.push(
      context,

      MaterialPageRoute(builder: (_) => EmiScreen(userId: widget.userId)),
    );
  }

  // ============================================================*

  // BORROW & LEND*

  // ============================================================*

  Future<void> _openBorrowLend() async {
    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => BorrowLendScreen(userId: widget.userId),
      ),
    );
  }

  // ============================================================*

  // BILLS*

  // ============================================================*

  void _openBills() {
    Navigator.push(
      context,

      MaterialPageRoute(builder: (_) => BillsScreen(userId: widget.userId)),
    );
  }

  // ============================================================*

  // CATEGORIES*

  // ============================================================*

  void _openCategories() {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => CategoriesScreen(userId: widget.userId),
      ),
    );
  }

  // ============================================================*

  // REPORTS*

  // ============================================================*

  void _openReports() {
    Navigator.push(
      context,

      MaterialPageRoute(builder: (_) => ReportsScreen(userId: widget.userId)),
    );
  }

  // ============================================================*

  // NOTIFICATIONS*

  // ============================================================*

  void _openNotifications() {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => NotificationsScreen(userId: widget.userId),
      ),
    );
  }

  // ============================================================*

  // SETTINGS*

  // ============================================================*

  void _openSettings() {
    Navigator.push(
      context,

      MaterialPageRoute(builder: (_) => SettingsScreen(userId: widget.userId)),
    );
  }

  // ============================================================*

  // HELP & SUPPORT*

  // ============================================================*

  void _openHelpSupport() {
    Navigator.push(
      context,

      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
    );
  }

  // ============================================================*

  // LOGOUT*

  // ============================================================*

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('userId');

      await prefs.remove('isLoggedIn');

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),

        (route) => false,
      );
    } catch (error) {
      debugPrint('Logout error: $error');

      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
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

            style: TextStyle(color: AppColors.textSecondary),
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

                _logout();
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

  // ============================================================*

  // BUILD*

  // ============================================================*

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildHeader(),

              const SizedBox(height: 28),

              _buildProfileCard(),

              const SizedBox(height: 28),

              _buildSectionTitle('Manage'),

              const SizedBox(height: 12),

              // ==================================================*

              // EMI & LOANS*

              // ==================================================*
              _buildMenuItem(
                icon: Icons.credit_card_rounded,

                iconBackground: const Color(0xFFF4EAFE),

                iconColor: const Color(0xFF8E5AD9),

                title: 'EMIs & Loans',

                subtitle: 'Manage your active EMIs',

                onTap: _openEmiScreen,
              ),

              // ==================================================*

              // BORROW & LEND*

              // ==================================================*
              _buildMenuItem(
                icon: Icons.handshake_rounded,

                iconBackground: const Color(0xFFFFF3DE),

                iconColor: AppColors.warning,

                title: 'Borrow & Lend',

                subtitle: 'Track money you owe or are owed',

                onTap: _openBorrowLend,
              ),

              // ==================================================*

              // BILLS & PAYMENTS*

              // ==================================================*
              _buildMenuItem(
                icon: Icons.receipt_long_rounded,

                iconBackground: const Color(0xFFE8F0FF),

                iconColor: AppColors.info,

                title: 'Bills & Payments',

                subtitle: 'Manage recurring payments',

                onTap: _openBills,
              ),

              // ==================================================*

              // CATEGORIES*

              // ==================================================*
              _buildMenuItem(
                icon: Icons.category_rounded,

                iconBackground: AppColors.primaryLight,

                iconColor: AppColors.primary,

                title: 'Categories',

                subtitle: 'Customize your expense categories',

                onTap: _openCategories,
              ),

              const SizedBox(height: 26),

              // ==================================================*

              // INSIGHTS*

              // ==================================================*
              _buildSectionTitle('Insights'),

              const SizedBox(height: 12),

              _buildMenuItem(
                icon: Icons.bar_chart_rounded,

                iconBackground: const Color(0xFFE8F5E9),

                iconColor: AppColors.income,

                title: 'Reports',

                subtitle: 'Understand your spending',

                onTap: _openReports,
              ),

              const SizedBox(height: 26),

              // ==================================================*

              // APP*

              // ==================================================*
              _buildSectionTitle('App'),

              const SizedBox(height: 12),

              // Notifications*
              _buildMenuItem(
                icon: Icons.notifications_none_rounded,

                iconBackground: const Color(0xFFFFE9E9),

                iconColor: AppColors.expense,

                title: 'Notifications',

                subtitle: 'Manage reminders and alerts',

                onTap: _openNotifications,
              ),

              // Settings*
              _buildMenuItem(
                icon: Icons.settings_outlined,

                iconBackground: const Color(0xFFF1F1F1),

                iconColor: AppColors.textSecondary,

                title: 'Settings',

                subtitle: 'App preferences and security',

                onTap: _openSettings,
              ),

              // Help & Support*
              _buildMenuItem(
                icon: Icons.help_outline_rounded,

                iconBackground: const Color(0xFFE8F0FF),

                iconColor: AppColors.info,

                title: 'Help & Support',

                subtitle: 'Get help with DueMate',

                onTap: _openHelpSupport,
              ),

              const SizedBox(height: 14),

              // ==================================================*

              // LOGOUT*

              // ==================================================*
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================*

  // HEADER*

  // ============================================================*

  Widget _buildHeader() {
    return const Text(
      'More',

      style: TextStyle(
        color: AppColors.textPrimary,

        fontSize: 30,

        fontWeight: FontWeight.w700,

        letterSpacing: -0.6,
      ),
    );
  }

  // ============================================================*

  // PROFILE CARD*

  // ============================================================*

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: _isLoading ? null : _openProfile,

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: AppColors.surface,

          borderRadius: BorderRadius.circular(22),

          border: Border.all(color: AppColors.border),
        ),

        child: Row(
          children: [
            Container(
              width: 56,

              height: 56,

              decoration: const BoxDecoration(
                color: AppColors.primaryLight,

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.person_rounded,

                color: AppColors.primary,

                size: 30,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    _isLoading ? 'Loading...' : _userName,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: AppColors.textPrimary,

                      fontSize: 16,

                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _phone.isNotEmpty ? _phone : 'Manage your profile',

                    style: const TextStyle(
                      color: AppColors.textSecondary,

                      fontSize: 12,
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

  // ============================================================*

  // SECTION TITLE*

  // ============================================================*

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

  // ============================================================*

  // MENU ITEM*

  // ============================================================*

  Widget _buildMenuItem({
    required IconData icon,

    required Color iconBackground,

    required Color iconColor,

    required String title,

    required String subtitle,

    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(18),

          onTap: onTap,

          child: Container(
            padding: const EdgeInsets.all(14),

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

                    borderRadius: BorderRadius.circular(13),
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

                const Icon(
                  Icons.chevron_right_rounded,

                  color: AppColors.textMuted,

                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================*

  // LOGOUT BUTTON*

  // ============================================================*

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,

      height: 52,

      child: OutlinedButton.icon(
        onPressed: _isLoggingOut ? null : _showLogoutDialog,

        icon: _isLoggingOut
            ? const SizedBox(
                width: 18,

                height: 18,

                child: CircularProgressIndicator(
                  strokeWidth: 2,

                  color: AppColors.expense,
                ),
              )
            : const Icon(
                Icons.logout_rounded,

                color: AppColors.expense,

                size: 19,
              ),

        label: Text(
          _isLoggingOut ? 'Logging out...' : 'Log out',

          style: const TextStyle(
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

// ============================================================================*

// EDIT PROFILE SCREEN*

// ============================================================================*

class _EditProfileScreen extends StatefulWidget {
  final int userId;

  final String userName;

  final String phone;

  final String email;

  final String currency;

  const _EditProfileScreen({
    required this.userId,

    required this.userName,

    required this.phone,

    required this.email,

    required this.currency,
  });

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late final TextEditingController _nameController;

  late final TextEditingController _phoneController;

  late final TextEditingController _emailController;

  late String _selectedCurrency;

  bool _isSaving = false;

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.userName);

    _phoneController = TextEditingController(text: widget.phone);

    _emailController = TextEditingController(text: widget.email);

    _selectedCurrency = _currencies.contains(widget.currency)
        ? widget.currency
        : 'INR';
  }

  @override
  void dispose() {
    _nameController.dispose();

    _phoneController.dispose();

    _emailController.dispose();

    super.dispose();
  }

  // ============================================================*

  // SAVE PROFILE*

  // ============================================================*

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));

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

        currency: _selectedCurrency,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $error')),
      );
    }
  }

  // ============================================================*

  // BUILD*

  // ============================================================*

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Edit Profile',

          style: TextStyle(fontWeight: FontWeight.w700),
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

              _buildCurrencyField(),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,

                height: 54,

                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,

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

  // ============================================================*

  // TEXT FIELD*

  // ============================================================*

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

  // ============================================================*

  // CURRENCY*

  // ============================================================*

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
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedCurrency = value;
                  });
                },
        ),
      ],
    );
  }
}
