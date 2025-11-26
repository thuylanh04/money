import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_theme.dart';
import 'transaction_view_screen.dart';

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

class _TransactionsTabContent extends StatefulWidget {
  const _TransactionsTabContent();

  @override
  State<_TransactionsTabContent> createState() => _TransactionsTabContentState();
}

class _TransactionsTabContentState extends State<_TransactionsTabContent> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _error = '';
  
  // Group transactions by category
  Map<String, List<Transaction>> get _groupedTransactions {
    final Map<String, List<Transaction>> result = {};
    
    for (var transaction in _transactions) {
      final category = transaction.categoryIdFE ?? 'Uncategorized';
      if (!result.containsKey(category)) {
        result[category] = [];
      }
      result[category]!.add(transaction);
    }
    
    // Calculate total amount for each category and sort by amount (descending)
    final sortedKeys = result.keys.toList()
      ..sort((a, b) {
        final aTotal = result[a]!.fold<double>(0, (sum, t) => sum + t.amount.abs());
        final bTotal = result[b]!.fold<double>(0, (sum, t) => sum + t.amount.abs());
        return bTotal.compareTo(aTotal);
      });
    
    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, result[key]!)),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final transactions = await TransactionService.getTransactions();
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load transactions. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // Helper methods for total income and expense (kept for potential future use)
  double get _totalIncome {
    return _transactions
        .where((t) => t.amount > 0)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get _totalExpense {
    return _transactions
        .where((t) => t.amount < 0)
        .fold(0, (sum, t) => sum + t.amount);
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransactions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _groupedTransactions.length,
        itemBuilder: (context, index) {
          final category = _groupedTransactions.keys.elementAt(index);
          final transactions = _groupedTransactions[category]!;
          final totalAmount = transactions.fold<double>(
            0,
            (sum, t) => sum + t.amount,
          );
          final isExpense = totalAmount < 0;
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              title: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: Text(
                '${isExpense ? '-' : ''}${_formatCurrency(totalAmount.abs())} VND',
                style: TextStyle(
                  color: isExpense ? AppTheme.errorRed : AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return ListTile(
                      title: Text(
                        '${transaction.note ?? 'No description'} • ${DateFormat('MMM d, y').format(transaction.date)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: Text(
                        '${transaction.amount < 0 ? '-' : ''}${_formatCurrency(transaction.amount.abs())} VND',
                        style: TextStyle(
                          color: transaction.amount < 0 ? AppTheme.errorRed : AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionViewScreen(transaction: transaction),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
