import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zombie_survival_game/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Start -> Difficulty -> Intro (screenshots)', (WidgetTester tester) async {
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
}

