import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/placeholder_chart.dart';

class ReportsScreen extends StatelessWidget {
  static const String routeName = '/reports';

  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final periods = ['This month', 'Last month', '3 months'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final isSelected = index == 0;
                  return ChoiceChip(
                    label: Text(periods[index]),
                    selected: isSelected,
                    onSelected: (_) {},
                    selectedColor: AppTheme.primaryGreen.withOpacity(0.1),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: periods.length,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                _SummaryCard(
                  title: 'Total spent',
                  amount: '500,000',
                  color: Colors.redAccent,
                ),
                SizedBox(width: 12),
                _SummaryCard(
                  title: 'Total income',
                  amount: '0',
                  color: AppTheme.primaryGreen,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const PlaceholderChart(),
            const SizedBox(height: 12),
            const Text(
              'Trending report',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
