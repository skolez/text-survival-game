import 'dart:math';

import '../models/game_state.dart';
import '../models/location.dart';
import '../models/zombie.dart';
import 'combat_system.dart';
import 'location_service.dart';

class GameEngine {
  static GameEngine? _instance;
  static GameEngine get instance => _instance ??= GameEngine._();
  GameEngine._();

  GameState gameState = GameState();
  List<Location> locations = [];
  String? lastEncounterResult;

  Future<void> initialize() async {
    try {
      locations = await LocationService.instance.loadLocations();
    } catch (e) {
      print('Error loading locations: $e');
      rethrow;
    }
  }

  Location? getCurrentLocation() {
    return LocationService.instance.getLocation(gameState.currentLocation);
  }

  List<String> getAvailableActions() {
    final location = getCurrentLocation();
    if (location == null) return [];

    return location.actions.map((action) => action.name).toList();
  }

  Map<String, dynamic> processAction(int actionIndex) {
    final location = getCurrentLocation();
    if (location == null) {
      return {"success": false, "message": "Current location not found"};
    }

    if (actionIndex < 0 || actionIndex >= location.actions.length) {
      return {"success": false, "message": "Invalid action"};
    }

    final action = location.actions[actionIndex];
    return _handleAction(action.name, location);
  }

  Map<String, dynamic> _handleAction(String actionName, Location location) {
    switch (actionName.toLowerCase()) {
      case "look around":
        return _lookAround(location);
      case "move to nearby location":
        return {
          "success": true,
          "message": "Choose a location to move to",
          "action": "move"
        };
      case "search for fuel":
        return _searchForFuel(location);
      case "check abandoned cars":
        return _checkAbandonedCars(location);
      case "repair vehicle":
        return _repairVehicle(location);
      case "rest here":
        return _restHere(location);
      case "rest safely":
        return _restHere(
            location); // Same as rest here, but location should be a shelter
      case "rest on porch":
        return _restHere(location); // Same as rest here
      case "climb bell tower":
        return _climbBellTower(location);
      case "descend to cemetery":
        return _descendToCemetery(location);
      case "search weapon section":
        return _searchWeaponSection(location);
      case "check camping gear":
        return _checkCampingGear(location);
      case "search storage room":
        return _searchStorageRoom(location);
      case "search pharmacy":
        return _searchPharmacy(location);
      case "check storage areas":
        return _checkStorageAreas(location);
      case "search produce section":
        return _searchProduceSection(location);
      case "search church":
        return _searchChurch(location);
      default:
        return _genericSearch(location);
    }
  }

  Map<String, dynamic> _lookAround(Location location) {
    final random = Random();

    // Check for zombie encounter
    if (random.nextDouble() <= location.zombieChance) {
      final zombie = Zombie.createRandom();
      return {
        "success": true,
        "message": "While looking around, you encounter a zombie!",
        "zombie": zombie
      };
    }

    // Find random item with weapon priority logic
    if (location.items.isNotEmpty) {
      double findChance = 0.4; // Base chance

      // Check if player has any weapons (excluding fists)
      final weapons = [
        "hunting knife",
        "baseball bat",
        "pistol",
        "hunting rifle",
        "shotgun",
        "crowbar",
        "axe",
        "kitchen knife",
        "meat cleaver",
        "police baton",
        "scalpel",
        "hammer",
        "pipe wrench"
      ];
      final hasWeapon =
          gameState.inventory.any((item) => weapons.contains(item));

      if (!hasWeapon) {
        // Increase chance to find items if no weapon, prioritize weapons
        findChance = 0.7; // Much higher chance
        final weaponsInLocation =
            location.items.where((item) => weapons.contains(item)).toList();

        if (weaponsInLocation.isNotEmpty && random.nextDouble() <= 0.6) {
          // 60% chance to find a weapon specifically if no weapon and weapons available
          final item =
              weaponsInLocation[random.nextInt(weaponsInLocation.length)];
          if (gameState.canAddItem(item)) {
            gameState.addItem(item);
            return {
              "success": true,
              "message":
                  "You found: $item - This could be useful for protection!"
            };
          } else {
            return {
              "success": true,
              "message": "You found $item but your inventory is full!"
            };
          }
        }
      } else {
        // Player has weapon, reduce chance for additional weapons
        final nonWeaponsInLocation =
            location.items.where((item) => !weapons.contains(item)).toList();

        if (nonWeaponsInLocation.isNotEmpty && random.nextDouble() <= 0.8) {
          // Prioritize non-weapon items if player already has a weapon
          final item =
              nonWeaponsInLocation[random.nextInt(nonWeaponsInLocation.length)];
          if (gameState.canAddItem(item)) {
            gameState.addItem(item);
            return {"success": true, "message": "You found: $item"};
          } else {
            return {
              "success": true,
              "message": "You found $item but your inventory is full!"
            };
          }
        }
      }

      // Fallback to random item
      if (random.nextDouble() <= findChance) {
        final item = location.items[random.nextInt(location.items.length)];
        if (gameState.canAddItem(item)) {
          gameState.addItem(item);
          return {"success": true, "message": "You found: $item"};
        } else {
          return {
            "success": true,
            "message": "You found $item but your inventory is full!"
          };
        }
      }
    }

    return {
      "success": true,
      "message": "You look around but don't find anything useful this time."
    };
  }

