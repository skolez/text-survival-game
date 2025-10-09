import 'dart:math';

enum Difficulty { easy, medium, hard }

class GameState {
  // Player stats
  double health = 100.0;
  double hunger = 100.0;
  double thirst = 100.0;
  double fatigue = 0.0;
  double fuel = 100.0;

  // Player inventory
  List<String> inventory = ['can of motor oil'];
  double maxInventoryWeight = 50.0;
  double currentWeight = 2.0; // motor oil weight

  // Location and world state
  String currentLocation = "Abandoned Gas Station";
  Set<String> visitedLocations = <String>{};
  Set<String> discoveredItems = <String>{};
  Set<String> discoveredLocations = <String>{};

  // Game progression
  bool gameIntroShown = false;
  Map<String, dynamic> storyFlags = {};
  int turnCount = 0;
  DateTime gameStartTime = DateTime.now();

  // Combat and survival
  List<String> weapons = [];
  List<String> armor = [];
  int zombieKills = 0;
  // Meta and session timing
  DateTime? lastSaveTime;
  DateTime? lastActionTime;

  // Difficulty
  Difficulty difficulty = Difficulty.medium;

  int daysSurvived = 0;

  // Progression system
  String survivorRank = "Rookie";
  int experiencePoints = 0;
  int skillPoints = 0;
  Map<String, int> skills = {
    "combat": 0,
    "scavenging": 0,
    "crafting": 0,
    "survival": 0,
  };

  // Dynamic events system
  List<Map<String, dynamic>> activeEvents = [];
  Set<String> completedEvents = <String>{};
  int eventCooldown = 0;

  // Vehicle system
  String? currentVehicle;
  double vehicleCondition = 0.0; // 0-100, 0 means broken
  List<String> vehiclePartsCollected = [];
  Map<String, Map<String, bool>> vehiclePartsInstalled = {};
  List<String> townsVisited = ["Riverside"]; // Starting town

  bool get hasWorkingVehicle =>
      currentVehicle != null && vehicleCondition >= 30;

  GameState();

  // Item effects mapping
  static const Map<String, Map<String, dynamic>> itemEffects = {
    // Food items
    "canned food": {
      "health": 5,
      "hunger": 25,
      "consumable": true,
      "weight": 0.5
    },
    "energy bar": {
      "health": 2,
      "hunger": 15,
      "fatigue": -5,
      "consumable": true,
      "weight": 0.2
    },
    "beef jerky": {"hunger": 20, "consumable": true, "weight": 0.3},
    "crackers": {"hunger": 10, "consumable": true, "weight": 0.2},
    "chocolate": {"health": 3, "hunger": 8, "consumable": true, "weight": 0.1},

    // Drinks
    "water bottle": {"thirst": 30, "consumable": true, "weight": 0.5},
    "energy drink": {
      "thirst": 15,
      "fatigue": -10,
      "consumable": true,
      "weight": 0.4
    },
    "soda": {"thirst": 20, "hunger": 5, "consumable": true, "weight": 0.4},
    "coffee": {"thirst": 10, "fatigue": -15, "consumable": true, "weight": 0.3},

    // Medical supplies
    "first aid kit": {"health": 30, "consumable": true, "weight": 1.0},
    "bandages": {"health": 15, "consumable": true, "weight": 0.3},
    "pain medication": {
      "health": 10,
      "fatigue": -5,
      "consumable": true,
      "weight": 0.1
    },
    "antibiotics": {"health": 25, "consumable": true, "weight": 0.2},

    // Tools and equipment (not consumable)
    "flashlight": {"weight": 0.5},
    "rope": {"weight": 1.0},
    "crowbar": {"weight": 2.0},
    "tire iron": {"weight": 1.5},
    "wrench": {"weight": 0.8},
    "screwdriver": {"weight": 0.3},
    "hammer": {"weight": 1.2},
    "duct tape": {"weight": 0.4},

    // Weapons (not consumable)
    "hunting knife": {"weight": 0.5},
    "baseball bat": {"weight": 1.0},
    "pistol": {"weight": 1.2},
    "hunting rifle": {"weight": 3.5},
    "shotgun": {"weight": 3.0},

    // Vehicle parts
    "car battery": {"weight": 15.0},
    "spark plugs": {"weight": 0.5},
    "motor oil": {"weight": 2.0},
    "tire": {"weight": 8.0},
    "fuel filter": {"weight": 0.3},

    // Ammunition
    "bullets": {"weight": 0.5},
    "rifle_rounds": {"weight": 0.8},
    "shells": {"weight": 1.0},

    // Miscellaneous
    "road map": {"weight": 0.1},
    "compass": {"weight": 0.2},
    "binoculars": {"weight": 0.8},
    "camping backpack": {"weight": 2.0},
    "sleeping bag": {"weight": 3.0},
  };

