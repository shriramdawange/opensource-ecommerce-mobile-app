import 'package:flutter/material.dart';

/// Design tokens extracted from Figma design
/// Light mode: node-id=92-1679
/// Dark mode: node-id=92-1730

class AppColors {
  // DARSH brand palette
  static const Color brandCoral = Color(0xFFFF5366);
  static const Color brandRose = Color(0xFFFF8290);
  static const Color brandBlush = Color(0xFFFFE8EC);
  static const Color brandCanvas = Color(0xFFF9F9FB);
  // Primary
  static const Color primary500 = Color(0xFFEA1A34);
  static const Color primary600 = Color(0xFFB91436);

  // Neutral - Light
  static const Color neutral50 = Color(0xFFF9F9FB);
  static const Color neutral100 = Color(0xFFF1F0F2);
  static const Color neutral200 = Color(0xFFE7E5E9);
  static const Color neutral300 = Color(0xFFD8D5DA);
  static const Color neutral400 = Color(0xFFAAA5AD);
  static const Color neutral500 = Color(0xFF77727A);
  static const Color neutral600 = Color(0xFF5C5760);
  static const Color neutral700 = Color(0xFF454149);
  static const Color neutral800 = Color(0xFF302D34);
  static const Color neutral900 = Color(0xFF25232A);

  // Status
  static const Color successGreen = Color(0xFF00A63E);
  static const Color success50 = Color(0xFFF0FDF4);
  static const Color success500 = Color(0xFF00C950);
  static const Color success700 = Color(0xFF008236);
  static const Color errorRed = Color(0xFFFB2C36);

  // Process / Info
  static const Color process600 = Color(0xFF155DFC);
  static const Color process700 = Color(0xFF1447E6);

  // Static
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

class AppTextStyles {
  /// Text-2: Roboto 500, 20px (auth heading)
  static TextStyle text2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w500,
      fontSize: 20,
      height: 1.17,
      color: isDark ? AppColors.neutral200 : AppColors.neutral800,
    );
  }

  /// Text-3: Roboto 600, 18px (section headers)
  static TextStyle text3(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w600,
      fontSize: 18,
      height: 1.17,
      color: isDark ? AppColors.neutral200 : AppColors.neutral900,
    );
  }

  /// Text-5: Roboto 400, 14px (body text)
  static TextStyle text5(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.17,
      color: isDark ? AppColors.neutral200 : AppColors.neutral800,
    );
  }

  /// Text-5 for dark mode category labels (semibold in dark)
  static TextStyle text5Category(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Roboto',
      fontWeight: isDark ? FontWeight.w600 : FontWeight.w400,
      fontSize: 14,
      height: 1.17,
      color: isDark ? AppColors.neutral200 : AppColors.neutral800,
    );
  }

  /// Text-6: Roboto 400, 12px (small text)
  static TextStyle text6(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.17,
      color: isDark ? AppColors.neutral300 : AppColors.neutral800,
    );
  }

  /// Price text: bold 18px
  static TextStyle priceText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w600,
      fontSize: 18,
      height: 1.17,
      color: isDark ? AppColors.white : AppColors.neutral900,
    );
  }

  /// Strikethrough price
  static TextStyle originalPriceText(BuildContext context) {
    return const TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.17,
      color: AppColors.neutral500,
      decoration: TextDecoration.lineThrough,
    );
  }

  /// Discount text
  static TextStyle discountText(BuildContext context) {
    return const TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.17,
      color: AppColors.primary500,
    );
  }

  /// Text-1: Roboto 600, 24px (large price)
  static TextStyle text1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w600,
      fontSize: 24,
      height: 1.17,
      color: isDark ? AppColors.neutral100 : AppColors.neutral900,
    );
  }

  /// Text-4: Roboto 600, 16px (section headers in product detail)
  static TextStyle text4(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 1.17,
      color: isDark ? AppColors.neutral100 : AppColors.black,
    );
  }

  /// Body text with 1.5x line height for descriptions
  static TextStyle bodyText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.5,
      color: isDark ? AppColors.neutral300 : AppColors.neutral800,
    );
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.white,
      visualDensity: VisualDensity.standard,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary500,
        secondary: AppColors.primary600,
        surface: AppColors.white,
        onSurface: AppColors.neutral900,
        outline: AppColors.neutral200,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.neutral50,
        selectedItemColor: AppColors.primary500,
        unselectedItemColor: AppColors.neutral800,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: AppColors.neutral100,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.neutral200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.neutral200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary500, width: 1.5)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.neutral900,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary500,
        secondary: AppColors.primary600,
        surface: AppColors.neutral900,
        onSurface: AppColors.neutral200,
        outline: AppColors.neutral800,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.neutral900,
        foregroundColor: AppColors.neutral200,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.neutral800,
        selectedItemColor: AppColors.primary500,
        unselectedItemColor: AppColors.neutral300,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.neutral800,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: AppColors.neutral800,
    );
  }
}