  Map<String, dynamic> _searchForFuel(Location location) {
    if (!location.fuelAvailable) {
      return {"success": true, "message": "There's no fuel available here."};
    }

    final random = Random();
    if (random.nextDouble() <= 0.6) {
      final fuelFound = 20 + random.nextInt(31); // 20-50 fuel
      gameState.fuel = (gameState.fuel + fuelFound).clamp(0, 100);
      return {
        "success": true,
        "message": "You found $fuelFound units of fuel!"
      };
    }

    return {
      "success": true,
      "message": "You search for fuel but the tanks are empty."
    };
  }

  Map<String, dynamic> _checkAbandonedCars(Location location) {
    final random = Random();

    // Check for zombie encounter
    if (random.nextDouble() <= 0.3) {
      final zombie = Zombie.createRandom();
      return {
        "success": true,
        "message": "A zombie was hiding in one of the cars!",
        "zombie": zombie
      };
    }

    // Find items in cars
    if (random.nextDouble() <= 0.5) {
      final carItems = [
        "road map",
        "flashlight",
        "energy drink",
        "first aid kit",
        "crowbar"
      ];
      final item = carItems[random.nextInt(carItems.length)];

      if (gameState.canAddItem(item)) {
        gameState.addItem(item);
        return {
          "success": true,
          "message": "You found $item in one of the abandoned cars!"
        };
      } else {
        return {
          "success": true,
          "message": "You found $item but your inventory is full!"
        };
      }
    }

    return {
      "success": true,
      "message": "The cars have been thoroughly looted already."
    };
  }

  Map<String, dynamic> _repairVehicle(Location location) {
    if (!location.hasRepairableVehicle) {
      return {
        "success": true,
        "message": "There are no repairable vehicles here."
      };
    }

    // Check if player has required parts
    final missingParts = <String>[];
    for (final part in location.partsNeeded) {
      if (!gameState.inventory.contains(part)) {
        missingParts.add(part);
      }
    }

    if (missingParts.isNotEmpty) {
      return {
        "success": true,
        "message":
            "You need these parts to repair the vehicle: ${missingParts.join(', ')}"
      };
    }

    // Remove parts from inventory and repair vehicle
    for (final part in location.partsNeeded) {
      gameState.removeItem(part);
    }

    gameState.currentVehicle = "Repaired Car";
    gameState.vehicleCondition = 100;

    return {
      "success": true,
      "message":
          "You successfully repair the vehicle! You can now travel to distant locations."
    };
  }

