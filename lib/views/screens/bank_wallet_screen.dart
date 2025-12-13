import 'package:flutter/material.dart';

class BankWalletScreen extends StatelessWidget {
  final String walletName;
  final String accountNumber;
  final double balance;

  const BankWalletScreen({
    Key? key,
    required this.walletName,
    required this.accountNumber,
    required this.balance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock giao dịch
    final transactions = [
      {'title': 'Salary', 'amount': 5000000, 'date': '2025-12-01'},
      {'title': 'Groceries', 'amount': -800000, 'date': '2025-12-03'},
      {'title': 'Utilities', 'amount': -200000, 'date': '2025-12-05'},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(walletName)),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.blue, size: 40),
              title: Text(walletName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account: $accountNumber'),
                  Text('Balance: ${balance.toStringAsFixed(0)} ₫'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                // FE mock sync
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync clicked (FE mock)')),
                );
              },
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final amount = tx['amount'] as int;
                final isIncome = amount > 0;
                return ListTile(
                  title: Text(tx['title'] as String),
                  subtitle: Text(tx['date'] as String),
                  trailing: Text(
                    '${amount.toString()} ₫',
                    style: TextStyle(color: isIncome ? Colors.green : Colors.red),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
