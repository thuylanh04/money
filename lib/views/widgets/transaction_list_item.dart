import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class TransactionListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
        child: Icon(icon, color: AppTheme.primaryGreen),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      trailing: Text(
        amount,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
