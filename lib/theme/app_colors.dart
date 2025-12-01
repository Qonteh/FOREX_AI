import 'package:flutter/material.dart';

class AppColors {
  // Primary colors from your logo
  static const Color primaryPurple = Color(0xFF8B5FBF); // Purple from logo
  static const Color primaryNavy = Color(0xFF2D3748);    // Dark navy from logo
  static const Color primaryWhite = Color(0xFFFFFFFF);   // Main white color
  
  // Secondary colors
  static const Color lightPurple = Color(0xFFB794F6);
  static const Color darkNavy = Color(0xFF1A202C);
  static const Color lightGray = Color(0xFFF8F9FA);      // VERY LIGHT GRAY BRO!
  static const Color mediumGray = Color(0xFFE2E8F0);
  
  // Trading specific colors
  static const Color bullishGreen = Color(0xFF48BB78);
  static const Color bearishRed = Color(0xFFE53E3E);
  static const Color warningOrange = Color(0xFFED8936);
  
  // Text colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textLight = Color(0xFF718096);
  
  // Background colors - ALL WHITE BRO!
  static const Color background = Color(0xFFFFFFFF);     // WHITE!
  static const Color surface = Color(0xFFFFFFFF);        // WHITE!
  static const Color cardBackground = Color(0xFFFFFFFF); // WHITE!
  
  // CANDLE COLORS FOR TRADING CHART - ADDED THESE!
  static const Color greenCandle = Color(0xFF00C853);    // Green for positive/buy candles
  static const Color redCandle = Color(0xFFD32F2F);      // Red for negative/sell candles
  
  // Additional trading colors for better visual hierarchy
  static const Color lightGreen = Color(0xFFC8F5C8);     // Light green for backgrounds
  static const Color lightRed = Color(0xFFFFE5E5);       // Light red for backgrounds
  static const Color lightPurpleBackground = Color(0xFFF3E8FF); // Light purple for highlights
  
  // Chart specific colors
  static const Color chartGrid = Color(0xFFE2E8F0);
  static const Color chartText = Color(0xFF4A5568);
  static const Color chartBackground = Color(0xFFFFFFFF);

  // Legacy support
  static const Color backgroundLight = Color(0xFFFFFFFF);  // WHITE!
  static const Color backgroundDark = Color(0xFF1A202C);
  static const Color surfaceLight = Color(0xFFFFFFFF);     // WHITE!
  static const Color surfaceDark = Color(0xFF2D3748);
}