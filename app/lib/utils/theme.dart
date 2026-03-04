import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

// Configures the global theme using Google Fonts (Inter) and AppColors.
class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.inter().fontFamily,

      // Define the AppBar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.background,
        iconTheme: IconThemeData(color: AppColors.mainText),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.mainText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Define the TextTheme
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.mainText, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.mainText),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.mainText),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppColors.mainText),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.secondaryText),
        labelMedium: GoogleFonts.inter(fontSize: 12, color: AppColors.secondaryText),
      ),

      // Define Card theme
      cardTheme: CardThemeData(


                elevation: 0,
        color: AppColors.cardBackground,
        surfaceTintColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),

      // Define BottomNavigationBar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.primary, // Purple for active tab
        unselectedItemColor: AppColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),

      // Define ElevatedButton theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}