import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/save_service.dart';

class SaveLoadScreen extends StatefulWidget {
  final GameState gameState;
  final bool isSaving;

  const SaveLoadScreen({
    super.key,
    required this.gameState,
    required this.isSaving,
  });

  @override
  State<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends State<SaveLoadScreen> {
  final SaveService _saveService = SaveService.instance;
  final TextEditingController _saveNameController = TextEditingController();
  List<SaveInfo> _saveList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaveList();
  }

  Future<void> _loadSaveList() async {
    final saves = await _saveService.getSaveList();
    setState(() {
      _saveList = saves;
      _isLoading = false;
    });
  }

  Future<void> _saveGame(String saveName) async {
    if (saveName.trim().isEmpty) {
      _showMessage("Please enter a save name", isError: true);
      return;
    }

    final success = await _saveService.saveGame(widget.gameState, saveName.trim());
    
    if (success) {
      Navigator.pop(context, true);
    } else {
      _showMessage("Failed to save game", isError: true);
    }
  }

  Future<void> _loadGame(String saveName) async {
    final gameState = await _saveService.loadGame(saveName);
    
    if (gameState != null) {
      Navigator.pop(context, gameState);
    } else {
      _showMessage("Failed to load game", isError: true);
    }
  }

  Future<void> _deleteSave(String saveName) async {
    final confirmed = await _showConfirmDialog(
      "Delete Save",
      "Are you sure you want to delete the save '$saveName'? This action cannot be undone.",
    );
    
    if (confirmed) {
      final success = await _saveService.deleteSave(saveName);
      if (success) {
        _loadSaveList(); // Refresh the list
        _showMessage("Save deleted successfully");
      } else {
        _showMessage("Failed to delete save", isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Save Game", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _saveNameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Save Name",
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveGame(_saveNameController.text);
            },
            child: const Text("Save", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: widget.isSaving ? Colors.green[800] : Colors.orange[800],
        title: Text(
          widget.isSaving ? "Save Game" : "Load Game",
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: widget.isSaving ? [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showSaveDialog,
            tooltip: "New Save",
          ),
        ] : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            )
          : _saveList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isSaving ? "No saves yet" : "No saved games found",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 18,
                        ),
                      ),
                      if (widget.isSaving) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showSaveDialog,
                          icon: const Icon(Icons.save),
                          label: const Text("Create New Save"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _saveList.length,
                  itemBuilder: (context, index) {
                    final save = _saveList[index];
                    
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        title: Text(
                          save.saveName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Location: ${save.currentLocation}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              save.getSummary(),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              "Saved: ${save.getFormattedSaveTime()}",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isSaving)
                              IconButton(
                                icon: const Icon(Icons.save, color: Colors.green),
                                onPressed: () => _saveGame(save.saveName),
                                tooltip: "Overwrite Save",
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.blue),
                                onPressed: () => _loadGame(save.saveName),
                                tooltip: "Load Game",
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSave(save.saveName),
                              tooltip: "Delete Save",
                            ),
                          ],
                        ),
                        onTap: widget.isSaving
                            ? () => _saveGame(save.saveName)
                            : () => _loadGame(save.saveName),
                      ),
                    );
                  },
                ),
      floatingActionButton: widget.isSaving
          ? FloatingActionButton(
              onPressed: _showSaveDialog,
              backgroundColor: Colors.green[700],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _saveNameController.dispose();
    super.dispose();
  }
}
