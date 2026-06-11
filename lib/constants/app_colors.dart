import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF6750A4);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFEADDFF);
  static const Color lightOnPrimaryContainer = Color(0xFF21005D);
  static const Color lightSecondary = Color(0xFF625B71);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFFEF7FF);
  static const Color lightOnBackground = Color(0xFF1D1B20);
  static const Color lightSurface = Color(0xFFFEF7FF);
  static const Color lightOnSurface = Color(0xFF1D1B20);
  static const Color lightError = Color(0xFFB3261E);
  static const Color lightOnError = Color(0xFFFFFFFF);

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFFD0BCFF);
  static const Color darkOnPrimary = Color(0xFF381E72);
  static const Color darkPrimaryContainer = Color(0xFF4F378B);
  static const Color darkOnPrimaryContainer = Color(0xFFEADDFF);
  static const Color darkSecondary = Color(0xFFCCC2DC);
  static const Color darkOnSecondary = Color(0xFF332D41);
  static const Color darkBackground = Color(0xFF141218);
  static const Color darkOnBackground = Color(0xFFE6E1E5);
  static const Color darkSurface = Color(0xFF1D1B20);
  static const Color darkOnSurface = Color(0xFFE6E1E5);
  static const Color darkError = Color(0xFFF2B8B5);
  static const Color darkOnError = Color(0xFF601410);

  // Custom Recovery Score / Mood Colors
  static const Color scoreShock = Color(0xFFEF5350);       // Soft Red
  static const Color scoreWithdrawal = Color(0xFFFF9800);  // Warm Orange
  static const Color scoreHealing = Color(0xFFFFEB3B);     // Gentle Yellow
  static const Color scoreGrowth = Color(0xFF4CAF50);      // Healing Green
  static const Color scoreMoveOn = Color(0xFF00BCD4);      // Serene Cyan

  static Color getScoreColor(double score) {
    if (score <= 20) return scoreShock;
    if (score <= 40) return scoreWithdrawal;
    if (score <= 60) return scoreHealing;
    if (score <= 80) return scoreGrowth;
    return scoreMoveOn;
  }
}
