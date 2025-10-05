# Contributing to Zombie Survival Story

Thank you for your interest in contributing to the Zombie Survival Story text adventure game! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- Python 3.8 or higher
- Basic understanding of Python programming
- Familiarity with text-based games (helpful but not required)

### Development Setup
1. Fork the repository
2. Clone your fork locally
3. Set up a virtual environment (recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
4. Install development dependencies:
   ```bash
   pip install -r requirements.txt
   ```
5. Run tests to ensure everything works:
   ```bash
   cd src
   python test_game.py
   ```

## 📋 How to Contribute

### Types of Contributions
- 🐛 **Bug Reports**: Report issues or unexpected behavior
- 💡 **Feature Requests**: Suggest new features or improvements
- 🔧 **Code Contributions**: Fix bugs or implement new features
- 📚 **Documentation**: Improve documentation, add examples
- 🧪 **Testing**: Add or improve test coverage
- 🎨 **Content**: Add new locations, items, or story elements

### Reporting Issues
When reporting bugs, please include:
- Python version and operating system
- Steps to reproduce the issue
- Expected vs. actual behavior
- Error messages (if any)
- Save file (if relevant)

### Suggesting Features
For feature requests, please provide:
- Clear description of the feature
- Use case or problem it solves
- Possible implementation approach
- Any relevant examples or mockups

## 🏗️ Development Guidelines

### Code Style
We follow PEP 8 Python style guidelines with these specifics:

#### General Rules
- Use 4 spaces for indentation (no tabs)
- Maximum line length: 88 characters (Black formatter default)
- Use descriptive variable and function names
- Add docstrings to all functions and classes
- Include type hints where possible

#### Example Code Style
```python
def calculate_damage(weapon: str, zombie_type: str) -> int:
    """
    Calculate damage dealt to a zombie.
    
    Args:
        weapon: Name of the weapon being used
        zombie_type: Type of zombie being attacked
        
    Returns:
        Damage amount as integer
        
    Raises:
        ValueError: If weapon or zombie_type is invalid
    """
    if not weapon or not zombie_type:
        raise ValueError("Weapon and zombie_type must be provided")
    
    base_damage = WEAPON_STATS.get(weapon, {}).get("damage", 0)
    zombie_resistance = ZOMBIE_STATS.get(zombie_type, {}).get("resistance", 1.0)
    
    return int(base_damage * zombie_resistance)
```

#### Naming Conventions
- **Functions and variables**: `snake_case`
- **Classes**: `PascalCase`
- **Constants**: `UPPER_SNAKE_CASE`
- **Private methods**: `_leading_underscore`
- **Files**: `snake_case.py`

### Project Structure
```
text-adventure-game/
├── src/                          # All source code
│   ├── main.py                   # Entry point
│   ├── game_engine.py            # Core game logic
│   ├── game_state.py             # State management
│   ├── combat_system.py          # Combat mechanics
│   ├── test_game.py              # Unit tests
│   ├── Functions/                # Utility functions
│   │   ├── __init__.py
│   │   └── *.py                  # Individual function modules
│   └── Assets/                   # Game data files
│       ├── locations.json        # Location definitions
│       └── *.txt                 # Text assets
├── requirements.txt              # Dependencies
├── README.md                     # Main documentation
├── CHANGELOG.md                  # Version history
└── CONTRIBUTING.md               # This file
```

### Testing Requirements
- All new features must include unit tests
- Maintain or improve test coverage
- Tests should be in `test_game.py` or separate test files
- Use descriptive test names and docstrings

#### Test Example
```python
def test_add_item_to_inventory(self):
    """Test adding an item to player inventory."""
    game_state = GameState()
    initial_count = len(game_state.inventory)
    
    result = game_state.add_item("water bottle", 0.5)
    
    self.assertTrue(result)
    self.assertEqual(len(game_state.inventory), initial_count + 1)
    self.assertIn("water bottle", game_state.inventory)
```

### Documentation Standards
- Use clear, concise language
- Include examples where helpful
- Update README.md for user-facing changes
- Update CHANGELOG.md for all changes
- Add docstrings to all public functions and classes

## 🔄 Development Workflow

### Branch Naming
- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `docs/description` - Documentation updates
- `test/description` - Test improvements

### Commit Messages
Use clear, descriptive commit messages:
```
Add zombie encounter system

- Implement random zombie encounters based on location
- Add different zombie types with unique stats
- Include combat mechanics and weapon system
- Add unit tests for combat functionality

Fixes #123
```

### Pull Request Process
1. **Create a branch** from `main` for your changes
2. **Make your changes** following the coding standards
3. **Add or update tests** for your changes
4. **Run all tests** to ensure they pass
5. **Update documentation** if needed
6. **Create a pull request** with:
   - Clear title and description
   - Reference to related issues
   - Screenshots (if UI changes)
   - Test results

### Code Review Process
- All changes require review before merging
- Address reviewer feedback promptly
- Keep discussions constructive and respectful
- Update your branch if requested

## 🎮 Game Design Guidelines

### Adding New Locations
When adding locations to `Assets/locations.json`:

```json
{
    "name": "Location Name",
    "description": "Detailed description that sets the mood and provides context",
    "actions": [
        {
            "name": "Action Name",
            "description": "What this action does"
        }
    ],
    "nearby": ["Connected Location 1", "Connected Location 2"],
    "items": ["possible", "items", "to", "find"],
    "dangers": ["potential", "hazards"],
    "zombie_chance": 0.3,
    "shelter": true,
    "secure_location": false,
    "rest_bonus": 10
}
```

#### Location Design Principles
- **Atmosphere**: Each location should have a distinct feel
- **Balance**: Risk vs. reward for items and safety
- **Connectivity**: Logical connections to other locations
- **Variety**: Different types of actions and encounters

### Adding New Items
Consider these factors when adding items:
- **Purpose**: What problem does this item solve?
- **Balance**: Is it too powerful or too weak?
- **Category**: Which inventory category does it belong to?
- **Weight**: Reasonable weight for inventory management
- **Rarity**: How common should this item be?

### Game Balance
- **Survival Stats**: Changes should maintain challenge without being punishing
- **Combat**: New weapons should fit within existing damage ranges
- **Resources**: Scarcity should create meaningful choices
- **Progression**: Players should feel advancement over time

## 🧪 Testing Guidelines

### Test Categories
1. **Unit Tests**: Test individual functions and classes
2. **Integration Tests**: Test component interactions
3. **Game Flow Tests**: Test complete gameplay scenarios
4. **Edge Cases**: Test error conditions and boundary values

### Running Tests
```bash
# Run all tests
cd src
python test_game.py

# Run with pytest (if installed)
pytest test_game.py -v

# Run with coverage (if installed)
pytest test_game.py --cov=. --cov-report=html
```

### Test Data
- Use temporary files for save/load tests
- Mock external dependencies when possible
- Clean up test data after tests complete
- Use realistic but simple test scenarios

## 📚 Resources

### Learning Resources
- [Python Official Documentation](https://docs.python.org/3/)
- [PEP 8 Style Guide](https://pep8.org/)
- [Python Type Hints](https://docs.python.org/3/library/typing.html)
- [unittest Documentation](https://docs.python.org/3/library/unittest.html)

### Game Development Resources
- [Interactive Fiction Technology Foundation](https://iftechfoundation.org/)
- [Text Adventure Development Guide](https://www.ifwiki.org/)
- [Game Design Patterns](https://gameprogrammingpatterns.com/)

## 🤝 Community Guidelines

### Code of Conduct
- Be respectful and inclusive
- Provide constructive feedback
- Help newcomers learn and contribute
- Focus on the code, not the person
- Celebrate diverse perspectives and approaches

### Communication
- Use clear, professional language
- Ask questions when unsure
- Provide context for your suggestions
- Be patient with review processes
- Thank contributors for their time

## 🏆 Recognition

Contributors will be recognized in:
- README.md acknowledgments section
- CHANGELOG.md for significant contributions
- Release notes for major features

## 📞 Getting Help

If you need help:
1. Check existing documentation
2. Search existing issues
3. Ask questions in discussions
4. Contact maintainers directly

Thank you for contributing to Zombie Survival Story! 🧟‍♂️🎮
