import 'package:flutter/material.dart';

/// High-level configuration for a swappable story/campaign.
///
/// Nothing here is wired into the existing game yet; this is a forward-looking
/// abstraction so we can drop in a different campaign (e.g. nuclear) by just
/// swapping the selected StoryConfig and assets.
class StoryConfig {
  final String id; // e.g. "zombie", "nuclear"
  final String title;
  final String description;

  /// Root folder for this story's assets (texts, images, sounds)
  /// Example: assets/stories/zombie
  final String assetRoot;

  /// Intro sequence parts (relative to [assetRoot])
  /// Example: ["opening_title.txt", "zombie_intro.txt"]
  final List<String> introParts;

  /// Enemy/actor set key that the engine can use to select behaviors and names
  /// (e.g. "zombies", "marauders").
  final String enemySetKey;

  /// Optional per-story theme colors. If null, fall back to the app default
  /// (light/dark) controlled by the existing theme toggle.
  final StoryThemePreset? themePreset;

  const StoryConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.assetRoot,
    required this.introParts,
    required this.enemySetKey,
    this.themePreset,
  });
}

/// Minimal theme surface we can translate to the existing AppTheme later.
class StoryThemePreset {
  final Color background;
  final Color surface;
  final Color primary;
  final Color text;
  final Color border;

  const StoryThemePreset({
    required this.background,
    required this.surface,
    required this.primary,
    required this.text,
    required this.border,
  });
}

/// Opinionated presets to illustrate how a different story could look.
class StoryPresets {
  static const zombie = StoryConfig(
    id: 'zombie',
    title: 'Zombie Survival Story',
    description: 'Survive the undead, repair your car, and escape the city.',
    assetRoot: 'assets/stories/zombie',
    introParts: [
      'opening_title.txt',
      'zombie_intro.txt',
    ],
    enemySetKey: 'zombies',
    themePreset: StoryThemePreset(
      background: Color(0xFF000000),
      surface: Color(0xFF0A0A0A),
      primary: Color(0xFF00FF41),
      text: Color(0xFFCCFFCC),
      border: Color(0xFF00CC33),
    ),
  );

  static const nuclear = StoryConfig(
    id: 'nuclear',
    title: 'Afterglow: Nuclear Exodus',
    description:
        'Radiation, scarcity, and marauders. Patch your rig and outrun the fallout.',
    assetRoot: 'assets/stories/nuclear',
    introParts: [
      // Placeholder files – can be created later without code changes
      'opening_title.txt',
      'nuclear_intro.txt',
    ],
    enemySetKey: 'marauders',
    themePreset: StoryThemePreset(
      background: Color(0xFF0C0A09),
      surface: Color(0xFF1B1B1B),
      primary: Color(0xFFFFA000),
      text: Color(0xFFFFF1C1),
      border: Color(0xFFFF8C00),
    ),
  );
}

