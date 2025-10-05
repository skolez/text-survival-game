# 🧟 Zombie Survival Story - Flutter Edition

A comprehensive text-based zombie survival adventure game built with Flutter/Dart. Survive the apocalypse, manage resources, fight zombies, and explore a detailed world as you try to make it home.

## 📖 Story

You and your friend Zack have been backpacking in the Wind River Mountain Range in Wyoming for a month. When you return to civilization, you discover that the world has changed - everyone is gone, replaced by hordes of zombies. Armed with your survival skills and whatever supplies you can find, you must navigate this dangerous new world.

Your mission: Survive as long as possible and try to make it home, or explore this post-apocalyptic world to uncover what happened.

## ✨ Features

### 🎮 Core Gameplay
- **Rich Location System**: Explore 10+ detailed locations including gas stations, hospitals, police stations, and wilderness areas
- **Dynamic Combat**: Fight different types of zombies with various weapons and tactics
- **Resource Management**: Monitor health, hunger, thirst, fatigue, and fuel levels
- **Inventory System**: Categorized inventory with weight limits and item usage
- **Save/Load System**: Multiple save slots with detailed save information

### 🧟 Survival Mechanics
- **Zombie Encounters**: Random encounters with different zombie types (walkers, runners, brutes, crawlers)
- **Weapon System**: Use melee weapons, firearms, and improvised weapons
- **Health & Status**: Manage multiple survival stats that affect gameplay
- **Rest & Recovery**: Find safe locations to rest and recover
- **Fuel Management**: Keep vehicles fueled for faster travel

### 🎯 Advanced Features
- **Location-Based Actions**: Different actions available at different locations
- **Item Categories**: Weapons, medical supplies, food, tools, and more
- **Visual Status Bars**: Color-coded health and resource indicators
- **Comprehensive Help System**: Built-in help and command reference
- **Error Handling**: Robust error handling and input validation

## 🚀 Installation & Setup

### Prerequisites
- Python 3.8 or higher
- pip (Python package installer)

### Quick Start
1. **Clone or download the game files**
   ```bash
   git clone <repository-url>
   cd text-adventure-game
   ```

2. **Install dependencies (optional, for testing)**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the game**
   ```bash
   cd src
   python main.py
   ```

### Alternative Setup
If you prefer to run without installing dependencies:
```bash
cd text-adventure-game/src
python main.py
```

## 🎮 How to Play

### Game Commands (All Numeric!)
- **Numbers (1-8)**: Choose location-specific actions
- **[0]**: Access global commands menu

### Global Commands Menu (Press 0)
- **[1]**: Show detailed character status
- **[2]**: Show inventory with options to use or view details
- **[3]**: Save your current game
- **[4]**: Load a previously saved game
- **[5]**: Show help screen
- **[6]**: Quit game

### Enhanced Inventory System
When you access your inventory (Global Menu → 2), you can:
- **[1] Use an item**: Select items by number to use them
- **[2] View item details**: Get detailed information about items
- **[0] Back to game**: Return to the main game
- Items are clearly marked as "usable" or "not usable"
- Consumables like food, drinks, and medical supplies can be used
- Weapons and tools are displayed but cannot be consumed

### Vehicle & Travel System
- **Short-Distance Travel**: Walk to nearby locations within the same town
- **Long-Distance Travel**: Use repaired vehicles to travel between towns
- **Vehicle Repair**: Find car parts and repair broken vehicles
- **Multiple Towns**: Explore Riverside, Millbrook, and other locations
- **Permanent Breakdown**: Vehicles break down after long trips - find new ones!

### Rich Location-Specific Searches
- **Contextual Actions**: Each location has unique search options (e.g., "Search weapon section", "Check camping gear")
- **Detailed Descriptions**: Rich narrative descriptions for each search action
- **Smart Item Discovery**: Different items based on what you're searching for
- **Environmental Storytelling**: Learn about the world through search descriptions
- **Zombie Encounters**: Random chance of encountering zombies during searches

