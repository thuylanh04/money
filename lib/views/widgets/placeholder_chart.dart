import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Placeholder for the report chart.
/// TODO: Replace with an actual chart package (e.g., fl_chart or charts_flutter) when integrating.
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
