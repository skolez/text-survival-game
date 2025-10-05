import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/location.dart';
import '../models/zombie.dart';
import '../services/game_engine.dart';
import '../services/save_service.dart';
import '../widgets/status_bar.dart';
import '../widgets/action_button.dart';
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
  List<String> _gameLog = [];
  bool _isLoading = true;
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _gameEngine.initialize();
    setState(() {
      _isLoading = false;
    });
    
    if (_showIntro) {
      _addToLog("🧟 ZOMBIE SURVIVAL STORY 🧟");
      _addToLog("=" * 40);
      _addToLog("You and your friend Zack have been backpacking in the Wind River Mountain Range in Wyoming for a month.");
      _addToLog("When you return to civilization, you discover that the world has changed - everyone is gone, replaced by hordes of zombies.");
      _addToLog("Armed with your survival skills and whatever supplies you can find, you must navigate this dangerous new world.");
      _addToLog("");
      _addToLog("Your mission: Survive as long as possible and try to make it home, or explore this post-apocalyptic world to uncover what happened.");
      _addToLog("");
      _showIntro = false;
    }
    
    _updateLocationDisplay();
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

    final nearbyLocations = location.getAllNearbyLocations();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Choose Destination", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: nearbyLocations.map((locationName) => 
            ListTile(
              title: Text(locationName, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                if (_gameEngine.moveToLocation(locationName)) {
                  _addToLog("🚶 You travel to $locationName");
                  _updateLocationDisplay();
                } else {
                  _addToLog("❌ Cannot travel to $locationName");
                }
              },
            )
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showGlobalMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Global Commands", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.health_and_safety, color: Colors.red),
              title: const Text("Show Status", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showStatus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: Colors.blue),
              title: const Text("Inventory", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showInventory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.save, color: Colors.green),
              title: const Text("Save Game", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showSaveDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open, color: Colors.orange),
              title: const Text("Load Game", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showLoadDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.purple),
              title: const Text("Help", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showHelp();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back", style: TextStyle(color: Colors.white)),
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
        title: const Text("GAME OVER", style: TextStyle(color: Colors.white, fontSize: 24)),
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            child: const Text("New Game", style: TextStyle(color: Colors.white)),
          ),
        ],
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
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        title: const Text("Zombie Survival Story", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showGlobalMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bars
          StatusBar(gameState: _gameEngine.gameState),
          
          // Game log
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
          
          // Action buttons
          if (location != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Divider(color: Colors.grey),
                  const Text(
                    "Available Actions:",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...location.actions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final action = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: ActionButton(
                        text: "${index + 1}. ${action.name}",
                        description: action.description,
                        onPressed: () => _handleAction(index),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
