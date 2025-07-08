import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF223A5E); // Deep Blue
  static const Color teal = Color(0xFF26A69A); // Teal
  static const Color accentYellow = Color(0xFFFFD600); // Yellow
  
  // Background Colors
  static const Color background = Color(0xFFF6F7FB); // Very light blue/gray
  static const Color card = Colors.white;
  
  // Status Colors
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color info = Colors.blue;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF223A5E);
  static const Color textSecondary = Color(0xFF223A5E);
  
  // Opacity Colors
  static Color get backgroundOverlay => Colors.black.withOpacity(0.08);
  static Color get cardShadow => Colors.black.withOpacity(0.05);
  static Color get cardShadowLight => Colors.black.withOpacity(0.04);
} 