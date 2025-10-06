import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_theme.dart';
import '../models/game_state.dart';
import '../models/zombie.dart';
import '../services/game_engine.dart';
import '../widgets/keyboard_dialog.dart';
import '../widgets/status_bar.dart';
import 'combat_screen.dart';
import 'inventory_screen.dart';
import 'save_load_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameEngine _gameEngine = GameEngine.instance;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<String> _gameLog = [];
  bool _isLoading = true;
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      final location = _gameEngine.getCurrentLocation();
      if (location == null) return KeyEventResult.ignored;

      // Handle number keys 1-9
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.digit1 ||
          key == LogicalKeyboardKey.numpad1) {
        if (location.actions.isNotEmpty) _handleAction(0);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit2 ||
          key == LogicalKeyboardKey.numpad2) {
        if (location.actions.length > 1) _handleAction(1);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit3 ||
          key == LogicalKeyboardKey.numpad3) {
        if (location.actions.length > 2) _handleAction(2);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit4 ||
          key == LogicalKeyboardKey.numpad4) {
        if (location.actions.length > 3) _handleAction(3);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit5 ||
          key == LogicalKeyboardKey.numpad5) {
        if (location.actions.length > 4) _handleAction(4);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit6 ||
          key == LogicalKeyboardKey.numpad6) {
        if (location.actions.length > 5) _handleAction(5);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit7 ||
          key == LogicalKeyboardKey.numpad7) {
        if (location.actions.length > 6) _handleAction(6);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit8 ||
          key == LogicalKeyboardKey.numpad8) {
        if (location.actions.length > 7) _handleAction(7);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit9 ||
          key == LogicalKeyboardKey.numpad9) {
        if (location.actions.length > 8) _handleAction(8);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit0 ||
          key == LogicalKeyboardKey.numpad0) {
        _showGlobalMenu();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> _initializeGame() async {
    try {
      // Add a timeout to prevent hanging
      await _gameEngine.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Game initialization timed out', const Duration(seconds: 10));
        },
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error during initialization: $e');
      setState(() {
        _isLoading = false;
      });
    }

    // Use WidgetsBinding to ensure this runs after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showIntro) {
        _addToLog("🧟 ZOMBIE SURVIVAL STORY 🧟");
        _addToLog("=" * 40);
        _addToLog(
            "You and your friend Zack have been backpacking in the Wind River Mountain Range in Wyoming for a month.");
        _addToLog(
            "When you return to civilization, you discover that the world has changed - everyone is gone, replaced by hordes of zombies.");
        _addToLog(
            "Armed with your survival skills and whatever supplies you can find, you must navigate this dangerous new world.");
        _addToLog("");
        _addToLog(
            "Your mission: Survive as long as possible and try to make it home, or explore this post-apocalyptic world to uncover what happened.");
        _addToLog("");
        _showIntro = false;
      }

      _updateLocationDisplay();
    });
  }

  void _addToLog(String message) {
    setState(() {
      _gameLog.add(message);
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _updateLocationDisplay() {
    final location = _gameEngine.getCurrentLocation();
    if (location != null) {
      _addToLog("");
      _addToLog("📍 ${location.name}");
      _addToLog(location.description);
      _addToLog("");
    }
  }

  void _handleAction(int actionIndex) async {
    // Check for game over
    if (_gameEngine.isGameOver()) {
      _showGameOver();
      return;
    }

    // Update survival stats
    _gameEngine.gameState.updateSurvivalStats();

    // Check for fatigue collapse
    final collapseResult = _gameEngine.gameState.checkFatigueCollapse();
    if (collapseResult["collapsed"]) {
      _addToLog("💤 ${collapseResult['message']}");
      _updateLocationDisplay();
      return;
    }

    // Check for random zombie encounter before action
    final randomZombie = _gameEngine.checkForRandomEncounter();
    if (randomZombie != null) {
      _addToLog("🧟 ZOMBIE ENCOUNTER!");
      _addToLog("You encounter ${randomZombie.description}!");
      await _startCombat(randomZombie);
      return;
    }

    // Process the action
    final result = _gameEngine.processAction(actionIndex);

    if (result["success"]) {
      _addToLog("✅ ${result['message']}");

      // Handle special action results
      if (result.containsKey("zombie")) {
        await _startCombat(result["zombie"]);
      } else if (result.containsKey("action") && result["action"] == "move") {
        _showMoveOptions();
      } else {
        _updateLocationDisplay();
      }
    } else {
      _addToLog("❌ ${result['message']}");
    }
  }

  Future<void> _startCombat(Zombie zombie) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CombatScreen(
          zombie: zombie,
          gameState: _gameEngine.gameState,
        ),
      ),
    );

    if (result != null) {
      if (result["victory"] == true) {
        _addToLog("🏆 You defeated ${zombie.description}!");
      } else if (result["fled"] == true) {
        _addToLog("🏃 You fled from ${zombie.description}!");
      } else if (result["player_died"] == true) {
        _showGameOver();
        return;
      }

      if (result["message"] != null) {
        _addToLog(result["message"]);
      }
    }

    _updateLocationDisplay();
  }

  void _showMoveOptions() {
    final location = _gameEngine.getCurrentLocation();
    if (location == null) return;

    final shortDistanceLocations = location.nearbyShort;
    final longDistanceLocations = location.nearbyLong;
    final hasVehicle = _gameEngine.gameState.hasWorkingVehicle;

    List<DialogOption> options = [];

    // Add short-distance locations (always accessible)
    for (final locationName in shortDistanceLocations) {
      options.add(DialogOption(
        title: locationName,
        icon: Icons.directions_walk,
        iconColor: AppTheme.primaryColor,
        onTap: () {
          Navigator.pop(context);
          if (_gameEngine.moveToLocation(locationName)) {
            _addToLog("🚶 You travel to $locationName");
            _updateLocationDisplay();
          } else {
            _addToLog("❌ Cannot travel to $locationName");
          }
        },
      ));
    }

    // Add long-distance locations (require vehicle)
    for (final locationName in longDistanceLocations) {
      final canTravel = hasVehicle;
      options.add(DialogOption(
        title: canTravel ? locationName : "$locationName (Vehicle Required)",
        icon: Icons.directions_car,
        iconColor: canTravel ? AppTheme.primaryColor : Colors.grey,
        onTap: canTravel
            ? () {
                Navigator.pop(context);
                if (_gameEngine.moveToLocation(locationName)) {
                  _addToLog("🚗 You drive to $locationName");
                  _updateLocationDisplay();
                } else {
                  _addToLog("❌ Cannot travel to $locationName");
                }
              }
            : () {
                Navigator.pop(context);
                _addToLog(
                    "❌ You need a working vehicle to travel to $locationName");
              },
      ));
    }

    showDialog(
      context: context,
      builder: (context) => KeyboardDialog(
        title: "Choose Destination",
        options: options,
      ),
    );
  }

  void _showGlobalMenu() {
    showDialog(
      context: context,
      builder: (context) => KeyboardDialog(
        title: "Global Commands",
        options: [
          DialogOption(
            title: "Show Status",
            icon: Icons.health_and_safety,
            iconColor: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _showStatus();
            },
          ),
          DialogOption(
            title: "Inventory",
            icon: Icons.inventory,
            iconColor: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              _showInventory();
            },
          ),
          DialogOption(
            title: "Save Game",
            icon: Icons.save,
            iconColor: Colors.green,
            onTap: () {
              Navigator.pop(context);
              _showSaveDialog();
            },
          ),
          DialogOption(
            title: "Load Game",
            icon: Icons.folder_open,
            iconColor: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              _showLoadDialog();
            },
          ),
          DialogOption(
            title: "Help",
            icon: Icons.help,
            iconColor: Colors.purple,
            onTap: () {
              Navigator.pop(context);
              _showHelp();
            },
          ),
        ],
      ),
    );
  }

  void _showStatus() {
    _addToLog("");
    _addToLog("📊 PLAYER STATUS");
    _addToLog("=" * 20);
    _addToLog(_gameEngine.gameState.getStatusSummary());
  }

  void _showInventory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryScreen(gameState: _gameEngine.gameState),
      ),
    );
    setState(() {}); // Refresh UI after returning from inventory
  }

  void _showSaveDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SaveLoadScreen(
          gameState: _gameEngine.gameState,
          isSaving: true,
        ),
      ),
    );

    if (result == true) {
      _addToLog("💾 Game saved successfully!");
    }
  }

  void _showLoadDialog() async {
    final loadedGameState = await Navigator.push<GameState>(
      context,
      MaterialPageRoute(
        builder: (context) => SaveLoadScreen(
          gameState: _gameEngine.gameState,
          isSaving: false,
        ),
      ),
    );

    if (loadedGameState != null) {
      setState(() {
        _gameEngine.gameState = loadedGameState;
        _gameLog.clear();
      });
      _addToLog("📁 Game loaded successfully!");
      _updateLocationDisplay();
    }
  }

  void _showHelp() {
    _addToLog("");
    _addToLog("❓ HELP");
    _addToLog("=" * 20);
    _addToLog("• Tap action buttons to perform actions");
    _addToLog("• Monitor your health, hunger, thirst, and fatigue");
    _addToLog("• Search locations for items and supplies");
    _addToLog("• Fight or flee from zombie encounters");
    _addToLog("• Use the Global Menu (⚙️) for status, inventory, save/load");
    _addToLog("• Rest in safe locations to recover fatigue");
    _addToLog("• Manage your inventory weight carefully");
    _addToLog("");
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Text("GAME OVER",
            style: TextStyle(color: Colors.white, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _gameEngine.getGameOverReason(),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "Final Stats:",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              "Days Survived: ${_gameEngine.gameState.daysSurvived}",
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "Zombies Killed: ${_gameEngine.gameState.zombieKills}",
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "Rank: ${_gameEngine.gameState.survivorRank}",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _gameEngine.gameState = GameState();
                _gameLog.clear();
                _showIntro = true;
              });
              _initializeGame();
            },
            child:
                const Text("New Game", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionRow(location) {
    final actions = location.actions;

    if (actions.isEmpty) {
      return const Text(
        "No actions available",
        style: TextStyle(color: Colors.white70, fontSize: 11),
      );
    }

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6.0, // Horizontal spacing between buttons
        runSpacing: 4.0, // Vertical spacing between rows
        children: actions.asMap().entries.map<Widget>((entry) {
          final index = entry.key;
          final action = entry.value;
          return _buildCompactActionButton(
            text: action.name,
            number: index + 1,
            onPressed: () => _handleAction(index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required String text,
    required int number,
    required VoidCallback onPressed,
  }) {
    // Truncate long action names
    String actionName = text;
    if (actionName.length > 12) {
      actionName = '${actionName.substring(0, 9)}...';
    }

    return SizedBox(
      width: 70, // Fixed small width
      height: 40, // Fixed small height
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: AppTheme.textColor,
          side: const BorderSide(
              color: AppTheme.borderColor, width: AppTheme.borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          elevation: AppTheme.elevation,
          padding: const EdgeInsets.all(2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Number badge
            Container(
              width: 16,
              height: 16,
              decoration: AppTheme.numberCircleDecoration,
              child: Center(
                child: Text(
                  number.toString(),
                  style: AppTheme.smallTextStyle,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Action name
            Expanded(
              child: Text(
                actionName,
                style: AppTheme.smallTextStyle.copyWith(fontSize: 8),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    final location = _gameEngine.getCurrentLocation();

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          title: Text("Zombie Survival Story",
              style: AppTheme.appBarTheme.titleTextStyle),
          shape: AppTheme.appBarTheme.shape,
          elevation: AppTheme.elevation,
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: AppTheme.textColor),
              onPressed: _showGlobalMenu,
            ),
          ],
        ),
        body: Stack(
          children: [
            // Main content area
            Column(
              children: [
                // Game log (maximized space)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _gameLog.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _gameLog[index],
                            style: AppTheme.narrativeTextStyle,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Compact action buttons - centered at bottom
                if (location != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        const Divider(color: Colors.grey),
                        Text(
                          "Actions (Press 1-${location.actions.length} or 0 for menu)",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        _buildCompactActionRow(location),
                      ],
                    ),
                  ),
              ],
            ),

            // Status bar positioned in bottom-right corner
            Positioned(
              bottom: 8,
              right: 8,
              child: StatusBar(gameState: _gameEngine.gameState),
            ),
          ],
        ),
      ),
    );
  }
}
