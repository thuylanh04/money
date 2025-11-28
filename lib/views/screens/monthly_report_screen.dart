import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_manage/models/transaction.dart';
import 'package:money_manage/services/transaction_service.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  late Future<List<Transaction>> _transactionsFuture;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() {
    setState(() {
      final transactionService = TransactionService();
      _transactionsFuture = transactionService.getUserTransactions();
    });
    return _transactionsFuture;
  }

  Map<String, double> _getCategoryTotals(List<Transaction> transactions, String type) {
    final Map<String, double> categoryTotals = {};
    
    for (var txn in transactions.where((t) => t.groupType == type)) {
      final categoryName = txn.categoryName ?? 'Khác';
      categoryTotals.update(
        categoryName,
        (value) => value + txn.amount,
        ifAbsent: () => txn.amount,
      );
    }
    
    return categoryTotals;
  }

  List<PieChartSectionData> _getPieChartSections(
    Map<String, double> categoryTotals,
    double total,
    List<Color> colors,
  ) {
    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    categoryTotals.forEach((category, amount) {
      final percentage = (amount / total * 100).toStringAsFixed(1);
      
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '$percentage%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo tháng'),
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
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
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
          final expenseByCategory = _getCategoryTotals(transactions, 'expense');
          final incomeByCategory = _getCategoryTotals(transactions, 'income');
          
          final totalExpense = expenseByCategory.values.fold(0.0, (sum, amount) => sum + amount);
          final totalIncome = incomeByCategory.values.fold(0.0, (sum, amount) => sum + amount);

          final expenseColors = [
            Colors.red[300]!,
            Colors.orange[300]!,
            Colors.amber[300]!,
            Colors.blue[300]!,
            Colors.green[300]!,
            Colors.purple[300]!,
          ];

          final incomeColors = [
            Colors.green[300]!,
            Colors.blue[300]!,
            Colors.cyan[300]!,
            Colors.teal[300]!,
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 24),
                _buildSummaryCard(totalIncome, totalExpense),
                const SizedBox(height: 32),
                _buildPieChartSection(
                  'Chi tiêu theo danh mục',
                  expenseByCategory,
                  totalExpense,
                  expenseColors,
                ),
                const SizedBox(height: 32),
                _buildPieChartSection(
                  'Thu nhập theo danh mục',
                  incomeByCategory,
                  totalIncome,
                  incomeColors,
                ),
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
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
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
          onPressed: _selectedMonth.month >= DateTime.now().month ? null : () {
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              _loadTransactions();
            });
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double totalIncome, double totalExpense) {
    final savings = totalIncome - totalExpense;
    
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
              'Tổng quan tháng này',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Tổng thu nhập', totalIncome, Colors.green[700]!),
            const SizedBox(height: 12),
            _buildSummaryRow('Tổng chi tiêu', totalExpense, Colors.red[700]!),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Tiết kiệm', 
              savings, 
              savings >= 0 ? Colors.blue[700]! : Colors.orange[700]!,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '₫${NumberFormat('#,###').format(amount)}',
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartSection(
    String title,
    Map<String, double> categoryData,
    double total,
    List<Color> colors,
  ) {
    if (categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sections: _getPieChartSections(categoryData, total, colors),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    startDegreeOffset: -90,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildLegend(categoryData, colors),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Map<String, double> categoryData, List<Color> colors) {
    final entries = categoryData.entries.toList();
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final percentage = (entry.value / categoryData.values.fold(0, (sum, amount) => sum + amount) * 100).toStringAsFixed(1);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
