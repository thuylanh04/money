import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manage/models/transaction.dart';
import 'package:money_manage/services/transaction_service.dart';
import 'package:money_manage/services/wallet_service.dart';
import 'package:money_manage/services/api_client.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../utils/connectivity.dart';

import '../../theme/app_theme.dart';
import '../../services/chart_service.dart';
import '../sections/top_spending_section.dart';
import '../sections/recent_transactions_section.dart';
import '../widgets/monthly_report_chart.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalBalance = 0;
  bool _isLoading = true;
  final WalletService _walletService = WalletService(ApiClient());
  Map<String, dynamic>? _walletData;

  @override
  void initState() {
    super.initState();
    _initHiveAndLoadCache();
    _loadWalletData();
    _loadTransactionData();
  }

  Future<void> _initHiveAndLoadCache() async {
    try {
      // HIVE: load cached totals for Home screen
      final box = Hive.box('home_cache');
      final cachedIncome = box.get('totalIncome');
      final cachedExpense = box.get('totalExpense');
      final cachedBalance = box.get('totalBalance');

      if (mounted) {
        setState(() {
          if (cachedIncome != null)
            _totalIncome = (cachedIncome as num).toDouble();
          if (cachedExpense != null)
            _totalExpense = (cachedExpense as num).toDouble();
          if (cachedBalance != null)
            _totalBalance = (cachedBalance as num).toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('HIVE: failed to load cache: $e');
    }
  }

  Future<void> _saveHomeCache() async {
    try {
      // HIVE: save cached totals for Home screen
      final box = Hive.box('home_cache');
      await box.put('totalIncome', _totalIncome);
      await box.put('totalExpense', _totalExpense);
      await box.put('totalBalance', _totalBalance);
    } catch (e) {
      print('HIVE: failed to save cache: $e');
    }
  }

  Future<void> _loadWalletData() async {
    try {
      final online = await hasInternet();
      if (!online) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final wallets = await _walletService.getUserWallets();
      if (wallets.isNotEmpty) {
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
                if (_walletData?['balance'] != null)
                  _totalBalance = _walletData!['balance'].toDouble();
              });
              await _saveHomeCache();
            }
          }
        }
      }
    } catch (e) {
      print('Error loading wallet data: $e');
      _loadTransactionData();
    }
  }

  Future<void> _loadTransactionData() async {
    try {
      final online = await hasInternet();
      if (!online) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final transactionService = TransactionService();
      final transactions = await transactionService.getUserTransactions();

      double income = 0;
      double expense = 0;
      final now = DateTime.now();

      for (var transaction in transactions) {
        final txDate = transaction.date.toLocal();
        if (txDate.year == now.year && txDate.month == now.month) {
          if (transaction.groupType == 'income') {
            income += transaction.amount.abs();
          } else if (transaction.groupType == 'expense') {
            expense += transaction.amount.abs();
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalIncome = income;
          _totalExpense = expense;
          if (_walletData == null || _walletData!['balance'] == null)
            _totalBalance = income - expense;
          _isLoading = false;
        });
        await _saveHomeCache();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          HomeHeader(balance: _totalBalance),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : MonthlyReportChart(
                  income: _totalIncome > 0 ? _totalIncome : 0,
                  expense: _totalExpense > 0 ? _totalExpense : 0),
          const SizedBox(height: 24),
          const _PromoBanner(),
          const SizedBox(height: 24),
          TopSpendingSection(),
          const SizedBox(height: 24),
          RecentTransactionsSection(),
        ],
      ),
    );
  }
}

class HomeHeader extends StatefulWidget {
  final double balance;
  const HomeHeader({required this.balance});
  @override
  _HomeHeaderState createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
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
                      ? '${widget.balance >= 0 ? '' : '-'}\$${NumberFormat('#,###').format(widget.balance.abs())}'
                      : '••••••',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _showBalance = !_showBalance),
                  child: Icon(
                      _showBalance ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Total Balance',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
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
              colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)])),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Limited time offer',
            style: TextStyle(color: Colors.white, fontSize: 12)),
        SizedBox(height: 8),
        Text('-80%',
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('Get the most out of Money Finwise Premium',
            style: TextStyle(color: Colors.white70, fontSize: 12))
      ]),
    );
  }
}
