import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppTextStyles {
  static final question = GoogleFonts.nunito(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
  );
  static final description = GoogleFonts.nunito(
    fontSize: 13,
    color: AppColors.primaryBlue.withOpacity(0.7),
  );
  static final answer = GoogleFonts.nunito(
    fontSize: 15,
    color: AppColors.primaryBlue.withOpacity(0.85),
  );
  static final header = GoogleFonts.nunito(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
  );
  // Add more as needed for your app
} 