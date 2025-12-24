import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manage/models/transaction.dart';
import 'package:money_manage/services/transaction_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../theme/app_theme.dart';
import '../../utils/connectivity.dart';

class TopSpendingSection extends StatefulWidget {
  const TopSpendingSection({super.key});
  @override
  _TopSpendingSectionState createState() => _TopSpendingSectionState();
}

class _TopSpendingSectionState extends State<TopSpendingSection> {
  List<Map<String, dynamic>> _topCategories = [];
  bool _isLoading = true;
  String _error = '';
  bool _hadCacheTop = false;

  @override
  void initState() {
    super.initState();
    _initTopSpending();
  }

  Future<bool> _loadCachedTopCategories() async {
    try {
      // HIVE: load cached top spending categories
      final box = Hive.box('home_cache');
      final cachedTop = box.get('topCategories');
      if (cachedTop != null && cachedTop is List) {
        if (!mounted) return true;
        setState(() {
          _topCategories = List<Map<String, dynamic>>.from(
              (cachedTop as List).map((e) => Map<String, dynamic>.from(e)));
          _isLoading = false;
        });
        _hadCacheTop = true;
        return true;
      }
      return false;
    } catch (e) {
      print('HIVE: failed to load top categories cache: $e');
      return false;
    }
  }

  Future<void> _initTopSpending() async {
    final hadCache = await _loadCachedTopCategories();
    final online = await hasInternet();
    if (!online) {
      if (!hadCache) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'No internet and no cached data';
        });
      }
      return;
    }
    await _loadTopSpending();
  }

  Future<void> _saveTopCategoriesCache() async {
    try {
      // HIVE: save top spending categories cache
      final box = Hive.box('home_cache');
      await box.put('topCategories', _topCategories);
    } catch (e) {
      print('HIVE: failed to save top categories cache: $e');
    }
  }

  Future<void> _loadTopSpending() async {
    try {
      final transactionService = TransactionService();
      final transactions = await transactionService.getUserTransactions();

      final categoryMap = <String, double>{};

      for (var transaction in transactions) {
        if (transaction.groupType == 'expense' &&
            transaction.categoryName != null) {
          final categoryName = transaction.categoryName!;
          categoryMap[categoryName] =
              (categoryMap[categoryName] ?? 0) + transaction.amount.abs();
        }
      }

      final sortedCategories = categoryMap.entries
          .map((e) => {'category': e.key, 'amount': e.value})
          .toList()
        ..sort(
            (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

      if (!mounted) return;
      setState(() {
        _topCategories = sortedCategories.take(3).toList();
        _isLoading = false;
      });
      await _saveTopCategoriesCache();
      _hadCacheTop = true;
    } catch (e) {
      if (!mounted) return;
      if (!_hadCacheTop) {
        setState(() {
          _error = 'Failed to load top spending';
          _isLoading = false;
        });
      } else {
        print('Top spending fetch failed, using cached data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Spending Categories',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_error.isNotEmpty)
          Text(_error, style: const TextStyle(color: Colors.red))
        else if (_topCategories.isEmpty)
          const Text('No spending data available')
        else
          ..._topCategories.map((category) => _buildCategoryItem(
              category['category'],
              category['amount'] as double,
              _getCategoryIcon(category['category']))),
      ],
    );
  }

  Widget _buildCategoryItem(String category, double amount, IconData icon) {
    final isIncome = false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        CircleAvatar(
            backgroundColor: isIncome
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green : Colors.red, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(category,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500))),
        Text('\$' + NumberFormat('#,###').format(amount),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isIncome ? Colors.green : Colors.red)),
      ]),
    );
  }

  IconData _getCategoryIcon(String category) {
    final iconMap = {
      'Food': Icons.restaurant,
      'Transportation': Icons.directions_car,
      'Shopping': Icons.shopping_bag,
      'Entertainment': Icons.movie,
      'Health': Icons.health_and_safety,
      'Bills': Icons.receipt,
      'Education': Icons.school,
      'Others': Icons.category,
    };
    return iconMap[category] ?? Icons.category;
  }
}
