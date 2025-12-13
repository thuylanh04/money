import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/auth_repository.dart';
import '../../providers/settings_provider.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'wallets_screen.dart';
import 'settings_screen.dart';
import '../../theme/app_theme.dart';
import 'bank_wallet_screen.dart'; // import mới
import 'add_bank_wallet_screen.dart'; // import mới

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
            child: Text(
              avatarText,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(child: Text(email)),
          ],
          const SizedBox(height: 24),

          // My Wallets
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('My Wallets'),
            onTap: () {
              Navigator.of(context).pushNamed(WalletsScreen.routeName);
            },
          ),

          // View Bank Wallet (FE mock)

          ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.blue),
            title: const Text('Add Bank Wallet (FE mock)'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddBankWalletScreen(),
                ),
              );
            },
          ),

          // Change Password
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const ChangePasswordScreen(),
              );
            },
          ),

          // Theme
          Consumer<SettingsProvider>(
            builder: (context, settings, child) => ListTile(
              leading: const Icon(Icons.color_lens_outlined),
              title: const Text('Theme'),
              trailing: Switch(
                value: settings.isDarkMode,
                onChanged: (value) {
                  settings.toggleTheme(value);
                },
              ),
            ),
          ),

          // Language
          Consumer<SettingsProvider>(
            builder: (context, settings, child) => ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              trailing: DropdownButton<String>(
                value: settings.languageCode,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setLanguage(value);
                  }
                },
              ),
            ),
          ),

          // Currency
          Consumer<SettingsProvider>(
            builder: (context, settings, child) => ListTile(
              leading: const Icon(Icons.attach_money_outlined),
              title: const Text('Currency'),
              trailing: Text(
                settings.currency,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),

          // Date Format
          Consumer<SettingsProvider>(
            builder: (context, settings, child) => ListTile(
              leading: const Icon(Icons.date_range_outlined),
              title: const Text('Date Format'),
              trailing: DropdownButton<String>(
                value: settings.dateFormat,
                items: const [
                  DropdownMenuItem(
                      value: 'dd/MM/yyyy', child: Text('DD/MM/YYYY')),
                  DropdownMenuItem(
                      value: 'MM/dd/yyyy', child: Text('MM/DD/YYYY')),
                  DropdownMenuItem(
                      value: 'yyyy-MM-dd', child: Text('YYYY-MM-DD')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setDateFormat(value);
                  }
                },
              ),
            ),
          ),

          // Settings
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pushNamed(SettingsScreen.routeName);
            },
          ),

          const Divider(height: 32),

          // Sign out
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