  Map<String, dynamic> _restHere(Location location) {
    // Allow rest if either fatigue is high OR health is low
    if (gameState.fatigue <= 10 && gameState.health >= 90) {
      return {
        "success": true,
        "message":
            "You're already well-rested and healthy. No need to rest right now."
      };
    }

    final restAmount = 20 + location.restBonus;
    gameState.fatigue = (gameState.fatigue - restAmount).clamp(0, 100);

    if (location.shelter) {
      // Safe rest - fully recover health
      final healthBefore = gameState.health;
      gameState.health = 100; // Full health recovery in safe locations
      final healthRecovered = 100 - healthBefore;

      return {
        "success": true,
        "message": healthRecovered > 0
            ? "You rest safely and recover $restAmount fatigue and $healthRecovered health. You feel completely refreshed!"
            : "You rest safely and recover $restAmount fatigue. You're already at full health."
      };
    } else {
      // Unsafe rest - partial health recovery
      final healthBefore = gameState.health;
      final healthRecovery =
          (25 + (restAmount * 0.5)).round(); // 25 + half of fatigue recovery
      gameState.health = (gameState.health + healthRecovery).clamp(0, 100);
      final actualHealthRecovered = gameState.health - healthBefore;

      // Risk of zombie encounter while resting in unsafe location
      final random = Random();
      if (random.nextDouble() <= 0.2) {
        final zombie = Zombie.createRandom();
        return {
          "success": true,
          "message":
              "While resting, you're attacked by a zombie! You managed to recover $restAmount fatigue and $actualHealthRecovered health before the attack.",
          "zombie": zombie
        };
      }
      return {
        "success": true,
        "message": actualHealthRecovered > 0
            ? "You rest and recover $restAmount fatigue and $actualHealthRecovered health, but it wasn't very safe."
            : "You rest and recover $restAmount fatigue, but it wasn't very safe and you couldn't heal much."
      };
    }
  }

  Map<String, dynamic> _searchWeaponSection(Location location) {
    final random = Random();
    final weapons = [
      "hunting knife",
      "baseball bat",
      "pistol",
      "bullets",
      "rifle_rounds"
    ];

    // Check if player has any weapons (excluding fists)
    final allWeapons = [
      "hunting knife",
      "baseball bat",
      "pistol",
      "hunting rifle",
      "shotgun",
      "crowbar",
      "axe",
      "kitchen knife",
      "meat cleaver",
      "police baton",
      "scalpel",
      "hammer",
      "pipe wrench"
    ];
    final hasWeapon =
        gameState.inventory.any((item) => allWeapons.contains(item));

    // Check for zombie encounter (slightly reduced in weapon section)
    if (random.nextDouble() <= location.zombieChance * 0.7) {
      final zombie = Zombie.createRandom();
      return {
        "success": true,
        "message":
            "While searching the weapon section, you encounter a zombie!",
        "zombie": zombie
      };
    }

    // Higher success rate if no weapon
    double successRate = hasWeapon ? 0.4 : 0.8;

    if (random.nextDouble() <= successRate) {
      final availableItems =
          weapons.where((item) => location.items.contains(item)).toList();
      if (availableItems.isNotEmpty) {
        final item = availableItems[random.nextInt(availableItems.length)];

        if (gameState.canAddItem(item)) {
          gameState.addItem(item);
          String message = hasWeapon
              ? "You found $item in the weapon section!"
              : "You found $item in the weapon section - This could save your life!";
          return {"success": true, "message": message};
        } else {
          return {
            "success": true,
            "message": "You found $item but your inventory is full!"
          };
        }
      }
    }

    return {
      "success": true,
      "message": "You search the weapon section but don't find anything useful."
    };
  }

  Map<String, dynamic> _checkCampingGear(Location location) {
    return _searchForSpecificItems(
        location,
        ["camping backpack", "sleeping bag", "compass", "rope", "flashlight"],
        "camping gear");
  }

  Map<String, dynamic> _searchStorageRoom(Location location) {
    return _searchForSpecificItems(
        location,
        [
          "canned food",
          "water bottle",
          "first aid kit",
          "crowbar",
          "duct tape"
        ],
        "storage room");
  }

  Map<String, dynamic> _searchPharmacy(Location location) {
    return _searchForSpecificItems(
        location,
        ["first aid kit", "bandages", "pain medication", "antibiotics"],
        "pharmacy");
  }

