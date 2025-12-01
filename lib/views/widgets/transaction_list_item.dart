import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';
import '../../theme/app_theme.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use groupType to determine if it's an expense or income
    // Default to expense if groupType is null
    final isExpense = transaction.groupType != 'income';
    final amountColor = isExpense ? AppTheme.error : AppTheme.primaryGreen;
    final amountSign = isExpense ? '-' : '+';
    final formattedDate = DateFormat('MMM d, y').format(transaction.date);
    
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isExpense 
              ? AppTheme.error.withOpacity(0.1) 
              : AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isExpense ? Icons.arrow_upward : Icons.arrow_downward,
          color: isExpense ? AppTheme.error : AppTheme.primaryGreen,
          size: 20,
        ),
      ),
      title: Text(
        transaction.categoryIdFE ?? 'Uncategorized',
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        formattedDate,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${transaction.amount.toStringAsFixed(2).replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(\.\d+)?\b)'),
                  (match) => '${match[1]},',
                )} USD',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: amountColor,
              fontSize: 14,
            ),
          ),
          if (transaction.note?.isNotEmpty ?? false)
            Text(
              transaction.note!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
