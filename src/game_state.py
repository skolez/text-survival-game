"""
Game State Management System for Text Adventure Game

This module handles all game state including player stats, inventory, location,
and game progression.
"""

import json
import os
from datetime import datetime
from typing import Any, Dict, List, Optional


class GameState:
    """Manages the complete game state including player data and world state."""
    
    def __init__(self):
        """Initialize a new game state with default values."""
        # Player stats
        self.health = 100
        self.hunger = 100
        self.thirst = 100
        self.fatigue = 0
        self.fuel = 100
        
        # Player inventory
        self.inventory = ['can of motor oil']
        self.max_inventory_weight = 50
        self.current_weight = 2  # motor oil weight
        
        # Location and world state
        self.current_location = "Abandoned Gas Station"
        self.visited_locations = set()
        self.discovered_items = set()
        self.discovered_locations = set()  # For hidden locations that have been unlocked
        
        # Game progression
        self.game_intro_shown = False
        self.story_flags = {}
        self.turn_count = 0
        self.game_start_time = datetime.now()
        
        # Combat and survival
        self.weapons = []
        self.armor = []
        self.zombie_kills = 0
        self.days_survived = 0

        # Progression system
        self.survivor_rank = "Rookie"
        self.experience_points = 0
        self.skill_points = 0
        self.skills = {
            "combat": 0,
            "scavenging": 0,
            "crafting": 0,
            "survival": 0
        }

        # Dynamic events system
        self.active_events = []
        self.completed_events = set()
        self.event_cooldown = 0

        # Vehicle system
        self.current_vehicle = None
        self.vehicle_condition = 0  # 0-100, 0 means broken
        self.vehicle_parts_collected = []
        self.vehicle_parts_installed = {}  # Track parts installed per location
        self.towns_visited = ["Riverside"]  # Starting town
        
    def add_item(self, item: str, weight: float = 1.0) -> bool:
        """
        Add an item to inventory if there's space.
        
        Args:
            item: Name of the item to add
            weight: Weight of the item
            
        Returns:
            True if item was added, False if inventory is full
        """
        if self.current_weight + weight <= self.max_inventory_weight:
            self.inventory.append(item)
            self.current_weight += weight
            return True
        return False
    
    def remove_item(self, item: str, weight: float = 1.0) -> bool:
        """
        Remove an item from inventory.
        
        Args:
            item: Name of the item to remove
            weight: Weight of the item
            
        Returns:
            True if item was removed, False if item not found
        """
        if item in self.inventory:
            self.inventory.remove(item)
            self.current_weight = max(0, self.current_weight - weight)
            return True
        return False
    
    def has_item(self, item: str) -> bool:
        """Check if player has a specific item."""
        return item in self.inventory
    
    def use_item(self, item: str) -> Dict[str, Any]:
        """
        Use an item and apply its effects.
        
        Args:
            item: Name of the item to use
            
        Returns:
            Dictionary with result information
        """
        if not self.has_item(item):
            return {"success": False, "message": f"You don't have {item}"}
        
        # Define item effects
        item_effects = {
            "water bottle": {"thirst": 30, "weight": 0.5, "consumable": True},
            "food rations": {"hunger": 40, "weight": 1.0, "consumable": True},
            "first aid kit": {"health": 25, "weight": 2.0, "consumable": True},
            "energy drink": {"fatigue": -20, "weight": 0.3, "consumable": True},
        }
        
        if item not in item_effects:
            return {"success": False, "message": f"You can't use {item}"}
        
        effects = item_effects[item]
        result_messages = []
        
        # Apply effects
        if "health" in effects:
            old_health = self.health
            self.health = min(100, self.health + effects["health"])
            if self.health > old_health:
                result_messages.append(f"Health restored by {self.health - old_health}")
        
        if "hunger" in effects:
            old_hunger = self.hunger
            self.hunger = min(100, self.hunger + effects["hunger"])
            if self.hunger > old_hunger:
                result_messages.append(f"Hunger reduced by {self.hunger - old_hunger}")
        
        if "thirst" in effects:
            old_thirst = self.thirst
            self.thirst = min(100, self.thirst + effects["thirst"])
            if self.thirst > old_thirst:
                result_messages.append(f"Thirst reduced by {self.thirst - old_thirst}")
        
        if "fatigue" in effects:
            old_fatigue = self.fatigue
            self.fatigue = max(0, self.fatigue + effects["fatigue"])
            if self.fatigue < old_fatigue:
                result_messages.append(f"Fatigue reduced by {old_fatigue - self.fatigue}")
        
        # Remove item if consumable
        if effects.get("consumable", False):
            self.remove_item(item, effects.get("weight", 1.0))
            result_messages.append(f"Used {item}")
        
        return {
            "success": True,
            "message": ". ".join(result_messages)
        }
    
    def move_to_location(self, location: str) -> bool:
        """
        Move player to a new location.
        
        Args:
            location: Name of the location to move to
            
        Returns:
            True if move was successful
        """
        self.visited_locations.add(self.current_location)
        self.current_location = location
        self.turn_count += 1
        return True
    
    def update_survival_stats(self, turns_passed: int = 1):
        """Update hunger, thirst, and fatigue based on time passed."""
        # More balanced stat degradation
        self.hunger = max(0, self.hunger - (turns_passed * 1.5))  # Reduced from 2
        self.thirst = max(0, self.thirst - (turns_passed * 2.5))  # Reduced from 3
        self.fatigue = min(100, self.fatigue + (turns_passed * 0.7))  # Reduced from 1

        # Health effects from low stats
        if self.hunger <= 20:
            self.health = max(0, self.health - 1)
        if self.thirst <= 10:
            self.health = max(0, self.health - 2)
        if self.fatigue >= 85:  # Increased threshold
            self.health = max(0, self.health - 1)
    
    def get_status_summary(self) -> str:
        """Get a formatted summary of player status."""
        status_lines = [
            f"Health: {self.health}/100",
            f"Hunger: {self.hunger}/100",
            f"Thirst: {self.thirst}/100",
            f"Fatigue: {self.fatigue}/100",
            f"Fuel: {self.fuel}/100",
            f"Inventory: {len(self.inventory)} items ({self.current_weight:.1f}/{self.max_inventory_weight} kg)",
            f"Location: {self.current_location}",
            f"Days Survived: {self.days_survived}",
            f"Zombie Kills: {self.zombie_kills}",
            "",
            f"🏆 Survivor Rank: {self.survivor_rank}",
            f"⭐ Experience Points: {self.experience_points}",
            f"🎯 Available Skill Points: {self.skill_points}"
        ]

        # Add skills if any are developed
        if any(skill > 0 for skill in self.skills.values()):
            status_lines.append("")
            status_lines.append("🛠️ Skills:")
            for skill_name, skill_level in self.skills.items():
                if skill_level > 0:
                    level = skill_level // 5
                    progress = skill_level % 5
                    status_lines.append(f"  {skill_name.title()}: Level {level} ({progress}/5)")

        # Add active events if any
        if self.active_events:
            status_lines.append("")
            status_lines.append("🎲 Active Events:")
            for event in self.active_events:
                expires = event.get('expires_in', 'Unknown')
                status_lines.append(f"  {event['title']} (Expires in {expires} days)")

        return "\n".join(status_lines)
    
    def is_game_over(self) -> tuple[bool, str]:
        """
        Check if game over conditions are met.

        Returns:
            Tuple of (is_game_over, reason)
        """
        if self.health <= 0:
            return True, "You died from your injuries."
        if self.hunger <= 0 and self.thirst <= 0:
            return True, "You died from starvation and dehydration."
        if self.hunger <= 0:
            return True, "You died from starvation."
        if self.thirst <= 0:
            return True, "You died from dehydration."

        return False, ""

    def check_fatigue_collapse(self) -> dict:
        """
        Check if player collapses from exhaustion and handle the consequences.

        Returns:
            Dictionary with collapse information and results
        """
        if self.fatigue < 95:
            return {"collapsed": False}

        import random

        # Player collapses from exhaustion
        print("\n💀 EXHAUSTION COLLAPSE! 💀")
        print("You can no longer stay awake and collapse where you are...")
        print("Your vision fades as exhaustion overwhelms you...")

        # Time passes while unconscious (2-4 hours)
        unconscious_time = random.randint(2, 4)
        self.update_survival_stats(unconscious_time)

        # Reduce fatigue significantly from the forced rest
        fatigue_recovery = random.randint(40, 60)
        self.fatigue = max(0, self.fatigue - fatigue_recovery)

        # Determine what happens while unconscious
        location_data = None
        # Try to get current location data (this will be passed from game engine)

        # Base danger chance - higher in dangerous areas
        danger_chance = 0.6  # 60% base chance of danger

        # Check if we're in a relatively safe location
        if hasattr(self, '_current_location_data'):
            location_data = self._current_location_data
            if location_data.get("secure_location", False):
                danger_chance = 0.1  # Very safe
            elif location_data.get("shelter", False):
                danger_chance = 0.3  # Somewhat safe
            elif location_data.get("zombie_chance", 0.2) < 0.2:
                danger_chance = 0.4  # Less dangerous area

        collapse_result = {
            "collapsed": True,
            "unconscious_time": unconscious_time,
            "fatigue_recovered": fatigue_recovery,
            "survived": True,
            "message": ""
        }

        if random.random() < danger_chance:
            # Something bad happened while unconscious
            event_roll = random.random()

            if event_roll < 0.4:  # 40% chance of zombie encounter
                # Zombie found you but you got lucky
                damage = random.randint(10, 25)
                self.health = max(1, self.health - damage)  # Always survive with at least 1 HP

                collapse_result["message"] = (
                    f"🧟 While unconscious, a zombie found you and attacked! "
                    f"You wake up injured (-{damage} health) but managed to crawl away to safety. "
                    f"You're lucky to be alive!"
                )

            elif event_roll < 0.7:  # 30% chance of being robbed/losing items
                if len(self.inventory) > 1:  # Don't take the last item
                    lost_item = random.choice([item for item in self.inventory if item != "can of motor oil"])
                    self.remove_item(lost_item, self.get_item_weight(lost_item))
                    collapse_result["message"] = (
                        f"🎒 While unconscious, scavengers found you and took your {lost_item}. "
                        f"At least they left you alive..."
                    )
                else:
                    collapse_result["message"] = (
                        "🎒 While unconscious, scavengers found you but you had nothing worth taking. "
                        "You wake up unharmed but shaken."
                    )

            else:  # 30% chance of environmental damage
                damage = random.randint(5, 15)
                self.health = max(1, self.health - damage)
                collapse_result["message"] = (
                    f"🌡️ You collapsed in a dangerous spot and suffered from exposure. "
                    f"You wake up with injuries (-{damage} health) but you're alive."
                )
        else:
            # Got lucky - nothing bad happened
            lucky_events = [
                "🍀 Miraculously, nothing disturbed your rest. You wake up feeling somewhat recovered.",
                "🍀 You collapsed in a hidden spot and slept safely. You're lucky no one found you.",
                "🍀 A kind stranger found you and moved you to safety before leaving. You wake up unharmed.",
                "🍀 You managed to crawl into cover before fully collapsing. You wake up safe but sore."
            ]
            collapse_result["message"] = random.choice(lucky_events)

        print(f"\n⏰ You were unconscious for {unconscious_time} hours.")
        print(f"😴 Fatigue reduced by {fatigue_recovery} points.")
        print(f"\n{collapse_result['message']}")

        return collapse_result

    def get_item_weight(self, item: str) -> float:
        """Get the weight of an item."""
        # Basic weight system - can be expanded
        weights = {
            "can of motor oil": 2.0,
            "water bottle": 1.0,
            "food rations": 1.5,
            "first aid kit": 2.0,
            "rusty church key": 0.1,
            "holy water": 0.5,
            "candles": 0.3,
            "old bible": 1.0,
            "flowers": 0.1
        }
        return weights.get(item, 1.0)  # Default weight

    def gain_experience(self, amount: int, skill_type: str = None):
        """Gain experience points and potentially level up skills."""
        self.experience_points += amount

        # Gain skill points based on experience
        if self.experience_points >= (self.skill_points + 1) * 100:
            self.skill_points += 1
            print(f"\n⭐ You gained a skill point! Total: {self.skill_points}")

        # Gain skill-specific experience
        if skill_type and skill_type in self.skills:
            self.skills[skill_type] += 1
            if self.skills[skill_type] % 5 == 0:  # Level up every 5 points
                print(f"\n🎯 Your {skill_type} skill improved! Level: {self.skills[skill_type] // 5}")

        # Update survivor rank
        self.update_survivor_rank()

    def update_survivor_rank(self):
        """Update survivor rank based on experience and achievements."""
        old_rank = self.survivor_rank

        if self.experience_points >= 1000 and self.days_survived >= 15:
            self.survivor_rank = "Legend"
        elif self.experience_points >= 500 and self.days_survived >= 10:
            self.survivor_rank = "Veteran"
        elif self.experience_points >= 200 and self.days_survived >= 5:
            self.survivor_rank = "Survivor"
        elif self.experience_points >= 50 and self.days_survived >= 2:
            self.survivor_rank = "Scavenger"
        else:
            self.survivor_rank = "Rookie"

        if old_rank != self.survivor_rank:
            print(f"\n🏆 RANK UP! You are now a {self.survivor_rank}!")

    def add_event(self, event_data: dict):
        """Add a dynamic event to the active events list."""
        self.active_events.append(event_data)

    def remove_event(self, event_id: str):
        """Remove an event from active events."""
        self.active_events = [e for e in self.active_events if e.get("id") != event_id]
        self.completed_events.add(event_id)

    def save_to_file(self, filename: str) -> bool:
        """
        Save game state to a JSON file.
        
        Args:
            filename: Path to save file
            
        Returns:
            True if save was successful
        """
        try:
            save_data = {
                "health": self.health,
                "hunger": self.hunger,
                "thirst": self.thirst,
                "fatigue": self.fatigue,
                "fuel": self.fuel,
                "inventory": self.inventory,
                "current_weight": self.current_weight,
                "current_location": self.current_location,
                "visited_locations": list(self.visited_locations),
                "discovered_items": list(self.discovered_items),
                "discovered_locations": list(self.discovered_locations),
                "game_intro_shown": self.game_intro_shown,
                "story_flags": self.story_flags,
                "turn_count": self.turn_count,
                "weapons": self.weapons,
                "armor": self.armor,
                "zombie_kills": self.zombie_kills,
                "days_survived": self.days_survived,
                "current_vehicle": self.current_vehicle,
                "vehicle_condition": self.vehicle_condition,
                "vehicle_parts_collected": self.vehicle_parts_collected,
                "vehicle_parts_installed": self.vehicle_parts_installed,
                "towns_visited": self.towns_visited,
                "survivor_rank": self.survivor_rank,
                "experience_points": self.experience_points,
                "skill_points": self.skill_points,
                "skills": self.skills,
                "active_events": self.active_events,
                "completed_events": list(self.completed_events),
                "event_cooldown": self.event_cooldown,
                "save_time": datetime.now().isoformat()
            }
            
            with open(filename, 'w') as f:
                json.dump(save_data, f, indent=2)
            return True
        except Exception as e:
            print(f"Error saving game: {e}")
            return False
    
    def load_from_file(self, filename: str) -> bool:
        """
        Load game state from a JSON file.
        
        Args:
            filename: Path to save file
            
        Returns:
            True if load was successful
        """
        try:
            if not os.path.exists(filename):
                return False
            
            with open(filename, 'r') as f:
                save_data = json.load(f)
            
            # Restore all saved data
            self.health = save_data.get("health", 100)
            self.hunger = save_data.get("hunger", 100)
            self.thirst = save_data.get("thirst", 100)
            self.fatigue = save_data.get("fatigue", 0)
            self.fuel = save_data.get("fuel", 100)
            self.inventory = save_data.get("inventory", [])
            self.current_weight = save_data.get("current_weight", 0)
            self.current_location = save_data.get("current_location", "Abandoned Gas Station")
            self.visited_locations = set(save_data.get("visited_locations", []))
            self.discovered_items = set(save_data.get("discovered_items", []))
            self.discovered_locations = set(save_data.get("discovered_locations", []))
            self.game_intro_shown = save_data.get("game_intro_shown", False)
            self.story_flags = save_data.get("story_flags", {})
            self.turn_count = save_data.get("turn_count", 0)
            self.weapons = save_data.get("weapons", [])
            self.armor = save_data.get("armor", [])
            self.zombie_kills = save_data.get("zombie_kills", 0)
            self.days_survived = save_data.get("days_survived", 0)

            # Load vehicle system data
            self.current_vehicle = save_data.get("current_vehicle", None)
            self.vehicle_condition = save_data.get("vehicle_condition", 0)
            self.vehicle_parts_collected = save_data.get("vehicle_parts_collected", [])
            self.vehicle_parts_installed = save_data.get("vehicle_parts_installed", {})
            self.towns_visited = save_data.get("towns_visited", ["Riverside"])

            # Load progression system data
            self.survivor_rank = save_data.get("survivor_rank", "Rookie")
            self.experience_points = save_data.get("experience_points", 0)
            self.skill_points = save_data.get("skill_points", 0)
            self.skills = save_data.get("skills", {"combat": 0, "scavenging": 0, "crafting": 0, "survival": 0})

            # Load dynamic events data
            self.active_events = save_data.get("active_events", [])
            self.completed_events = set(save_data.get("completed_events", []))
            self.event_cooldown = save_data.get("event_cooldown", 0)

            return True
        except Exception as e:
            print(f"Error loading game: {e}")
            return False

    def repair_vehicle(self, parts_used: list, location: str) -> dict:
        """
        Attempt to repair a vehicle using collected parts.

        Args:
            parts_used: List of parts to use for repair

        Returns:
            Dict with success status and message
        """
        if not parts_used:
            return {"success": False, "message": "No parts selected for repair."}

        # Check if player has all required parts
        missing_parts = []
        for part in parts_used:
            if part not in self.inventory:
                missing_parts.append(part)

        if missing_parts:
            return {"success": False, "message": f"Missing parts: {', '.join(missing_parts)}"}

        # Calculate repair success based on parts quality
        repair_amount = 0
        parts_consumed = []

        for part in parts_used:
            if part in ["car battery", "alternator"]:
                repair_amount += 30
            elif part in ["spark plugs", "brake pads"]:
                repair_amount += 20
            elif part in ["motor oil", "transmission fluid"]:
                repair_amount += 15
            else:
                repair_amount += 10

            parts_consumed.append(part)

        # Track parts installed at this location
        if location not in self.vehicle_parts_installed:
            self.vehicle_parts_installed[location] = []

        # Remove used parts from inventory and track installation
        for part in parts_consumed:
            self.remove_item(part, 1.0)  # Assume 1kg weight for parts
            self.vehicle_parts_installed[location].append(part)

        # Set vehicle condition
        self.vehicle_condition = min(100, repair_amount)
        self.current_vehicle = f"Repaired Car ({location})"

        if self.vehicle_condition >= 60:
            return {"success": True, "message": f"Vehicle successfully repaired! Condition: {self.vehicle_condition}%\nParts installed: {', '.join(self.vehicle_parts_installed[location])}"}
        elif self.vehicle_condition >= 30:
            return {"success": True, "message": f"Vehicle partially repaired. Condition: {self.vehicle_condition}% - might break down soon.\nParts installed: {', '.join(self.vehicle_parts_installed[location])}"}
        else:
            return {"success": False, "message": f"Repair failed. Vehicle condition only {self.vehicle_condition}% - not roadworthy.\nParts installed: {', '.join(self.vehicle_parts_installed[location])}"}

    def can_travel_long_distance(self) -> bool:
        """Check if player can travel to distant locations."""
        return self.current_vehicle is not None and self.vehicle_condition >= 30

    def use_vehicle_for_travel(self) -> dict:
        """Use vehicle for long-distance travel, potentially breaking it down."""
        if not self.can_travel_long_distance():
            return {"success": False, "message": "No working vehicle available for long-distance travel."}

        # Vehicle breaks down after use
        self.current_vehicle = None
        self.vehicle_condition = 0

        return {"success": True, "message": "Vehicle has taken you to your destination but broke down permanently."}

    def get_current_town(self) -> str:
        """Get the current town based on location."""
        location_data = self.get_location_data(self.current_location)
        if location_data:
            return location_data.get("town", "Unknown")
        return "Unknown"

    def get_location_data(self, location_name: str) -> dict:
        """Get location data from the locations file."""
        try:
            from Functions.read_location_data import read_location_data
            locations = read_location_data()
            for location in locations:
                if location["name"] == location_name:
                    return location
        except Exception:
            pass
        return {}

    def show_game_over_screen(self, reason: str = ""):
        """Display the game over screen with ASCII art."""
        try:
            with open("Assets/game_over.txt", "r") as f:
                game_over_art = f.read()
            print(game_over_art)
        except FileNotFoundError:
            print("=" * 60)
            print("GAME OVER")
            print("=" * 60)

        print(f"\n{reason}")
        print(f"\n📊 FINAL STATISTICS:")
        print(f"Days Survived: {self.days_survived}")
        print(f"Zombies Killed: {self.zombie_kills}")
        print(f"Towns Visited: {', '.join(self.towns_visited)}")
        print(f"Items Collected: {len(self.discovered_items)}")

        if self.current_vehicle:
            print(f"Final Vehicle: {self.current_vehicle} ({self.vehicle_condition}%)")

        print(f"\nThank you for playing Zombie Survival Story!")

        print("\nWhat would you like to do?")
        print("[1] Start a new game")
        print("[2] Quit game")

        while True:
            try:
                choice = int(input("\nEnter your choice: "))
                if choice == 1:
                    return "restart"
                elif choice == 2:
                    return "quit"
                else:
                    print("Invalid choice! Please enter 1 or 2.")
            except ValueError:
                print("Please enter a valid number!")


# Global game state instance
game_state = GameState()
