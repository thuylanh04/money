import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manage/models/chart_data.dart';
import 'package:money_manage/services/transaction_service.dart';
import 'package:money_manage/models/transaction.dart';
// Assuming AppTheme file exists for color usage
import 'package:money_manage/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

// CHANGED FROM StatelessWidget TO StatefulWidget
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  // State variables for time filter
  late List<Map<String, dynamic>> _timeFilters;
  late Map<String, dynamic> _selectedFilter;
  final ScrollController _scrollController = ScrollController();

  // Analysis state (Expense/Income)
  bool _isExpenseAnalysis = true;
  bool _isLoading = true;

  // Store expense and income data separately
  List<ChartData> _expenseData = [];
  List<ChartData> _incomeData = [];

  // Getter to get current data
  List<ChartData> get _currentData =>
      _isExpenseAnalysis ? _expenseData : _incomeData;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _initializeTimeFilters();
    _loadBothChartData(); // Load both types of data
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Handle scroll event if needed
  }

  // Load chart data by getting transactions and grouping by category
  Future<void> _loadBothChartData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final year = _selectedFilter['year'] as int;
    final month = _selectedFilter['month'] as int;

    try {
      final service = TransactionService();
      final transactions = await service.getUserTransactions();

      // Filter transactions for the selected month/year
      final filtered = transactions
          .where((t) => t.date.year == year && t.date.month == month);

      // Aggregate amounts per category for expense and income separately
      final Map<String, double> expenseMap = {};
      final Map<String, double> incomeMap = {};

      double totalExpense = 0.0;
      double totalIncome = 0.0;

      for (final t in filtered) {
        final category = t.categoryName ?? 'Others';
        final amt = t.amount.abs();
        if (t.groupType != null && t.groupType!.toLowerCase() == 'income') {
          incomeMap[category] = (incomeMap[category] ?? 0) + amt;
          totalIncome += amt;
        } else {
          expenseMap[category] = (expenseMap[category] ?? 0) + amt;
          totalExpense += amt;
        }
      }

      // Convert maps to ChartData lists
      final expenseList = expenseMap.entries.map((e) {
        final amount = e.value;
        final percentage =
            totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;
        return ChartData(
            category: e.key, amount: amount, percentage: percentage, icon: '');
      }).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      final incomeList = incomeMap.entries.map((e) {
        final amount = e.value;
        final percentage = totalIncome > 0 ? (amount / totalIncome) * 100 : 0.0;
        return ChartData(
            category: e.key, amount: amount, percentage: percentage, icon: '');
      }).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      if (!mounted) return;
      setState(() {
        _expenseData = expenseList;
        _incomeData = incomeList;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (kDebugMode) {
        print('Error loading chart data from transactions: $e');
      }
    }
  }

  // Toggle between expense and income
  void _toggleAnalysisType(bool isExpense) {
    if (_isExpenseAnalysis != isExpense) {
      setState(() {
        _isExpenseAnalysis = isExpense;
      });
    }
  }

  // Initialize time filter (last 12 months)
  void _initializeTimeFilters() {
    final now = DateTime.now();

    // Create a list of 12 months from current month backwards
    _timeFilters = List.generate(12, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      final monthName = DateFormat('MMM yyyy').format(date);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      return {
        'label': monthName,
        'year': date.year,
        'month': date.month,
        'key': monthKey,
      };
    }).reversed.toList();

    // Set current month as default (last element)
    _selectedFilter = _timeFilters.last;

    // Auto-scroll to current month after UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedMonth();
    });
  }

  // Scroll to selected month
  void _scrollToSelectedMonth() {
    if (_scrollController.hasClients) {
      final index = _timeFilters
          .indexWhere((filter) => filter['key'] == _selectedFilter['key']);
      if (index != -1) {
        final double itemWidth = 100.0; // Estimated width of each filter item
        final double screenWidth = MediaQuery.of(context).size.width;
        final double scrollPosition =
            (itemWidth * index) - (screenWidth / 2) + (itemWidth / 2);

        _scrollController.animateTo(
          scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // Widget to display Total (Expense/Income)
  Widget _buildTotalExpenseCard(double totalAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isExpenseAnalysis ? 'Total Expenses' : 'Total Income',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatCurrency(totalAmount)} USD',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isExpenseAnalysis
                ? Colors.red[700] // Red for expenses
                : Colors.green[700], // Green for income
          ),
        ),
      ],
    );
  }

  // Load chart data based on selected filter
  void _loadChartData() {
    _loadBothChartData();
  }

  // Apply new filter and reload data
  void _applyFilter(Map<String, dynamic> filter) {
    // Don't reload if filter hasn't changed
    if (_selectedFilter['key'] == filter['key']) return;

    setState(() {
      _selectedFilter = filter;
    });

    _loadChartData();
    _scrollToSelectedMonth();
  }

  // Helper method to format currency (e.g., 1,000,000)
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'vi_VN');
    return formatter.format(amount);
  }

  // Helper method to get color for category (Matched colors)
  Color _getColorForCategory(String category) {
    // Use specific Hex/RGB colors to ensure consistency
    final colors = {
      // Green for Food & Drinks
      'Ăn uống': const Color(0xFF4CAF50),
      // Blue for Shopping
      'Mua sắm': const Color(0xFF2196F3),
      // Orange for Transportation
      'Di chuyển': const Color(0xFFFF9800),
      // Purple for Entertainment
      'Giải trí': const Color(0xFF9C27B0),
      // Blue Grey for Others
      'Khác': const Color(0xFF607D8B),
    };
    return colors[category] ?? Colors.grey;
  }

  // Widget to build toggle button between Expense and Income
  Widget _buildAnalysisTypeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // Expense Button
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleAnalysisType(true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _isExpenseAnalysis
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'Expenses',
                    style: TextStyle(
                      color:
                          _isExpenseAnalysis ? Colors.white : Colors.grey[700],
                      fontWeight: _isExpenseAnalysis
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Income Button
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleAnalysisType(false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: !_isExpenseAnalysis
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'Income',
                    style: TextStyle(
                      color:
                          !_isExpenseAnalysis ? Colors.white : Colors.grey[700],
                      fontWeight: !_isExpenseAnalysis
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total amount (expense or income) for current month
    final totalAmount =
        _currentData.fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        centerTitle: true,
        // Time filter and toggle button
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              _buildTimeFilterBar(context),
              _buildAnalysisTypeToggle(),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // TOTAL AMOUNT CARD AT THE TOP
                  _buildTotalExpenseCard(totalAmount),

                  const SizedBox(height: 24),

                  // Display Chart or Empty Message
                  _currentData.isEmpty
                      ? Center(
                          child: Text(
                            _isExpenseAnalysis
                                ? 'No expenses in ${_selectedFilter['label']}'
                                : 'No income in ${_selectedFilter['label']}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        )
                      // DISPLAY CHART
                      : _buildExpenseChart(_currentData, totalAmount),

                  const SizedBox(height: 24),

                  // Details list
                  if (_currentData.isNotEmpty) _buildExpenseList(_currentData),
                ],
              ),
            ),
    );
  }

  // Widget to build time filter bar
  Widget _buildTimeFilterBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _timeFilters.length,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemBuilder: (context, index) {
          final filter = _timeFilters[index];
          final isSelected = _selectedFilter['key'] == filter['key'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () => _applyFilter(filter),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    filter['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget to build pie chart
  Widget _buildExpenseChart(List<ChartData> data, double totalAmount) {
    return Center(
      child: SizedBox(
        height: 210,
        width: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sections: _chartSections(data),
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                pieTouchData: PieTouchData(enabled: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to create slices for PieChart
  List<PieChartSectionData> _chartSections(List<ChartData> data) {
    // Function to generate random color based on category name
    Color getColorForCategory(String category, bool isExpense) {
      // Create a hash from category name to ensure consistency
      final hash = category.hashCode.abs();

      // Choose color palette based on type (expense or income)
      final hueRange = isExpense
          ? const [0, 60] // Red to yellow
          : [80, 180]; // Green to blue

      // Generate color based on hash
      return HSLColor.fromAHSL(
        1.0, // Opacity
        (hash % (hueRange[1] - hueRange[0]) + hueRange[0])
            .toDouble(), // Hue
        0.7, // Saturation
        0.6, // Lightness
      ).toColor();
    }

    return data.map((item) {
      final color = getColorForCategory(item.category, _isExpenseAnalysis);
      return PieChartSectionData(
        color: color,
        value: item.percentage,
        title: '${item.percentage.round()}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        borderSide: const BorderSide(color: Colors.white, width: 0.5),
      );
    }).toList();
  }

  // Widget to build details list
  Widget _buildExpenseList(List<ChartData> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isExpenseAnalysis ? 'Expense Details' : 'Income Details',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...data.map((item) => _buildExpenseItem(item)).toList(),
      ],
    );
  }

  // Widget to build each expense/income item in the list
  Widget _buildExpenseItem(ChartData item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category name
          Expanded(
            child: Text(
              item.category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Amount
          Text(
            '${_isExpenseAnalysis ? '-' : '+'}${_formatCurrency(item.amount)} USD',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
