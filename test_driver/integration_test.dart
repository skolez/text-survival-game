import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();
  final Directory outDir = Directory('screenshots');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  await integrationDriver(
    driver: driver,
    onScreenshot: (String name, List<int> image, [Map<String, Object?>? args]) async {
      final file = File('${outDir.path}/$name.png');
      await file.writeAsBytes(image);
      // Return true to indicate success; returning false would fail the test.
      return true;
    },
  );
}

