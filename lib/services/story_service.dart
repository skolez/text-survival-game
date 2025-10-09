import 'package:flutter/services.dart';

class StoryService {
  /// Load text content from an asset file
  static Future<String> loadAssetText(String assetPath) async {
    try {
      return await rootBundle.loadString(assetPath);
    } catch (e) {
      print('Error loading asset $assetPath: $e');
      return '';
    }
  }

  /// Parse the intro story into separate parts for typing effect
  static List<String> parseIntroStory(String introText) {
    // Split by "---" separators and clean up
    final parts = introText
        .split('---')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && part != 'Introduction:')
        .toList();

    // Normalize formatting: remove hardcoded newlines so text flows responsively
    String _normalize(String s) {
      // Replace all line breaks with a single space, then collapse repeated spaces
      final noNewlines = s.replaceAll(RegExp(r"\s*\n\s*"), ' ');
      return noNewlines.replaceAll(RegExp(r" {2,}"), ' ').trim();
    }

    // Update character names and locations and normalize formatting
    final updatedParts = parts.map((part) {
      final replaced = part
          .replaceAll('Zack', 'Alex')
          .replaceAll('Wind River Mountain Range', 'Rocky Mountain Range')
          .replaceAll('Wyoming', 'Colorado');
      return _normalize(replaced);
    }).toList();

    return updatedParts;
  }

  /// Generate story content for completing a town and moving to the next
  static String generateTownCompletionStory(
      String completedTown, String nextTown, int townNumber) {
    switch (townNumber) {
      case 1:
        return _generateFirstTownCompletion(completedTown, nextTown);
      case 2:
        return _generateSecondTownCompletion(completedTown, nextTown);
      case 3:
        return _generateThirdTownCompletion(completedTown, nextTown);
      default:
        return _generateGenericTownCompletion(
            completedTown, nextTown, townNumber);
    }
  }

  static String _generateFirstTownCompletion(
      String completedTown, String nextTown) {
    return """
The engine roars to life! After hours of scavenging and careful repairs, you've managed to get the old car running. Alex grins as the headlights cut through the growing dusk.

"We did it!" Alex shouts over the engine noise. "This baby should get us to the next town."

You both climb into the vehicle, grateful to have wheels again. The radio crackles with static, but no voices emerge from the white noise. The world still feels empty, abandoned.

As you drive away from $completedTown, you can't help but look back at the place that taught you so much about survival. The zombies you encountered, the supplies you found, the close calls you survived - it all feels like a lifetime ago, even though it's only been days.

"Where to next?" Alex asks, consulting the road map you found.

"$nextTown," you reply, pointing to a dot on the map about 50 miles north. "It's bigger than this place. Maybe we'll find more survivors... or at least more answers."

The car lurches forward into the unknown, leaving behind the familiar dangers of $completedTown for whatever awaits in $nextTown.
""";
  }

  static String _generateSecondTownCompletion(
      String completedTown, String nextTown) {
    return """
The second car sputters and dies just as you finish the last repair. But this time, you and Alex work like a well-oiled team. You've learned so much since that first terrifying encounter with the undead.

"Remember when we were afraid of a single zombie?" Alex chuckles, wiping grease from their hands. "Now look at us."

You nod, thinking about how much you've both changed. Your movements are more confident, your decisions quicker. The apocalypse has forged you into survivors.

The new vehicle is in better condition than the last one. As you load your hard-earned supplies into the trunk, you notice how much more organized you've become. Every item has its place, every resource is accounted for.

"$nextTown is supposed to be a bigger city," Alex says, studying the map. "More people lived there before... whatever this is happened. That could mean more supplies, but also..."

"More zombies," you finish. "We can handle it. We've come this far."

The engine starts smoothly, and you drive toward $nextTown with a mixture of anticipation and caution. Each town teaches you something new about this changed world.
""";
  }

  static String _generateThirdTownCompletion(
      String completedTown, String nextTown) {
    return """
This time, the car repair feels routine. Your hands move with practiced efficiency, and Alex anticipates your needs before you even ask. You've become a formidable team.

"Three towns down," Alex says, leaning against the newly repaired vehicle. "How many more do you think are out there?"

You pause, considering the question. Each town has revealed more pieces of the puzzle - abandoned military checkpoints, hastily scrawled messages on walls, evidence of a world that fell apart quickly.

"As many as it takes," you reply. "Until we find other survivors, or figure out what caused all this."

The supplies you've gathered tell a story of preparation and panic. Some people saw this coming, others were caught completely off guard. You're determined not to be in either category - you'll be ready for whatever comes next.

$nextTown looms on the horizon as you drive, its skyline promising new challenges and opportunities. The radio still offers nothing but static, but you haven't given up hope of hearing another human voice.

"Whatever's waiting for us in $nextTown," Alex says, "we'll face it together."

You nod, gripping the steering wheel tighter as you approach your next destination.
""";
  }

  static String _generateGenericTownCompletion(
      String completedTown, String nextTown, int townNumber) {
    return """
Another town, another car repaired and ready for the road. You and Alex have this down to a science now - scavenge, survive, repair, and move on.

"Town number $townNumber," Alex observes, checking the map. "We're getting good at this."

Too good, perhaps. The routine of survival has become second nature, but you can't shake the feeling that you're missing something important. Each abandoned town raises more questions than it answers.

The car starts easily - you've learned to choose your vehicles wisely and maintain them properly. As you drive toward $nextTown, you wonder what new challenges await.

"Do you ever think about what we'll do if we actually find other survivors?" Alex asks.

It's a question you've both avoided, but it hangs in the air between you. What would normal life even look like now?

"We'll figure it out when we get there," you say, focusing on the road ahead.

$nextTown appears in the distance, another dot on the map that might hold answers, supplies, or just more questions about this changed world.
""";
  }

  /// Generate character development story based on player progress
  static String generateCharacterMoment(
      String characterName, int townNumber, String situation) {
    // This would generate dynamic character development moments
    // For now, return a placeholder
    return """
$characterName looks at you with a mixture of exhaustion and determination.

"We've come so far," they say quietly. "Sometimes I can barely remember what life was like before all this."

You understand the feeling. Each day in this new world changes you both a little more.
""";
  }

  /// Get typing speed setting (can be adjusted)
  static int getTypingSpeed() {
    // This could be made configurable via settings
    return 30; // milliseconds per character
  }

  /// Set typing speed (for settings menu)
  static void setTypingSpeed(int speed) {
    // TODO: Implement settings persistence
  }
}
