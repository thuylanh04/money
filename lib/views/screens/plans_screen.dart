import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PlansScreen extends StatelessWidget {
  static const String routeName = '/plans';

  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Budgets'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  size: 72,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'You have no budget',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start saving money by creating budgets and we will help you stick to it',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: navigate to create budget/plan screen.
                  },
                  child: const Text('Create a budget'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {},
                child: const Text('How to use your budget?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
