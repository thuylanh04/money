import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manage/models/transaction.dart';
import 'package:money_manage/services/transaction_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../theme/app_theme.dart';
import '../../utils/connectivity.dart';

class RecentTransactionsSection extends StatefulWidget {
  const RecentTransactionsSection({super.key});
  @override
  _RecentTransactionsSectionState createState() =>
      _RecentTransactionsSectionState();
}

class _RecentTransactionsSectionState extends State<RecentTransactionsSection> {
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;
  String _error = '';
  bool _hadCacheRecent = false;

  @override
  void initState() {
    super.initState();
    _initRecentTransactions();
  }

  Future<bool> _loadCachedRecentTransactions() async {
    try {
      // HIVE: load cached recent transactions
      final box = Hive.box('home_cache');
      final cached = box.get('recentTransactions');
      if (cached != null && cached is List) {
        final list = (cached as List)
            .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (!mounted) return true;
        setState(() {
          _recentTransactions = list;
          _isLoading = false;
        });
        _hadCacheRecent = true;
        return true;
      }
      return false;
    } catch (e) {
      print('HIVE: failed to load recent transactions cache: $e');
      return false;
    }
  }

  Future<void> _saveRecentTransactionsCache() async {
    try {
      // HIVE: save recent transactions cache
      final box = Hive.box('home_cache');
      final asMaps = _recentTransactions.map((t) => t.toJson()).toList();
      await box.put('recentTransactions', asMaps);
      _hadCacheRecent = true;
    } catch (e) {
      print('HIVE: failed to save recent transactions cache: $e');
    }
  }

  Future<void> _initRecentTransactions() async {
    final hadCache = await _loadCachedRecentTransactions();
    final online = await hasInternet();
    if (!online) {
      if (!hadCache) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'No internet and no cached transactions';
        });
      }
      return;
    }
    await _loadRecentTransactions();
  }

  Future<void> _loadRecentTransactions() async {
    try {
      final transactionService = TransactionService();
      final transactions = await transactionService.getUserTransactions();
      transactions.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        _recentTransactions = transactions.take(5).toList();
        _isLoading = false;
      });
      await _saveRecentTransactionsCache();
    } catch (e) {
      if (!mounted) return;
      if (!_hadCacheRecent) {
        setState(() {
          _error = 'Failed to load recent transactions';
          _isLoading = false;
        });
      } else {
        print('Recent transactions fetch failed, using cached data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Recent transactions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/transactions'),
              child: const Text('See all',
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen)))
        ]),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_error.isNotEmpty)
          Text(_error, style: const TextStyle(color: Colors.red))
        else if (_recentTransactions.isEmpty)
          const Text('No recent transactions')
        else
          ..._recentTransactions
              .map((transaction) => _buildTransactionItem(transaction)),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isExpense = transaction.groupType != 'income';
    final formattedDate = DateFormat('dd MMMM yyyy').format(transaction.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: isExpense
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            child: Icon(isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                color: isExpense ? Colors.red : Colors.green, size: 20)),
        title: Text(transaction.categoryName ?? 'Uncategorized',
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(formattedDate,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Text(
            '${isExpense ? '-' : '+'}\$${NumberFormat('#,###').format(transaction.amount)}',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isExpense ? Colors.red : Colors.green)),
        onTap: () => Navigator.pushNamed(context, '/transaction_detail',
            arguments: transaction.idFE),
      ),
    );
  }
}
