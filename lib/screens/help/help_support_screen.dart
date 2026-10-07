import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I add a transaction?',

      'answer':
          'Open the Transactions section and tap the add button. Select whether the transaction is an income or expense, enter the amount and other details, then save it.',
    },

    {
      'question': 'How do I manage my bills?',

      'answer':
          'Open More and select Bills & Payments. From there you can add, edit, view and manage your recurring bills.',
    },

    {
      'question': 'How do I manage EMIs?',

      'answer':
          'Open More and select EMIs & Loans. You can add your EMI details and keep track of payments and remaining amounts.',
    },

    {
      'question': 'How do I track borrowed money?',

      'answer':
          'Open More and select Borrow & Lend. You can record money you borrowed or lent and keep track of the outstanding amount.',
    },

    {
      'question': 'How do I change my currency?',

      'answer':
          'Open More → Settings and select your preferred currency under Preferences.',
    },

    {
      'question': 'How do I edit my profile?',

      'answer':
          'Open More → Settings or tap your profile card in the More section. You can update your name, phone number, email and currency.',
    },

    {
      'question': 'Where can I see my spending reports?',

      'answer':
          'Open More → Reports. You can view spending by category along with monthly and weekly financial information.',
    },

    {
      'question': 'How do I manage notifications?',

      'answer':
          'Open More → Notifications. You can view notifications, mark them as read and delete notifications.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _faqs;
    }

    return _faqs.where((faq) {
      final question = faq['question']?.toLowerCase() ?? '';

      final answer = faq['answer']?.toLowerCase() ?? '';

      return question.contains(query) || answer.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================*

  // CONTACT SUPPORT*

  // ============================================================*

  void _contactSupport() {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),

          decoration: const BoxDecoration(
            color: AppColors.surface,

            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),

          child: SafeArea(
            top: false,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Center(
                  child: Container(
                    width: 42,

                    height: 4,

                    decoration: BoxDecoration(
                      color: AppColors.border,

                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Contact Support',

                  style: TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: 19,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Choose how you would like to get help.',

                  style: TextStyle(
                    color: AppColors.textSecondary,

                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 20),

                _buildContactOption(
                  icon: Icons.email_outlined,

                  title: 'Email Support',

                  subtitle: 'Send us an email with your issue',

                  onTap: () {
                    Navigator.pop(sheetContext);

                    _showEmailSupport();
                  },
                ),

                const SizedBox(height: 10),

                _buildContactOption(
                  icon: Icons.chat_bubble_outline_rounded,

                  title: 'Send Feedback',

                  subtitle: 'Tell us how we can improve DueMate',

                  onTap: () {
                    Navigator.pop(sheetContext);

                    _showFeedbackDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactOption({
    required IconData icon,

    required String title,

    required String subtitle,

    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.background,

      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(16),

        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Row(
            children: [
              Container(
                width: 44,

                height: 44,

                decoration: BoxDecoration(
                  color: AppColors.primaryLight,

                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(icon, color: AppColors.primary, size: 21),
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

                        fontSize: 13,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,

                      style: const TextStyle(
                        color: AppColors.textSecondary,

                        fontSize: 10,
                      ),
                    ),
                  ],
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
    );
  }

  void _showEmailSupport() {
    showDialog<void>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,

          title: const Text(
            'Email Support',

            style: TextStyle(
              color: AppColors.textPrimary,

              fontWeight: FontWeight.w700,
            ),
          ),

          content: const Text(
            'To contact DueMate support, send your issue and relevant details to your support email address.',

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

  // ============================================================*

  // FEEDBACK*

  // ============================================================*

  void _showFeedbackDialog() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,

          title: const Text(
            'Send Feedback',

            style: TextStyle(
              color: AppColors.textPrimary,

              fontWeight: FontWeight.w700,
            ),
          ),

          content: TextField(
            controller: controller,

            maxLines: 5,

            decoration: const InputDecoration(
              hintText: 'Tell us what you think...',

              alignLabelWithHint: true,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                controller.dispose();

                Navigator.pop(dialogContext);
              },

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  return;
                }

                controller.dispose();

                Navigator.pop(dialogContext);

                _showMessage('Thank you for your feedback.');
              },

              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================*

  // FAQ*

  // ============================================================*

  void _openFaq(Map<String, String> faq) {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),

          decoration: const BoxDecoration(
            color: AppColors.surface,

            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),

          child: SafeArea(
            top: false,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Center(
                  child: Container(
                    width: 42,

                    height: 4,

                    decoration: BoxDecoration(
                      color: AppColors.border,

                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  faq['question'] ?? 'Question',

                  style: const TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: 18,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  faq['answer'] ?? '',

                  style: const TextStyle(
                    color: AppColors.textSecondary,

                    fontSize: 13,

                    height: 1.55,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,

                  height: 48,

                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },

                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================*

  // MESSAGE*

  // ============================================================*

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================*

  // BUILD*

  // ============================================================*

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,

        elevation: 0,

        title: const Text(
          'Help & Support',

          style: TextStyle(
            color: AppColors.textPrimary,

            fontSize: 20,

            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _buildHeader(),

            const SizedBox(height: 22),

            _buildSearch(),

            const SizedBox(height: 24),

            _buildQuickSupport(),

            const SizedBox(height: 28),

            _buildSectionTitle('Frequently asked questions'),

            const SizedBox(height: 12),

            if (faqs.isEmpty)
              _buildNoResults()
            else
              ...faqs.map(
                (faq) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),

                  child: _buildFaqCard(faq),
                ),
              ),

            const SizedBox(height: 22),

            _buildSectionTitle('More help'),

            const SizedBox(height: 12),

            _buildMoreHelpCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================*

  // HEADER*

  // ============================================================*

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'How can we help?',

          style: TextStyle(
            color: AppColors.textPrimary,

            fontSize: 25,

            fontWeight: FontWeight.w700,

            letterSpacing: -0.5,
          ),
        ),

        SizedBox(height: 6),

        Text(
          'Find answers or get help with DueMate.',

          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  // ============================================================*

  // SEARCH*

  // ============================================================*

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,

      decoration: InputDecoration(
        hintText: 'Search help articles...',

        prefixIcon: const Icon(Icons.search_rounded),

        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },

                icon: const Icon(Icons.close_rounded),
              )
            : null,
      ),
    );
  }

  // ============================================================*

  // QUICK SUPPORT*

  // ============================================================*

  Widget _buildQuickSupport() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.primary,

        borderRadius: BorderRadius.circular(22),
      ),

      child: Row(
        children: [
          Container(
            width: 48,

            height: 48,

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),

              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.support_agent_rounded,

              color: Colors.white,

              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Need more help?',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 14,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Contact the DueMate support team.',

                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: _contactSupport,

            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.14),
            ),

            icon: const Icon(
              Icons.arrow_forward_rounded,

              color: Colors.white,

              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================*

  // FAQ CARD*

  // ============================================================*

  Widget _buildFaqCard(Map<String, String> faq) {
    return Material(
      color: AppColors.surface,

      borderRadius: BorderRadius.circular(17),

      child: InkWell(
        onTap: () => _openFaq(faq),

        borderRadius: BorderRadius.circular(17),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),

          child: Row(
            children: [
              Container(
                width: 38,

                height: 38,

                decoration: BoxDecoration(
                  color: AppColors.primaryLight,

                  borderRadius: BorderRadius.circular(11),
                ),

                child: const Icon(
                  Icons.question_mark_rounded,

                  color: AppColors.primary,

                  size: 18,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  faq['question'] ?? '',

                  style: const TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: 12,

                    fontWeight: FontWeight.w700,
                  ),
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
      ),
    );
  }

  // ============================================================*

  // NO RESULTS*

  // ============================================================*

  Widget _buildNoResults() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: AppColors.border),
      ),

      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 32),

          SizedBox(height: 10),

          Text(
            'No results found',

            style: TextStyle(
              color: AppColors.textPrimary,

              fontSize: 14,

              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Try searching with different words.',

            textAlign: TextAlign.center,

            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================*

  // MORE HELP*

  // ============================================================*

  Widget _buildMoreHelpCard() {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        children: [
          _buildMoreHelpItem(
            icon: Icons.email_outlined,

            title: 'Contact support',

            subtitle: 'Get assistance with your account',

            onTap: _contactSupport,
          ),

          const Divider(height: 1, indent: 66, color: AppColors.border),

          _buildMoreHelpItem(
            icon: Icons.feedback_outlined,

            title: 'Send feedback',

            subtitle: 'Share suggestions with us',

            onTap: _showFeedbackDialog,
          ),

          const Divider(height: 1, indent: 66, color: AppColors.border),

          _buildMoreHelpItem(
            icon: Icons.info_outline_rounded,

            title: 'About DueMate',

            subtitle: 'Version 1.0.0',

            onTap: () {
              showAboutDialog(
                context: context,

                applicationName: 'DueMate',

                applicationVersion: '1.0.0',

                applicationIcon: const Icon(
                  Icons.account_balance_wallet_rounded,

                  color: AppColors.primary,

                  size: 35,
                ),

                children: const [
                  Text(
                    'DueMate is a personal finance management application for tracking your money, bills, EMIs, debts and spending.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMoreHelpItem({
    required IconData icon,

    required String title,

    required String subtitle,

    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          children: [
            Container(
              width: 40,

              height: 40,

              decoration: BoxDecoration(
                color: AppColors.background,

                borderRadius: BorderRadius.circular(11),
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

  // ============================================================*

  // SECTION TITLE*

  // ============================================================*

  Widget _buildSectionTitle(String title) {
    return Text(
      title,

      style: const TextStyle(
        color: AppColors.textPrimary,

        fontSize: 16,

        fontWeight: FontWeight.w700,
      ),
    );
  }
}