  bool canAddItem(String item) {
    double itemWeight = itemEffects[item]?['weight'] ?? 1.0;
    return currentWeight + itemWeight <= maxInventoryWeight;
  }

  bool addItem(String item) {
    if (!canAddItem(item)) return false;

    inventory.add(item);
    currentWeight += itemEffects[item]?['weight'] ?? 1.0;
    discoveredItems.add(item);
    return true;
  }

  bool removeItem(String item, [double? weight]) {
    if (!inventory.contains(item)) return false;

    inventory.remove(item);
    currentWeight -= weight ?? itemEffects[item]?['weight'] ?? 1.0;
    currentWeight = max(0, currentWeight);
    return true;
  }

  Map<String, dynamic> useItem(String item) {
    if (!inventory.contains(item)) {
      return {"success": false, "message": "Item not found in inventory"};
    }

    Map<String, dynamic>? effects = itemEffects[item];
    if (effects == null) {
      return {"success": false, "message": "Unknown item: $item"};
    }

    if (effects['consumable'] != true) {
      return {"success": false, "message": "$item cannot be consumed"};
    }

    List<String> resultMessages = [];

    // Apply effects
    if (effects.containsKey('health')) {
      double oldHealth = health;
      health = (health + effects['health']).clamp(0.0, 100.0);
      if (health > oldHealth) {
        resultMessages.add("Health restored by ${health - oldHealth}");
      }
    }

    if (effects.containsKey('hunger')) {
      double oldHunger = hunger;
      hunger = (hunger + effects['hunger']).clamp(0.0, 100.0);
      if (hunger > oldHunger) {
        resultMessages.add("Hunger reduced by ${hunger - oldHunger}");
      }
    }

    if (effects.containsKey('thirst')) {
      double oldThirst = thirst;
      thirst = (thirst + effects['thirst']).clamp(0.0, 100.0);
      if (thirst > oldThirst) {
        resultMessages.add("Thirst reduced by ${thirst - oldThirst}");
      }
    }

    if (effects.containsKey('fatigue')) {
      double oldFatigue = fatigue;
      fatigue = (fatigue + effects['fatigue']).clamp(0.0, 100.0);
      if (fatigue < oldFatigue) {
        resultMessages.add("Fatigue reduced by ${oldFatigue - fatigue}");
      }
    }

    // Remove item if consumable
    if (effects['consumable'] == true) {
      removeItem(item, effects['weight']?.toDouble());
      resultMessages.add("Used $item");
    }

    return {"success": true, "message": resultMessages.join(". ")};
  }

  bool moveToLocation(String location) {
    visitedLocations.add(currentLocation);
    currentLocation = location;
    turnCount++;
    return true;
  }

  void updateSurvivalStats([int turnsPassed = 1]) {
    // More balanced stat degradation
    hunger = max(0, hunger - (turnsPassed * 1.5));
    thirst = max(0, thirst - (turnsPassed * 2.5));
    fatigue = min(100, fatigue + (turnsPassed * 0.7));

    // Health effects from low stats
    if (hunger <= 20) {
      health = max(0, health - 1);
    }
    if (thirst <= 10) {
      health = max(0, health - 2);
    }
    if (fatigue >= 85) {
      health = max(0, health - 1);
    }
  }

  String getStatusSummary() {
    return """
Health: ${health.toInt()}/100
Hunger: ${hunger.toInt()}/100
Thirst: ${thirst.toInt()}/100
Fatigue: ${fatigue.toInt()}/100
Fuel: ${fuel.toInt()}/100
Inventory: ${inventory.length} items (${currentWeight.toStringAsFixed(1)}/$maxInventoryWeight kg)
Location: $currentLocation
Days Survived: $daysSurvived
Zombie Kills: $zombieKills

🏆 Survivor Rank: $survivorRank
⭐ Experience Points: $experiencePoints
🎯 Available Skill Points: $skillPoints
""";
  }

  bool isGameOver() {
    return health <= 0;
  }

  Map<String, dynamic> checkFatigueCollapse() {
    if (fatigue >= 95) {
      // Force rest
      fatigue = max(0, fatigue - 30);
      health = max(0, health - 10);
      hunger = max(0, hunger - 15);
      thirst = max(0, thirst - 20);

      return {
        "collapsed": true,
        "message":
            "You collapse from exhaustion! You wake up hours later, weaker and more vulnerable."
      };
    }
    return {"collapsed": false};
  }

