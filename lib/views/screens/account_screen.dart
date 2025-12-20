import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/auth_repository.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'wallets_screen.dart';
import 'settings_screen.dart';
import '../../theme/app_theme.dart';
import 'bank_wallet_screen.dart';
import 'add_bank_wallet_screen.dart';

class AccountScreen extends StatefulWidget {
  static const String routeName = '/account';

  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _displayEmail(String raw) {
    final match = RegExp(
      r'[a-zA-Z0-9._%+-]+@gmail\.com',
    ).firstMatch(raw);

    return match?.group(0) ?? '';
  }

  String _email = '';
  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      setState(() {
        _email = authProvider.currentUser?.email ?? '';
        _username = authProvider.currentUser?.name ?? 'User';
      });
    } else {
      // If no user is logged in, try to load just the email from storage
      StorageService.getEmail().then((email) {
        if (email != null && email.isNotEmpty) {
          setState(() {
            _email = email;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarText = (_email.isNotEmpty ? _email[0] : 'U').toUpperCase();

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
          if (_email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _displayEmail(_email),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
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
            subtitle: _email.isNotEmpty
                ? Text(
                    _displayEmail(_email),
                    // textAlign: TextAlign.center,
                  )
                : null,
            onTap: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.clearUser();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
