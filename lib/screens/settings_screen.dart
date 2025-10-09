import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _darkMode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeStr = prefs.getString('theme') ?? 'dark';
      _darkMode = themeStr == 'dark';
      AppTheme.setTheme(_darkMode ? AppThemeMode.dark : AppThemeMode.light);
    } catch (_) {
      _darkMode = AppTheme.currentTheme == AppThemeMode.dark;
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveTheme(bool dark) async {
    AppTheme.setTheme(dark ? AppThemeMode.dark : AppThemeMode.light);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', dark ? 'dark' : 'light');
    } catch (_) {}
    setState(() {
      _darkMode = dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: AppTheme.panelDecoration,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dark Mode (Matrix Green)',
                      style: AppTheme.labelTextStyle),
                  Switch(
                    value: _darkMode,
                    thumbColor: WidgetStatePropertyAll(AppTheme.primaryColor),
                    onChanged: (v) => _saveTheme(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Theme changes apply immediately and persist across sessions.',
                style: AppTheme.smallTextStyle),
          ],
        ),
      ),
    );
  }
}
