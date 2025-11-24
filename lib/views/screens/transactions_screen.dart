import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/transaction_list_item.dart';

class TransactionsScreen extends StatefulWidget {
  static const String routeName = '/transactions';

  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Balance'),
            Tab(text: 'Last week'),
            Tab(text: 'This week'),
            Tab(text: 'Future'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (_) => const _TransactionsTabContent()),
      ),
    );
  }
}

class _TransactionsTabContent extends StatelessWidget {
  const _TransactionsTabContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inflow',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  SizedBox(height: 4),
                  Text('0',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outflow',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  SizedBox(height: 4),
                  Text('-500,000',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Balance',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  SizedBox(height: 4),
                  Text('-500,000',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: navigate to reports for this period.
              },
              child: const Text('View report for this period'),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '24 Today',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: TransactionListItem(
                  title: 'Health & Fitness',
                  subtitle: 'Health & Fitness',
                  amount: '500,000',
                  icon: Icons.health_and_safety,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
