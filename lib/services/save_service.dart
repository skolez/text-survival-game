import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';

class SaveService {
  static SaveService? _instance;
  static SaveService get instance => _instance ??= SaveService._();
  SaveService._();

  static const String _savePrefix = 'zombie_save_';
  static const String _saveListKey = 'save_list';

  Future<bool> saveGame(GameState gameState, String saveName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveData = gameState.toJson();
      saveData['saveName'] = saveName;
      saveData['saveTime'] = DateTime.now().toIso8601String();

      final saveKey = '$_savePrefix$saveName';
      final success = await prefs.setString(saveKey, json.encode(saveData));

      if (success) {
        await _updateSaveList(saveName);
      }

      return success;
    } catch (e) {
      print('Error saving game: $e');
      return false;
    }
  }

  Future<GameState?> loadGame(String saveName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveKey = '$_savePrefix$saveName';
      final saveDataString = prefs.getString(saveKey);

      if (saveDataString == null) return null;

      final saveData = json.decode(saveDataString);
      final gameState = GameState();
      gameState.fromJson(saveData);

      return gameState;
    } catch (e) {
      print('Error loading game: $e');
      return null;
    }
  }

  Future<List<SaveInfo>> getSaveList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveNames = prefs.getStringList(_saveListKey) ?? [];
      final saveInfoList = <SaveInfo>[];

      for (final saveName in saveNames) {
        final saveKey = '$_savePrefix$saveName';
        final saveDataString = prefs.getString(saveKey);

        if (saveDataString != null) {
          try {
            final saveData = json.decode(saveDataString);
            saveInfoList.add(SaveInfo.fromJson(saveData));
          } catch (e) {
            print('Error parsing save $saveName: $e');
          }
        }
      }

      // Sort by save time, newest first
      saveInfoList.sort((a, b) => b.saveTime.compareTo(a.saveTime));

      return saveInfoList;
    } catch (e) {
      print('Error getting save list: $e');
      return [];
    }
  }

  Future<bool> deleteSave(String saveName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveKey = '$_savePrefix$saveName';
      final success = await prefs.remove(saveKey);

      if (success) {
        await _removeSaveFromList(saveName);
      }

      return success;
    } catch (e) {
      print('Error deleting save: $e');
      return false;
    }
  }

  Future<void> _updateSaveList(String saveName) async {
    final prefs = await SharedPreferences.getInstance();
    final saveNames = prefs.getStringList(_saveListKey) ?? [];

    if (!saveNames.contains(saveName)) {
      saveNames.add(saveName);
      await prefs.setStringList(_saveListKey, saveNames);
    }
  }

  Future<void> _removeSaveFromList(String saveName) async {
    final prefs = await SharedPreferences.getInstance();
    final saveNames = prefs.getStringList(_saveListKey) ?? [];

    saveNames.remove(saveName);
    await prefs.setStringList(_saveListKey, saveNames);
  }

  Future<bool> saveExists(String saveName) async {
    final prefs = await SharedPreferences.getInstance();
    final saveKey = '$_savePrefix$saveName';
    return prefs.containsKey(saveKey);
  }

  /// Check if there's any save game available
  static Future<bool> hasSaveGame() async {
    try {
      final saveService = SaveService.instance;
      final saveList = await saveService.getSaveList();
      return saveList.isNotEmpty;
    } catch (e) {
      print('Error checking for save game: $e');
      return false;
    }
  }

  /// Load the most recent save game
  static Future<GameState?> loadMostRecentGame() async {
    try {
      final saveService = SaveService.instance;
      final saveList = await saveService.getSaveList();

      if (saveList.isEmpty) {
        return null;
      }

      // Get the most recent save (list is already sorted by save time)
      final mostRecentSave = saveList.first;
      return await saveService.loadGame(mostRecentSave.saveName);
    } catch (e) {
      print('Error loading most recent game: $e');
      return null;
    }
  }
}

class SaveInfo {
  final String saveName;
  final DateTime saveTime;
  final String currentLocation;
  final int health;
  final int daysSurvived;
  final int zombieKills;
  final String survivorRank;

  SaveInfo({
    required this.saveName,
    required this.saveTime,
    required this.currentLocation,
    required this.health,
    required this.daysSurvived,
    required this.zombieKills,
    required this.survivorRank,
  });

  factory SaveInfo.fromJson(Map<String, dynamic> json) {
    return SaveInfo(
      saveName: json['saveName'] ?? 'Unknown Save',
      saveTime: DateTime.tryParse(json['saveTime'] ?? '') ?? DateTime.now(),
      currentLocation: json['currentLocation'] ?? 'Unknown Location',
      health: (json['health'] ?? 100).toInt(),
      daysSurvived: json['daysSurvived'] ?? 0,
      zombieKills: json['zombieKills'] ?? 0,
      survivorRank: json['survivorRank'] ?? 'Rookie',
    );
  }

  String getFormattedSaveTime() {
    return '${saveTime.day}/${saveTime.month}/${saveTime.year} ${saveTime.hour.toString().padLeft(2, '0')}:${saveTime.minute.toString().padLeft(2, '0')}';
  }

  String getSummary() {
    return 'Health: $health | Days: $daysSurvived | Kills: $zombieKills | Rank: $survivorRank';
  }
}
