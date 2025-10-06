import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_theme.dart';
import '../models/game_state.dart';
import '../models/zombie.dart';
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
  final FocusNode _focusNode = FocusNode();
  late Zombie _zombie;
  bool _combatEnded = false;

  @override
  void initState() {
    super.initState();
    _zombie = widget.zombie;
    _addToCombatLog("🧟 ZOMBIE ENCOUNTER!");
    _addToCombatLog("You encounter ${_zombie.description}!");
    _addToCombatLog(
        "Zombie Health: ${_zombie.health.toInt()}/${_zombie.maxHealth.toInt()}");
    _addToCombatLog("Your Health: ${widget.gameState.health.toInt()}/100");
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent || _combatEnded) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final availableWeapons =
        _combatSystem.getAvailableWeapons(widget.gameState);

    // Handle weapon selection (1-9 and numpad 1-9)
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      if (availableWeapons.isNotEmpty) {
        final weapon = availableWeapons[0];
        final canUseResult =
            _combatSystem.canUseWeapon(weapon, widget.gameState);
        if (canUseResult["canUse"]) _attack(weapon);
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      if (availableWeapons.length > 1) {
        final weapon = availableWeapons[1];
        final canUseResult =
            _combatSystem.canUseWeapon(weapon, widget.gameState);
        if (canUseResult["canUse"]) _attack(weapon);
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit3 ||
        key == LogicalKeyboardKey.numpad3) {
      if (availableWeapons.length > 2) {
        final weapon = availableWeapons[2];
        final canUseResult =
            _combatSystem.canUseWeapon(weapon, widget.gameState);
        if (canUseResult["canUse"]) _attack(weapon);
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit0 ||
        key == LogicalKeyboardKey.numpad0) {
      _attemptFlee();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyI) {
      _showInventory();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _addToCombatLog(String message) {
    setState(() {
      _combatLog.add(message);
    });
  }

  void _attack(String weapon) {
    if (_combatEnded) return;

    final attackResult =
        _combatSystem.attackZombie(weapon, _zombie, widget.gameState);

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
        widget.gameState.health =
            (widget.gameState.health - zombieAttack["damage"]).clamp(0, 100);

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

  void _endCombat(
      {bool victory = false, bool fled = false, bool playerDied = false}) {
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
                onTap: isUsable
                    ? () {
                        Navigator.pop(context);
                        final result = widget.gameState.useItem(item);
                        _addToCombatLog("💊 ${result['message']}");
                        setState(() {});
                      }
                    : null,
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
    final availableWeapons =
        _combatSystem.getAvailableWeapons(widget.gameState);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          title: Text("Combat", style: AppTheme.appBarTheme.titleTextStyle),
          shape: AppTheme.appBarTheme.shape,
          elevation: AppTheme.elevation,
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Combat status
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: AppTheme.panelDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text("Your Health", style: AppTheme.labelTextStyle),
                          Text(
                            "${widget.gameState.health.toInt()}/100",
                            style: TextStyle(
                              color: widget.gameState.health > 50
                                  ? Colors.green
                                  : widget.gameState.health > 25
                                      ? Colors.orange
                                      : Colors.red,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text("VS",
                          style:
                              AppTheme.labelTextStyle.copyWith(fontSize: 20)),
                      Column(
                        children: [
                          Text("${_zombie.type.toUpperCase()}",
                              style: AppTheme.labelTextStyle),
                          Text(
                            "${_zombie.health.toInt()}/${_zombie.maxHealth.toInt()}",
                            style: TextStyle(
                              color: _zombie.health > _zombie.maxHealth * 0.5
                                  ? Colors.red
                                  : _zombie.health > _zombie.maxHealth * 0.25
                                      ? Colors.orange
                                      : Colors.red[300],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Zombie image
                Container(
                  height: 270, // Increased to accommodate 250px image + padding
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: _buildZombieImage(),
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
                            style: AppTheme.narrativeTextStyle,
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
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 16),

                        // Attack options
                        const Text("Attack with:",
                            style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              availableWeapons.asMap().entries.map((entry) {
                            final index = entry.key;
                            final weapon = entry.value;
                            final canUseResult = _combatSystem.canUseWeapon(
                                weapon, widget.gameState);
                            final canUse = canUseResult["canUse"];

                            return ElevatedButton(
                              onPressed: canUse ? () => _attack(weapon) : null,
                              style: canUse
                                  ? ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.backgroundColor,
                                      foregroundColor: AppTheme.textColor,
                                      side: const BorderSide(
                                          color: AppTheme.borderColor,
                                          width: AppTheme.borderWidth),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.borderRadius),
                                      ),
                                      elevation: AppTheme.elevation,
                                    )
                                  : ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[800],
                                      foregroundColor: Colors.grey[400],
                                      side: const BorderSide(
                                          color: Colors.grey,
                                          width: AppTheme.borderWidth),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.borderRadius),
                                      ),
                                      elevation: AppTheme.elevation,
                                    ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00FF41)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFF00FF41),
                                          width: 1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Color(0xFF00FF41),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(weapon),
                                ],
                              ),
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
                              label: const Text("Flee (0)"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.backgroundColor,
                                foregroundColor: AppTheme.textColor,
                                side: const BorderSide(
                                    color: AppTheme.borderColor,
                                    width: AppTheme.borderWidth),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadius),
                                ),
                                elevation: AppTheme.elevation,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showInventory,
                              icon: const Icon(Icons.inventory),
                              label: const Text("Inventory (I)"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.backgroundColor,
                                foregroundColor: AppTheme.textColor,
                                side: const BorderSide(
                                    color: AppTheme.borderColor,
                                    width: AppTheme.borderWidth),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadius),
                                ),
                                elevation: AppTheme.elevation,
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

            // Status bar positioned in lower right corner
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 200),
                decoration: AppTheme.panelDecoration.copyWith(
                  color: AppTheme.backgroundColor.withOpacity(0.9),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Left column - 3 stats
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatRow("❤️", "Health", widget.gameState.health),
                        _buildStatRow("🍖", "Hunger", widget.gameState.hunger),
                        _buildStatRow("💧", "Thirst", widget.gameState.thirst),
                      ],
                    ),
                    const SizedBox(width: 8), // Reduced gap between columns
                    // Right column - 3 stats
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatRow(
                            "😴", "Energy", 100 - widget.gameState.fatigue),
                        _buildStatRow("⛽", "Fuel", widget.gameState.fuel),
                        _buildStatRow(
                            "🎒",
                            "Weight",
                            ((widget.gameState.maxInventoryWeight -
                                    widget.gameState.currentWeight) /
                                widget.gameState.maxInventoryWeight *
                                100)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ), // Close Stack
      ), // Close Scaffold
    ); // Close KeyboardListener
  }

  Widget _buildStatRow(String icon, String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              "${value.toInt()}%",
              style: TextStyle(
                color: AppTheme.getStatusColor(value),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZombieImage() {
    // Choose image based on zombie type and health
    String imagePath;
    if (_zombie.type.toLowerCase().contains('crawler') ||
        _zombie.type.toLowerCase().contains('crawling') ||
        _zombie.health < _zombie.maxHealth * 0.3) {
      // Use crawling zombie for crawlers or heavily damaged zombies
      imagePath = 'images/crawling_zombie.png';
    } else {
      // Use running zombie for most other zombies
      imagePath = 'images/running_zombie.png';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imagePath,
          height: 250, // Increased from 100 to 250 (2.5x bigger)
          width: 200, // Increased from 80 to 200 (2.5x bigger)
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image fails to load
            return Container(
              height: 250, // Match the new image size
              width: 200, // Match the new image size
              decoration: BoxDecoration(
                color: Colors.red[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning,
                color: Colors.white,
                size: 40,
              ),
            );
          },
        ),
      ),
    );
  }
}
