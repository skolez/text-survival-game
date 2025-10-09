import 'package:flutter/material.dart';

enum AppThemeMode { dark, light }

/// Centralized theme configuration for the Zombie Survival Game
/// Supports both dark mode (Matrix green) and light mode themes
class AppTheme {
  static AppThemeMode _currentTheme = AppThemeMode.dark;

  static AppThemeMode get currentTheme => _currentTheme;

  static void setTheme(AppThemeMode theme) {
    _currentTheme = theme;
  }

  // Core Colors - Dynamic based on theme
  static Color get backgroundColor =>
      _currentTheme == AppThemeMode.dark ? Colors.black : Colors.white;
  static Color get primaryColor => _currentTheme == AppThemeMode.dark
      ? const Color(0xFF00FF41)
      : const Color(0xFF006B1A); // Matrix green / Dark green
  static Color get textColor => _currentTheme == AppThemeMode.dark
      ? const Color(0xFF00FF41)
      : const Color(0xFF006B1A);
  static Color get borderColor => _currentTheme == AppThemeMode.dark
      ? const Color(0xFF00FF41)
      : const Color(0xFF006B1A);
  static Color get surfaceColor => _currentTheme == AppThemeMode.dark
      ? Colors.grey[900]!
      : Colors.grey[100]!;
  static Color get cardColor =>
      _currentTheme == AppThemeMode.dark ? Colors.grey[850]! : Colors.grey[50]!;
  static Color get disabledColor => _currentTheme == AppThemeMode.dark
      ? Colors.grey[600]!
      : Colors.grey[400]!;

  // Secondary Colors
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.yellow;

  // Border and Layout
  static const double borderWidth = 1.0;
  static const double borderRadius = 8.0;
  static const double elevation = 3.0;

  // Status Colors (for health, stats, etc.)
  static const Color healthyColor = Color(0xFF00FF41); // 66-100%
  static const Color warningStatusColor = Colors.yellow; // 33-65%
  static const Color criticalColor = Colors.red; // 0-32%

  /// Get status color based on percentage value
  static Color getStatusColor(double value) {
    if (value >= 66) return healthyColor;
    if (value >= 33) return warningStatusColor;
    return criticalColor;
  }

  /// Standard button style for action buttons
  static ButtonStyle get actionButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        side: BorderSide(color: borderColor, width: borderWidth),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: elevation,
      );

  /// App bar theme
  static AppBarTheme get appBarTheme => AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: elevation,
        shape: Border(
          bottom: BorderSide(color: borderColor, width: borderWidth),
        ),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textColor),
      );

  /// Container decoration for panels and status bars
  static BoxDecoration get panelDecoration => BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(borderRadius),
      );

  /// Text style for narrative/story text
  static TextStyle get narrativeTextStyle => TextStyle(
        color: textColor,
        fontFamily: 'monospace',
        fontSize: 14,
      );

  /// Text style for UI labels
  static TextStyle get labelTextStyle => TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      );

  /// Text style for small UI text
  static TextStyle get smallTextStyle => TextStyle(
        color: textColor,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      );

  /// Number circle decoration for action buttons
  static BoxDecoration get numberCircleDecoration => BoxDecoration(
        color: primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor, width: borderWidth),
      );
}
