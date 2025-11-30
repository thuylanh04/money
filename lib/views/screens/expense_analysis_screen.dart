import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manage/models/transaction.dart';
import 'package:money_manage/services/transaction_service.dart';

class ExpenseAnalysisScreen extends StatefulWidget {
  const ExpenseAnalysisScreen({super.key});

  @override
  State<ExpenseAnalysisScreen> createState() => _ExpenseAnalysisScreenState();
}

class _ExpenseAnalysisScreenState extends State<ExpenseAnalysisScreen> {
  late Future<List<Transaction>> _transactionsFuture;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() {
    setState(() {
      _transactionsFuture = TransactionService().getUserTransactions();
    });
    return _transactionsFuture;
  }

  double _getTotalExpenses(List<Transaction> transactions) {
    return transactions
        .where((txn) => txn.groupType == 'expense')
        .fold(0, (sum, txn) => sum + txn.amount);
  }

  double _getTotalIncome(List<Transaction> transactions) {
    return transactions
        .where((txn) => txn.groupType == 'income')
        .fold(0, (sum, txn) => sum + txn.amount);
  }

  Map<String, double> _getCategoryTotals(List<Transaction> transactions) {
    final Map<String, double> categoryTotals = {};

    for (var txn in transactions.where((t) => t.groupType == 'expense')) {
      final categoryName = txn.categoryName ?? 'Khác';
      categoryTotals.update(
        categoryName,
        (value) => value + txn.amount,
        ifAbsent: () => txn.amount,
      );
    }

    return categoryTotals;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích chi tiêu'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Lỗi khi tải dữ liệu'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTransactions,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Không có dữ liệu giao dịch'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTransactions,
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;
          final totalExpense = _getTotalExpenses(transactions);
          final totalIncome = _getTotalIncome(transactions);
          final savings = totalIncome - totalExpense;
          final categoryTotals = _getCategoryTotals(transactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 24),
                _buildSummaryCard(totalExpense, totalIncome, savings),
                const SizedBox(height: 24),
                _buildExpenseByCategory(categoryTotals, totalExpense),
                const SizedBox(height: 24),
                _buildRecentTransactions(transactions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthName = DateFormat('MMMM yyyy', 'vi_VN').format(_selectedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
          onPressed: () {
            setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              _loadTransactions();
            });
          },
        ),
        Text(
          monthName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onPressed: _selectedMonth
                  .isBefore(DateTime(DateTime.now().year, DateTime.now().month))
              ? () {
                  setState(() {
                    _selectedMonth =
                        DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                    _loadTransactions();
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      double totalExpense, double totalIncome, double savings) {
    return Card(
      elevation: 0,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Tổng chi tiêu tháng này',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₫${NumberFormat('#,###').format(totalExpense)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Tổng thu nhập', totalIncome, Colors.green),
                _buildStatItem(
                  'Tiết kiệm',
                  savings > 0 ? savings : 0,
                  savings > 0 ? Colors.blue : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount >= 0 ? '+' : ''}₫${NumberFormat('#,###').format(amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseByCategory(
      Map<String, double> categoryTotals, double totalExpense) {
    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi tiêu theo danh mục',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...categoryTotals.entries
            .map((entry) => _buildCategoryItem(
                  entry.key,
                  entry.value,
                  totalExpense,
                ))
            .toList(),
      ],
    );
  }

  Widget _buildCategoryItem(String name, double amount, double totalExpense) {
    final percentage = totalExpense > 0 ? (amount / totalExpense) : 0.0;
    final icon = _getCategoryIcon(name);
    final color = _getCategoryColor(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage.toDouble(),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(percentage * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₫${NumberFormat('#,###').format(amount)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions) {
    // Sort by date descending and take first 5
    final recentTransactions = transactions
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayTransactions = recentTransactions.take(5).toList();

    if (displayTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giao dịch gần đây',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...displayTransactions
            .map((txn) => _buildTransactionItem(txn))
            .toList(),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction txn) {
    final isExpense = txn.groupType == 'expense';
    final categoryName = txn.categoryName ?? 'Khác';
    final note = txn.note?.isNotEmpty == true ? txn.note! : 'Không có mô tả';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getCategoryColor(categoryName).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getCategoryIcon(categoryName),
            color: _getCategoryColor(categoryName),
            size: 20,
          ),
        ),
        title: Text(
          note,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '$categoryName • ${_formatDate(txn.date)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${isExpense ? '-' : '+'}₫${NumberFormat('#,###').format(txn.amount)}',
          style: TextStyle(
            color: isExpense ? Colors.red : Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('ăn') || lowerCategory.contains('uống')) {
      return Icons.restaurant;
    } else if (lowerCategory.contains('mua') || lowerCategory.contains('sắm')) {
      return Icons.shopping_bag;
    } else if (lowerCategory.contains('điện') ||
        lowerCategory.contains('nước') ||
        lowerCategory.contains('internet') ||
        lowerCategory.contains('hóa đơn')) {
      return Icons.receipt;
    } else if (lowerCategory.contains('di chuyển') ||
        lowerCategory.contains('xăng') ||
        lowerCategory.contains('xe')) {
      return Icons.directions_car;
    } else if (lowerCategory.contains('giải trí') ||
        lowerCategory.contains('xem phim') ||
        lowerCategory.contains('game')) {
      return Icons.movie;
    } else if (lowerCategory.contains('lương') ||
        lowerCategory.contains('thu nhập')) {
      return Icons.account_balance_wallet;
    } else {
      return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('ăn') || lowerCategory.contains('uống')) {
      return Colors.red;
    } else if (lowerCategory.contains('mua') || lowerCategory.contains('sắm')) {
      return Colors.blue;
    } else if (lowerCategory.contains('điện') ||
        lowerCategory.contains('nước') ||
        lowerCategory.contains('internet') ||
        lowerCategory.contains('hóa đơn')) {
      return Colors.orange;
    } else if (lowerCategory.contains('di chuyển') ||
        lowerCategory.contains('xăng') ||
        lowerCategory.contains('xe')) {
      return Colors.green;
    } else if (lowerCategory.contains('giải trí') ||
        lowerCategory.contains('xem phim') ||
        lowerCategory.contains('game')) {
      return Colors.purple;
    } else if (lowerCategory.contains('lương') ||
        lowerCategory.contains('thu nhập')) {
      return Colors.teal;
    } else {
      return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (date.year == now.year) {
      return DateFormat('d MMM', 'vi_VN').format(date);
    } else {
      return DateFormat('d/M/yyyy', 'vi_VN').format(date);
    }
  }
}
