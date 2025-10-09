import 'package:flutter/material.dart';

import 'constants/app_theme.dart';
import 'screens/start_screen.dart';
import 'utils/platform_utils.dart';

void main() {
  runApp(const ZombieSurvivalApp());
}

class ZombieSurvivalApp extends StatefulWidget {
  const ZombieSurvivalApp({super.key});

  @override
  State<ZombieSurvivalApp> createState() => _ZombieSurvivalAppState();
}

class _ZombieSurvivalAppState extends State<ZombieSurvivalApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zombie Survival Story',
      theme: _buildTheme(),
      home: const StartScreen(),
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: AppTheme.currentTheme == AppThemeMode.dark
          ? Brightness.dark
          : Brightness.light,
      scaffoldBackgroundColor: AppTheme.backgroundColor,
      primaryColor: AppTheme.primaryColor,
      cardColor: AppTheme.cardColor,
      textTheme: TextTheme(
        bodyLarge:
            TextStyle(color: AppTheme.textColor, fontFamily: 'monospace'),
        bodyMedium:
            TextStyle(color: AppTheme.textColor, fontFamily: 'monospace'),
        headlineLarge: TextStyle(
          color: AppTheme.primaryColor,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppTheme.primaryColor,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppTheme.actionButtonStyle,
      ),
      appBarTheme: AppTheme.appBarTheme,
      dialogTheme: DialogThemeData(
        backgroundColor: AppTheme.backgroundColor,
        titleTextStyle: TextStyle(
          color: AppTheme.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: AppTheme.textColor,
          fontSize: 14,
        ),
      ),
    );
  }
}
