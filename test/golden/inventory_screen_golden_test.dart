import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:zombie_survival_game/models/game_state.dart';
import 'package:zombie_survival_game/screens/inventory_screen.dart';

void main() {
  testGoldens('InventoryScreen golden (sample items)', (tester) async {
    final gs = GameState()
      ..inventory = [
        'canned food',
        'water bottle',
        'first aid kit',
        'hunting knife',
        'crowbar',
        'car battery',
        'spark plugs',
        'motor oil',
        'energy bar',
      ]
      ..currentWeight = 0;
    for (final item in gs.inventory) {
      gs.currentWeight += (GameState.itemEffects[item]?['weight'] ?? 1.0) as double;
    }

    await tester.pumpWidgetBuilder(
      MaterialApp(home: InventoryScreen(gameState: gs)),
      surfaceSize: const Size(1024, 768),
    );

    await screenMatchesGolden(tester, 'inventory_screen');
  });
}

