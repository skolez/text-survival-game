import 'package:flutter/material.dart';

/// Optional bridge to translate a story theme preset into a Material ThemeData
/// without refactoring your existing AppTheme yet. Use if/when we want story-
/// specific themes at runtime.
class ThemePresetsBridge {
  static ThemeData toMaterialTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color text,
    required Color border,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.black,
      secondary: primary,
      onSecondary: Colors.black,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(background),
          foregroundColor: WidgetStatePropertyAll(text),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStatePropertyAll(BorderSide(color: border, width: 1)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      dividerColor: border.withValues(alpha: 0.4),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
      ),
    );
  }
}
