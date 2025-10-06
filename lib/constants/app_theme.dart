import 'package:flutter/material.dart';

/// Centralized theme configuration for the Zombie Survival Game
/// Matrix-inspired green theme with consistent styling across all screens
class AppTheme {
  // Core Colors
  static const Color backgroundColor = Colors.black;
  static const Color primaryColor = Color(0xFF00FF41); // Matrix green
  static const Color textColor = Color(0xFF00FF41); // Matrix green
  static const Color borderColor = Color(0xFF00FF41); // Matrix green
  
  // Secondary Colors
  static const Color disabledColor = Colors.grey;
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
    side: const BorderSide(color: borderColor, width: borderWidth),
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
    shape: const Border(
      bottom: BorderSide(color: borderColor, width: borderWidth),
    ),
    titleTextStyle: const TextStyle(
      color: textColor,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: const IconThemeData(color: textColor),
  );
  
  /// Container decoration for panels and status bars
  static BoxDecoration get panelDecoration => BoxDecoration(
    color: backgroundColor,
    border: Border.all(color: borderColor, width: borderWidth),
    borderRadius: BorderRadius.circular(borderRadius),
  );
  
  /// Text style for narrative/story text
  static const TextStyle narrativeTextStyle = TextStyle(
    color: textColor,
    fontFamily: 'monospace',
    fontSize: 14,
  );
  
  /// Text style for UI labels
  static const TextStyle labelTextStyle = TextStyle(
    color: textColor,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );
  
  /// Text style for small UI text
  static const TextStyle smallTextStyle = TextStyle(
    color: textColor,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
  
  /// Number circle decoration for action buttons
  static BoxDecoration get numberCircleDecoration => BoxDecoration(
    color: primaryColor.withOpacity(0.3),
    borderRadius: BorderRadius.circular(11),
    border: Border.all(color: borderColor, width: borderWidth),
  );
}
