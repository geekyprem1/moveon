import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Light Theme Colors (Organic Luxury Wellness)
  static const Color lightPrimary = Color(0xFF5A5266);          // Lavender Slate
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFF3EFF5);   // Soft Mist
  static const Color lightOnPrimaryContainer = Color(0xFF2A2433);
  static const Color lightSecondary = Color(0xFF8AA194);          // Sage Green
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFFDFBF7);         // Alabaster Warm White
  static const Color lightOnBackground = Color(0xFF2A292E);
  static const Color lightSurface = Color(0xFFFAF8F5);            // Eggshell
  static const Color lightOnSurface = Color(0xFF2A292E);
  static const Color lightError = Color(0xFFC76D6A);
  static const Color lightOnError = Color(0xFFFFFFFF);

  // Dark Theme Colors (Midnight Charcoal)
  static const Color darkPrimary = Color(0xFFC8BBD8);           // Pale Lavender
  static const Color darkOnPrimary = Color(0xFF2A2433);
  static const Color darkPrimaryContainer = Color(0xFF211E26);    // Midnight Violet
  static const Color darkOnPrimaryContainer = Color(0xFFE4DDE9);
  static const Color darkSecondary = Color(0xFFA3B5AB);           // Muted Sage
  static const Color darkOnSecondary = Color(0xFF212623);
  static const Color darkBackground = Color(0xFF0F0E11);          // Deep Charcoal Slate
  static const Color darkOnBackground = Color(0xFFE5E3E8);
  static const Color darkSurface = Color(0xFF17161A);             // Charcoal Card
  static const Color darkOnSurface = Color(0xFFE5E3E8);
  static const Color darkError = Color(0xFFD48B89);
  static const Color darkOnError = Color(0xFF471A1A);

  // Custom Recovery Score / Mood Colors (Soft Pastel Gradients)
  static const Color scoreShock = Color(0xFFE28D8A);       // Pastel Red
  static const Color scoreWithdrawal = Color(0xFFE4B38A);  // Pastel Peach
  static const Color scoreHealing = Color(0xFFE2D58A);     // Pastel Yellow
  static const Color scoreGrowth = Color(0xFFA1C3B1);      // Pastel Sage Green
  static const Color scoreMoveOn = Color(0xFF8EB8C3);      // Pastel Soothing Cyan

  static Color getScoreColor(double score) {
    if (score <= 20) return scoreShock;
    if (score <= 40) return scoreWithdrawal;
    if (score <= 60) return scoreHealing;
    if (score <= 80) return scoreGrowth;
    return scoreMoveOn;
  }
}
