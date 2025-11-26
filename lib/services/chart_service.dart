import 'package:money_manage/models/chart_data.dart';

class ChartService {
  static List<ChartData> getExpenseChartData() {
    return [
      ChartData(
        category: 'Ăn uống',
        amount: 2500000,
        percentage: 35,
        icon: '🍔',
      ),
      ChartData(
        category: 'Mua sắm',
        amount: 1800000,
        percentage: 25,
        icon: '🛍️',
      ),
      ChartData(
        category: 'Di chuyển',
        amount: 1200000,
        percentage: 17,
        icon: '🚕',
      ),
      ChartData(
        category: 'Giải trí',
        amount: 900000,
        percentage: 13,
        icon: '🎮',
      ),
      ChartData(
        category: 'Khác',
        amount: 600000,
        percentage: 10,
        icon: '📌',
      ),
    ];
  }

  static List<Map<String, dynamic>> getMonthlyData() {
    return [
      {
        'month': 'T9',
        'expense': 8000000,
        'income': 15000000,
      },
      {
        'month': 'T10',
        'expense': 12000000,
        'income': 18000000,
      },
      {
        'month': 'T11',
        'expense': 15000000,
        'income': 20000000,
      },
      {
        'month': 'T12',
        'expense': 18000000,
        'income': 22000000,
      },
    ];
  }
}
