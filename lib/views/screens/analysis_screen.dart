import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manage/models/chart_data.dart';
import 'package:money_manage/services/chart_service.dart';
// Giả định file AppTheme tồn tại để sử dụng màu sắc
import 'package:money_manage/theme/app_theme.dart';
import 'package:intl/intl.dart';

// CHUYỂN TỪ StatelessWidget SANG StatefulWidget
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  // Biến trạng thái cho bộ lọc thời gian
  late List<Map<String, dynamic>> _timeFilters;
  late Map<String, dynamic> _selectedFilter;

  // Dữ liệu chi tiêu cho tháng được chọn
  List<ChartData> _chartData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeTimeFilters();
    _loadChartData();
  }

  // Khởi tạo bộ lọc thời gian (12 tháng gần nhất)
  void _initializeTimeFilters() {
    final now = DateTime.now();

    // Tạo danh sách 12 tháng từ tháng hiện tại lùi về
    final tempFilters = List.generate(12, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      final monthName = DateFormat('MMM yyyy').format(date);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      return {
        'label': monthName,
        'year': date.year,
        'month': date.month,
        'key': monthKey,
      };
    });

    // Đảo ngược danh sách (từ cũ nhất đến mới nhất)
    _timeFilters = tempFilters.reversed.toList();

    // Set tháng hiện tại là mặc định (phần tử cuối cùng)
    _selectedFilter = _timeFilters.last;
  }

  // Widget hiển thị Tổng chi tiêu (Đã loại bỏ Card và Elevation)
  Widget _buildTotalExpenseCard(double totalAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text(
        //   'Tổng chi tiêu tháng này',
        //   style: TextStyle(
        //     fontSize: 14,
        //     color: Colors.grey,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
        const SizedBox(height: 4),
        Text(
          '${_formatCurrency(totalAmount)} VND',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            // Sử dụng màu chủ đạo của Theme
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  // Tải dữ liệu biểu đồ dựa trên bộ lọc được chọn
  void _loadChartData() {
    setState(() {
      _isLoading = true;
    });

    final year = _selectedFilter['year'] as int;
    final month = _selectedFilter['month'] as int;

    // Sử dụng service để lấy dữ liệu đã được lọc
    _chartData = ChartService.getExpenseChartData(year: year, month: month);

    setState(() {
      _isLoading = false;
    });
  }

  // Áp dụng bộ lọc mới và tải lại dữ liệu
  void _applyFilter(Map<String, dynamic> filter) {
    // Không tải lại nếu bộ lọc không thay đổi
    if (_selectedFilter['key'] == filter['key']) return;

    setState(() {
      _selectedFilter = filter;
    });

    _loadChartData();
  }

  // Helper method để định dạng tiền tệ (VD: 1,000,000)
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'vi_VN');
    return formatter.format(amount);
  }

  // Helper method để lấy màu cho danh mục (Đã chỉnh màu khớp)
  Color _getColorForCategory(String category) {
    // Dùng mã màu Hex/RGB cụ thể để đảm bảo tính nhất quán
    final colors = {
      // Màu Xanh Lá (Green) cho Ăn uống
      'Ăn uống': const Color(0xFF4CAF50),
      // Màu Xanh Dương (Blue) cho Mua sắm
      'Mua sắm': const Color(0xFF2196F3),
      // Màu Cam (Orange) cho Di chuyển
      'Di chuyển': const Color(0xFFFF9800),
      // Màu Tím (Purple) cho Giải trí
      'Giải trí': const Color(0xFF9C27B0),
      // Màu Xám Xanh (Blue Grey) cho Khác
      'Khác': const Color(0xFF607D8B),
    };
    return colors[category] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    // Tính tổng chi tiêu của tháng hiện tại
    final totalExpense =
        _chartData.fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Analysis'),
        centerTitle: true,
        // Thanh lọc thời gian ở dưới AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildTimeFilterBar(context),
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

                  // THẺ TỔNG CHI TIÊU Ở TRÊN CÙNG
                  _buildTotalExpenseCard(totalExpense),

                  const SizedBox(height: 24),

                  // Hiển thị Biểu đồ hoặc Thông báo rỗng
                  _chartData.isEmpty
                      ? Center(
                          child: Text(
                            'Không có chi tiêu nào trong ${_selectedFilter['label']}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        )
                      // BIỂU ĐỒ TRÒN (Không còn tổng tiền ở giữa)
                      : _buildExpenseChart(_chartData, totalExpense),

                  const SizedBox(height: 24),

                  // Danh sách chi tiết
                  if (_chartData.isNotEmpty) _buildExpenseList(_chartData),
                ],
              ),
            ),
    );
  }

  // Widget xây dựng thanh lọc thời gian
  Widget _buildTimeFilterBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
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

  // Widget xây dựng biểu đồ tròn
  Widget _buildExpenseChart(List<ChartData> data, double totalAmount) {
    return Center(
      child: SizedBox(
        height: 220,
        width: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sections: _chartSections(data),
                sectionsSpace: 2,
                centerSpaceRadius: 60, // Giữ khoảng trống ở giữa
                pieTouchData: PieTouchData(enabled: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm tạo các lát cắt cho PieChart
  List<PieChartSectionData> _chartSections(List<ChartData> data) {
    return data.map((item) {
      return PieChartSectionData(
        color: _getColorForCategory(item.category),
        value: item.percentage,
        title: '${item.percentage.toInt()}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Widget xây dựng danh sách chi tiết
  Widget _buildExpenseList(List<ChartData> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi tiết chi tiêu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...data.map((item) => _buildExpenseItem(item)).toList(),
      ],
    );
  }

  // Widget xây dựng từng mục chi tiêu trong danh sách
  Widget _buildExpenseItem(ChartData item) {
    // GIẢ ĐỊNH: Số lượng giao dịch là hằng số hoặc được lấy từ service
    const int transactionCount = 7;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getColorForCategory(item.category).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.icon,
                style: TextStyle(
                  fontSize: 22,
                  color: _getColorForCategory(item.category),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Danh mục và số giao dịch
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$transactionCount Transactions',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey, // Giả định AppTheme.textSecondary
                  ),
                ),
              ],
            ),
          ),
          // Số tiền chi tiêu
          Text(
            '-${_formatCurrency(item.amount)} VND',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}
