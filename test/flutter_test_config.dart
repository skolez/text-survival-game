import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();

  // Deterministic viewport for goldens
  final binding = TestWidgetsFlutterBinding.ensureInitialized()
      as AutomatedTestWidgetsFlutterBinding;
  // Use deprecated window test values (stable across Flutter 3.35) for determinism
  binding.window.devicePixelRatioTestValue =
      2.0; // ignore: deprecated_member_use
  binding.window.physicalSizeTestValue =
      const ui.Size(1080, 1920); // ignore: deprecated_member_use
  timeDilation = 1.0; // no animation slowdowns

  return GoldenToolkit.runWithConfiguration(
    () async => await testMain(),
    config: GoldenToolkitConfiguration(
      enableRealShadows: false,
    ),
  );
}
