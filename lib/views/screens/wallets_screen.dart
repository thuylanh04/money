import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class WalletsScreen extends StatelessWidget {
  static const String routeName = '/wallets';

  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallets'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.account_balance_wallet_outlined),
            title: Text('Cash'),
            subtitle: Text('Default wallet'),
            trailing: Text(
              'USD 0',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.credit_card_outlined),
            title: Text('Add bank account'),
            subtitle: Text('Link a new bank or card account'),
          ),
        ],
      ),
    );
  }
}
