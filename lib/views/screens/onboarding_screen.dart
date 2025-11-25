import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Onboarding screen layout được phỏng đoán dựa trên thiết kế Money Lover:
/// - Header logo + language pill
/// - Card hiển thị "Saved this month" và các mục tiêu
/// - Text mô tả + indicator + button Sign up / link Sign in.
class OnboardingScreen extends StatelessWidget {
  static const String routeName = '/onboarding';

  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isTablet ? width * 0.15 : 24.0;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.savings, color: AppTheme.primaryGreen),
                            SizedBox(width: 8),
                            Text(
                              'Money — Finwise',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFE8F5E9),
                          ),
                          child: const Text(
                            'ENGLISH',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: constraints.maxHeight * 0.08),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saved this month',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                '840',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(width: 8),
                              Chip(
                                label: Text('+15%'),
                                backgroundColor: Color(0xFFE8F5E9),
                                labelStyle: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SavingCard(
                      title: 'New phone',
                      amount: '+320',
                    ),
                    const SizedBox(height: 8),
                    _SavingCard(
                      title: 'Saving account',
                      amount: '+520',
                    ),
                    SizedBox(height: constraints.maxHeight * 0.1),
                    const Center(
                      child: Text(
                        'Keep your savings grow every month',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: _PageIndicator(activeIndex: 2, total: 5),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.06),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed(SignUpScreen.routeName);
                        },
                        child: const Text('SIGN UP FOR FREE'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed(LoginScreen.routeName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                        child: const Text('SIGN IN'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SavingCard extends StatelessWidget {
  final String title;
  final String amount;

  const _SavingCard({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int activeIndex;
  final int total;

  const _PageIndicator({required this.activeIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryGreen : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
