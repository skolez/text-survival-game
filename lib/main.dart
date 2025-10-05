import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const ZombieSurvivalApp());
}

class ZombieSurvivalApp extends StatelessWidget {
  const ZombieSurvivalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zombie Survival Story',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontFamily: 'monospace'),
          bodyMedium: TextStyle(color: Colors.white, fontFamily: 'monospace'),
          headlineLarge: TextStyle(color: Colors.red, fontFamily: 'monospace', fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.red, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[800],
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
