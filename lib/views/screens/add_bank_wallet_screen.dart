import 'package:flutter/material.dart';
import 'bank_wallet_screen.dart';

class AddBankWalletScreen extends StatefulWidget {
  const AddBankWalletScreen({Key? key}) : super(key: key);

  @override
  State<AddBankWalletScreen> createState() => _AddBankWalletScreenState();
}

class _AddBankWalletScreenState extends State<AddBankWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();
  String _cardType = 'Checking';
  bool _isConnecting = false;

  void _connectBank() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isConnecting = true);

    // Mock delay để simulate kết nối
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isConnecting = false);

      // Navigate to BankWalletScreen với dữ liệu mock
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BankWalletScreen(
            walletName: _bankController.text,
            accountNumber: _accountController.text,
            balance: 1250000, // mock balance
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Bank Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _bankController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  hintText: 'e.g., Vietcombank',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter bank name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  hintText: '123456789',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter account number' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _cardType,
                decoration: const InputDecoration(labelText: 'Card Type'),
                items: const [
                  DropdownMenuItem(value: 'Checking', child: Text('Checking')),
                  DropdownMenuItem(value: 'Savings', child: Text('Savings')),
                ],
                onChanged: (v) => setState(() => _cardType = v!),
              ),
              const SizedBox(height: 24),
              _isConnecting
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _connectBank,
                      icon: const Icon(Icons.link),
                      label: const Text('Connect Bank'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
