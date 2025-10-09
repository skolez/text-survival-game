import 'package:flutter/foundation.dart';

import '../models/story_config.dart';

/// Central place to select and retrieve the active story configuration.
///
/// Today we default to the existing zombie story. In the future this can be
/// loaded from a settings screen, a save slot, or deep-link parameter.
class StoryRegistry {
  static StoryConfig _active = StoryPresets.zombie;

  static StoryConfig get active => _active;

  /// Swap the active story at runtime (e.g., from a settings menu).
  static void select(StoryConfig config) {
    _active = config;
    if (kDebugMode) {
      // ignore: avoid_print
      print('[StoryRegistry] Active story set to: ${config.id}');
    }
  }

  /// Known built-in stories. External DLCs/mods could be added later by
  /// reading manifests from disk or network.
  static List<StoryConfig> builtIns() => const [
        StoryPresets.zombie,
        StoryPresets.nuclear,
      ];

  /// Utility to resolve a path inside the story's assetRoot.
  static String assetPath(String relative) =>
      '${_active.assetRoot}/${relative.replaceFirst('/', '')}';
}

