"""
Unit Tests for Text Adventure Game

This module contains comprehensive unit tests for all game components.
Run with: python -m pytest test_game.py -v
"""

import unittest
import tempfile
import os
import json
from unittest.mock import patch, MagicMock

# Import game modules
from game_state import GameState
from combat_system import CombatSystem, Zombie
from Functions.read_location_data import read_location_data, get_default_locations
from Functions.check_inventory import check_inventory, get_item_info


class TestGameState(unittest.TestCase):
    """Test the GameState class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.game_state = GameState()
    
    def test_initial_state(self):
        """Test initial game state values."""
        self.assertEqual(self.game_state.health, 100)
        self.assertEqual(self.game_state.hunger, 100)
        self.assertEqual(self.game_state.thirst, 100)
        self.assertEqual(self.game_state.fatigue, 0)
        self.assertEqual(self.game_state.fuel, 100)
        self.assertEqual(self.game_state.current_location, "Abandoned Gas Station")
        self.assertIn("can of motor oil", self.game_state.inventory)
    
    def test_add_item_success(self):
        """Test successfully adding an item to inventory."""
        initial_count = len(self.game_state.inventory)
        result = self.game_state.add_item("water bottle", 0.5)
        
        self.assertTrue(result)
        self.assertEqual(len(self.game_state.inventory), initial_count + 1)
        self.assertIn("water bottle", self.game_state.inventory)
        self.assertEqual(self.game_state.current_weight, 2.5)  # 2 + 0.5
    
    def test_add_item_weight_limit(self):
        """Test adding item when weight limit is exceeded."""
        # Fill inventory to near capacity
        self.game_state.current_weight = 49.5
        result = self.game_state.add_item("heavy item", 1.0)
        
        self.assertFalse(result)
        self.assertNotIn("heavy item", self.game_state.inventory)
    
    def test_remove_item_success(self):
        """Test successfully removing an item from inventory."""
        self.game_state.add_item("test item", 1.0)
        initial_count = len(self.game_state.inventory)
        
        result = self.game_state.remove_item("test item", 1.0)
        
        self.assertTrue(result)
        self.assertEqual(len(self.game_state.inventory), initial_count - 1)
        self.assertNotIn("test item", self.game_state.inventory)
    
    def test_remove_item_not_found(self):
        """Test removing an item that doesn't exist."""
        result = self.game_state.remove_item("nonexistent item", 1.0)
        self.assertFalse(result)
    
    def test_has_item(self):
        """Test checking if player has an item."""
        self.assertTrue(self.game_state.has_item("can of motor oil"))
        self.assertFalse(self.game_state.has_item("nonexistent item"))
    
    def test_use_item_water_bottle(self):
        """Test using a water bottle."""
        self.game_state.add_item("water bottle", 0.5)
        self.game_state.thirst = 50
        
        result = self.game_state.use_item("water bottle")
        
        self.assertTrue(result["success"])
        self.assertEqual(self.game_state.thirst, 80)  # 50 + 30
        self.assertNotIn("water bottle", self.game_state.inventory)
    
    def test_use_item_not_owned(self):
        """Test using an item the player doesn't have."""
        result = self.game_state.use_item("water bottle")
        
        self.assertFalse(result["success"])
        self.assertIn("don't have", result["message"])
    
    def test_move_to_location(self):
        """Test moving to a new location."""
        old_location = self.game_state.current_location
        result = self.game_state.move_to_location("New Location")
        
        self.assertTrue(result)
        self.assertEqual(self.game_state.current_location, "New Location")
        self.assertIn(old_location, self.game_state.visited_locations)
        self.assertEqual(self.game_state.turn_count, 1)
    
    def test_update_survival_stats(self):
        """Test survival stat degradation."""
        initial_hunger = self.game_state.hunger
        initial_thirst = self.game_state.thirst
        initial_fatigue = self.game_state.fatigue
        
        self.game_state.update_survival_stats(1)
        
        self.assertLess(self.game_state.hunger, initial_hunger)
        self.assertLess(self.game_state.thirst, initial_thirst)
        self.assertGreater(self.game_state.fatigue, initial_fatigue)
    
    def test_is_game_over_health(self):
        """Test game over condition for health."""
        self.game_state.health = 0
        is_over, reason = self.game_state.is_game_over()
        
        self.assertTrue(is_over)
        self.assertIn("died from your injuries", reason)
    
    def test_is_game_over_starvation(self):
        """Test game over condition for starvation."""
        self.game_state.hunger = 0
        is_over, reason = self.game_state.is_game_over()
        
        self.assertTrue(is_over)
        self.assertIn("starvation", reason)
    
    def test_save_and_load(self):
        """Test saving and loading game state."""
        # Modify game state
        self.game_state.health = 75
        self.game_state.add_item("test item", 1.0)
        self.game_state.move_to_location("Test Location")
        
        # Save to temporary file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            temp_filename = f.name
        
        try:
            # Save
            result = self.game_state.save_to_file(temp_filename)
            self.assertTrue(result)
            
            # Create new game state and load
            new_game_state = GameState()
            result = new_game_state.load_from_file(temp_filename)
            
            self.assertTrue(result)
            self.assertEqual(new_game_state.health, 75)
            self.assertIn("test item", new_game_state.inventory)
            self.assertEqual(new_game_state.current_location, "Test Location")
            
        finally:
            # Clean up
            if os.path.exists(temp_filename):
                os.unlink(temp_filename)


