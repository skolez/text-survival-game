import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zombie_survival_game/main.dart';

void main() {
  testWidgets('Game app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZombieSurvivalApp());

    // Verify that the app title is displayed
    expect(find.text('Zombie Survival Story'), findsOneWidget);

    // Verify that we can find the status bars
    expect(find.text('Health: 100'), findsOneWidget);
    expect(find.text('Hunger: 100'), findsOneWidget);
    expect(find.text('Thirst: 100'), findsOneWidget);
  });

  testWidgets('Game state initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZombieSurvivalApp());
    
    // Wait for the game to initialize
    await tester.pumpAndSettle();
    
    // Check that we start at the gas station
    expect(find.textContaining('Abandoned Gas Station'), findsOneWidget);
    
    // Check that action buttons are present
    expect(find.textContaining('Look around'), findsOneWidget);
    expect(find.textContaining('Move to nearby location'), findsOneWidget);
  });
}
