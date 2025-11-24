import 'package:flutter/material.dart';

/// Account screen placeholder based on reference design (avatar, email, menu list).
class AccountScreen extends StatelessWidget {
  static const String routeName = '/account';

  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CircleAvatar(
            radius: 32,
            child: Text('V'),
          ),
          SizedBox(height: 12),
          Center(child: Text('Free account')), // phỏng đoán text
          SizedBox(height: 24),
          ListTile(
            leading: Icon(Icons.account_balance_wallet_outlined),
            title: Text('My Wallets'),
          ),
          ListTile(
            leading: Icon(Icons.category_outlined),
            title: Text('Categories'),
          ),
          ListTile(
            leading: Icon(Icons.receipt_long_outlined),
            title: Text('Bills'),
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
        ],
      ),
    );
  }
}