  Map<String, dynamic> _checkStorageAreas(Location location) {
    return _searchForSpecificItems(
        location,
        ["canned food", "water bottle", "energy bar", "crackers"],
        "storage areas");
  }

  Map<String, dynamic> _searchProduceSection(Location location) {
    return _searchForSpecificItems(location,
        ["canned food", "water bottle", "energy bar"], "produce section");
  }

  Map<String, dynamic> _searchChurch(Location location) {
    return _searchForSpecificItems(location,
        ["first aid kit", "water bottle", "canned food", "candles"], "church");
  }

  Map<String, dynamic> _searchForSpecificItems(
      Location location, List<String> possibleItems, String areaName) {
    final random = Random();

    // Check for zombie encounter
    if (random.nextDouble() <= location.zombieChance * 0.8) {
      final zombie = Zombie.createRandom();
      return {
        "success": true,
        "message": "While searching the $areaName, you encounter a zombie!",
        "zombie": zombie
      };
    }

    // Find item
    if (random.nextDouble() <= 0.5) {
      final availableItems =
          possibleItems.where((item) => location.items.contains(item)).toList();
      if (availableItems.isNotEmpty) {
        final item = availableItems[random.nextInt(availableItems.length)];

        if (gameState.canAddItem(item)) {
          gameState.addItem(item);
          return {
            "success": true,
            "message": "You found $item in the $areaName!"
          };
        } else {
          return {
            "success": true,
            "message": "You found $item but your inventory is full!"
          };
        }
      }
    }

    return {
      "success": true,
      "message": "You search the $areaName but don't find anything useful."
    };
  }

  Map<String, dynamic> _genericSearch(Location location) {
    return _lookAround(location);
  }

  bool moveToLocation(String locationName) {
    final currentLoc = getCurrentLocation();
    if (currentLoc == null) return false;

    if (!currentLoc.canTravelTo(locationName,
        hasWorkingVehicle: gameState.hasWorkingVehicle)) {
      return false;
    }

    gameState.moveToLocation(locationName);
    gameState.updateSurvivalStats();

    return true;
  }

  Zombie? checkForRandomEncounter() {
    final location = getCurrentLocation();
    if (location == null) return null;

    return CombatSystem.instance
        .checkForZombieEncounter(location.name, location.zombieChance);
  }

  bool isGameOver() {
    return gameState.isGameOver();
  }

  String getGameOverReason() {
    if (gameState.health <= 0) {
      return "You have died from your injuries. Game Over.";
    }
    return "Game Over";
  }

  Map<String, dynamic> _climbBellTower(Location location) {
    // Check if player has the required key
    if (!gameState.inventory.contains("rusty church key")) {
      return {
        "success": false,
        "message":
            "🔒 The bell tower door is locked! You need a rusty church key to access the bell tower. Perhaps you should search the church or cemetery for a key..."
      };
    }

    // Player has the key - unlock the bell tower
    final bellTowerName = "Riverside Church Bell Tower";

    // Add the bell tower to discovered locations
    if (!gameState.discoveredLocations.contains(bellTowerName)) {
      gameState.discoveredLocations.add(bellTowerName);
    }

    // Move player to the bell tower
    gameState.moveToLocation(bellTowerName);

    // Gain experience for discovering a secret location
    gameState.experiencePoints += 15;

    return {
      "success": true,
      "message":
          "🗝️ You use the rusty church key to unlock the bell tower door! The heavy wooden door creaks open, revealing a narrow spiral staircase. You climb the worn stone steps, emerging into the bell tower chamber.\n\n🏰 LOCATION DISCOVERED: $bellTowerName\nThis secure location is now available for travel!\n\n⭐ You gained 15 experience points for discovering a secret location!"
    };
  }

  Map<String, dynamic> _descendToCemetery(Location location) {
    // Move player back to the cemetery
    final cemeteryName = "Riverside Cemetery";
    gameState.moveToLocation(cemeteryName);

    return {
      "success": true,
      "message":
          "🪜 You carefully climb down the spiral staircase... The heavy wooden door closes behind you as you return to the cemetery.\n\nYou are now back at the $cemeteryName."
    };
  }
}
