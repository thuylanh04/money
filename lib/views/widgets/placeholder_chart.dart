import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Placeholder cho biểu đồ báo cáo.
/// TODO: Thay bằng package chart thực (ví dụ fl_chart hoặc charts_flutter) khi tích hợp.
class PlaceholderChart extends StatelessWidget {
  final double height;

  const PlaceholderChart({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Chart placeholder',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    );
  }
}
