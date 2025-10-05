import 'package:flutter/material.dart';
import '../models/game_state.dart';

class InventoryScreen extends StatefulWidget {
  final GameState gameState;

  const InventoryScreen({super.key, required this.gameState});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedCategory = 'All';
  
  final Map<String, List<String>> _categories = {
    'All': [],
    'Weapons': ['hunting knife', 'baseball bat', 'pistol', 'hunting rifle', 'shotgun', 'crowbar', 'tire iron'],
    'Medical': ['first aid kit', 'bandages', 'pain medication', 'antibiotics'],
    'Food': ['canned food', 'energy bar', 'beef jerky', 'crackers', 'chocolate'],
    'Drinks': ['water bottle', 'energy drink', 'soda', 'coffee'],
    'Tools': ['flashlight', 'rope', 'crowbar', 'tire iron', 'wrench', 'screwdriver', 'hammer', 'duct tape'],
    'Vehicle Parts': ['car battery', 'spark plugs', 'motor oil', 'tire', 'fuel filter'],
    'Ammunition': ['bullets', 'rifle_rounds', 'shells'],
    'Miscellaneous': ['road map', 'compass', 'binoculars', 'camping backpack', 'sleeping bag'],
  };

  List<String> _getFilteredInventory() {
    if (_selectedCategory == 'All') {
      return widget.gameState.inventory;
    }
    
    final categoryItems = _categories[_selectedCategory] ?? [];
    return widget.gameState.inventory.where((item) => categoryItems.contains(item)).toList();
  }

  String _getItemCategory(String item) {
    for (final entry in _categories.entries) {
      if (entry.key != 'All' && entry.value.contains(item)) {
        return entry.key;
      }
    }
    return 'Miscellaneous';
  }

  void _useItem(String item) {
    final result = widget.gameState.useItem(item);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          result["success"] ? "Item Used" : "Cannot Use Item",
          style: TextStyle(
            color: result["success"] ? Colors.green : Colors.red,
          ),
        ),
        content: Text(
          result["message"],
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    setState(() {}); // Refresh the inventory display
  }

  void _showItemDetails(String item) {
    final itemInfo = GameState.itemEffects[item];
    final category = _getItemCategory(item);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(item, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category: $category", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            if (itemInfo != null) ...[
              Text("Weight: ${itemInfo['weight']} kg", style: const TextStyle(color: Colors.white)),
              if (itemInfo['consumable'] == true) ...[
                const SizedBox(height: 8),
                const Text("Effects when used:", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                if (itemInfo['health'] != null)
                  Text("Health: +${itemInfo['health']}", style: const TextStyle(color: Colors.green)),
                if (itemInfo['hunger'] != null)
                  Text("Hunger: +${itemInfo['hunger']}", style: const TextStyle(color: Colors.green)),
                if (itemInfo['thirst'] != null)
                  Text("Thirst: +${itemInfo['thirst']}", style: const TextStyle(color: Colors.green)),
                if (itemInfo['fatigue'] != null)
                  Text("Fatigue: ${itemInfo['fatigue']}", style: const TextStyle(color: Colors.green)),
              ] else ...[
                const SizedBox(height: 8),
                const Text("This item cannot be consumed.", style: TextStyle(color: Colors.orange)),
              ],
            ] else ...[
              const Text("No additional information available.", style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
        actions: [
          if (itemInfo?['consumable'] == true)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _useItem(item);
              },
              child: const Text("Use Item", style: TextStyle(color: Colors.green)),
            ),
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
    final filteredInventory = _getFilteredInventory();
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: const Text("Inventory", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Inventory summary
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[900],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Items: ${widget.gameState.inventory.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      "Weight: ${widget.gameState.currentWeight.toStringAsFixed(1)}/${widget.gameState.maxInventoryWeight} kg",
                      style: TextStyle(
                        color: widget.gameState.currentWeight > widget.gameState.maxInventoryWeight * 0.8 
                            ? Colors.red 
                            : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Weight bar
                LinearProgressIndicator(
                  value: widget.gameState.currentWeight / widget.gameState.maxInventoryWeight,
                  backgroundColor: Colors.grey[700],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.gameState.currentWeight > widget.gameState.maxInventoryWeight * 0.8 
                        ? Colors.red 
                        : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          
          // Category filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.keys.length,
              itemBuilder: (context, index) {
                final category = _categories.keys.elementAt(index);
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: Colors.blue[700],
                    backgroundColor: Colors.grey[800],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Inventory list
          Expanded(
            child: filteredInventory.isEmpty
                ? const Center(
                    child: Text(
                      "No items in this category",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredInventory.length,
                    itemBuilder: (context, index) {
                      final item = filteredInventory[index];
                      final itemInfo = GameState.itemEffects[item];
                      final isUsable = itemInfo?['consumable'] == true;
                      final weight = itemInfo?['weight']?.toString() ?? '?';
                      
                      return Card(
                        color: Colors.grey[850],
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(
                            item,
                            style: TextStyle(
                              color: isUsable ? Colors.green : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Category: ${_getItemCategory(item)}",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                "Weight: ${weight} kg",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isUsable)
                                IconButton(
                                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                                  onPressed: () => _useItem(item),
                                  tooltip: "Use Item",
                                ),
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.blue),
                                onPressed: () => _showItemDetails(item),
                                tooltip: "Item Details",
                              ),
                            ],
                          ),
                          onTap: () => _showItemDetails(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
