import 'package:flutter/material.dart';
import '../models/zombie.dart';
import '../models/game_state.dart';
import '../services/combat_system.dart';

class CombatScreen extends StatefulWidget {
  final Zombie zombie;
  final GameState gameState;

  const CombatScreen({
    super.key,
    required this.zombie,
    required this.gameState,
  });

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  final CombatSystem _combatSystem = CombatSystem.instance;
  final List<String> _combatLog = [];
  late Zombie _zombie;
  bool _combatEnded = false;

  @override
  void initState() {
    super.initState();
    _zombie = widget.zombie;
    _addToCombatLog("🧟 ZOMBIE ENCOUNTER!");
    _addToCombatLog("You encounter ${_zombie.description}!");
    _addToCombatLog("Zombie Health: ${_zombie.health.toInt()}/${_zombie.maxHealth.toInt()}");
    _addToCombatLog("Your Health: ${widget.gameState.health.toInt()}/100");
  }

  void _addToCombatLog(String message) {
    setState(() {
      _combatLog.add(message);
    });
  }

  void _attack(String weapon) {
    if (_combatEnded) return;

    final attackResult = _combatSystem.attackZombie(weapon, _zombie, widget.gameState);
    
    if (attackResult["success"]) {
      _addToCombatLog("⚔️ ${attackResult['message']}");
      
      if (attackResult["zombieKilled"]) {
        _addToCombatLog("🏆 Victory! You killed the zombie!");
        _endCombat(victory: true);
        return;
      }
    } else {
      _addToCombatLog("❌ ${attackResult['message']}");
      return;
    }

    // Zombie attacks back if still alive
    if (_zombie.isAlive) {
      final zombieAttack = _zombie.attack();
      _addToCombatLog("🧟 ${zombieAttack['message']}");
      
      if (zombieAttack["hit"]) {
        widget.gameState.health = (widget.gameState.health - zombieAttack["damage"]).clamp(0, 100);
        
        if (widget.gameState.health <= 0) {
          _addToCombatLog("💀 You have been killed!");
          _endCombat(playerDied: true);
          return;
        }
      }
    }

    setState(() {}); // Refresh UI
  }

  void _attemptFlee() {
    if (_combatEnded) return;

    final fleeResult = _combatSystem.attemptFlee(_zombie, widget.gameState);
    _addToCombatLog("🏃 ${fleeResult['message']}");
    
    if (fleeResult["success"]) {
      _endCombat(fled: true);
    } else {
      // Failed flee, check if player died from the attack
      if (widget.gameState.health <= 0) {
        _addToCombatLog("💀 You have been killed!");
        _endCombat(playerDied: true);
      }
    }
    
    setState(() {}); // Refresh UI
  }

  void _endCombat({bool victory = false, bool fled = false, bool playerDied = false}) {
    setState(() {
      _combatEnded = true;
    });

    // Delay before returning to give player time to read final message
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, {
          "victory": victory,
          "fled": fled,
          "player_died": playerDied,
          "message": _combatLog.isNotEmpty ? _combatLog.last : null,
        });
      }
    });
  }

  void _showInventory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Inventory", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: widget.gameState.inventory.length,
            itemBuilder: (context, index) {
              final item = widget.gameState.inventory[index];
              final itemInfo = GameState.itemEffects[item];
              final isUsable = itemInfo?["consumable"] == true;
              
              return ListTile(
                title: Text(
                  item,
                  style: TextStyle(
                    color: isUsable ? Colors.green : Colors.white,
                  ),
                ),
                subtitle: Text(
                  isUsable ? "Usable" : "Not usable in combat",
                  style: TextStyle(
                    color: isUsable ? Colors.green[300] : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                onTap: isUsable ? () {
                  Navigator.pop(context);
                  final result = widget.gameState.useItem(item);
                  _addToCombatLog("💊 ${result['message']}");
                  setState(() {});
                } : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableWeapons = _combatSystem.getAvailableWeapons(widget.gameState);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        title: const Text("Combat", style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Combat status
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.red[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Your Health", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(
                      "${widget.gameState.health.toInt()}/100",
                      style: TextStyle(
                        color: widget.gameState.health > 50 ? Colors.green : 
                               widget.gameState.health > 25 ? Colors.orange : Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Text("VS", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Column(
                  children: [
                    Text("${_zombie.type.toUpperCase()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(
                      "${_zombie.health.toInt()}/${_zombie.maxHealth.toInt()}",
                      style: TextStyle(
                        color: _zombie.health > _zombie.maxHealth * 0.5 ? Colors.red : 
                               _zombie.health > _zombie.maxHealth * 0.25 ? Colors.orange : Colors.red[300],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Combat log
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: _combatLog.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      _combatLog[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Combat actions
          if (!_combatEnded)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "Choose your action:",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  
                  // Attack options
                  const Text("Attack with:", style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableWeapons.map((weapon) {
                      final canUseResult = _combatSystem.canUseWeapon(weapon, widget.gameState);
                      final canUse = canUseResult["canUse"];
                      
                      return ElevatedButton(
                        onPressed: canUse ? () => _attack(weapon) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canUse ? Colors.red[700] : Colors.grey[700],
                          foregroundColor: Colors.white,
                        ),
                        child: Text(weapon),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Other actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _attemptFlee,
                        icon: const Icon(Icons.directions_run),
                        label: const Text("Flee"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showInventory,
                        icon: const Icon(Icons.inventory),
                        label: const Text("Inventory"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // Combat ended message
          if (_combatEnded)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                "Combat ended. Returning to game...",
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
