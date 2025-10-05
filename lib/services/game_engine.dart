import 'dart:math';
import '../models/game_state.dart';
import '../models/location.dart';
import '../models/zombie.dart';
import 'location_service.dart';
import 'combat_system.dart';

class GameEngine {
  static GameEngine? _instance;
  static GameEngine get instance => _instance ??= GameEngine._();
  GameEngine._();

  GameState gameState = GameState();
  List<Location> locations = [];
  String? lastEncounterResult;

  Future<void> initialize() async {
    locations = await LocationService.instance.loadLocations();
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
        return {"success": true, "message": "Choose a location to move to", "action": "move"};
      case "search for fuel":
        return _searchForFuel(location);
      case "check abandoned cars":
        return _checkAbandonedCars(location);
      case "repair vehicle":
        return _repairVehicle(location);
      case "rest here":
        return _restHere(location);
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
      return {"success": true, "message": "While looking around, you encounter a zombie!", "zombie": zombie};
    }

    // Find random item
    if (location.items.isNotEmpty && random.nextDouble() <= 0.4) {
      final item = location.items[random.nextInt(location.items.length)];
      if (gameState.canAddItem(item)) {
        gameState.addItem(item);
        return {"success": true, "message": "You found: $item"};
      } else {
        return {"success": true, "message": "You found $item but your inventory is full!"};
      }
    }

    return {"success": true, "message": "You look around but don't find anything useful this time."};
  }

  Map<String, dynamic> _searchForFuel(Location location) {
    if (!location.fuelAvailable) {
      return {"success": true, "message": "There's no fuel available here."};
    }

    final random = Random();
    if (random.nextDouble() <= 0.6) {
      final fuelFound = 20 + random.nextInt(31); // 20-50 fuel
      gameState.fuel = (gameState.fuel + fuelFound).clamp(0, 100);
      return {"success": true, "message": "You found $fuelFound units of fuel!"};
    }

    return {"success": true, "message": "You search for fuel but the tanks are empty."};
  }

  Map<String, dynamic> _checkAbandonedCars(Location location) {
    final random = Random();
    
    // Check for zombie encounter
    if (random.nextDouble() <= 0.3) {
      final zombie = Zombie.createRandom();
      return {"success": true, "message": "A zombie was hiding in one of the cars!", "zombie": zombie};
    }

    // Find items in cars
    if (random.nextDouble() <= 0.5) {
      final carItems = ["road map", "flashlight", "energy drink", "first aid kit", "crowbar"];
      final item = carItems[random.nextInt(carItems.length)];
      
      if (gameState.canAddItem(item)) {
        gameState.addItem(item);
        return {"success": true, "message": "You found $item in one of the abandoned cars!"};
      } else {
        return {"success": true, "message": "You found $item but your inventory is full!"};
      }
    }

    return {"success": true, "message": "The cars have been thoroughly looted already."};
  }

  Map<String, dynamic> _repairVehicle(Location location) {
    if (!location.hasRepairableVehicle) {
      return {"success": true, "message": "There are no repairable vehicles here."};
    }

    // Check if player has required parts
    final missingParts = <String>[];
    for (final part in location.partsNeeded) {
      if (!gameState.inventory.contains(part)) {
        missingParts.add(part);
      }
    }

    if (missingParts.isNotEmpty) {
      return {"success": true, "message": "You need these parts to repair the vehicle: ${missingParts.join(', ')}"};
    }

    // Remove parts from inventory and repair vehicle
    for (final part in location.partsNeeded) {
      gameState.removeItem(part);
    }

    gameState.currentVehicle = "Repaired Car";
    gameState.vehicleCondition = 100;
    
    return {"success": true, "message": "You successfully repair the vehicle! You can now travel to distant locations."};
  }

  Map<String, dynamic> _restHere(Location location) {
    if (gameState.fatigue <= 10) {
      return {"success": true, "message": "You're not tired enough to rest right now."};
    }

    final restAmount = 20 + location.restBonus;
    gameState.fatigue = (gameState.fatigue - restAmount).clamp(0, 100);
    
    if (location.shelter) {
      gameState.health = (gameState.health + 5).clamp(0, 100);
      return {"success": true, "message": "You rest safely and recover $restAmount fatigue and 5 health."};
    } else {
      // Risk of zombie encounter while resting in unsafe location
      final random = Random();
      if (random.nextDouble() <= 0.2) {
        final zombie = Zombie.createRandom();
        return {"success": true, "message": "While resting, you're attacked by a zombie!", "zombie": zombie};
      }
      return {"success": true, "message": "You rest and recover $restAmount fatigue, but it wasn't very safe."};
    }
  }

  Map<String, dynamic> _searchWeaponSection(Location location) {
    return _searchForSpecificItems(location, ["hunting knife", "baseball bat", "pistol", "bullets", "rifle_rounds"], "weapon section");
  }

  Map<String, dynamic> _checkCampingGear(Location location) {
    return _searchForSpecificItems(location, ["camping backpack", "sleeping bag", "compass", "rope", "flashlight"], "camping gear");
  }

  Map<String, dynamic> _searchStorageRoom(Location location) {
    return _searchForSpecificItems(location, ["canned food", "water bottle", "first aid kit", "crowbar", "duct tape"], "storage room");
  }

  Map<String, dynamic> _searchPharmacy(Location location) {
    return _searchForSpecificItems(location, ["first aid kit", "bandages", "pain medication", "antibiotics"], "pharmacy");
  }

  Map<String, dynamic> _checkStorageAreas(Location location) {
    return _searchForSpecificItems(location, ["canned food", "water bottle", "energy bar", "crackers"], "storage areas");
  }

  Map<String, dynamic> _searchProduceSection(Location location) {
    return _searchForSpecificItems(location, ["canned food", "water bottle", "energy bar"], "produce section");
  }

  Map<String, dynamic> _searchChurch(Location location) {
    return _searchForSpecificItems(location, ["first aid kit", "water bottle", "canned food", "candles"], "church");
  }

  Map<String, dynamic> _searchForSpecificItems(Location location, List<String> possibleItems, String areaName) {
    final random = Random();
    
    // Check for zombie encounter
    if (random.nextDouble() <= location.zombieChance * 0.8) {
      final zombie = Zombie.createRandom();
      return {"success": true, "message": "While searching the $areaName, you encounter a zombie!", "zombie": zombie};
    }

    // Find item
    if (random.nextDouble() <= 0.5) {
      final availableItems = possibleItems.where((item) => location.items.contains(item)).toList();
      if (availableItems.isNotEmpty) {
        final item = availableItems[random.nextInt(availableItems.length)];
        
        if (gameState.canAddItem(item)) {
          gameState.addItem(item);
          return {"success": true, "message": "You found $item in the $areaName!"};
        } else {
          return {"success": true, "message": "You found $item but your inventory is full!"};
        }
      }
    }

    return {"success": true, "message": "You search the $areaName but don't find anything useful."};
  }

  Map<String, dynamic> _genericSearch(Location location) {
    return _lookAround(location);
  }

  bool moveToLocation(String locationName) {
    final currentLoc = getCurrentLocation();
    if (currentLoc == null) return false;

    if (!currentLoc.canTravelTo(locationName)) {
      return false;
    }

    gameState.moveToLocation(locationName);
    gameState.updateSurvivalStats();
    
    return true;
  }

  Zombie? checkForRandomEncounter() {
    final location = getCurrentLocation();
    if (location == null) return null;

    return CombatSystem.instance.checkForZombieEncounter(location.name, location.zombieChance);
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
}
