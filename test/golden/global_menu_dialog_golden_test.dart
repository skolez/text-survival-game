import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:zombie_survival_game/widgets/keyboard_dialog.dart';

void main() {
  testGoldens('Global Menu dialog golden', (tester) async {
    final dialog = KeyboardDialog(
      title: 'Global Commands',
      options: [
        DialogOption(title: 'Show Status', icon: Icons.health_and_safety, iconColor: Colors.red, onTap: () {}),
        DialogOption(title: 'Inventory', icon: Icons.inventory, iconColor: Colors.blue, onTap: () {}),
        DialogOption(title: 'Save Game', icon: Icons.save, iconColor: Colors.green, onTap: () {}),
        DialogOption(title: 'Load Game', icon: Icons.folder_open, iconColor: Colors.orange, onTap: () {}),
        DialogOption(title: 'Help', icon: Icons.help, iconColor: Colors.purple, onTap: () {}),
        DialogOption(title: 'Settings', icon: Icons.settings, iconColor: Colors.grey, onTap: () {}),
        DialogOption(title: 'Go to Home Screen', icon: Icons.home, iconColor: Colors.teal, onTap: () {}),
      ],
    );

    await tester.pumpWidgetBuilder(
      MaterialApp(home: Scaffold(body: Center(child: dialog))),
      surfaceSize: const Size(1024, 768),
    );

    await screenMatchesGolden(tester, 'global_menu_dialog');
  });
}

