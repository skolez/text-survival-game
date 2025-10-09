import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
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
    'Weapons': [
      'hunting knife',
      'baseball bat',
      'pistol',
      'hunting rifle',
      'shotgun',
      'crowbar',
      'tire iron'
    ],
    'Medical': ['first aid kit', 'bandages', 'pain medication', 'antibiotics'],
    'Food': [
      'canned food',
      'energy bar',
      'beef jerky',
      'crackers',
      'chocolate'
    ],
    'Drinks': ['water bottle', 'energy drink', 'soda', 'coffee'],
    'Tools': [
      'flashlight',
      'rope',
      'crowbar',
      'tire iron',
      'wrench',
      'screwdriver',
      'hammer',
      'duct tape'
    ],
    'Vehicle Parts': [
      'car battery',
      'spark plugs',
      'motor oil',
      'tire',
      'fuel filter'
    ],
    'Ammunition': ['bullets', 'rifle_rounds', 'shells'],
    'Miscellaneous': [
      'road map',
      'compass',
      'binoculars',
      'camping backpack',
      'sleeping bag'
    ],
  };

  List<String> _getFilteredInventory() {
    if (_selectedCategory == 'All') {
      return widget.gameState.inventory;
    }

    final categoryItems = _categories[_selectedCategory] ?? [];
    return widget.gameState.inventory
        .where((item) => categoryItems.contains(item))
        .toList();
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
        backgroundColor: AppTheme.backgroundColor,
        title: Text(
          result["success"] ? "Item Used" : "Cannot Use Item",
          style: TextStyle(
            color: result["success"] ? AppTheme.primaryColor : Colors.red,
          ),
        ),
        content: Text(
          result["message"],
          style: TextStyle(color: AppTheme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: AppTheme.textColor)),
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
        backgroundColor: AppTheme.backgroundColor,
        title: Text(item, style: TextStyle(color: AppTheme.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category: $category",
                style: TextStyle(
                    color: AppTheme.textColor.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            if (itemInfo != null) ...[
              Text("Weight: ${itemInfo['weight']} kg",
                  style: TextStyle(color: AppTheme.textColor)),
              if (itemInfo['consumable'] == true) ...[
                const SizedBox(height: 8),
                Text("Effects when used:",
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold)),
                if (itemInfo['health'] != null)
                  Text("Health: +${itemInfo['health']}",
                      style: TextStyle(color: AppTheme.primaryColor)),
                if (itemInfo['hunger'] != null)
                  Text("Hunger: +${itemInfo['hunger']}",
                      style: TextStyle(color: AppTheme.primaryColor)),
                if (itemInfo['thirst'] != null)
                  Text("Thirst: +${itemInfo['thirst']}",
                      style: TextStyle(color: AppTheme.primaryColor)),
                if (itemInfo['fatigue'] != null)
                  Text("Fatigue: ${itemInfo['fatigue']}",
                      style: TextStyle(color: AppTheme.primaryColor)),
              ] else ...[
                const SizedBox(height: 8),
                const Text("This item cannot be consumed.",
                    style: TextStyle(color: Colors.orange)),
              ],
            ] else ...[
              Text("No additional information available.",
                  style: TextStyle(
                      color: AppTheme.textColor.withValues(alpha: 0.7))),
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
              child: Text("Use Item",
                  style: TextStyle(color: AppTheme.primaryColor)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: AppTheme.textColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredInventory = _getFilteredInventory();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textColor,
        title: Text("Inventory", style: TextStyle(color: AppTheme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Inventory summary
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: AppTheme.panelDecoration,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Items: ${widget.gameState.inventory.length}",
                      style: TextStyle(color: AppTheme.textColor, fontSize: 16),
                    ),
                    Text(
                      "Weight: ${widget.gameState.currentWeight.toStringAsFixed(1)}/${widget.gameState.maxInventoryWeight} kg",
                      style: TextStyle(
                        color: widget.gameState.currentWeight >
                                widget.gameState.maxInventoryWeight * 0.8
                            ? Colors.red
                            : AppTheme.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Weight bar
                LinearProgressIndicator(
                  value: widget.gameState.currentWeight /
                      widget.gameState.maxInventoryWeight,
                  backgroundColor: AppTheme.surfaceColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.gameState.currentWeight >
                            widget.gameState.maxInventoryWeight * 0.8
                        ? Colors.red
                        : AppTheme.primaryColor,
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
                    selectedColor: AppTheme.surfaceColor,
                    backgroundColor: AppTheme.surfaceColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.textColor
                          : AppTheme.textColor.withValues(alpha: 0.7),
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
                        color: AppTheme.cardColor,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(
                            item,
                            style: TextStyle(
                              color: isUsable
                                  ? AppTheme.primaryColor
                                  : AppTheme.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Category: ${_getItemCategory(item)}",
                                style: TextStyle(
                                    color: AppTheme.textColor
                                        .withValues(alpha: 0.7),
                                    fontSize: 12),
                              ),
                              Text(
                                "Weight: ${weight} kg",
                                style: TextStyle(
                                    color: AppTheme.textColor
                                        .withValues(alpha: 0.7),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isUsable)
                                IconButton(
                                  icon: Icon(Icons.play_arrow,
                                      color: AppTheme.primaryColor),
                                  onPressed: () => _useItem(item),
                                  tooltip: "Use Item",
                                ),
                              IconButton(
                                icon: Icon(Icons.info_outline,
                                    color: AppTheme.primaryColor),
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