class TestCombatSystem(unittest.TestCase):
    """Test the CombatSystem class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.combat_system = CombatSystem()
        self.zombie = Zombie("walker")
    
    def test_zombie_creation(self):
        """Test zombie creation with different types."""
        walker = Zombie("walker")
        self.assertEqual(walker.type, "walker")
        self.assertEqual(walker.health, 30)
        self.assertEqual(walker.damage, 15)
        self.assertTrue(walker.is_alive)
        
        runner = Zombie("runner")
        self.assertEqual(runner.type, "runner")
        self.assertEqual(runner.health, 25)
        self.assertEqual(runner.damage, 20)
    
    def test_zombie_take_damage(self):
        """Test zombie taking damage."""
        initial_health = self.zombie.health
        killed = self.zombie.take_damage(10)
        
        self.assertFalse(killed)
        self.assertEqual(self.zombie.health, initial_health - 10)
        self.assertTrue(self.zombie.is_alive)
        
        # Kill zombie
        killed = self.zombie.take_damage(100)
        self.assertTrue(killed)
        self.assertFalse(self.zombie.is_alive)
    
    def test_zombie_attack(self):
        """Test zombie attack."""
        damage = self.zombie.attack()
        self.assertGreater(damage, 0)
        self.assertIsInstance(damage, int)
        
        # Dead zombie shouldn't attack
        self.zombie.is_alive = False
        damage = self.zombie.attack()
        self.assertEqual(damage, 0)
    
    def test_get_available_weapons(self):
        """Test getting available weapons."""
        weapons = self.combat_system.get_available_weapons()
        self.assertIn("fists", weapons)
        
        # Mock game state with weapons
        with patch('combat_system.game_state') as mock_game_state:
            mock_game_state.inventory = ["hunting knife", "pistol"]
            weapons = self.combat_system.get_available_weapons()
            self.assertIn("fists", weapons)
            self.assertIn("hunting knife", weapons)
            self.assertIn("pistol", weapons)
    
    def test_can_use_weapon(self):
        """Test weapon usage validation."""
        # Test basic weapon
        can_use, reason = self.combat_system.can_use_weapon("fists")
        self.assertTrue(can_use)
        
        # Test weapon requiring ammo
        can_use, reason = self.combat_system.can_use_weapon("pistol")
        self.assertFalse(can_use)
        self.assertIn("bullets", reason)
        
        # Add ammo and test again
        self.combat_system.ammunition["bullets"] = 10
        can_use, reason = self.combat_system.can_use_weapon("pistol")
        self.assertTrue(can_use)


class TestLocationData(unittest.TestCase):
    """Test location data functions."""
    
    def test_get_default_locations(self):
        """Test getting default location data."""
        locations = get_default_locations()
        
        self.assertIsInstance(locations, list)
        self.assertGreater(len(locations), 0)
        
        # Check first location structure
        location = locations[0]
        self.assertIn("name", location)
        self.assertIn("description", location)
        self.assertIn("actions", location)
    
    @patch('Functions.read_location_data.os.path.exists')
    def test_read_location_data_file_not_found(self, mock_exists):
        """Test reading location data when file doesn't exist."""
        mock_exists.return_value = False
        
        with patch('builtins.print') as mock_print:
            locations = read_location_data()
            mock_print.assert_called()
            
        self.assertIsInstance(locations, list)
        self.assertGreater(len(locations), 0)
    
    def test_read_location_data_with_valid_file(self):
        """Test reading location data from a valid file."""
        # Create temporary JSON file
        test_data = [
            {
                "name": "Test Location",
                "description": "A test location",
                "actions": [{"name": "Test Action", "description": "A test action"}]
            }
        ]
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(test_data, f)
            temp_filename = f.name
        
        try:
            with patch('Functions.read_location_data.os.path.exists') as mock_exists:
                mock_exists.return_value = True
                with patch('builtins.open', unittest.mock.mock_open(read_data=json.dumps(test_data))):
                    locations = read_location_data()
                    
            self.assertEqual(len(locations), 1)
            self.assertEqual(locations[0]["name"], "Test Location")
            
        finally:
            if os.path.exists(temp_filename):
                os.unlink(temp_filename)


class TestInventoryFunctions(unittest.TestCase):
    """Test inventory-related functions."""
    
    def test_check_inventory_empty(self):
        """Test checking empty inventory."""
        result = check_inventory([])
        self.assertIn("empty", result.lower())
    
    def test_check_inventory_with_items(self):
        """Test checking inventory with items."""
        items = ["water bottle", "hunting knife", "first aid kit"]
        result = check_inventory(items)
        
        self.assertIn("INVENTORY", result)
        for item in items:
            self.assertIn(item, result)
    
    def test_get_item_info(self):
        """Test getting item information."""
        info = get_item_info("water bottle")
        self.assertIn("thirst", info.lower())
        
        info = get_item_info("hunting knife")
        self.assertIn("damage", info.lower())
        
        # Test unknown item
        info = get_item_info("unknown item")
        self.assertEqual(info, "")


if __name__ == '__main__':
    # Run tests
    unittest.main(verbosity=2)
