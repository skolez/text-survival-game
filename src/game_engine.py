"""
Game Engine - Core game loop and mechanics

This module contains the main game engine that handles the game loop,
action processing, and coordinates between different game systems.
"""

import os
from datetime import datetime
from typing import Dict, Optional

from combat_system import combat_system
from Functions.clear_screen import clear_screen
from Functions.read_location_data import read_location_data
from Functions.scroll_text_file import scroll_text_file
from game_state import game_state


class GameEngine:
    """Main game engine that handles the game loop and core mechanics."""
    
    def __init__(self):
        """Initialize the game engine."""
        self.locations = read_location_data()
        self.running = True
        self.last_encounter_result = None  # Store last encounter result for display
        self.commands = {
            'help': self.show_help,
            'status': self.show_status,
            'inventory': self.show_inventory,
            'save': self.save_game,
            'load': self.load_game,
            'quit': self.quit_game,
            'exit': self.quit_game
        }
    
    def start_game(self):
        """Start the main game loop."""
        self.show_intro()
        
        while self.running:
            try:
                # Check for game over conditions
                game_over, reason = game_state.is_game_over()
                if game_over:
                    self.handle_game_over(reason)
                    break

                # Update survival stats
                game_state.update_survival_stats()

                # Check for fatigue collapse BEFORE other events
                collapse_result = game_state.check_fatigue_collapse()
                if collapse_result["collapsed"]:
                    # Player collapsed - show results and continue
                    input("\nPress Enter to continue...")
                    # Skip other events this turn since player was unconscious
                    self.display_location()
                    self.get_player_input()
                    continue

                # Check for dynamic events
                self.check_dynamic_events()

                # Check for zombie encounters
                zombie = combat_system.check_for_zombie_encounter(game_state.current_location)
                if zombie:
                    encounter_result = combat_system.run_combat_encounter(zombie)
                    self.last_encounter_result = encounter_result.get("result_message", "")

                    if encounter_result.get("player_died", False):
                        # Player died in combat - game over will be handled by main loop
                        continue
                    elif encounter_result["fled"]:
                        # Player fled, continue with reduced stats
                        game_state.fatigue = min(100, game_state.fatigue + 10)

                # Display current location and options
                self.display_location()

                # Get and process player input
                choice = self.get_player_input()
                self.process_choice(choice)
                
            except KeyboardInterrupt:
                print("\n\nGame interrupted. Goodbye!")
                break
            except Exception as e:
                print(f"An error occurred: {e}")
                print("The game will continue...")
    
    def show_intro(self):
        """Display the game introduction."""
        if not game_state.game_intro_shown:
            clear_screen()
            print("Press Enter at any time to skip the introduction...")
            print()

            try:
                scroll_text_file('Assets/opening_title.txt', 0, 0.1, allow_skip=True)
                scroll_text_file('Assets/zombie_intro.txt', 40, 0.2, 85, allow_skip=True)
            except KeyboardInterrupt:
                # If user presses Ctrl+C, skip intro
                clear_screen()
                print("Introduction skipped.")

            print()
            print("Press Enter to continue...")
            input()
            game_state.game_intro_shown = True
    
    def display_location(self):
        """Display current location information and available actions."""
        clear_screen()

        # Show encounter result at the top if there was one
        if self.last_encounter_result:
            print("=" * 60)
            print(f"  {self.last_encounter_result}")
            print("=" * 60)
            print()
            self.last_encounter_result = None  # Clear after showing

        # Show location name
        print(f"=== {game_state.current_location} ===")
        print()

        # Find current location data
        location_data = self.get_location_data(game_state.current_location)
        if not location_data:
            print("Error: Location data not found!")
            return

        # Show location description
        print(location_data["description"])
        print()
        
        # Show survival status warnings
        self.show_status_warnings()
        
        # Show available actions
        print("What do you want to do?")
        actions = location_data.get("actions", [])
        
        for i, action in enumerate(actions, 1):
            print(f"[{i}] {action['name']}")
        
        # Show global commands
        print()
        print("[0] Global Commands (status, inventory, save, load, help, quit)")
    
    def get_location_data(self, location_name: str) -> Optional[Dict]:
        """Get location data by name."""
        for location in self.locations:
            if location["name"] == location_name:
                return location
        return None
    
    def show_status_warnings(self):
        """Show warnings for low survival stats with visual indicators."""
        warnings = []

        # Health warnings
        if game_state.health <= 10:
            warnings.append("💀 You are critically injured and near death!")
        elif game_state.health <= 25:
            warnings.append("⚠️  You are badly injured!")
        elif game_state.health <= 50:
            warnings.append("🩹 You have some injuries that need attention.")

        # Hunger warnings
        if game_state.hunger <= 5:
            warnings.append("💀 You are starving to death!")
        elif game_state.hunger <= 20:
            warnings.append("🍽️  You are very hungry!")
        elif game_state.hunger <= 40:
            warnings.append("🥪 You could use some food.")

        # Thirst warnings
        if game_state.thirst <= 5:
            warnings.append("💀 You are dying of thirst!")
        elif game_state.thirst <= 20:
            warnings.append("💧 You are very thirsty!")
        elif game_state.thirst <= 40:
            warnings.append("🚰 You could use some water.")

        # Fatigue warnings
        if game_state.fatigue >= 90:
            warnings.append("😵 You are about to collapse from exhaustion!")
        elif game_state.fatigue >= 80:
            warnings.append("😴 You are exhausted!")
        elif game_state.fatigue >= 60:
            warnings.append("🥱 You are getting tired.")

        # Fuel warnings
        if game_state.fuel <= 5:
            warnings.append("⛽ Your vehicle is almost out of fuel!")
        elif game_state.fuel <= 20:
            warnings.append("⛽ Your vehicle is low on fuel!")
        elif game_state.fuel <= 40:
            warnings.append("🚗 You should look for fuel soon.")

        # Show status bar
        self.show_status_bar()

        if warnings:
            print("\n" + "="*50)
            print("⚠️  STATUS WARNINGS ⚠️")
            print("="*50)
            for warning in warnings:
                print(warning)
            print("="*50)
            print()

    def show_status_bar(self):
        """Show a visual status bar for key stats."""
        def get_bar(value: int, max_value: int = 100, length: int = 20) -> str:
            """Create a visual progress bar."""
            filled = int((value / max_value) * length)
            bar = "█" * filled + "░" * (length - filled)

            # Color coding based on value
            if value <= 20:
                return f"🔴{bar}"
            elif value <= 50:
                return f"🟡{bar}"
            else:
                return f"🟢{bar}"

        print("\n" + "="*60)
        print("📊 STATUS")
        print("="*60)
        print(f"❤️  Health:  {get_bar(game_state.health)} {game_state.health}/100")
        print(f"🍽️  Hunger:  {get_bar(game_state.hunger)} {game_state.hunger}/100")
        print(f"💧 Thirst:  {get_bar(game_state.thirst)} {game_state.thirst}/100")
        print(f"😴 Fatigue: {get_bar(100-game_state.fatigue)} {100-game_state.fatigue}/100")
        print(f"⛽ Fuel:    {get_bar(game_state.fuel)} {game_state.fuel}/100")
        print("="*60)
    
    def get_player_input(self) -> str:
        """Get and validate player input."""
        while True:
            try:
                choice = input("\nEnter your choice: ").strip().lower()
                if choice:
                    return choice
                print("Please enter a valid choice.")
            except EOFError:
                return "quit"
    
    def process_choice(self, choice: str):
        """Process the player's choice."""
        # Check if it's a number (action choice)
        try:
            action_num = int(choice)
            if action_num == 0:
                # Global commands submenu
                self.show_global_commands()
            else:
                self.handle_action(action_num)
        except ValueError:
            print(f"Invalid input: {choice}")
            print("Please enter a number. Press 0 for global commands.")
            input("Press Enter to continue...")

    def show_global_commands(self):
        """Show global commands submenu."""
        while True:
            clear_screen()
            print("=" * 50)
            print("🌍 GLOBAL COMMANDS")
            print("=" * 50)
            print()
            print("[1] Show detailed character status")
            print("[2] Show inventory and use items")
            print("[3] Save your current game")
            print("[4] Load a previously saved game")
            print("[5] Show help screen")
            print("[6] Quit game")
            print("[0] Back to game")

            try:
                choice = int(input("\nEnter your choice: ").strip())

                if choice == 0:
                    break
                elif choice == 1:
                    self.show_status()
                elif choice == 2:
                    self.show_inventory()
                elif choice == 3:
                    self.save_game()
                elif choice == 4:
                    self.load_game()
                elif choice == 5:
                    self.show_help()
                elif choice == 6:
                    self.running = False
                    break
                else:
                    print("Invalid choice! Please enter a number 0-6.")
                    input("Press Enter to continue...")
            except ValueError:
                print("Invalid input! Please enter a number.")
                input("Press Enter to continue...")

    def handle_action(self, action_num: int):
        """Handle numbered action choices."""
        location_data = self.get_location_data(game_state.current_location)
        if not location_data:
            return
        
        actions = location_data.get("actions", [])
        if 1 <= action_num <= len(actions):
            action = actions[action_num - 1]
            self.execute_action(action)
        else:
            print("Invalid action number!")
            input("Press Enter to continue...")
    
    def execute_action(self, action: Dict):
        """Execute a specific action."""
        action_name = action["name"].lower()

        if "look around" in action_name:
            self.handle_look_around()
        elif "move" in action_name or "go" in action_name:
            if "nearby" in action_name:
                self.handle_move_short()
            elif "distant" in action_name:
                self.handle_move_long()
            else:
                self.handle_move_short()  # Default to short distance
        elif "repair" in action_name and "vehicle" in action_name:
            self.handle_repair_vehicle()
        elif "travel" in action_name and "distant" in action_name:
            self.handle_move_long()
        elif "check your inventory" in action_name or action_name == "inventory":
            self.show_inventory()
        elif ("search" in action_name or "check" in action_name or
              "explore" in action_name or "examine" in action_name):
            self.handle_search(action)
        elif "use" in action_name:
            self.handle_use_item()
        elif "buy" in action_name or "purchase" in action_name:
            self.handle_buy_gear()
        elif "rest" in action_name or "sleep" in action_name:
            self.handle_rest()
        elif "fuel" in action_name:
            self.handle_refuel()
        elif "climb" in action_name and "bell tower" in action_name:
            self.handle_climb_bell_tower()
        elif "descend" in action_name and "cemetery" in action_name:
            self.handle_descend_to_cemetery()
        else:
            print(f"Action '{action['name']}' is not yet implemented.")
            input("Press Enter to continue...")
    
    def handle_look_around(self):
        """Handle looking around the current location."""
        from Functions.look_around import look_around
        result = look_around(game_state.current_location, game_state.inventory)
        print(result)
        input("Press Enter to continue...")
    
    def handle_move_short(self):
        """Handle player movement to nearby locations (walking distance)."""
        location_data = self.get_location_data(game_state.current_location)
        if not location_data:
            print("Error: Could not load location data.")
            input("Press Enter to continue...")
            return

        nearby_locations = location_data.get("nearby_short", []).copy()

        # Add discovered hidden locations that are accessible from current location
        current_town = location_data.get("town", "")
        for location in self.locations:
            if (location.get("hidden", False) and
                location["name"] in game_state.discovered_locations and
                location.get("town", "") == current_town and
                location["name"] not in nearby_locations):
                nearby_locations.append(location["name"])

        # Also check if current location has a direct hidden_location connection
        hidden_location = location_data.get("hidden_location")
        if (hidden_location and
            hidden_location in game_state.discovered_locations and
            hidden_location not in nearby_locations):
            nearby_locations.append(hidden_location)

        if not nearby_locations:
            print("There are no nearby locations you can walk to from here.")
            input("Press Enter to continue...")
            return

        print("\n" + "="*50)
        print("🚶 NEARBY LOCATIONS (Walking Distance)")
        print("="*50)
        print("Where would you like to go?")

        for i, location in enumerate(nearby_locations, 1):
            # Mark discovered hidden locations
            if location in game_state.discovered_locations:
                location_obj = self.get_location_data(location)
                if location_obj and location_obj.get("hidden", False):
                    print(f"[{i}] {location} 🗝️")
                else:
                    print(f"[{i}] {location}")
            else:
                print(f"[{i}] {location}")

        print("[0] Cancel")

        try:
            choice = int(input("\nEnter your choice: ").strip())

            if choice == 0:
                return
            elif 1 <= choice <= len(nearby_locations):
                new_location = nearby_locations[choice - 1]
                print(f"\nTraveling to {new_location}...")
                game_state.move_to_location(new_location)
                print("You have arrived!")
            else:
                print("Invalid choice!")
        except ValueError:
            print("Please enter a valid number!")

        input("Press Enter to continue...")

    def handle_move_long(self):
        """Handle player movement to distant locations (requires vehicle)."""
        if not game_state.can_travel_long_distance():
            print("\n" + "="*50)
            print("🚗 LONG-DISTANCE TRAVEL")
            print("="*50)
            print("You need a working vehicle to travel to distant locations.")
            print("Find and repair a vehicle first!")
            input("Press Enter to continue...")
            return

        location_data = self.get_location_data(game_state.current_location)
        if not location_data:
            print("Error: Could not load location data.")
            input("Press Enter to continue...")
            return

        distant_locations = location_data.get("nearby_long", [])
        if not distant_locations:
            print("There are no distant locations you can travel to from here.")
            input("Press Enter to continue...")
            return

        print("\n" + "="*50)
        print("🚗 DISTANT LOCATIONS (Vehicle Required)")
        print("="*50)
        print(f"Current vehicle: {game_state.current_vehicle} ({game_state.vehicle_condition}%)")
        print("⚠️  WARNING: Your vehicle will break down permanently after this trip!")
        print()
        print("Where would you like to go?")

        for i, location in enumerate(distant_locations, 1):
            print(f"[{i}] {location}")

        print("[0] Cancel")

        try:
            choice = int(input("\nEnter your choice: ").strip())

            if choice == 0:
                return
            elif 1 <= choice <= len(distant_locations):
                new_location = distant_locations[choice - 1]

                # Confirm the trip
                print(f"\nTravel to {new_location}?")
                print("This will permanently break down your vehicle!")
                confirm = input("Are you sure? (y/n): ").strip().lower()

                if confirm in ['y', 'yes']:
                    print(f"\nTraveling to {new_location}...")

                    # Use vehicle and break it down
                    result = game_state.use_vehicle_for_travel()
                    print(result["message"])

                    # Move to new location
                    game_state.move_to_location(new_location)

                    # Add new town to visited list
                    new_town = game_state.get_current_town()
                    if new_town not in game_state.towns_visited:
                        game_state.towns_visited.append(new_town)
                        print(f"\nWelcome to {new_town}! This is a new area to explore.")

                    print("You have arrived!")
                else:
                    print("Travel cancelled.")
            else:
                print("Invalid choice!")
        except ValueError:
            print("Please enter a valid number!")

        input("Press Enter to continue...")

    def handle_repair_vehicle(self):
        """Handle vehicle repair using collected parts."""
        location_data = self.get_location_data(game_state.current_location)
        if not location_data:
            print("Error: Could not load location data.")
            input("Press Enter to continue...")
            return

        # Check if this location has a repairable vehicle
        if not location_data.get("has_repairable_vehicle", False):
            print("No vehicle to repair at this location.")
            input("Press Enter to continue...")
            return

        parts_needed = location_data.get("parts_needed", [])
        current_location = game_state.current_location

        # Show parts already installed at this location
        installed_parts = game_state.vehicle_parts_installed.get(current_location, [])

        print("\n" + "="*50)
        print("🔧 VEHICLE REPAIR")
        print("="*50)

        if installed_parts:
            print(f"Parts already installed on this vehicle:")
            for part in installed_parts:
                print(f"  ✅ {part}")
            print()

        print("Parts needed for vehicle repair:")
        for part in parts_needed:
            if part in installed_parts:
                print(f"  ✅ {part} (already installed)")
            elif part in game_state.inventory:
                print(f"  🔧 {part} (ready to install)")
            else:
                print(f"  ❌ {part} (need to find)")

        # Show available parts in inventory that aren't already installed
        available_parts = [part for part in parts_needed
                          if part in game_state.inventory and part not in installed_parts]

        if not available_parts:
            if len(installed_parts) == len(parts_needed):
                print("\nVehicle is fully repaired!")
                print(f"Vehicle condition: {game_state.vehicle_condition}%")
            else:
                print("\nYou don't have any new parts to install.")
            input("Press Enter to continue...")
            return

        print(f"\nYou have {len(available_parts)} new parts to install.")
        print("Available parts to install:")
        for i, part in enumerate(available_parts, 1):
            print(f"  [{i}] {part}")

        print("\nSelect parts to use for repair (enter numbers separated by spaces):")
        print("Example: 1 3 5")
        print("[0] Cancel")

        try:
            choice = input("Enter your choice: ").strip()

            if choice == "0":
                return

            # Parse selected parts
            selected_indices = [int(x) - 1 for x in choice.split()]
            selected_parts = [available_parts[i] for i in selected_indices if 0 <= i < len(available_parts)]

            if selected_parts:
                result = game_state.repair_vehicle(selected_parts, current_location)
                print(f"\n{result['message']}")
            else:
                print("No valid parts selected.")

        except (ValueError, IndexError):
            print("Invalid input! Please enter numbers separated by spaces.")

        input("Press Enter to continue...")

    def handle_search(self, action: Dict = None):
        """Handle searching for items with location-specific details."""
        import random

        location_data = self.get_location_data(game_state.current_location)
        if not location_data:
            print("Error: Could not load location data.")
            input("Press Enter to continue...")
            return

        # Get action-specific search details
        action_name = action["name"].lower() if action else "general search"
        location_name = game_state.current_location.lower()

        print(f"\n🔍 {action['name'] if action else 'Searching the area'}...")
        print("="*50)

        # Location-specific search results with rich descriptions
        search_results = self.get_search_results(location_name, action_name)

        if search_results["description"]:
            print(search_results["description"])

        # Random chance of finding something
        success_chance = search_results.get("success_chance", 0.6)
        if random.random() < success_chance:
            possible_items = search_results.get("items", location_data.get("items", []))
            if possible_items:
                found_item = random.choice(possible_items)
                weight = self.get_item_weight(found_item)

                if game_state.add_item(found_item, weight):
                    print(f"\n✅ You found: {found_item}")
                    if search_results.get("item_description"):
                        print(f"   {search_results['item_description']}")
                    game_state.discovered_items.add(found_item)

                    # Check if this item unlocks a hidden location
                    self.check_for_hidden_location_unlock(found_item)

                    # Gain scavenging experience
                    game_state.gain_experience(5, "scavenging")
                else:
                    print(f"\n❌ You found {found_item}, but your inventory is full!")
                    # Still gain some experience for finding something
                    game_state.gain_experience(2, "scavenging")
            else:
                nothing_msg = search_results.get('nothing_found', 'You search around but don\'t find anything useful.')
                print(f"\n{nothing_msg}")
        else:
            failure_msg = search_results.get('failure_message', 'You search the area but come up empty-handed.')
            print(f"\n{failure_msg}")

        # Check for zombie encounters during search
        if random.random() < location_data.get("zombie_chance", 0.2):
            print("\n⚠️  You hear shuffling sounds nearby... better be careful!")

        input("Press Enter to continue...")

    def check_for_hidden_location_unlock(self, item: str):
        """Check if finding an item unlocks a hidden location."""
        # Check all locations for hidden ones that require this item
        for location in self.locations:
            if (location.get("hidden", False) and
                location.get("requires_item") == item and
                location["name"] not in game_state.discovered_locations):

                # Unlock the hidden location
                game_state.discovered_locations.add(location["name"])
                print(f"\n🗝️ DISCOVERY! The {item} unlocks access to: {location['name']}")
                print("This location is now available for travel!")

                # Add to nearby locations of the current area
                current_town = self.get_location_data(game_state.current_location).get("town")
                if location.get("town") == current_town:
                    print(f"You can now access this location from nearby areas in {current_town}.")

    def check_dynamic_events(self):
        """Check and trigger dynamic events based on game state."""
        import random

        # Reduce event cooldown
        if game_state.event_cooldown > 0:
            game_state.event_cooldown -= 1

        # Don't trigger new events if cooldown is active or if there are already active events
        if game_state.event_cooldown > 0 or len(game_state.active_events) >= 2:
            return

        # Progressive difficulty based on days survived
        event_chance = 0.1 + (game_state.days_survived * 0.02)  # Increases over time

        if random.random() < event_chance:
            self.trigger_random_event()

    def trigger_random_event(self):
        """Trigger a random dynamic event."""
        import random

        # Define possible events based on progression
        events = []

        # Early game events (Days 1-3)
        if game_state.days_survived <= 3:
            events.extend([
                {
                    "id": "supply_cache_1",
                    "type": "supply_drop",
                    "title": "📻 Radio Broadcast",
                    "description": "You hear a faint radio transmission mentioning a supply cache hidden in the cemetery.",
                    "location": "Riverside Cemetery",
                    "reward": ["first aid kit", "canned food", "water bottle"],
                    "expires_in": 3,
                    "difficulty": "easy"
                },
                {
                    "id": "survivor_tip_1",
                    "type": "information",
                    "title": "🗣️ Survivor's Note",
                    "description": "You find a hastily scrawled note: 'The church bell tower is safe - key hidden in cemetery'",
                    "hint": "rusty church key",
                    "expires_in": 5,
                    "difficulty": "easy"
                }
            ])

        # Mid game events (Days 4-7)
        if 4 <= game_state.days_survived <= 7:
            events.extend([
                {
                    "id": "horde_warning",
                    "type": "warning",
                    "title": "⚠️ Horde Movement",
                    "description": "You notice increased zombie activity. A large group seems to be moving through town.",
                    "effect": "increased_zombie_chance",
                    "duration": 2,
                    "difficulty": "medium"
                },
                {
                    "id": "weather_storm",
                    "type": "weather",
                    "title": "🌧️ Storm Approaching",
                    "description": "Dark clouds gather. Heavy rain will make travel dangerous but provide fresh water.",
                    "effect": "travel_penalty",
                    "benefit": "water_bonus",
                    "duration": 1,
                    "difficulty": "medium"
                }
            ])

        # Late game events (Days 8+)
        if game_state.days_survived >= 8:
            events.extend([
                {
                    "id": "military_supply",
                    "type": "rare_supply",
                    "title": "🚁 Military Supply Drop",
                    "description": "You spot a military helicopter dropping supplies in the distance.",
                    "location": "Riverside Town Square",
                    "reward": ["tactical vest", "military rations", "ammunition"],
                    "expires_in": 2,
                    "difficulty": "hard"
                }
            ])

        # Filter out completed events
        available_events = [e for e in events if e["id"] not in game_state.completed_events]

        if available_events:
            event = random.choice(available_events)
            game_state.add_event(event)
            game_state.event_cooldown = random.randint(2, 4)  # Cooldown between events

            print(f"\n🎲 DYNAMIC EVENT: {event['title']}")
            print("=" * 50)
            print(event['description'])
            print("=" * 50)
            input("Press Enter to continue...")

    def get_search_results(self, location_name: str, action_name: str) -> dict:
        """Get detailed search results based on location and specific action."""

        # Riverside locations
        if "gas station" in location_name:
            if "fuel" in action_name:
                return {
                    "description": "You check the fuel pumps and storage tanks. Most are empty, but you might find some residual fuel.",
                    "items": ["motor oil", "diesel fuel", "gas can"],
                    "success_chance": 0.4,
                    "nothing_found": "The fuel systems are completely drained.",
                    "item_description": "This could be useful for vehicles or generators."
                }
            elif "car" in action_name or "vehicle" in action_name:
                return {
                    "description": "You search through the abandoned vehicles in the parking lot. Keys dangle from ignitions, doors hang open.",
                    "items": ["car battery", "spark plugs", "motor oil", "jumper cables", "road map", "sunglasses", "phone charger", "tire iron"],
                    "success_chance": 0.8,
                    "nothing_found": "The cars have been thoroughly picked over already.",
                    "item_description": "Vehicle parts and supplies left behind in the chaos of evacuation."
                }
            else:
                return {
                    "description": "You search the convenience store area. Shelves are mostly empty, but there might be something in the back areas.",
                    "items": ["energy drink", "flashlight", "batteries", "snack bar", "lighter", "crowbar"],
                    "success_chance": 0.6
                }

        elif "sporting goods" in location_name:
            if "weapon" in action_name:
                return {
                    "description": "You search the weapons section. Display cases are smashed, but some items might remain in the storage areas.",
                    "items": ["hunting knife", "baseball bat", "crossbow bolts", "gun cleaning kit"],
                    "success_chance": 0.5,
                    "nothing_found": "The weapon displays have been completely cleaned out.",
                    "item_description": "Could be useful for protection or hunting."
                }
            elif "camping" in action_name or "gear" in action_name:
                return {
                    "description": "You explore the camping and outdoor gear section. Tents are scattered, but useful equipment remains.",
                    "items": ["sleeping bag", "camping backpack", "compass", "rope", "water purification tablets"],
                    "success_chance": 0.8,
                    "item_description": "Essential survival gear for the outdoors."
                }
            elif "storage" in action_name:
                return {
                    "description": "You check the employee storage room behind the counter. Boxes of inventory are stacked high.",
                    "items": ["binoculars", "multi-tool", "emergency whistle", "camping stove", "fishing line"],
                    "success_chance": 0.7,
                    "item_description": "New inventory that never made it to the shelves."
                }

        elif "supermarket" in location_name:
            if "pharmacy" in action_name:
                return {
                    "description": "You search the pharmacy section. Most prescription drugs are gone, but over-the-counter items remain.",
                    "items": ["painkillers", "bandages", "antiseptic", "vitamins", "thermometer"],
                    "success_chance": 0.6,
                    "item_description": "Medical supplies that could save your life."
                }
            elif "storage" in action_name:
                return {
                    "description": "You explore the employee storage areas and loading dock. Pallets of goods sit unopened.",
                    "items": ["canned food", "bottled water", "energy bars", "toilet paper", "soap"],
                    "success_chance": 0.8,
                    "item_description": "Supplies that were being restocked when everything went wrong."
                }
            elif "food" in action_name:
                return {
                    "description": "You search the food aisles. Most perishables are spoiled, but canned and packaged goods remain.",
                    "items": ["canned food", "energy bar", "crackers", "peanut butter", "instant coffee"],
                    "success_chance": 0.7,
                    "item_description": "Non-perishable food that's still good to eat."
                }

        # Cemetery locations
        elif "cemetery" in location_name:
            if "church" in action_name:
                return {
                    "description": "You search the old church building. Dust motes dance in the colored light from stained glass windows.",
                    "items": ["rusty church key", "holy water", "candles", "old bible"],
                    "success_chance": 0.7,
                    "nothing_found": "The church has been thoroughly searched already.",
                    "item_description": "Religious artifacts and keys left behind by the congregation."
                }
            elif "mausoleum" in action_name:
                return {
                    "description": "You investigate the stone mausoleums. Heavy doors creak open to reveal dark chambers.",
                    "items": ["rusty church key", "flowers", "jewelry", "coins"],
                    "success_chance": 0.6,
                    "nothing_found": "The burial chambers contain only dust and memories.",
                    "item_description": "Items left by mourners and caretakers."
                }
            else:
                return {
                    "description": "You search among the weathered headstones and overgrown paths.",
                    "items": ["rusty church key", "flowers", "candles", "holy water"],
                    "success_chance": 0.5,
                    "nothing_found": "The cemetery grounds have been picked clean.",
                    "item_description": "Memorial items and forgotten belongings."
                }

        # Millbrook locations
        elif "auto shop" in location_name:
            if "car parts" in action_name or "parts" in action_name:
                return {
                    "description": "You search through the auto shop's parts inventory. Shelves are lined with automotive components.",
                    "items": ["alternator", "radiator", "brake pads", "transmission fluid", "spark plugs", "car battery", "motor oil"],
                    "success_chance": 0.9,
                    "nothing_found": "The parts shelves have been completely cleaned out.",
                    "item_description": "Professional automotive parts for vehicle repair."
                }
            elif "tool" in action_name:
                return {
                    "description": "You check the tool area. Wrenches, jacks, and diagnostic equipment are scattered about.",
                    "items": ["wrench set", "car jack", "tire iron", "jumper cables", "diagnostic scanner"],
                    "success_chance": 0.8,
                    "item_description": "Professional automotive tools."
                }
            else:
                return {
                    "description": "You search the general auto shop area. Oil stains and scattered parts tell the story of interrupted work.",
                    "items": ["motor oil", "brake fluid", "coolant", "air freshener", "shop rags", "spark plugs"],
                    "success_chance": 0.7,
                    "item_description": "Automotive fluids and supplies."
                }

        # Default search for any location
        return {
            "description": f"You search around {game_state.current_location}. The area shows signs of hasty evacuation.",
            "items": ["coins", "keys", "newspaper", "pen", "tissues"],
            "success_chance": 0.4,
            "nothing_found": "You find only debris and signs of the chaos that occurred here.",
            "failure_message": "Your search turns up nothing of value."
        }

    def get_item_weight(self, item: str) -> float:
        """Get the weight of an item for inventory management."""
        weights = {
            # Light items
            "coins": 0.1, "keys": 0.1, "pen": 0.1, "lighter": 0.1,
            "painkillers": 0.2, "bandages": 0.2, "vitamins": 0.2,
            "energy bar": 0.2, "crackers": 0.3, "batteries": 0.3,

            # Medium items
            "energy drink": 0.5, "water bottle": 0.5, "canned food": 0.6,
            "flashlight": 0.7, "road map": 0.2, "newspaper": 0.1,
            "first aid kit": 1.0, "rope": 1.2, "compass": 0.3,

            # Heavy items
            "hunting knife": 0.8, "baseball bat": 1.5, "sleeping bag": 2.0,
            "camping backpack": 1.8, "car battery": 15.0, "motor oil": 2.0,
            "jumper cables": 3.0, "tire iron": 2.5, "binoculars": 1.0,

            # Car parts
            "spark plugs": 0.5, "alternator": 8.0, "radiator": 12.0,
            "brake pads": 3.0, "transmission fluid": 2.5, "brake fluid": 1.0,
            "coolant": 2.0, "wrench set": 4.0, "car jack": 8.0,
            "diagnostic scanner": 1.5, "shop rags": 0.3,

            # Weapons
            "crowbar": 2.0, "kitchen knife": 0.5, "meat cleaver": 1.0,
            "police baton": 1.2, "tactical vest": 3.0, "scalpel": 0.3,
            "hammer": 1.5, "pipe wrench": 2.0, "pistol": 1.0, "ammunition": 0.5
        }
        return weights.get(item, 1.0)  # Default 1kg for unknown items

    def handle_use_item(self):
        """Handle using an item from inventory."""
        if not game_state.inventory:
            print("Your inventory is empty!")
            input("Press Enter to continue...")
            return
        
        print("Which item do you want to use?")
        for i, item in enumerate(game_state.inventory, 1):
            print(f"[{i}] {item}")
        
        try:
            choice = int(input("Enter item number: "))
            if 1 <= choice <= len(game_state.inventory):
                item = game_state.inventory[choice - 1]
                result = game_state.use_item(item)
                print(result["message"])
            else:
                print("Invalid item number!")
        except ValueError:
            print("Please enter a valid number!")
        
        input("Press Enter to continue...")
    
    def handle_buy_gear(self):
        """Handle buying gear from stores."""
        print("Store functionality coming soon!")
        input("Press Enter to continue...")

    def handle_descend_to_cemetery(self):
        """Handle descending from the bell tower to the cemetery."""
        print("\n🪜 You carefully climb down the spiral staircase...")
        print("The heavy wooden door closes behind you as you return to the cemetery.")

        # Move player back to the cemetery
        cemetery_name = "Riverside Cemetery"
        game_state.move_to_location(cemetery_name)
        print(f"\nYou are now back at the {cemetery_name}.")

        input("Press Enter to continue...")

    def handle_rest(self):
        """Handle resting to recover fatigue and health."""
        location_data = self.get_location_data(game_state.current_location)

        # Check if location allows resting
        is_safe = location_data.get("secure_location", False)
        has_shelter = location_data.get("shelter", False)
        rest_bonus = location_data.get("rest_bonus", 0)

        if not is_safe and not has_shelter:
            print("This location doesn't seem safe for resting. You might be attacked while sleeping!")
            choice = input("Do you want to rest anyway? (y/n): ").strip().lower()
            if choice not in ['y', 'yes']:
                print("You decide not to rest here.")
                input("Press Enter to continue...")
                return

        # Enhanced rest messages based on location safety
        if is_safe:
            print("🏠 You settle into this secure location for a proper rest...")
            print("The safety of this place allows you to truly relax and recover.")
        elif has_shelter:
            print("🏕️ You find some shelter and prepare to rest...")
            print("It's not perfectly safe, but better than sleeping in the open.")
        else:
            print("😰 You try to rest in this dangerous location...")
            print("You keep one eye open, ready to flee at any moment.")

        # Enhanced recovery based on location type
        if is_safe:
            # Safe locations provide excellent recovery
            fatigue_recovery = 50 + rest_bonus
            health_recovery = 20 + (rest_bonus // 2)
        elif has_shelter:
            # Sheltered locations provide good recovery
            fatigue_recovery = 35 + rest_bonus
            health_recovery = 10 + (rest_bonus // 2)
        else:
            # Dangerous locations provide minimal recovery
            fatigue_recovery = 20 + rest_bonus
            health_recovery = 3 + (rest_bonus // 2)

        # Apply recovery
        old_fatigue = game_state.fatigue
        old_health = game_state.health

        game_state.fatigue = max(0, game_state.fatigue - fatigue_recovery)
        game_state.health = min(100, game_state.health + health_recovery)

        # Time passes while resting
        rest_time = 3 if is_safe else 2 if has_shelter else 1
        game_state.update_survival_stats(rest_time)

        print(f"\n💤 You rest for several hours...")
        print(f"✨ Fatigue reduced by {old_fatigue - game_state.fatigue}")
        print(f"❤️ Health restored by {game_state.health - old_health}")

        # Risk of encounter if not in safe location
        if not is_safe:
            import random
            encounter_chance = 0.4 if not has_shelter else 0.2
            if random.random() < encounter_chance:
                print("\n⚠️ Your rest is interrupted by strange noises!")
                print("You couldn't get proper rest due to the disturbance.")
                game_state.fatigue = min(100, game_state.fatigue + 15)
            elif has_shelter:
                print("\n🛡️ Your shelter kept you relatively safe during rest.")
        else:
            print("\n🏠 You feel completely refreshed after resting in safety!")

        input("\nPress Enter to continue...")

    def handle_climb_bell_tower(self):
        """Handle climbing the bell tower action."""
        # Check if player has the required key
        if "rusty church key" not in game_state.inventory:
            print("\n🔒 The bell tower door is locked!")
            print("You need a key to access the bell tower.")
            print("Perhaps you should search the church or cemetery for a key...")
            input("Press Enter to continue...")
            return

        # Player has the key - unlock the bell tower
        print("\n🗝️ You use the rusty church key to unlock the bell tower door!")
        print("The heavy wooden door creaks open, revealing a narrow spiral staircase.")
        print("You climb the worn stone steps, emerging into the bell tower chamber.")

        # Add the bell tower to discovered locations
        bell_tower_name = "Riverside Church Bell Tower"
        if bell_tower_name not in game_state.discovered_locations:
            game_state.discovered_locations.add(bell_tower_name)
            print(f"\n🏰 LOCATION DISCOVERED: {bell_tower_name}")
            print("This secure location is now available for travel!")

        # Move player to the bell tower
        game_state.move_to_location(bell_tower_name)
        print(f"\nYou are now in the {bell_tower_name}.")

        # Gain experience for discovering a secret location
        game_state.gain_experience(15, "survival")

        input("Press Enter to continue...")

    def handle_refuel(self):
        """Handle refueling vehicles."""
        location_data = self.get_location_data(game_state.current_location)

        if not location_data.get("fuel_available", False):
            print("There's no fuel available at this location.")
            input("Press Enter to continue...")
            return

        # Check if player has fuel containers
        fuel_items = []
        for item in game_state.inventory:
            if "fuel" in item.lower() or "gasoline" in item.lower() or "diesel" in item.lower():
                fuel_items.append(item)

        if not fuel_items:
            print("You don't have any fuel containers to use.")
            input("Press Enter to continue...")
            return

        print("Available fuel:")
        for i, fuel in enumerate(fuel_items, 1):
            print(f"[{i}] {fuel}")

        try:
            choice = int(input("Which fuel do you want to use? ")) - 1
            if 0 <= choice < len(fuel_items):
                selected_fuel = fuel_items[choice]

                # Determine fuel amount based on type
                fuel_amounts = {
                    "gasoline": 25,
                    "diesel fuel": 30,
                    "motor oil": 5  # Not really fuel, but gives small boost
                }

                fuel_amount = 20  # Default
                for fuel_type, amount in fuel_amounts.items():
                    if fuel_type in selected_fuel:
                        fuel_amount = amount
                        break

                # Apply fuel
                old_fuel = game_state.fuel
                game_state.fuel = min(100, game_state.fuel + fuel_amount)
                game_state.remove_item(selected_fuel)

                print(f"You use {selected_fuel} to refuel.")
                print(f"Fuel increased by {game_state.fuel - old_fuel}")

            else:
                print("Invalid choice!")
        except ValueError:
            print("Please enter a valid number!")

        input("Press Enter to continue...")
    
    def show_help(self):
        """Show help information."""
        help_text = """
=== ZOMBIE SURVIVAL HELP ===

GAME COMMANDS:
- Enter numbers (1-8) to choose location-specific actions
- Enter [0] to access global commands menu

GLOBAL COMMANDS (accessed via [0]):
  [1] Show detailed character status
  [2] Show inventory and use items
  [3] Save your current game
  [4] Load a previously saved game
  [5] Show this help screen
  [6] Quit game

SURVIVAL TIPS:
- Monitor your health, hunger, thirst, and fatigue
- Search locations for useful items
- Use items to restore your stats
- Find and repair vehicles for long-distance travel
- Be careful with your fuel - you might need to walk!
- Some locations may have zombies - be prepared!

VEHICLE SYSTEM:
- Find broken vehicles and repair them with parts
- Use vehicles to travel to distant towns and cities
- Each vehicle will eventually break down permanently
- You'll need to find new vehicles in each new area

GOAL:
Survive the zombie apocalypse and explore multiple towns,
or see how long you can survive in this dangerous world.
        """
        print(help_text)
        input("Press Enter to continue...")
    
    def show_status(self):
        """Show detailed player status."""
        print("\n=== CHARACTER STATUS ===")
        print(game_state.get_status_summary())
        input("\nPress Enter to continue...")
    
    def show_inventory(self):
        """Show player inventory with option to use items."""
        from Functions.check_inventory import check_inventory

        if not game_state.inventory:
            print("Your inventory is empty!")
            input("Press Enter to continue...")
            return

        while True:
            clear_screen()
            result = check_inventory(game_state.inventory)
            print(result)
            print(f"Total weight: {game_state.current_weight:.1f}/{game_state.max_inventory_weight} kg")
            print("\n" + "="*50)
            print("INVENTORY ACTIONS:")
            print("[1] Use an item")
            print("[2] View item details")
            print("[0] Back to game")

            try:
                choice = int(input("\nWhat would you like to do? ").strip())

                if choice == 0:
                    break
                elif choice == 1:
                    self.use_item_from_inventory()
                elif choice == 2:
                    self.view_item_details()
                else:
                    print("Invalid choice! Please enter 0, 1, or 2.")
                    input("Press Enter to continue...")
            except ValueError:
                print("Invalid input! Please enter a number.")
                input("Press Enter to continue...")

    def use_item_from_inventory(self):
        """Allow player to select and use an item by number."""
        if not game_state.inventory:
            print("Your inventory is empty!")
            input("Press Enter to continue...")
            return

        print("\n" + "="*50)
        print("USE ITEM - Select an item to use:")
        print("="*50)

        # Show numbered list of items
        usable_items = []
        for i, item in enumerate(game_state.inventory, 1):
            # Check if item is usable (without actually using it)
            is_usable = self.can_use_item(item)
            if is_usable:
                usable_items.append((i, item))
                print(f"[{i}] {item}")
            else:
                print(f"[{i}] {item} (not usable)")

        if not usable_items:
            print("\nNo usable items in your inventory!")
            input("Press Enter to continue...")
            return

        print("[0] Cancel")

        try:
            choice = int(input(f"\nEnter item number (1-{len(game_state.inventory)}): "))

            if choice == 0:
                return
            elif 1 <= choice <= len(game_state.inventory):
                item = game_state.inventory[choice - 1]

                # Confirm usage
                print(f"\nUse {item}?")
                confirm = input("(y/n): ").strip().lower()

                if confirm in ['y', 'yes']:
                    result = game_state.use_item(item)
                    print(f"\n{result['message']}")

                    if result['success']:
                        print("✅ Item used successfully!")
                    else:
                        print("❌ Could not use item.")
                else:
                    print("Cancelled.")
            else:
                print("Invalid item number!")

        except ValueError:
            print("Please enter a valid number!")

        input("Press Enter to continue...")

    def view_item_details(self):
        """Show detailed information about items."""
        if not game_state.inventory:
            print("Your inventory is empty!")
            input("Press Enter to continue...")
            return

        print("\n" + "="*50)
        print("ITEM DETAILS - Select an item to view:")
        print("="*50)

        for i, item in enumerate(game_state.inventory, 1):
            print(f"[{i}] {item}")

        print("[0] Cancel")

        try:
            choice = int(input(f"\nEnter item number (1-{len(game_state.inventory)}): "))

            if choice == 0:
                return
            elif 1 <= choice <= len(game_state.inventory):
                item = game_state.inventory[choice - 1]

                from Functions.check_inventory import get_item_info
                info = get_item_info(item)

                print(f"\n" + "="*50)
                print(f"📋 {item.upper()}")
                print("="*50)

                if info:
                    print(f"Description: {info}")
                else:
                    print("No additional information available.")

                # Show if item is usable
                if self.can_use_item(item):
                    print("Status: Can be used")
                else:
                    print("Status: Not usable")

            else:
                print("Invalid item number!")

        except ValueError:
            print("Please enter a valid number!")

        input("Press Enter to continue...")

    def can_use_item(self, item: str) -> bool:
        """Check if an item can be used without actually using it."""
        # Define usable items and their conditions
        usable_items = {
            "water bottle", "energy drink", "soda", "beer", "coffee",
            "energy bar", "canned food", "mre", "granola bar", "beef jerky",
            "first aid kit", "bandages", "painkillers", "antibiotics",
            "can of motor oil"
        }

        return item.lower() in usable_items

    def save_game(self):
        """Save the current game state with multiple slot support."""
        import glob
        import os
        from datetime import datetime

        print("\n" + "="*50)
        print("💾 SAVE GAME")
        print("="*50)

        # Show existing save files
        save_files = glob.glob("*.json")
        save_files = [f for f in save_files if f.startswith("save_")]

        if save_files:
            print("Existing save files:")
            for i, save_file in enumerate(save_files, 1):
                try:
                    # Get file modification time
                    mod_time = os.path.getmtime(save_file)
                    mod_date = datetime.fromtimestamp(mod_time).strftime("%Y-%m-%d %H:%M:%S")
                    print(f"[{i}] {save_file} (Last saved: {mod_date})")
                except:
                    print(f"[{i}] {save_file}")
            print()

        print("Save options:")
        print("[1] Quick save (save_quicksave.json)")
        print("[2] New save file")
        print("[3] Overwrite existing save")
        print("[0] Cancel")

        try:
            choice = input("Enter your choice: ").strip()

            if choice == "0":
                print("Save cancelled.")
                input("Press Enter to continue...")
                return
            elif choice == "1":
                filename = "save_quicksave.json"
            elif choice == "2":
                custom_name = input("Enter save file name: ").strip()
                if not custom_name:
                    print("Invalid filename!")
                    input("Press Enter to continue...")
                    return
                filename = f"save_{custom_name}.json"
            elif choice == "3":
                if not save_files:
                    print("No existing save files to overwrite!")
                    input("Press Enter to continue...")
                    return

                print("Which file do you want to overwrite?")
                for i, save_file in enumerate(save_files, 1):
                    print(f"[{i}] {save_file}")

                file_choice = int(input("Enter file number: ")) - 1
                if 0 <= file_choice < len(save_files):
                    filename = save_files[file_choice]
                else:
                    print("Invalid choice!")
                    input("Press Enter to continue...")
                    return
            else:
                print("Invalid choice!")
                input("Press Enter to continue...")
                return

            # Perform the save
            if game_state.save_to_file(filename):
                print(f"✅ Game saved successfully to {filename}")
                print(f"📊 Game stats: Day {game_state.days_survived}, Turn {game_state.turn_count}")
                print(f"📍 Location: {game_state.current_location}")
            else:
                print("❌ Failed to save game!")

        except ValueError:
            print("Please enter a valid number!")
        except Exception as e:
            print(f"Error during save: {e}")

        input("Press Enter to continue...")

    def load_game(self):
        """Load a saved game state with multiple slot support."""
        import glob
        import os
        from datetime import datetime

        print("\n" + "="*50)
        print("📁 LOAD GAME")
        print("="*50)

        # Find all save files
        save_files = glob.glob("*.json")
        save_files = [f for f in save_files if f.startswith("save_")]

        if not save_files:
            print("No save files found!")
            input("Press Enter to continue...")
            return

        print("Available save files:")
        for i, save_file in enumerate(save_files, 1):
            try:
                # Get file modification time and size
                mod_time = os.path.getmtime(save_file)
                mod_date = datetime.fromtimestamp(mod_time).strftime("%Y-%m-%d %H:%M:%S")
                file_size = os.path.getsize(save_file)

                # Try to get some game info from the file
                try:
                    import json
                    with open(save_file, 'r') as f:
                        save_data = json.load(f)
                    location = save_data.get("current_location", "Unknown")
                    days = save_data.get("days_survived", 0)
                    health = save_data.get("health", 0)

                    print(f"[{i}] {save_file}")
                    print(f"    📅 Saved: {mod_date}")
                    print(f"    📍 Location: {location}")
                    print(f"    🗓️  Day {days}, ❤️  Health: {health}/100")
                    print()
                except:
                    print(f"[{i}] {save_file} (Last saved: {mod_date})")
            except:
                print(f"[{i}] {save_file}")

        print("[0] Cancel")

        try:
            choice = int(input("Enter the number of the save file to load: "))

            if choice == 0:
                print("Load cancelled.")
                input("Press Enter to continue...")
                return
            elif 1 <= choice <= len(save_files):
                filename = save_files[choice - 1]

                # Confirm load
                confirm = input(f"Load {filename}? This will overwrite your current game! (y/n): ").strip().lower()
                if confirm not in ['y', 'yes']:
                    print("Load cancelled.")
                    input("Press Enter to continue...")
                    return

                # Perform the load
                if game_state.load_from_file(filename):
                    print(f"✅ Game loaded successfully from {filename}")
                    print(f"📊 Loaded stats: Day {game_state.days_survived}, Turn {game_state.turn_count}")
                    print(f"📍 Current location: {game_state.current_location}")
                    print(f"❤️  Health: {game_state.health}/100")
                else:
                    print("❌ Failed to load game! File may be corrupted.")
            else:
                print("Invalid choice!")

        except ValueError:
            print("Please enter a valid number!")
        except Exception as e:
            print(f"Error during load: {e}")

        input("Press Enter to continue...")
    
    def quit_game(self):
        """Quit the game."""
        save_choice = input("Do you want to save before quitting? (y/n): ").strip().lower()
        if save_choice in ['y', 'yes']:
            self.save_game()
        
        print("Thanks for playing! Goodbye!")
        self.running = False
    
    def handle_game_over(self, reason: str):
        """Handle game over scenario."""
        clear_screen()
        choice = game_state.show_game_over_screen(reason)

        if choice == "restart":
            # Reset game state
            import game_state as gs_module
            from game_state import GameState
            gs_module.game_state = GameState()
            self.last_encounter_result = None  # Clear any encounter results
            self.start_game()
        else:
            self.running = False
