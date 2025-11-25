import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Settings screen UI phỏng theo screenshot: nhiều section với các tuỳ chọn và switch.
class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _excludeFromReport = true;
  bool _alwaysShowDetails = false;
  bool _notificationsTone = true;
  bool _usingLocation = false;
  bool _keypadVibration = true;
  bool _wifiOnlySync = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SectionHeader('Display'),
          const SizedBox(height: 4),
          const _SimpleTile(title: 'Theme', value: 'Light'),
          const _SimpleTile(title: 'Select language', value: 'English'),
          const _SimpleTile(title: 'Currency for Total Wallet', value: 'USD'),
          const _SimpleTile(title: 'Select date format', value: '25/11/2025'),
          const _SimpleTile(title: 'Set first day of week', value: 'Monday'),
          const _SimpleTile(title: 'Set first day of the month', value: '1st'),
          const _SimpleTile(title: 'Set future period', value: '3 months'),
          SwitchListTile(
            value: _excludeFromReport,
            onChanged: (v) => setState(() => _excludeFromReport = v),
            title: const Text('Exclude from report'),
            subtitle: const Text(
              'Enable option Exclude from report in Add Transaction and Edit Transaction.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          SwitchListTile(
            value: _alwaysShowDetails,
            onChanged: (v) => setState(() => _alwaysShowDetails = v),
            title: const Text('Always show details transaction'),
          ),
          const SizedBox(height: 16),
          _SectionHeader('Notifications'),
          const SizedBox(height: 4),
          SwitchListTile(
            value: _notificationsTone,
            onChanged: (v) => setState(() => _notificationsTone = v),
            title: const Text('Notifications tone'),
            subtitle: const Text(
              'Play sounds for notifications',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader('System'),
          const SizedBox(height: 4),
          const _SimpleTile(title: 'Enable password', value: 'Not set'),
          SwitchListTile(
            value: _usingLocation,
            onChanged: (v) => setState(() => _usingLocation = v),
            title: const Text('Using location'),
          ),
          SwitchListTile(
            value: _keypadVibration,
            onChanged: (v) => setState(() => _keypadVibration = v),
            title: const Text('Enable numeric keypad vibration'),
          ),
          const SizedBox(height: 16),
          _SectionHeader('Database'),
          const SizedBox(height: 4),
          SwitchListTile(
            value: _wifiOnlySync,
            onChanged: (v) => setState(() => _wifiOnlySync = v),
            title: const Text('Auto sync over Wi-Fi only'),
            subtitle: const Text('Last update: 2 minutes ago',
                style: TextStyle(fontSize: 12)),
          ),
          const _SimpleTile(
            title: 'Tap to update exchange rate',
            value: '16 hours ago',
          ),
          const SizedBox(height: 16),
          _SectionHeader('About'),
          const SizedBox(height: 4),
          const _SimpleTile(title: 'Walkthrough', value: ''),
          const _SimpleTile(title: 'About Money — Finwise', value: ''),
          const SizedBox(height: 24),
          const Text(
            'demo@finwise.app',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.primaryGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  final String title;
  final String value;

  const _SimpleTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: value.isEmpty
          ? null
          : Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
    );
  }
}
