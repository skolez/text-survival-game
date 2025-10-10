import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:zombie_survival_game/models/game_state.dart';
import 'package:zombie_survival_game/widgets/status_bar.dart';

void main() {
  testGoldens('StatusBar golden', (tester) async {
    final gs = GameState()
      ..health = 82
      ..hunger = 64
      ..thirst = 45
      ..fatigue = 30
      ..fuel = 70
      ..currentWeight = 10;

    await tester.pumpWidgetBuilder(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: StatusBar(gameState: gs),
          ),
        ),
      ),
      surfaceSize: const Size(1024, 768),
    );

    await screenMatchesGolden(tester, 'status_bar');
  });
}

