import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'wallets_screen.dart';
import 'categories_screen.dart';
import 'bills_screen.dart';

/// Account screen placeholder based on reference design (avatar, email, menu list).
class AccountScreen extends StatelessWidget {
  static const String routeName = '/account';

  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthRepository().currentUser;
    final email = currentUser?.email ?? '';
    final avatarText = (email.isNotEmpty ? email[0] : 'U').toUpperCase();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 32,
            child: Text(avatarText),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('Free account')),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(child: Text(email)),
          ],
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('My Wallets'),
            onTap: () {
              Navigator.of(context).pushNamed(WalletsScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categories'),
            onTap: () {
              Navigator.of(context).pushNamed(CategoriesScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Bills'),
            onTap: () {
              Navigator.of(context).pushNamed(BillsScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pushNamed(SettingsScreen.routeName);
            },
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sign out'),
            subtitle: email.isNotEmpty ? Text(email) : null,
            onTap: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                LoginScreen.routeName,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
