import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_manage/models/transaction.dart';
import 'package:money_manage/services/transaction_service.dart';
import 'package:money_manage/theme/app_theme.dart';

class SpendingAnalysisScreen extends StatefulWidget {
  const SpendingAnalysisScreen({super.key});

  @override
  State<SpendingAnalysisScreen> createState() => _SpendingAnalysisScreenState();
}

class _SpendingAnalysisScreenState extends State<SpendingAnalysisScreen> {
  DateTime _selectedMonth = DateTime.now();
  late Future<List<Transaction>> _transactionsFuture;
  String _selectedTab = 'Chi tiêu'; // 'Chi tiêu' or 'Thu nhập'

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await TransactionService().getUserTransactions();
      setState(() {
        _transactionsFuture = Future.value(transactions);
      });
    } catch (e) {
      setState(() {
        _transactionsFuture = Future.error(e);
      });
    }
  }

  Map<String, double> _getCategoryTotals(List<Transaction> transactions) {
    final Map<String, double> categoryTotals = {};

    for (var txn in transactions.where((t) =>
        t.groupType == _selectedTab.toLowerCase() &&
        t.date.year == _selectedMonth.year &&
        t.date.month == _selectedMonth.month)) {
      final categoryName = txn.categoryName ?? 'Khác';
      categoryTotals.update(
        categoryName,
        (value) =>
            value + txn.amount, // Removed .abs() as backend handles the sign
        ifAbsent: () =>
            txn.amount, // Removed .abs() as backend handles the sign
      );
    }

    return categoryTotals;
  }

  double _getTotalAmount(List<Transaction> transactions) {
    return transactions
        .where((t) =>
            t.groupType == _selectedTab.toLowerCase() &&
            t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month)
        .fold(
            0.0,
            (sum, txn) =>
                sum + txn.amount); // Removed .abs() as backend handles the sign
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Analysis'),
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
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
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
          final categoryTotals = _getCategoryTotals(transactions);
          final totalAmount = _getTotalAmount(transactions);
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 24),
                _buildTabBar(),
                const SizedBox(height: 24),
                _buildTotalAmountCard(totalAmount),
                const SizedBox(height: 24),
                _buildPieChart(categoryTotals, totalAmount),
                const SizedBox(height: 24),
                _buildCategoryList(sortedCategories, totalAmount),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthName = DateFormat('MMMM yyyy', 'vi_VN').format(_selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
            onPressed: _selectedMonth.month >= DateTime.now().month
                ? null
                : () {
                    setState(() {
                      _selectedMonth = DateTime(
                          _selectedMonth.year, _selectedMonth.month + 1);
                      _loadTransactions();
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton('Chi tiêu'),
          _buildTabButton('Thu nhập'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title) {
    final isSelected = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalAmountCard(double totalAmount) {
    return Card(
      elevation: 0,
      color: _selectedTab == 'Chi tiêu'
          ? AppTheme.error.withOpacity(0.08)
          : AppTheme.primaryGreen.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Tổng ${_selectedTab.toLowerCase()}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat('#,###').format(totalAmount)} VND',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(
      Map<String, double> categoryTotals, double totalAmount) {
    if (categoryTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            'Không có dữ liệu ${_selectedTab.toLowerCase()} trong tháng này',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 240,
          padding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: _getPieChartSections(categoryTotals, totalAmount),
                  sectionsSpace: 1.5,
                  centerSpaceRadius: 80,
                  startDegreeOffset: -90,
                  borderData: FlBorderData(show: false),
                  centerSpaceColor: Colors.transparent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tổng cộng',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${NumberFormat('#,###').format(totalAmount)} VND',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // const SizedBox(height: 8),
        // _buildLegend(categoryTotals),
      ],
    );
  }

  List<PieChartSectionData> _getPieChartSections(
      Map<String, double> categoryTotals, double totalAmount) {
    final List<PieChartSectionData> sections = [];
    final colors = _selectedTab == 'Chi tiêu'
        ? [
            const Color(0xFF4CAF50), // Xanh lá cây
            const Color(0xFF2196F3), // Xanh dương
            const Color(0xFFFF9800), // Cam
            const Color(0xFF9C27B0), // Tím
            const Color(0xFFF44336), // Đỏ
            const Color(0xFF00BCD4), // Xanh ngọc
            const Color(0xFFFFC107), // Vàng
            const Color(0xFF795548), // Nâu
            const Color(0xFF607D8B), // Xám xanh
            const Color(0xFFFF5722), // Cam đậm
          ]
        : [
            const Color(0xFF2196F3), // Xanh dương
            const Color(0xFF4CAF50), // Xanh lá
            const Color(0xFF9C27B0), // Tím
            const Color(0xFF00BCD4), // Xanh ngọc
            const Color(0xFF009688), // Xanh ngọc đậm
            const Color(0xFF3F51B5), // Chàm
            const Color(0xFF673AB7), // Tím đậm
            const Color(0xFF00ACC1), // Xanh ngọc sáng
          ];

    int colorIndex = 0;
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedCategories) {
      final percentage = (entry.value / totalAmount * 100);
      final showLabel = percentage >= 3; // Giảm ngưỡng hiển thị phần trăm
      final color = colors[colorIndex % colors.length];

      // Tự động điều chỉnh màu chữ dựa trên độ sáng của màu nền
      final isLightColor = color.computeLuminance() > 0.5;

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: showLabel ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 22, // Giảm kích thước để tạo khoảng trống ở giữa
          titleStyle: TextStyle(
            fontSize: percentage > 10 ? 12 : 10,
            fontWeight: FontWeight.bold,
            color: isLightColor ? Colors.black87 : Colors.white,
            shadows: isLightColor
                ? []
                : [
                    Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 2,
                        offset: const Offset(1, 1))
                  ],
          ),
          borderSide: const BorderSide(color: Colors.white, width: 2),
          titlePositionPercentageOffset: 0.55, // Điều chỉnh vị trí phần trăm
        ),
      );
      colorIndex++;
    }

    return sections;
  }

  Widget _buildLegend(Map<String, double> categoryTotals) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total =
        categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    final colors = _selectedTab == 'Chi tiêu'
        ? [
            const Color(0xFF4CAF50), // Xanh lá cây
            const Color(0xFF2196F3), // Xanh dương
            const Color(0xFFFF9800), // Cam
            const Color(0xFF9C27B0), // Tím
            const Color(0xFFF44336), // Đỏ
            const Color(0xFF00BCD4), // Xanh ngọc
            const Color(0xFFFFC107), // Vàng
            const Color(0xFF795548), // Nâu
            const Color(0xFF607D8B), // Xám xanh
            const Color(0xFFFF5722), // Cam đậm
          ]
        : [
            const Color(0xFF2196F3), // Xanh dương
            const Color(0xFF4CAF50), // Xanh lá
            const Color(0xFF9C27B0), // Tím
            const Color(0xFF00BCD4), // Xanh ngọc
            const Color(0xFF009688), // Xanh ngọc đậm
            const Color(0xFF3F51B5), // Chàm
            const Color(0xFF673AB7), // Tím đậm
            const Color(0xFF00ACC1), // Xanh ngọc sáng
          ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết danh mục',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            sortedCategories.length,
            (index) {
              final entry = sortedCategories[index];
              final percentage = (entry.value / total * 100);
              final color = colors[index % colors.length];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Màu đại diện
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tên danh mục
                    Expanded(
                      flex: 4,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Phần trăm
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    // Số tiền
                    const SizedBox(width: 8),
                    Text(
                      '${NumberFormat('#,###').format(entry.value)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Tổng cộng
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _selectedTab == 'Chi tiêu'
                  ? AppTheme.error.withOpacity(0.08)
                  : AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng ${_selectedTab.toLowerCase()}:',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(total)} VND',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
      List<MapEntry<String, double>> categories, double totalAmount) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh mục',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...categories.map((entry) {
          final percentage = (entry.value / totalAmount * 100);
          return _buildCategoryItem(entry.key, entry.value, percentage);
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryItem(String category, double amount, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _selectedTab == 'Chi tiêu'
                  ? AppTheme.error.withOpacity(0.08)
                  : AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: _selectedTab == 'Chi tiêu'
                  ? AppTheme.error
                  : AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _selectedTab == 'Chi tiêu'
                          ? AppTheme.error
                          : AppTheme.primaryGreen,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormat('#,###').format(amount)} VND',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    // Add your category to icon mapping here
    switch (category.toLowerCase()) {
      case 'ăn uống':
        return Icons.restaurant;
      case 'mua sắm':
        return Icons.shopping_bag;
      case 'di chuyển':
        return Icons.directions_car;
      case 'nhà cửa':
        return Icons.home;
      case 'hóa đơn':
        return Icons.receipt;
      case 'giải trí':
        return Icons.movie;
      case 'lương':
        return Icons.work;
      case 'thưởng':
        return Icons.card_giftcard;
      default:
        return Icons.category;
    }
  }
}
