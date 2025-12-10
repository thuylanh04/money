import 'package:flutter/material.dart';


import '../../repositories/auth_repository.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'settings_screen.dart';
import 'wallets_screen.dart';
import '../../theme/app_theme.dart';


/// Updated AccountScreen: removed Categories & Bills, added Profile menu.
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
              // Here you might want to call your authRepository.signOut() before navigating
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



