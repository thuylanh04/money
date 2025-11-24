import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Transaction detail / Add transaction screen.
/// Layout được phỏng đoán dựa trên screenshot "Add transaction".
class TransactionDetailScreen extends StatefulWidget {
  static const String routeName = '/transaction-detail';

  const TransactionDetailScreen({super.key});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isTablet = media.size.width > 600;
    final horizontalPadding = isTablet ? media.size.width * 0.08 : 16.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add transaction'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
            Tab(text: 'Debt/Loan'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
              child: Column(
                children: [
                  _RowItem(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: 'Cash',
                    subtitle: 'Wallet',
                  ),
                  const SizedBox(height: 12),
                  const _AmountField(),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.category_outlined),
                    title: 'Select category',
                    subtitle: 'Tap to choose',
                    showChevron: true,
                    onTap: () {
                      // TODO: open select category screen.
                    },
                  ),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.notes_outlined),
                    title: 'Write note',
                    subtitle: 'Optional',
                  ),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: 'Monday, 24/11/2025',
                    subtitle: 'Date',
                    showChevron: true,
                  ),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.person_outline),
                    title: 'With',
                    subtitle: 'None',
                    showChevron: true,
                  ),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.event_outlined),
                    title: 'Select event',
                    subtitle: 'No event',
                    showChevron: true,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: false,
                    onChanged: (_) {},
                    title: const Text('Exclude from report'),
                    subtitle: const Text(
                      'Don\'t include this transaction in reports such as Overview.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          const _CalculatorPad(),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final bool showChevron;
  final VoidCallback? onTap;

  const _RowItem({
    required this.leading,
    required this.title,
    this.subtitle,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron) const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      decoration: const InputDecoration(
        prefixText: 'USD ',
        border: UnderlineInputBorder(),
      ),
    );
  }
}

class _CalculatorPad extends StatelessWidget {
  const _CalculatorPad();

  @override
  Widget build(BuildContext context) {
    final buttons = [
      '7', '8', '9', 'C',
      '4', '5', '6', '+',
      '1', '2', '3', '-',
      '0', '00', '.', '>',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.3,
            ),
            itemCount: buttons.length,
            itemBuilder: (context, index) {
              final label = buttons[index];
              final isAction = ['C', '+', '-', '>'].contains(label);
              final isPrimary = label == '>';
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPrimary ? AppTheme.primaryGreen : Colors.grey.shade100,
                  foregroundColor: isPrimary ? Colors.white : Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {},
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isAction ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