  Map<String, dynamic> toJson() {
    return {
      'health': health,
      'hunger': hunger,
      'thirst': thirst,
      'fatigue': fatigue,
      'fuel': fuel,
      'inventory': inventory,
      'maxInventoryWeight': maxInventoryWeight,
      'currentWeight': currentWeight,
      'currentLocation': currentLocation,
      'visitedLocations': visitedLocations.toList(),
      'discoveredItems': discoveredItems.toList(),
      'discoveredLocations': discoveredLocations.toList(),
      'gameIntroShown': gameIntroShown,
      'storyFlags': storyFlags,
      'turnCount': turnCount,
      'gameStartTime': gameStartTime.toIso8601String(),
      'weapons': weapons,
      'armor': armor,
      'zombieKills': zombieKills,
      'daysSurvived': daysSurvived,
      'survivorRank': survivorRank,
      'experiencePoints': experiencePoints,
      'skillPoints': skillPoints,
      'skills': skills,
      'activeEvents': activeEvents,
      'completedEvents': completedEvents.toList(),
      'eventCooldown': eventCooldown,
      'currentVehicle': currentVehicle,
      'vehicleCondition': vehicleCondition,
      'vehiclePartsCollected': vehiclePartsCollected,
      'vehiclePartsInstalled': vehiclePartsInstalled,
      'townsVisited': townsVisited,
      'difficulty': difficulty.name,
      'lastSaveTime': lastSaveTime?.toIso8601String(),
      'lastActionTime': lastActionTime?.toIso8601String(),
    };
  }

  void fromJson(Map<String, dynamic> json) {
    health = json['health']?.toDouble() ?? 100.0;
    hunger = json['hunger']?.toDouble() ?? 100.0;
    thirst = json['thirst']?.toDouble() ?? 100.0;
    fatigue = json['fatigue']?.toDouble() ?? 0.0;
    fuel = json['fuel']?.toDouble() ?? 100.0;
    inventory = List<String>.from(json['inventory'] ?? ['can of motor oil']);
    maxInventoryWeight = json['maxInventoryWeight']?.toDouble() ?? 50.0;
    currentWeight = json['currentWeight']?.toDouble() ?? 2.0;
    currentLocation = json['currentLocation'] ?? "Abandoned Gas Station";
    visitedLocations = Set<String>.from(json['visitedLocations'] ?? []);
    discoveredItems = Set<String>.from(json['discoveredItems'] ?? []);
    discoveredLocations = Set<String>.from(json['discoveredLocations'] ?? []);
    gameIntroShown = json['gameIntroShown'] ?? false;
    storyFlags = Map<String, dynamic>.from(json['storyFlags'] ?? {});
    turnCount = json['turnCount'] ?? 0;
    gameStartTime =
        DateTime.tryParse(json['gameStartTime'] ?? '') ?? DateTime.now();
    weapons = List<String>.from(json['weapons'] ?? []);
    armor = List<String>.from(json['armor'] ?? []);
    zombieKills = json['zombieKills'] ?? 0;
    daysSurvived = json['daysSurvived'] ?? 0;
    survivorRank = json['survivorRank'] ?? "Rookie";
    experiencePoints = json['experiencePoints'] ?? 0;
    skillPoints = json['skillPoints'] ?? 0;
    skills = Map<String, int>.from(json['skills'] ??
        {"combat": 0, "scavenging": 0, "crafting": 0, "survival": 0});
    activeEvents = List<Map<String, dynamic>>.from(json['activeEvents'] ?? []);
    completedEvents = Set<String>.from(json['completedEvents'] ?? []);
    eventCooldown = json['eventCooldown'] ?? 0;
    currentVehicle = json['currentVehicle'];
    vehicleCondition = json['vehicleCondition']?.toDouble() ?? 0.0;
    vehiclePartsCollected =
        List<String>.from(json['vehiclePartsCollected'] ?? []);
    vehiclePartsInstalled = Map<String, Map<String, bool>>.from(
        json['vehiclePartsInstalled']
                ?.map((k, v) => MapEntry(k, Map<String, bool>.from(v))) ??
            {});
    townsVisited = List<String>.from(json['townsVisited'] ?? ["Riverside"]);

    // Difficulty
    final difficultyStr = (json['difficulty'] ?? 'medium') as String;
    switch (difficultyStr) {
      case 'easy':
        difficulty = Difficulty.easy;
        break;
      case 'hard':
        difficulty = Difficulty.hard;
        break;
      default:
        difficulty = Difficulty.medium;
    }

    // Timestamps
    lastSaveTime = json['lastSaveTime'] != null
        ? DateTime.tryParse(json['lastSaveTime'])
        : null;
    lastActionTime = json['lastActionTime'] != null
        ? DateTime.tryParse(json['lastActionTime'])
        : null;
  }
}
