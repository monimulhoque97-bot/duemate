import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildLogo(),
              const Spacer(),
              _buildIllustration(),
              const SizedBox(height: 42),
              const Text(
                'Everything about your\nmoney, organized.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Track expenses, manage EMIs, remember payments, '
                'and keep your important things in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
              const Spacer(),
              _buildGetStartedButton(context),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'I already have an account',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'DueMate',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 245,
            height: 245,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            top: 12,
            left: 34,
            child: _buildSmallCard(
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFFEAF7F1),
            ),
          ),
          Positioned(
            top: 45,
            right: 24,
            child: _buildSmallCard(
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFFFFF3DE),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 25,
            child: _buildSmallCard(
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFE8F0FF),
            ),
          ),
          Positioned(
            bottom: 18,
            right: 38,
            child: _buildSmallCard(
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFFF4EAFE),
            ),
          ),
          Container(
            width: 142,
            height: 178,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Available',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                const Text(
                  '₹25,000',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.income,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'On track',
                      style: TextStyle(
                        color: AppColors.income,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard({required IconData icon, required Color color}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primary, size: 19),
        ),
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        },
        child: const Text('Get Started'),
      ),
    );
  }
}
