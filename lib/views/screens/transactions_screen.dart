// lib/views/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:money_manage/models/transaction.dart';
import 'package:money_manage/services/transaction_service.dart';
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
  late final List<String> _timeFilters;
  late String _selectedFilter;

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
    
    // Initialize time filters based on current date
    final now = DateTime.now();
    final currentMonth = '${now.month.toString().padLeft(2, '0')}/${now.year}';
    
    // Calculate previous month
    DateTime prevMonth = DateTime(now.year, now.month - 1, 1);
    final previousMonth = '${prevMonth.month.toString().padLeft(2, '0')}/${prevMonth.year}';
    
    // Set the filters with dynamic months
    _timeFilters = [
      'Tháng này ($currentMonth)',
      'Tháng trước ($previousMonth)',
      '09/2025'  // Fixed date as per requirement
    ];
    _selectedFilter = _timeFilters[0];
    
    _loadTransactions();
    // Apply this month's filter by default
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyFilter(_timeFilters[0]);
      });
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
      final transactions = await TransactionService.getUserTransactions();
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading transactions: $e');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      final now = DateTime.now();
      
      if (filter.startsWith('Tháng này')) {
        _filteredTransactions = _transactions.where((transaction) {
          final transactionDate = transaction.date;
          return transactionDate.year == now.year && transactionDate.month == now.month;
        }).toList();
      } else if (filter.startsWith('Tháng trước')) {
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        _filteredTransactions = _transactions.where((transaction) {
          final transactionDate = transaction.date;
          return transactionDate.year == prevMonth.year && transactionDate.month == prevMonth.month;
        }).toList();
      } else if (filter == '09/2025') {
        _filteredTransactions = _transactions.where((transaction) {
          final transactionDate = transaction.date;
          return transactionDate.year == 2025 && transactionDate.month == 9;
        }).toList();
      }
      
      // Sort by date in descending order (newest first)
      _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao dịch'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: List.generate(_timeFilters.length, (index) {
                    final isSelected = _selectedFilter == _timeFilters[index];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _applyFilter(_timeFilters[index]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            _timeFilters[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
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
            Text('Lỗi: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransactions,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Center(child: Text('Không có giao dịch nào trong $_selectedFilter.')),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = _filteredTransactions[index];
          final formattedDate = DateFormat('dd/MM/yyyy').format(transaction.date);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpandableNotifier(
              child: Column(
                children: <Widget>[
                  // Header (always visible)
                  ListTile(
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
                      transaction.categoryName ?? 'Giao dịch',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_isIncome(transaction) ? '+' : '-'} ${_formatCurrency(transaction.amount.abs())}',
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
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      ExpandableController.of(context)?.toggle();
                    },
                  ),
                  
                  // Expandable section
                  Expandable(
                    collapsed: const SizedBox.shrink(),
                    expanded: _buildTransactionDetails(transaction, formattedDate),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionDetails(Transaction transaction, String formattedDate) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          
          if (transaction.note?.isNotEmpty ?? false) ...[
            _buildDetailRow('Ghi chú', transaction.note!),
            const SizedBox(height: 8),
          ],
          
          if (transaction.walletName?.isNotEmpty ?? false)
            _buildDetailRow('Ví', transaction.walletName!),
          
          if (transaction.image != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              'Hóa đơn', 
              'Có đính kèm',
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

  Widget _buildDetailRow(String label, String value, {IconData? icon, Color? iconColor}) {
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