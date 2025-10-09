import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_theme.dart';
import '../models/game_state.dart';
import '../services/game_engine.dart';
import '../services/save_service.dart';
import 'game_screen.dart';
import 'intro_screen.dart';
import 'settings_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _hasSaveGame = false;

  @override
  void initState() {
    super.initState();
    _checkForSaveGame();
  }

  Future<void> _checkForSaveGame() async {
    final hasSave = await SaveService.hasSaveGame();
    setState(() {
      _hasSaveGame = hasSave;
    });
  }

  void _toggleTheme() {
    setState(() {
      AppTheme.setTheme(AppTheme.currentTheme == AppThemeMode.dark
          ? AppThemeMode.light
          : AppThemeMode.dark);
    });
  }

  void _startNewGame() async {
    // Choose difficulty first
    Difficulty? selected = await showDialog<Difficulty>(
      context: context,
      builder: (context) {
        Difficulty temp = GameEngine.instance.gameState.difficulty;
        return AlertDialog(
          backgroundColor: AppTheme.backgroundColor,
          title: Text('Select Difficulty',
              style: TextStyle(color: AppTheme.textColor)),
          content: StatefulBuilder(
            builder: (context, setState) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Difficulty:',
                    style: TextStyle(color: AppTheme.textColor)),
                const SizedBox(width: 12),
                DropdownButton<Difficulty>(
                  value: temp,
                  dropdownColor: AppTheme.backgroundColor,
                  items: [
                    DropdownMenuItem(
                        value: Difficulty.easy,
                        child: Text('Easy',
                            style: TextStyle(color: AppTheme.textColor))),
                    DropdownMenuItem(
                        value: Difficulty.medium,
                        child: Text('Medium',
                            style: TextStyle(color: AppTheme.textColor))),
                    DropdownMenuItem(
                        value: Difficulty.hard,
                        child: Text('Hard',
                            style: TextStyle(color: AppTheme.textColor))),
                  ],
                  onChanged: (v) => setState(() => temp = v ?? temp),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('Cancel', style: TextStyle(color: AppTheme.textColor)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, temp),
              child:
                  Text('Start', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        );
      },
    );

    if (selected == null) return;

    // Persist and apply selection
    GameEngine.instance.gameState.difficulty = selected;
    try {
      final prefs = await SharedPreferences.getInstance();
      final diffStr = selected == Difficulty.easy
          ? 'easy'
          : selected == Difficulty.hard
              ? 'hard'
              : 'medium';
      await prefs.setString('difficulty', diffStr);
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const IntroScreen()),
    );
  }

  void _continueGame() async {
    if (_hasSaveGame) {
      final gameState = await SaveService.loadMostRecentGame();
      if (gameState != null && mounted) {
        // TODO: Pass the loaded game state to the game screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GameScreen()),
        );
      } else {
        _showErrorDialog('Failed to load save game');
      }
    }
  }

  void _loadGame() {
    // TODO: Implement load game dialog with multiple save slots
    _continueGame(); // For now, just load the most recent save
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: Text('Error', style: TextStyle(color: AppTheme.textColor)),
        content: Text(message, style: TextStyle(color: AppTheme.textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.surfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Theme toggle button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    onPressed: _toggleTheme,
                    icon: Icon(
                      AppTheme.currentTheme == AppThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: AppTheme.textColor,
                    ),
                    // tooltip removed on web to reduce mouse tracking noise
                  ),
                ),
              ),

              // Title
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ZOMBIE',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 8,
                        ),
                      ),
                      Text(
                        'SURVIVAL',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 8,
                        ),
                      ),
                      Text(
                        'STORY',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'A Text-Based Adventure',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 16,
                          fontFamily: 'monospace',
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Menu buttons
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        _buildMenuButton(
                          'NEW GAME',
                          Icons.play_arrow,
                          _startNewGame,
                        ),
                        const SizedBox(height: 12),
                        _buildMenuButton(
                          'CONTINUE',
                          Icons.play_circle_outline,
                          _hasSaveGame ? _continueGame : null,
                        ),
                        const SizedBox(height: 12),
                        _buildMenuButton(
                          'LOAD GAME',
                          Icons.folder_open,
                          _hasSaveGame ? _loadGame : null,
                        ),
                        const SizedBox(height: 20),
                        _buildMenuButton(
                          'SETTINGS',
                          Icons.settings,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuButton(
                          'EXIT',
                          Icons.exit_to_app,
                          () {
                            // TODO: Implement proper exit for mobile
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Created by Skolez',
                  style: TextStyle(
                    color: AppTheme.textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String text, IconData icon, VoidCallback? onPressed) {
    final isEnabled = onPressed != null;

    return SizedBox(
      width: 220,
      height: 45,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isEnabled ? AppTheme.textColor : AppTheme.disabledColor,
        ),
        label: Text(
          text,
          style: TextStyle(
            color: isEnabled ? AppTheme.textColor : AppTheme.disabledColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? AppTheme.backgroundColor : AppTheme.surfaceColor,
          foregroundColor:
              isEnabled ? AppTheme.textColor : AppTheme.disabledColor,
          side: BorderSide(
            color: isEnabled ? AppTheme.borderColor : AppTheme.disabledColor,
            width: AppTheme.borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          elevation: isEnabled ? AppTheme.elevation : 0,
        ),
      ),
    );
  }
}
