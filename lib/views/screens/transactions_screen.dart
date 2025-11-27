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
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao dịch'),
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

    if (_transactions.isEmpty) {
      return const Center(child: Text('Không có giao dịch nào.'));
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          final formattedDate = DateFormat('HH:mm • dd/MM/yyyy').format(transaction.date);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpandableNotifier(
              child: Column(
                children: <Widget>[
                  // Header (always visible)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transaction.amount >= 0 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.red.withOpacity(0.1),
                      child: Icon(
                        transaction.amount >= 0 
                            ? Icons.arrow_upward 
                            : Icons.arrow_downward,
                        color: transaction.amount >= 0 
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
                    trailing: Text(
                      '${transaction.amount >= 0 ? '+' : ''}${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: transaction.amount >= 0 
                            ? Colors.green 
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  Widget _buildDetailRow(String label, String value, 
      {IconData? icon, Color iconColor = Colors.grey}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}