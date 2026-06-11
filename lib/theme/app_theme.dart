import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData getTheme(bool isDark, String themeName) {
    if (themeName == 'sakura') {
      return isDark ? darkSakuraTheme : lightSakuraTheme;
    }
    return isDark ? darkTheme : lightTheme;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        primaryContainer: AppColors.lightPrimaryContainer,
        onPrimaryContainer: AppColors.lightOnPrimaryContainer,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightOnSecondary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        error: AppColors.lightError,
        onError: AppColors.lightOnError,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: Colors.grey.shade100,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: AppColors.darkOnPrimaryContainer,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnSecondary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.shade900,
            width: 1,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: Colors.grey.shade900,
      ),
    );
  }

  static ThemeData get lightSakuraTheme {
    return lightTheme.copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE91E63), // Pink
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFFCE4EC), // Light Pink Container
        onPrimaryContainer: Color(0xFF880E4F),
        secondary: Color(0xFF880E4F),
        onSecondary: Colors.white,
      ),
    );
  }

  static ThemeData get darkSakuraTheme {
    return darkTheme.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF80AB), // Pink glow
        onPrimary: Color(0xFF880E4F),
        primaryContainer: Color(0xFF880E4F),
        onPrimaryContainer: Color(0xFFFF80AB),
        secondary: Color(0xFFFF80AB),
        onSecondary: Color(0xFF880E4F),
      ),
    );
  }
}
