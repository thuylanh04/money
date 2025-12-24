// lib/views/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:money_manage/models/transaction.dart';
import 'package:money_manage/services/transaction_service.dart';
import 'transaction_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:expandable/expandable.dart';

class TransactionsScreen extends StatefulWidget {
  static const String routeName = '/transactions';

  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  String _error = '';

  // Time filter options
  late final List<Map<String, dynamic>> _timeFilters;
  late Map<String, dynamic> _selectedFilter;
  final ScrollController _scrollController = ScrollController();

  // Helper method to format currency
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  // Helper method to determine if transaction is income
  bool _isIncome(Transaction transaction) {
    return transaction.groupType == 'income';
  }

  @override
  void initState() {
    super.initState();

    // Initialize time filters with past 12 months
    final now = DateTime.now();
    _timeFilters = List.generate(12, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      final monthName = DateFormat('MMM yyyy').format(date);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      return {
        'label': monthName,
        'year': date.year,
        'month': date.month,
        'key': monthKey,
      };
    }).reversed.toList();

    // Set the current month as default
    _selectedFilter = _timeFilters.last;

    _loadTransactions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Method to scroll to the selected month in the filter bar
  void _scrollToSelectedMonth() {
    if (_scrollController.hasClients) {
      // Find the index of the current month in the filters
      final index = _timeFilters
          .indexWhere((filter) => filter['key'] == _selectedFilter['key']);
      if (index != -1) {
        // Calculate the position to scroll to
        final double itemWidth = 100.0; // Approximate width of each filter item
        final double screenWidth = MediaQuery.of(context).size.width;
        final double scrollPosition =
            (itemWidth * index) - (screenWidth / 2) + (itemWidth / 2);

        // Animate the scroll
        _scrollController.animateTo(
          scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _loadTransactions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final transactionService = TransactionService();
      final transactions = await transactionService.getUserTransactions();
      if (mounted) {
        setState(() {
          _transactions = transactions;
          // Apply the current month's filter after loading transactions
          _applyFilter(_selectedFilter);
          _isLoading = false;
        });

        // Wait for the next frame to ensure the UI is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedMonth();
        });
      }
    } catch (e) {
      print('Error loading transactions: $e');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          // Clear filtered transactions on error
          _filteredTransactions = [];
        });
      }
    }
  }

  void _applyFilter(Map<String, dynamic> filter) {
    setState(() {
      _selectedFilter = filter;
      final year = filter['year'] as int;
      final month = filter['month'] as int;

      _filteredTransactions = _transactions.where((transaction) {
        final transactionDate = transaction.date;
        return transactionDate.year == year && transactionDate.month == month;
      }).toList();

      // Sort by date in descending order (newest first)
      _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  // Add a method to handle transaction deletion
  Future<void> _deleteTransaction(Transaction transaction) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final transactionService = TransactionService();
      final success =
          await transactionService.deleteTransaction(transaction.idFE);

      if (success && mounted) {
        // Remove the transaction from the list
        setState(() {
          _transactions.removeWhere((t) => t.idFE == transaction.idFE);
          _applyFilter(_selectedFilter); // Refresh the filtered list
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete transaction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _timeFilters.length,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemBuilder: (context, index) {
                final filter = _timeFilters[index];
                final isSelected = _selectedFilter['key'] == filter['key'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: GestureDetector(
                    onTap: () => _applyFilter(filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          filter['label'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  // Helper method to group transactions by date
  Map<String, List<Transaction>> _groupTransactionsByDate() {
    final Map<String, List<Transaction>> groupedTransactions = {};

    for (final transaction in _filteredTransactions) {
      final dateKey = DateFormat('dd/MM/yyyy').format(transaction.date);

      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }

      groupedTransactions[dateKey]!.add(transaction);
    }

    // Sort the map by date in descending order (newest first)
    final sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd/MM/yyyy').parse(a);
        final dateB = DateFormat('dd/MM/yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    final sortedMap = <String, List<Transaction>>{};
    for (var key in sortedKeys) {
      sortedMap[key] = groupedTransactions[key]!;
    }

    return sortedMap;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                        'You are offline. Please check your internet connection and try again.',
                        style: const TextStyle(color: Colors.red)))),
            ElevatedButton(
              onPressed: _loadTransactions,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Center(
              child:
                  Text('No transactions found in ${_selectedFilter['label']}')),
        ],
      );
    }

    final groupedTransactions = _groupTransactionsByDate();

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: groupedTransactions.length,
        itemBuilder: (context, index) {
          final dateKey = groupedTransactions.keys.elementAt(index);
          final transactions = groupedTransactions[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              // List of transactions for this date
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (ctx, idx) {
                  final transaction = transactions[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _isIncome(transaction)
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        child: Icon(
                          _isIncome(transaction)
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: _isIncome(transaction)
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        transaction.categoryName ?? 'Transaction',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_isIncome(transaction) ? '+' : '-'}${_formatCurrency(transaction.amount.abs())}',
                            style: TextStyle(
                              color: _isIncome(transaction)
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'USD',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        // Wait for the transaction detail screen to return a result
                        final shouldRefresh =
                            await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (context) => TransactionDetailScreen(
                                transaction: transaction),
                          ),
                        );

                        // If the transaction was deleted in the detail screen, refresh the list
                        if (shouldRefresh == true) {
                          _loadTransactions();
                        }
                      },
                      onLongPress: () {
                        // Show delete confirmation on long press
                        _deleteTransaction(transaction);
                      },
                    ),
                  );
                },
              ),

              // Add some space between date groups
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionDetails(
      Transaction transaction, String formattedDate) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (transaction.note?.isNotEmpty ?? false) ...[
            _buildDetailRow('Note', transaction.note!),
            const SizedBox(height: 8),
          ],
          if (transaction.walletName?.isNotEmpty ?? false)
            _buildDetailRow('Wallet', transaction.walletName!),
          if (transaction.image != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              'Receipt',
              'Attached',
              icon: Icons.receipt,
              iconColor: Colors.blue,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'ID: ${transaction.idFE}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {IconData? icon, Color? iconColor}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: iconColor ?? Colors.grey[600]),
          const SizedBox(width: 8),
        ],
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
