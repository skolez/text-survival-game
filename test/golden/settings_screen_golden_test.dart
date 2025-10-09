import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zombie_survival_game/screens/settings_screen.dart';

void main() {
  testGoldens('SettingsScreen golden (dark and light)', (tester) async {
    SharedPreferences.setMockInitialValues({'theme': 'dark'});

    await tester.pumpWidgetBuilder(
      const SettingsScreen(),
      wrapper: materialAppWrapper(theme: ThemeData.dark()),
      surfaceSize: const Size(1024, 768),
    );
    await screenMatchesGolden(tester, 'settings_screen_dark');

    // Switch to light theme and re-pump
    SharedPreferences.setMockInitialValues({'theme': 'light'});
    await tester.pumpWidgetBuilder(
      const SettingsScreen(),
      wrapper: materialAppWrapper(theme: ThemeData.light()),
      surfaceSize: const Size(1024, 768),
    );
    await screenMatchesGolden(tester, 'settings_screen_light');
  });
}

