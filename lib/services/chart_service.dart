import 'package:money_manage/models/chart_data.dart';
import 'package:intl/intl.dart'; // Cần thêm import này nếu chưa có

class ChartService {
  // Sample data (Mock data) for each month (December, November, October 2025)
  static final Map<String, List<ChartData>> _monthlyExpenseData = {
    // Data for December 2025 (Current month - total 7,000,000 USD)
    '2025-12': [
      ChartData(
        category: 'Dining',
        amount: 2500000, // Fixed amount
        percentage: 35,
        icon: '🍽️',
      ),
      ChartData(
        category: 'Shopping',
        amount: 1800000,
        percentage: 25,
        icon: '🛍️',
      ),
      ChartData(
        category: 'Transportation',
        amount: 1200000,
        percentage: 17,
        icon: '🚗',
      ),
      ChartData(
        category: 'Entertainment',
        amount: 900000,
        percentage: 13,
        icon: '🎬',
      ),
      ChartData(
        category: 'Other',
        amount: 600000,
        percentage: 10,
        icon: '🏠',
      ),
    ],

    // Data for November 2025 (total 6,500,000 USD)
    '2025-11': [
      ChartData(
          category: 'Dining', amount: 3000000, percentage: 46.15, icon: '🍽️'),
      ChartData(
          category: 'Shopping', amount: 1000000, percentage: 15.38, icon: '🛍️'),
      ChartData(
          category: 'Transportation',
          amount: 1500000,
          percentage: 23.08,
          icon: '🚗'),
      ChartData(
          category: 'Entertainment', amount: 500000, percentage: 7.69, icon: '🎬'),
      ChartData(category: 'Other', amount: 500000, percentage: 7.69, icon: '🏠'),
    ],

    // Data for October 2025 (total 1,000,000 USD)
    '2025-10': [
      ChartData(
          category: 'Dining', amount: 500000, percentage: 50, icon: '🍽️'),
      ChartData(category: 'Other', amount: 500000, percentage: 50, icon: '🏠'),
    ],
  };

  static Future<List<ChartData>> getExpenseChartData({int? year, int? month}) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    // 1. Create actual search key: 'YYYY-MM'
    final key = '$targetYear-${targetMonth.toString().padLeft(2, '0')}';

    // Use null-aware operator (??) to provide an empty list as default if not found
    List<ChartData> data = _monthlyExpenseData[key] ?? [];

    // 2. If there's no actual data (empty data), try to get mock data (assuming year 2025)
    if (data.isEmpty) {
      final mockKey = '2025-${targetMonth.toString().padLeft(2, '0')}';
      data = _monthlyExpenseData[mockKey] ?? [];
    }

    // 3. If there's still no data after checking mock, return an empty list
    if (data.isEmpty) {
      return [];
    }

    // RECALCULATE PERCENTAGE
    final totalAmount = data.fold<double>(0, (sum, item) => sum + item.amount);

    // Tránh chia cho 0
    if (totalAmount == 0) return data;

    // Map lại dữ liệu với percentage đã tính toán lại
    return data.map((item) {
      double calculatedPercentage = (item.amount / totalAmount) * 100;
      return ChartData(
        category: item.category,
        amount: item.amount,
        // Update the recalculated and rounded percentage
        percentage: calculatedPercentage.roundToDouble(),
        icon: item.icon,
      );
    }).toList();
  }

  // Other sample method (keep as is)
  static List<Map<String, dynamic>> getMonthlyData() {
    return [
      {'month': 'Sep', 'expense': 8000000, 'income': 15000000},
      {'month': 'Oct', 'expense': 12000000, 'income': 18000000},
      {'month': 'Nov', 'expense': 15000000, 'income': 20000000},
      {'month': 'Dec', 'expense': 18000000, 'income': 22000000},
    ];
  }

  // Add sample data for income
  static final Map<String, List<ChartData>> _monthlyIncomeData = {
    '2025-12': [
      ChartData(
        category: 'Salary',
        amount: 15000000,
        percentage: 75,
        icon: '💰',
      ),
      ChartData(
        category: 'Investment',
        amount: 3000000,
        percentage: 15,
        icon: '📈',
      ),
      ChartData(
        category: 'Part-time',
        amount: 2000000,
        percentage: 10,
        icon: '💼',
      ),
    ],
    // Add data for other months if needed
    '2025-11': [
      ChartData(
        category: 'Salary',
        amount: 15000000,
        percentage: 80,
        icon: '💰',
      ),
      ChartData(
        category: 'Investment',
        amount: 2000000,
        percentage: 15,
        icon: '📈',
      ),
      ChartData(
        category: 'Part-time',
        amount: 1000000,
        percentage: 5,
        icon: '💼',
      ),
    ],
    '2025-10': [
      ChartData(
        category: 'Salary',
        amount: 15000000,
        percentage: 85,
        icon: '💰',
      ),
      ChartData(
        category: 'Investment',
        amount: 1500000,
        percentage: 10,
        icon: '📈',
      ),
      ChartData(
        category: 'Part-time',
        amount: 1000000,
        percentage: 5,
        icon: '💼',
      ),
    ],
  };

// Add a new method to get income data
  static Future<List<ChartData>> getIncomeChartData({int? year, int? month}) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    // Create actual search key: 'YYYY-MM'
    final key = '$targetYear-${targetMonth.toString().padLeft(2, '0')}';

    // Get income data
    List<ChartData> data = _monthlyIncomeData[key] ?? [];

    // If no data, return sample data
    if (data.isEmpty) {
      final mockKey = '2025-${targetMonth.toString().padLeft(2, '0')}';
      data = _monthlyIncomeData[mockKey] ?? [];
    }

    if (data.isEmpty) {
      return [];
    }

    // Recalculate the percentage
    final totalAmount = data.fold<double>(0, (sum, item) => sum + item.amount);
    if (totalAmount == 0) return data;

    return data.map((item) {
      double calculatedPercentage = (item.amount / totalAmount) * 100;
      return ChartData(
        category: item.category,
        amount: item.amount,
        percentage: calculatedPercentage.roundToDouble(),
        icon: item.icon,
      );
    }).toList();
  }
}
