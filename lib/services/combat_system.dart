import 'dart:math';
import '../models/zombie.dart';
import '../models/game_state.dart';

class CombatSystem {
  static CombatSystem? _instance;
  static CombatSystem get instance => _instance ??= CombatSystem._();
  CombatSystem._();

  final Map<String, Map<String, dynamic>> weapons = {
    "fists": {
      "damage": 8.0,
      "accuracy": 0.7,
      "durability": 999,
      "description": "your bare hands"
    },
    "hunting knife": {
      "damage": 15.0,
      "accuracy": 0.8,
      "durability": 50,
      "description": "a sharp hunting knife"
    },
    "baseball bat": {
      "damage": 20.0,
      "accuracy": 0.75,
      "durability": 30,
      "description": "a wooden baseball bat"
    },
    "pistol": {
      "damage": 35.0,
      "accuracy": 0.6,
      "durability": 100,
      "description": "a pistol",
      "ammo_type": "bullets"
    },
    "hunting rifle": {
      "damage": 50.0,
      "accuracy": 0.8,
      "durability": 80,
      "description": "a hunting rifle",
      "ammo_type": "rifle_rounds"
    },
    "shotgun": {
      "damage": 45.0,
      "accuracy": 0.7,
      "durability": 60,
      "description": "a shotgun",
      "ammo_type": "shells"
    },
    "crowbar": {
      "damage": 18.0,
      "accuracy": 0.75,
      "durability": 40,
      "description": "a heavy crowbar"
    },
    "tire iron": {
      "damage": 16.0,
      "accuracy": 0.7,
      "durability": 35,
      "description": "a tire iron"
    },
  };

  List<String> getAvailableWeapons(GameState gameState) {
    List<String> availableWeapons = ["fists"]; // Always available
    
    for (String item in gameState.inventory) {
      if (weapons.containsKey(item)) {
        availableWeapons.add(item);
      }
    }
    
    return availableWeapons;
  }

  Map<String, dynamic> canUseWeapon(String weapon, GameState gameState) {
    if (!weapons.containsKey(weapon)) {
      return {"canUse": false, "reason": "Unknown weapon"};
    }

    if (weapon == "fists") {
      return {"canUse": true, "reason": ""};
    }

    if (!gameState.inventory.contains(weapon)) {
      return {"canUse": false, "reason": "Weapon not in inventory"};
    }

    final weaponInfo = weapons[weapon]!;
    final String? ammoType = weaponInfo["ammo_type"];
    
    if (ammoType != null && !gameState.inventory.contains(ammoType)) {
      return {"canUse": false, "reason": "No ammunition"};
    }

    return {"canUse": true, "reason": ""};
  }

  Map<String, dynamic> attackZombie(String weapon, Zombie zombie, GameState gameState) {
    final canUseResult = canUseWeapon(weapon, gameState);
    if (!canUseResult["canUse"]) {
      return {
        "success": false,
        "message": "Cannot use $weapon: ${canUseResult['reason']}",
        "damage": 0.0,
        "zombieKilled": false,
      };
    }

    final weaponInfo = weapons[weapon]!;
    final random = Random();

    // Check if attack hits
    final double accuracy = weaponInfo["accuracy"];
    if (random.nextDouble() > accuracy) {
      return {
        "success": true,
        "message": "You swing ${weaponInfo['description']} but miss ${zombie.description}!",
        "damage": 0.0,
        "zombieKilled": false,
      };
    }

    // Calculate damage with some randomness
    double baseDamage = weaponInfo["damage"];
    double actualDamage = baseDamage + (random.nextInt(6) - 2); // ±2 damage variation
    actualDamage = actualDamage.clamp(1.0, baseDamage + 5);

    // Apply damage to zombie
    zombie.takeDamage(actualDamage);

    // Consume ammo if needed
    final String? ammoType = weaponInfo["ammo_type"];
    if (ammoType != null) {
      gameState.removeItem(ammoType);
    }

    String message;
    if (zombie.isAlive) {
      message = "You hit ${zombie.description} with ${weaponInfo['description']} for ${actualDamage.toInt()} damage!";
    } else {
      message = "You kill ${zombie.description} with ${weaponInfo['description']} for ${actualDamage.toInt()} damage!";
      gameState.zombieKills++;
      gameState.experiencePoints += 10;
    }

    return {
      "success": true,
      "message": message,
      "damage": actualDamage,
      "zombieKilled": !zombie.isAlive,
    };
  }

  Zombie? checkForZombieEncounter(String locationName, double zombieChance) {
    final random = Random();
    if (random.nextDouble() <= zombieChance) {
      return Zombie.createRandom();
    }
    return null;
  }

  Map<String, dynamic> attemptFlee(Zombie zombie, GameState gameState) {
    final random = Random();
    
    // Base flee chance is 60%, modified by zombie speed and player fatigue
    double fleeChance = 0.6;
    
    // Faster zombies are harder to flee from
    fleeChance -= (zombie.speed - 1) * 0.1;
    
    // High fatigue makes it harder to flee
    if (gameState.fatigue > 70) {
      fleeChance -= 0.2;
    }
    
    fleeChance = fleeChance.clamp(0.2, 0.8); // Keep between 20% and 80%
    
    if (random.nextDouble() <= fleeChance) {
      // Successful flee
      gameState.fatigue = (gameState.fatigue + 10).clamp(0, 100);
      return {
        "success": true,
        "message": "You successfully escape from ${zombie.description}!",
        "fled": true,
      };
    } else {
      // Failed flee - zombie gets a free attack
      final attackResult = zombie.attack();
      if (attackResult["hit"]) {
        gameState.health = (gameState.health - attackResult["damage"]).clamp(0, 100);
      }
      
      return {
        "success": false,
        "message": "You try to run but ${zombie.description} catches up! ${attackResult['message']}",
        "fled": false,
        "damage": attackResult["damage"],
      };
    }
  }

  String getWeaponDescription(String weapon) {
    final weaponInfo = weapons[weapon];
    if (weaponInfo == null) return "Unknown weapon";
    
    String desc = "${weaponInfo['description']} (Damage: ${weaponInfo['damage'].toInt()}, Accuracy: ${(weaponInfo['accuracy'] * 100).toInt()}%)";
    
    if (weaponInfo.containsKey('ammo_type')) {
      desc += " - Requires ${weaponInfo['ammo_type']}";
    }
    
    return desc;
  }
}
