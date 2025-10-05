import 'dart:math';

class Zombie {
  final String type;
  double health;
  final double maxHealth;
  final double damage;
  final int speed;
  final String description;
  bool isAlive;

  Zombie({
    required this.type,
    required this.health,
    required this.maxHealth,
    required this.damage,
    required this.speed,
    required this.description,
    this.isAlive = true,
  });

  factory Zombie.create([String zombieType = "walker"]) {
    const Map<String, Map<String, dynamic>> zombieStats = {
      "walker": {
        "health": 30.0,
        "damage": 15.0,
        "speed": 1,
        "description": "a slow-moving infected"
      },
      "runner": {
        "health": 25.0,
        "damage": 20.0,
        "speed": 3,
        "description": "a fast infected"
      },
      "brute": {
        "health": 60.0,
        "damage": 25.0,
        "speed": 1,
        "description": "a massive infected"
      },
      "crawler": {
        "health": 15.0,
        "damage": 10.0,
        "speed": 2,
        "description": "a crawling infected"
      }
    };

    final stats = zombieStats[zombieType] ?? zombieStats["walker"]!;
    final health = stats["health"] as double;

    return Zombie(
      type: zombieType,
      health: health,
      maxHealth: health,
      damage: stats["damage"] as double,
      speed: stats["speed"] as int,
      description: stats["description"] as String,
    );
  }

  static Zombie createRandom() {
    const types = ["walker", "runner", "brute", "crawler"];
    final random = Random();
    final randomType = types[random.nextInt(types.length)];
    return Zombie.create(randomType);
  }

  void takeDamage(double damageAmount) {
    health = (health - damageAmount).clamp(0.0, maxHealth);
    if (health <= 0) {
      isAlive = false;
    }
  }

  Map<String, dynamic> attack() {
    final random = Random();
    final hitChance = 0.7; // 70% chance to hit
    
    if (random.nextDouble() <= hitChance) {
      // Vary damage slightly
      final actualDamage = damage + (random.nextInt(6) - 2); // ±2 damage variation
      return {
        "hit": true,
        "damage": actualDamage.clamp(1.0, damage + 5),
        "message": "The $description attacks you for ${actualDamage.toInt()} damage!"
      };
    } else {
      return {
        "hit": false,
        "damage": 0.0,
        "message": "The $description swipes at you but misses!"
      };
    }
  }

  String getHealthStatus() {
    final healthPercent = (health / maxHealth * 100).round();
    if (healthPercent > 75) {
      return "The $description looks healthy and dangerous.";
    } else if (healthPercent > 50) {
      return "The $description is wounded but still fighting.";
    } else if (healthPercent > 25) {
      return "The $description is badly injured and staggering.";
    } else {
      return "The $description is barely standing, near death.";
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'health': health,
      'maxHealth': maxHealth,
      'damage': damage,
      'speed': speed,
      'description': description,
      'isAlive': isAlive,
    };
  }

  factory Zombie.fromJson(Map<String, dynamic> json) {
    return Zombie(
      type: json['type'] ?? 'walker',
      health: (json['health'] ?? 30.0).toDouble(),
      maxHealth: (json['maxHealth'] ?? 30.0).toDouble(),
      damage: (json['damage'] ?? 15.0).toDouble(),
      speed: json['speed'] ?? 1,
      description: json['description'] ?? 'a slow-moving infected',
      isAlive: json['isAlive'] ?? true,
    );
  }
}
