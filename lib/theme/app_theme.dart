import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme definition.
/// NOTE: Màu sắc, font, spacing được phỏng đoán dựa trên thiết kế tham chiếu.
class AppTheme {
  static const Color primaryGreen = Color(0xFF00C853); // phỏng đoán từ button xanh
  static const Color accentGreen = Color(0xFF00E676);
  static const Color backgroundGrey = Color(0xFFF5F5F7);
  static const Color textPrimary = Color(0xFF101010);
  static const Color textSecondary = Color(0xFF707070);
  static const Color error = Color(0xFFFF3B30); // Red color for errors and expenses

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: false);
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme);
    return base.copyWith(
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: base.colorScheme.copyWith(
        primary: primaryGreen,
        secondary: accentGreen,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
      ),
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
    );
  }
}
