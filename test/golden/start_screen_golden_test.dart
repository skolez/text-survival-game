import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zombie_survival_game/screens/start_screen.dart';

void main() {
  testGoldens('StartScreen golden', (tester) async {
    // Initialize mock shared preferences so StartScreen initState can read safely.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidgetBuilder(
      const StartScreen(),
      wrapper: materialAppWrapper(theme: ThemeData.dark()),
      surfaceSize: const Size(1024, 768),
    );
    await screenMatchesGolden(tester, 'start_screen');
  });
}
