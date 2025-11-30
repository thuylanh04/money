import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manage/models/chart_data.dart';
import 'package:money_manage/services/chart_service.dart';
// Giả định file AppTheme tồn tại để sử dụng màu sắc
import 'package:money_manage/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

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
  final ScrollController _scrollController = ScrollController();

  // Trạng thái phân tích (Chi tiêu/Thu nhập)
  bool _isExpenseAnalysis = true;
  bool _isLoading = true;

  // Lưu trữ riêng dữ liệu chi tiêu và thu nhập
  List<ChartData> _expenseData = [];
  List<ChartData> _incomeData = [];

  // Getter để lấy dữ liệu hiện tại
  List<ChartData> get _currentData => _isExpenseAnalysis ? _expenseData : _incomeData;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _initializeTimeFilters();
    _loadBothChartData(); // Tải cả 2 loại dữ liệu
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Xử lý sự kiện scroll nếu cần
  }

  // Tải song song dữ liệu chi tiêu và thu nhập
  Future<void> _loadBothChartData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final year = _selectedFilter['year'] as int;
    final month = _selectedFilter['month'] as int;

    try {
      final expenseFuture = ChartService.getExpenseChartData(year: year, month: month);
      final incomeFuture = ChartService.getIncomeChartData(year: year, month: month);

      final results = await Future.wait([expenseFuture, incomeFuture]);

      if (!mounted) return;
      
      setState(() {
        _expenseData = results[0];
        _incomeData = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Xử lý lỗi nếu cần
      if (kDebugMode) {
        print('Error loading chart data: $e');
      }
    }
  }

  // Chuyển đổi giữa chi tiêu và thu nhập
  void _toggleAnalysisType(bool isExpense) {
    if (_isExpenseAnalysis != isExpense) {
      setState(() {
        _isExpenseAnalysis = isExpense;
      });
    }
  }

  // Khởi tạo bộ lọc thời gian (12 tháng gần nhất)
  void _initializeTimeFilters() {
    final now = DateTime.now();

    // Tạo danh sách 12 tháng từ tháng hiện tại lùi về
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

    // Set tháng hiện tại là mặc định (phần tử cuối cùng)
    _selectedFilter = _timeFilters.last;
    
    // Tự động cuộn đến tháng hiện tại sau khi UI được build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedMonth();
    });
  }
  
  // Cuộn đến tháng được chọn
  void _scrollToSelectedMonth() {
    if (_scrollController.hasClients) {
      final index = _timeFilters.indexWhere(
        (filter) => filter['key'] == _selectedFilter['key']
      );
      if (index != -1) {
        final double itemWidth = 100.0; // Chiều rộng ước tính của mỗi mục lọc
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

  // Widget hiển thị Tổng tiền (Chi tiêu/Thu nhập)
  Widget _buildTotalExpenseCard(double totalAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isExpenseAnalysis ? 'Tổng chi tiêu' : 'Tổng thu nhập',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatCurrency(totalAmount)} VND',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isExpenseAnalysis
                ? Colors.red[700] // Màu đỏ cho chi tiêu
                : Colors.green[700], // Màu xanh lá cho thu nhập
          ),
        ),
      ],
    );
  }

  // Tải dữ liệu biểu đồ dựa trên bộ lọc được chọn
  void _loadChartData() {
    _loadBothChartData();
  }

  // Áp dụng bộ lọc mới và tải lại dữ liệu
  void _applyFilter(Map<String, dynamic> filter) {
    // Không tải lại nếu bộ lọc không thay đổi
    if (_selectedFilter['key'] == filter['key']) return;

    setState(() {
      _selectedFilter = filter;
    });

    _loadChartData();
    _scrollToSelectedMonth();
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

  // Widget xây dựng nút chuyển đổi giữa Chi tiêu và Thu nhập
  Widget _buildAnalysisTypeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // Nút Chi tiêu
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleAnalysisType(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _isExpenseAnalysis
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'Chi tiêu',
                    style: TextStyle(
                      color: _isExpenseAnalysis ? Colors.white : Colors.grey[700],
                      fontWeight: _isExpenseAnalysis ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Nút Thu nhập
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleAnalysisType(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: !_isExpenseAnalysis
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'Thu nhập',
                    style: TextStyle(
                      color: !_isExpenseAnalysis ? Colors.white : Colors.grey[700],
                      fontWeight: !_isExpenseAnalysis ? FontWeight.bold : FontWeight.normal,
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
    // Tính tổng tiền (chi tiêu hoặc thu nhập) của tháng hiện tại
    final totalAmount = _currentData.fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        centerTitle: true,
        // Thanh lọc thời gian và nút chuyển đổi
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

                  // THẺ TỔNG TIỀN Ở TRÊN CÙNG
                  _buildTotalExpenseCard(totalAmount),

                  const SizedBox(height: 24),

                  // Hiển thị Biểu đồ hoặc Thông báo rỗng
                  _currentData.isEmpty
                      ? Center(
                          child: Text(
                            _isExpenseAnalysis
                                ? 'Không có chi tiêu nào trong ${_selectedFilter['label']}'
                                : 'Không có thu nhập nào trong ${_selectedFilter['label']}',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      // HIỂN THỊ BIỂU ĐỒ
                      : _buildExpenseChart(_currentData, totalAmount),

                  const SizedBox(height: 24),

                  // Danh sách chi tiết
                  if (_currentData.isNotEmpty) _buildExpenseList(_currentData),
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

  // Widget xây dựng biểu đồ tròn
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

  // Hàm tạo các lát cắt cho PieChart
  List<PieChartSectionData> _chartSections(List<ChartData> data) {
    // Hàm tạo màu ngẫu nhiên dựa trên tên danh mục
    Color getColorForCategory(String category, bool isExpense) {
      // Tạo một mã băm từ tên danh mục để đảm bảo tính nhất quán
      final hash = category.hashCode.abs();
      
      // Chọn bảng màu dựa trên loại (chi tiêu hoặc thu nhập)
      final hueRange = isExpense 
          ? const [0, 60] // Đỏ đến vàng
          : [80, 180];    // Xanh lá đến xanh dương
      
      // Tạo màu dựa trên mã băm
      return HSLColor.fromAHSL(
        1.0, // Độ trong suốt
        (hash % (hueRange[1] - hueRange[0]) + hueRange[0]).toDouble(), // Màu sắc
        0.7, // Độ bão hòa
        0.6, // Độ sáng
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

  // Widget xây dựng danh sách chi tiết
  Widget _buildExpenseList(List<ChartData> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isExpenseAnalysis ? 'Chi tiết chi tiêu' : 'Chi tiết thu nhập',
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

  // Widget xây dựng từng mục chi tiêu trong danh sách
  Widget _buildExpenseItem(ChartData item) {
    // GIẢ ĐỊNH: Số lượng giao dịch là hằng số hoặc được lấy từ service
    const int transactionCount = 7;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
            '${_isExpenseAnalysis ? '-' : '+'}${_formatCurrency(item.amount)} VND',
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
