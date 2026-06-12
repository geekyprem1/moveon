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
      scaffoldBackgroundColor: AppColors.lightBackground,
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
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: AppColors.lightOnSurface.withAlpha(20),
            width: 1.0,
          ),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
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
        color: AppColors.lightOnSurface.withAlpha(15),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
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
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: AppColors.darkOnSurface.withAlpha(20),
            width: 1.0,
          ),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
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
        color: AppColors.darkOnSurface.withAlpha(15),
      ),
    );
  }

  static ThemeData get lightSakuraTheme {
    return lightTheme.copyWith(
      colorScheme: lightTheme.colorScheme.copyWith(
        primary: const Color(0xFFC76D8A), // Soft pink
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFFAF0F2), // Very soft warm pink container
        onPrimaryContainer: const Color(0xFF673243),
        secondary: const Color(0xFF673243),
        onSecondary: Colors.white,
      ),
    );
  }

  static ThemeData get darkSakuraTheme {
    return darkTheme.copyWith(
      colorScheme: darkTheme.colorScheme.copyWith(
        primary: const Color(0xFFF3B8C9), // Light glowing pink
        onPrimary: const Color(0xFF673243),
        primaryContainer: const Color(0xFF381C25),
        onPrimaryContainer: const Color(0xFFF3B8C9),
        secondary: const Color(0xFFF3B8C9),
        onSecondary: const Color(0xFF673243),
      ),
    );
  }
}
