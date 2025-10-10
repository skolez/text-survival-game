import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zombie_survival_game/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Ensure screenshots directory exists
  final screenshotsDir = Directory('screenshots');
  if (!screenshotsDir.existsSync()) {
    screenshotsDir.createSync(recursive: true);
  }

  testWidgets('Start -> Difficulty -> Intro (screenshots)',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    await binding.takeScreenshot('01-start');

    // Tap NEW GAME on Start Screen
    final newGame = find.text('NEW GAME');
    expect(newGame, findsOneWidget);
    await tester.tap(newGame);
    await tester.pumpAndSettle();

    await binding.takeScreenshot('02-difficulty');

    // Confirm dialog by pressing "Start"
    final startBtn = find.text('Start');
    if (startBtn.evaluate().isNotEmpty) {
      await tester.tap(startBtn);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    await binding.takeScreenshot('03-intro_or_game');
  });

  testWidgets('Settings: open and toggle theme (screenshots)',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Go to Settings from Start Screen
    final settings = find.text('SETTINGS');
    expect(settings, findsOneWidget);
    await tester.tap(settings);
    await tester.pumpAndSettle();

    await binding.takeScreenshot('04-settings_dark');

    // Toggle the theme switch
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    await binding.takeScreenshot('05-settings_light');

    // Navigate back to Start
    final backFinder = find.byTooltip('Back');
    if (backFinder.evaluate().isNotEmpty) {
      await tester.tap(backFinder);
      await tester.pumpAndSettle();
    }

    await binding.takeScreenshot('06-start_after_settings');
  });

  testWidgets('Game menu: open global menu and inventory (screenshots)',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Start a new game
    await tester.tap(find.text('NEW GAME'));
    await tester.pumpAndSettle();
    final startBtn = find.text('Start');
    if (startBtn.evaluate().isNotEmpty) {
      await tester.tap(startBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // Open global menu via the AppBar settings icon
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await binding.takeScreenshot('07-global_menu');

    // Tap Inventory in the menu
    final inventory = find.text('Inventory');
    if (inventory.evaluate().isNotEmpty) {
      await tester.tap(inventory);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('08-inventory');

      // Back from Inventory
      final backFinder = find.byTooltip('Back');
      if (backFinder.evaluate().isNotEmpty) {
        await tester.tap(backFinder);
        await tester.pumpAndSettle();
      }
    }

    // Open menu again and show status
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    final showStatus = find.text('Show Status');
    if (showStatus.evaluate().isNotEmpty) {
      await tester.tap(showStatus);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('09-game_status');
    }
  });

  testWidgets('Save/Load roundtrip and Move flow (screenshots)',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Start a new game
    await tester.tap(find.text('NEW GAME'));
    await tester.pumpAndSettle();
    final startBtn = find.text('Start');
    if (startBtn.evaluate().isNotEmpty) {
      await tester.tap(startBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // Open menu -> Save Game
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Game'));
    await tester.pumpAndSettle();

    // If no saves yet, create one
    final createBtn = find.text('Create New Save');
    if (createBtn.evaluate().isNotEmpty) {
      await tester.tap(createBtn);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('10-save_dialog');
      await tester.enterText(find.byType(TextField), 'it_save1');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    } else {
      // Overwrite first save if list exists
      final overwrite = find.byIcon(Icons.save).first;
      if (overwrite.evaluate().isNotEmpty) {
        await tester.tap(overwrite);
        await tester.pumpAndSettle();
      }
    }

    await binding.takeScreenshot('11-saved');

    // Open menu -> Load Game
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load Game'));
    await tester.pumpAndSettle();

    final saveTile = find.text('it_save1');
    if (saveTile.evaluate().isNotEmpty) {
      await tester.tap(saveTile);
      await tester.pumpAndSettle();
    } else {
      // Fallback: tap first play icon
      final play = find.byIcon(Icons.play_arrow).first;
      if (play.evaluate().isNotEmpty) {
        await tester.tap(play);
        await tester.pumpAndSettle();
      }
    }

    await binding.takeScreenshot('12-loaded');

    // Try to trigger Move dialog via an action button containing 'Move to Nearby Location'
    final moveBtn = find.text('Move to Nearby Location');
    if (moveBtn.evaluate().isNotEmpty) {
      await tester.tap(moveBtn);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('13-move_dialog');
      // Tap first option
      final firstOption = find.byType(ListTile).first;
      if (firstOption.evaluate().isNotEmpty) {
        await tester.tap(firstOption);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('14-after_move');
      }
    }
  });
}
