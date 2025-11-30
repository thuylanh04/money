import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_manage/models/transaction.dart';
import 'package:money_manage/services/transaction_service.dart';
import 'package:money_manage/services/wallet_service.dart';
import 'package:money_manage/services/storage_service.dart';
import 'package:money_manage/services/api_client.dart';

import '../../theme/app_theme.dart';
import '../../services/chart_service.dart';
import '../widgets/income_expense_chart.dart';
import '../widgets/monthly_report_chart.dart';
import 'account_screen.dart';
import 'analysis_screen.dart';
import 'transaction_detail_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeContent(),
      const TransactionsScreen(),
      const AnalysisScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        selectedItemColor: AppTheme.primaryGreen,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            label: 'Phân tích',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed(TransactionDetailScreen.routeName);
          },
          backgroundColor: AppTheme.primaryGreen,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

/// Home content dựa trên screenshot: balance, wallet card, report card, banner, top spending, recent transactions.
class _HomeContent extends StatefulWidget {
  const _HomeContent({super.key});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalBalance = 0;
  bool _isLoading = true;
  final WalletService _walletService = WalletService(ApiClient());
  Map<String, dynamic>? _walletData;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _loadTransactionData();
  }

  Future<void> _loadWalletData() async {
    try {
      final wallets = await _walletService.getUserWallets();
      if (wallets.isNotEmpty) {
        // Get the first wallet's ID FE
        final walletIdFE = wallets.first.idFE;
        if (walletIdFE != null) {
          final response =
              await ApiClient().get('/api/v1/transactions/amount/$walletIdFE');
          if (response != null &&
              response['code'] == 1000 &&
              response['result'] is List &&
              response['result'].isNotEmpty) {
            if (mounted) {
              setState(() {
                _walletData = response['result'][0];
                // Update the balance if available in the response
                if (_walletData?['balance'] != null) {
                  _totalBalance = _walletData!['balance'].toDouble();
                }
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading wallet data: $e');
      // Fall back to the existing balance calculation
      _loadTransactionData();
    }
  }

  Future<void> _loadTransactionData() async {
    try {
      final transactionService = TransactionService();
      final transactions = await transactionService.getUserTransactions();

      double income = 0;
      double expense = 0;

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      for (var transaction in transactions) {
        if (transaction.date.isAfter(currentMonth)) {
          if (transaction.groupType == 'income') {
            income +=
                transaction.amount.abs(); // Ensure positive amount for income
          } else if (transaction.groupType == 'expense') {
            expense +=
                transaction.amount.abs(); // Ensure positive amount for expense
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalIncome = income;
          _totalExpense = expense;
          // Only update balance if we didn't get it from the wallet API
          if (_walletData == null || _walletData!['balance'] == null) {
            _totalBalance = income - expense;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Handle error
      print('Error loading transaction data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeHeader(balance: _totalBalance),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : MonthlyReportChart(
                  income: _totalIncome > 0 ? _totalIncome : 0,
                  expense: _totalExpense > 0 ? _totalExpense : 0,
                ),
          const SizedBox(height: 24),
          const _PromoBanner(),
          const SizedBox(height: 24),
          _TopSpendingSection(),
          const SizedBox(height: 24),
          _RecentTransactionsSection(),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatefulWidget {
  final double balance;

  const _HomeHeader({required this.balance});

  @override
  _HomeHeaderState createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> {
  bool _showBalance = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _showBalance
                      ? '${widget.balance >= 0 ? '' : '-'}₫${NumberFormat('#,###').format(widget.balance.abs())}'
                      : '••••••',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showBalance = !_showBalance;
                    });
                  },
                  child: Icon(
                    _showBalance ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Tổng số dư',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Row(
          children: const [
            Icon(Icons.search),
            SizedBox(width: 12),
            Icon(Icons.notifications_outlined),
          ],
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Wallets',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cash',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Text(
            '-\$ 500,000',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Report this month',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                  );
                },
                child: const Text(
                  'See reports',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Total spent',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            '500,000',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: 30,
                minY: 0,
                maxY: 600000,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        if (value == 1) {
                          return const Text('01/11',
                              style: TextStyle(fontSize: 10));
                        }
                        if (value == 30) {
                          return const Text('30/11',
                              style: TextStyle(fontSize: 10));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 100000) {
                          return const Text('100K',
                              style: TextStyle(fontSize: 10));
                        }
                        if (value == 200000) {
                          return const Text('200K',
                              style: TextStyle(fontSize: 10));
                        }
                        if (value == 300000) {
                          return const Text('300K',
                              style: TextStyle(fontSize: 10));
                        }
                        if (value == 400000) {
                          return const Text('400K',
                              style: TextStyle(fontSize: 10));
                        }
                        if (value == 500000) {
                          return const Text('500K',
                              style: TextStyle(fontSize: 10));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 2,
                    dotData: FlDotData(show: true),
                    spots: const [
                      FlSpot(1, 0),
                      FlSpot(15, 0),
                      FlSpot(24, 500000),
                      FlSpot(30, 500000),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Trending report',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)], // phỏng đoán
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Limited time offer',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            '-80%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Get the most out of Money Finwise Premium',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TopSpendingSection extends StatefulWidget {
  const _TopSpendingSection();

  @override
  _TopSpendingSectionState createState() => _TopSpendingSectionState();
}

class _TopSpendingSectionState extends State<_TopSpendingSection> {
  List<Map<String, dynamic>> _topCategories = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTopSpending();
  }

  Future<void> _loadTopSpending() async {
    try {
      final transactionService = TransactionService();
      final transactions = await transactionService.getUserTransactions();

      // Group transactions by category and sum amounts (only expenses)
      final categoryMap = <String, double>{};
      final categoryNames = <String, String>{};

      for (var transaction in transactions) {
        if (transaction.groupType == 'expense' &&
            transaction.categoryName != null) {
          final categoryName = transaction.categoryName!;
          categoryMap[categoryName] =
              (categoryMap[categoryName] ?? 0) + transaction.amount.abs();
          categoryNames[categoryName] = categoryName;
        }
      }

      // Convert to list and sort by amount in descending order
      final sortedCategories = categoryMap.entries
          .map((e) => {
                'category': e.key,
                'amount': e.value,
              })
          .toList()
        ..sort(
            (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

      // Take top 5
      if (!mounted) return;
      setState(() {
        _topCategories = sortedCategories.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load top spending';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top spending',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to transactions screen with expense filter
                Navigator.pushNamed(context, TransactionsScreen.routeName);
              },
              child: const Text(
                'See details',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
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
                category['amount'],
                _getCategoryIcon(category['category']),
              )),
      ],
    );
  }

  Widget _buildCategoryItem(String category, double amount, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
            child: Icon(icon, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '\$${NumberFormat('#,###').format(amount)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red, // Expense color
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    // Map categories to appropriate icons
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

class _RecentTransactionsSection extends StatefulWidget {
  const _RecentTransactionsSection();

  @override
  _RecentTransactionsSectionState createState() =>
      _RecentTransactionsSectionState();
}

class _RecentTransactionsSectionState
    extends State<_RecentTransactionsSection> {
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRecentTransactions();
  }

  Future<void> _loadRecentTransactions() async {
    try {
      final transactionService = TransactionService();
      final transactions = await transactionService.getUserTransactions();

      // Sort by date in descending order and take first 5
      transactions.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _recentTransactions = transactions.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load recent transactions';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent transactions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, TransactionsScreen.routeName);
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
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
    final icon = _getCategoryIcon(transaction.categoryName ?? 'Other');
    final formattedDate = DateFormat('dd MMMM yyyy').format(transaction.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense
              ? Colors.red.withOpacity(0.1)
              : AppTheme.primaryGreen.withOpacity(0.1),
          child: Icon(
            icon,
            color: isExpense ? Colors.red : AppTheme.primaryGreen,
          ),
        ),
        title: Text(
          transaction.categoryName ?? 'Uncategorized',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          formattedDate,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          '${isExpense ? '-' : '+'}\$${NumberFormat('#,###').format(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isExpense ? Colors.red : AppTheme.primaryGreen,
          ),
        ),
        onTap: () {
          // Navigate to transaction detail
          Navigator.pushNamed(
            context,
            TransactionDetailScreen.routeName,
            arguments: transaction.idFE,
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.category;

    final iconMap = {
      'Food': Icons.restaurant,
      'Transportation': Icons.directions_car,
      'Shopping': Icons.shopping_bag,
      'Entertainment': Icons.movie,
      'Health': Icons.health_and_safety,
      'Bills': Icons.receipt,
      'Education': Icons.school,
      'Salary': Icons.work,
      'Investment': Icons.trending_up,
      'Gift': Icons.card_giftcard,
    };

    return iconMap[category] ?? Icons.category;
  }
}
