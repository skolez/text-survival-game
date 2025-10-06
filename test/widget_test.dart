import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zombie_survival_game/main.dart';

void main() {
  testWidgets('Game app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZombieSurvivalApp());

    // Wait a bit for initial loading
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that we have a Scaffold (basic app structure)
    expect(find.byType(Scaffold), findsOneWidget);

    // Verify that we have an AppBar
    expect(find.byType(AppBar), findsOneWidget);

    // Verify that we have a loading indicator initially or the game screen
    final hasLoading =
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasGameContent = find.byType(Stack).evaluate().isNotEmpty;
    expect(hasLoading || hasGameContent, isTrue);
  });

  testWidgets('UI Layout Components Test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZombieSurvivalApp());

    // Wait for the game to potentially initialize
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Check for basic UI components that should be present
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    // Check for either loading state or game content
    final hasLoading =
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasGameContent = find.byType(Stack).evaluate().isNotEmpty;

    expect(hasLoading || hasGameContent, isTrue,
        reason: 'Should have either loading indicator or game content');
  });
}
