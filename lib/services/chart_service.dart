import 'package:money_manage/models/chart_data.dart';
import 'package:intl/intl.dart'; // Cần thêm import này nếu chưa có

class ChartService {
  // Dữ liệu mẫu (Mock data) cho từng tháng (Tháng 12, 11, 10 năm 2025)
  static final Map<String, List<ChartData>> _monthlyExpenseData = {
    // Dữ liệu cho Tháng 12 năm 2025 (Tháng hiện tại - tổng 7,000,000 VND)
    '2025-12': [
      ChartData(
        category: 'Ăn uống',
        amount: 2500000, // Đã sửa lỗi số tiền
        percentage: 35, 
        icon: '🍽️',
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
        icon: '🚗',
      ),
      ChartData(
        category: 'Giải trí',
        amount: 900000,
        percentage: 13,
        icon: '🎬',
      ),
      ChartData(
        category: 'Khác',
        amount: 600000,
        percentage: 10,
        icon: '🏠',
      ),
    ],

    // Dữ liệu cho Tháng 11 năm 2025 (tổng 6,500,000 VND)
    '2025-11': [
      ChartData(
          category: 'Ăn uống', amount: 3000000, percentage: 46.15, icon: '🍽️'),
      ChartData(
          category: 'Mua sắm', amount: 1000000, percentage: 15.38, icon: '🛍️'),
      ChartData(
          category: 'Di chuyển', amount: 1500000, percentage: 23.08, icon: '🚗'),
      ChartData(
          category: 'Giải trí', amount: 500000, percentage: 7.69, icon: '🎬'),
      ChartData(category: 'Khác', amount: 500000, percentage: 7.69, icon: '🏠'),
    ],

    // Dữ liệu cho Tháng 10 năm 2025 (tổng 1,000,000 VND)
    '2025-10': [
      ChartData(
          category: 'Ăn uống', amount: 500000, percentage: 50, icon: '🍽️'),
      ChartData(category: 'Khác', amount: 500000, percentage: 50, icon: '🏠'),
    ],
  };

  static List<ChartData> getExpenseChartData({int? year, int? month}) {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    // 1. Tạo khóa tìm kiếm thực tế: 'YYYY-MM'
    final key = '$targetYear-${targetMonth.toString().padLeft(2, '0')}';

    // Sử dụng toán tử null-aware (??) để cung cấp giá trị mặc định là danh sách rỗng nếu không tìm thấy
    List<ChartData> data = _monthlyExpenseData[key] ?? [];

    // 2. Nếu không có dữ liệu thực tế (dữ liệu rỗng), thử lấy dữ liệu mock (giả định năm 2025)
    if (data.isEmpty) {
      final mockKey = '2025-${targetMonth.toString().padLeft(2, '0')}';
      data = _monthlyExpenseData[mockKey] ?? [];
    }

    // 3. Nếu vẫn không có dữ liệu sau khi kiểm tra mock, trả về danh sách rỗng
    if (data.isEmpty) {
      return [];
    }

    // TÍNH TOÁN LẠI PERCENTAGE
    final totalAmount = data.fold<double>(0, (sum, item) => sum + item.amount);

    // Tránh chia cho 0
    if (totalAmount == 0) return data;

    // Map lại dữ liệu với percentage đã tính toán lại
    return data.map((item) {
      double calculatedPercentage = (item.amount / totalAmount) * 100;
      return ChartData(
        category: item.category,
        amount: item.amount,
        // Cập nhật percentage được tính toán lại và làm tròn
        percentage: calculatedPercentage.roundToDouble(),
        icon: item.icon,
      );
    }).toList();
  }

  // Phương thức mẫu khác (giữ nguyên)
  static List<Map<String, dynamic>> getMonthlyData() {
    return [
      {'month': 'T9', 'expense': 8000000, 'income': 15000000},
      {'month': 'T10', 'expense': 12000000, 'income': 18000000},
      {'month': 'T11', 'expense': 15000000, 'income': 20000000},
      {'month': 'T12', 'expense': 18000000, 'income': 22000000},
    ];
  }
}