### Gameplay Tips
1. **Monitor Your Stats**: Keep an eye on health, hunger, thirst, and fatigue
2. **Search Locations**: Look around and search for useful items
3. **Manage Weight**: Your inventory has weight limits - choose items wisely
4. **Find Safe Shelter**: Some locations are safer for resting than others
5. **Conserve Fuel**: You might need to walk if you run out of gas
6. **Prepare for Combat**: Zombies can appear anywhere - stay armed

### Combat System
- Choose from available weapons (fists, knives, guns, etc.)
- Different weapons have different damage and accuracy ratings
- Firearms require ammunition
- You can attempt to flee from combat
- Some locations have higher zombie encounter rates

## 📁 Project Structure

```
text-adventure-game/
├── src/                          # Source code
│   ├── main.py                   # Game entry point
│   ├── game_engine.py            # Main game engine and loop
│   ├── game_state.py             # Game state management
│   ├── combat_system.py          # Combat mechanics
│   ├── test_game.py              # Unit tests
│   ├── Functions/                # Game function modules
│   │   ├── __init__.py
│   │   ├── check_inventory.py    # Inventory management
│   │   ├── clear_screen.py       # Screen utilities
│   │   ├── look_around.py        # Location exploration
│   │   ├── move_location.py      # Movement system
│   │   ├── read_location_data.py # Location data loading
│   │   └── ...                   # Other utility functions
│   └── Assets/                   # Game assets
│       ├── locations.json        # Location definitions
│       ├── opening_title.txt     # ASCII art title
│       └── zombie_intro.txt      # Intro story text
├── requirements.txt              # Python dependencies
├── setup.py                     # Package setup (for distribution)
└── README.md                    # This file
```

## 🧪 Testing

The game includes comprehensive unit tests covering all major components.

### Running Tests
```bash
cd src
python test_game.py
```

### With pytest (if installed)
```bash
cd src
pytest test_game.py -v
```

### Test Coverage
- Game state management (save/load, inventory, stats)
- Combat system (zombies, weapons, damage)
- Location system (data loading, validation)
- Inventory functions (categorization, item info)

## 🎨 Customization

### Adding New Locations
Edit `src/Assets/locations.json` to add new locations:
```json
{
    "name": "New Location",
    "description": "Description of the location",
    "actions": [
        {"name": "Action Name", "description": "What the action does"}
    ],
    "nearby": ["Connected Location 1", "Connected Location 2"],
    "items": ["item1", "item2"],
    "zombie_chance": 0.3,
    "shelter": true
}
```

### Adding New Items
Modify the item definitions in:
- `src/Functions/check_inventory.py` (for categorization and info)
- `src/game_state.py` (for item effects)
- `src/combat_system.py` (for weapons)

### Modifying Game Balance
Adjust values in:
- `src/game_state.py`: Survival stat degradation rates
- `src/combat_system.py`: Weapon damage and zombie stats
- `src/Assets/locations.json`: Zombie encounter rates

## 🐛 Troubleshooting

### Common Issues

**Game won't start**
- Ensure you're running Python 3.8+
- Check that all files are in the correct directories
- Try running from the `src` directory

**Save files not working**
- Ensure the game has write permissions in the directory
- Save files are created in the same directory as the game

**Missing locations.json**
- The game will use default locations if the file is missing
- Check that `Assets/locations.json` exists and is valid JSON

### Error Messages
The game includes comprehensive error handling and will display helpful messages for most issues.

## 🔧 Development

### Code Style
- Follow PEP 8 Python style guidelines
- Use type hints where possible
- Include docstrings for all functions and classes
- Write unit tests for new features

### Contributing
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

### Future Enhancements
- Multiplayer support
- Graphics/GUI interface
- More complex crafting system
- Larger world map
- Character progression system
- Multiple story paths

## 📜 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- ASCII art title generated using [Patorjk.com](http://patorjk.com/software/taag/) with Banner3-D font
- Inspired by classic text adventure games
- Built as a learning project for Python game development

## 📞 Support

If you encounter any issues or have questions:
1. Check the troubleshooting section above
2. Review the help system in-game (type `help`)
3. Check the unit tests for usage examples
4. Create an issue in the project repository

---

**Enjoy surviving the zombie apocalypse!** 🧟‍♂️🎮
