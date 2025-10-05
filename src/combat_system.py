"""
Combat System for Text Adventure Game

This module handles all combat mechanics including zombie encounters,
weapon usage, and damage calculations.
"""

import random
from typing import Dict, List, Optional, Tuple

from game_state import game_state


class Zombie:
    """Represents a zombie enemy."""
    
    def __init__(self, zombie_type: str = "walker"):
        """Initialize a zombie with type-specific stats."""
        zombie_stats = {
            "walker": {"health": 30, "damage": 15, "speed": 1, "description": "a slow-moving infected"},
            "runner": {"health": 25, "damage": 20, "speed": 3, "description": "a fast infected"},
            "brute": {"health": 60, "damage": 25, "speed": 1, "description": "a massive infected"},
            "crawler": {"health": 15, "damage": 10, "speed": 2, "description": "a crawling infected"}
        }
        
        stats = zombie_stats.get(zombie_type, zombie_stats["walker"])
        self.type = zombie_type
        self.health = stats["health"]
        self.max_health = stats["health"]
        self.damage = stats["damage"]
        self.speed = stats["speed"]
        self.description = stats["description"]
        self.is_alive = True
    
    def take_damage(self, damage: int) -> bool:
        """
        Apply damage to zombie.
        
        Args:
            damage: Amount of damage to apply
            
        Returns:
            True if zombie is killed, False otherwise
        """
        self.health -= damage
        if self.health <= 0:
            self.is_alive = False
            return True
        return False
    
    def attack(self) -> int:
        """
        Zombie attacks, returns damage dealt.
        
        Returns:
            Damage amount (with some randomness)
        """
        if not self.is_alive:
            return 0
        
        # Add some randomness to damage
        base_damage = self.damage
        variation = random.randint(-5, 5)
        return max(1, base_damage + variation)


class CombatSystem:
    """Handles all combat mechanics."""
    
    def __init__(self):
        """Initialize combat system."""
        self.weapons = {
            "fists": {"damage": 8, "accuracy": 0.7, "durability": 999, "description": "your bare hands"},
            "hunting knife": {"damage": 15, "accuracy": 0.8, "durability": 50, "description": "a sharp hunting knife"},
            "baseball bat": {"damage": 20, "accuracy": 0.75, "durability": 30, "description": "a wooden baseball bat"},
            "pistol": {"damage": 35, "accuracy": 0.6, "durability": 100, "description": "a pistol", "ammo_type": "bullets"},
            "hunting rifle": {"damage": 50, "accuracy": 0.8, "durability": 80, "description": "a hunting rifle", "ammo_type": "rifle_rounds"},
            "shotgun": {"damage": 45, "accuracy": 0.7, "durability": 60, "description": "a shotgun", "ammo_type": "shells"},
            "crowbar": {"damage": 18, "accuracy": 0.8, "durability": 80, "description": "a sturdy crowbar"},
            "axe": {"damage": 25, "accuracy": 0.7, "durability": 40, "description": "a sharp axe"}
        }
        
        self.ammunition = {
            "bullets": 0,
            "rifle_rounds": 0,
            "shells": 0
        }
    
    def check_for_zombie_encounter(self, location_name: str) -> Optional[Zombie]:
        """
        Check if a zombie encounter occurs at the current location.
        
        Args:
            location_name: Name of the current location
            
        Returns:
            Zombie instance if encounter occurs, None otherwise
        """
        # Get location data to check zombie chance
        from Functions.read_location_data import read_location_data
        locations = read_location_data()
        
        current_location = None
        for location in locations:
            if location["name"] == location_name:
                current_location = location
                break
        
        if not current_location:
            return None
        
        zombie_chance = current_location.get("zombie_chance", 0.1)
        
        if random.random() < zombie_chance:
            # Determine zombie type based on location
            zombie_types = ["walker", "crawler"]
            
            # Some locations have more dangerous zombies
            if "hospital" in location_name.lower():
                zombie_types.extend(["runner", "brute"])
            elif "town square" in location_name.lower():
                zombie_types.extend(["runner"])
            
            zombie_type = random.choice(zombie_types)
            return Zombie(zombie_type)
        
        return None
    
    def get_available_weapons(self) -> List[str]:
        """Get list of weapons available to the player."""
        available = ["fists"]  # Always have fists
        
        for item in game_state.inventory:
            if item in self.weapons:
                available.append(item)
        
        return available
    
    def get_weapon_info(self, weapon: str) -> Dict:
        """Get information about a weapon."""
        return self.weapons.get(weapon, self.weapons["fists"])
    
    def can_use_weapon(self, weapon: str) -> Tuple[bool, str]:
        """
        Check if player can use a weapon.
        
        Args:
            weapon: Name of the weapon
            
        Returns:
            Tuple of (can_use, reason_if_not)
        """
        if weapon not in self.weapons:
            return False, "Unknown weapon"
        
        weapon_info = self.weapons[weapon]
        
        # Check if weapon requires ammo
        if "ammo_type" in weapon_info:
            ammo_type = weapon_info["ammo_type"]
            if self.ammunition.get(ammo_type, 0) <= 0:
                return False, f"No {ammo_type} remaining"
        
        # Check durability (simplified - assume weapons don't break for now)
        return True, ""
    
    def attack_zombie(self, weapon: str, zombie: Zombie) -> Dict:
        """
        Player attacks a zombie.
        
        Args:
            weapon: Name of weapon to use
            zombie: Target zombie
            
        Returns:
            Dictionary with attack results
        """
        can_use, reason = self.can_use_weapon(weapon)
        if not can_use:
            return {
                "success": False,
                "message": f"Cannot use {weapon}: {reason}",
                "damage": 0,
                "zombie_killed": False
            }
        
        weapon_info = self.weapons[weapon]
        
        # Check if attack hits
        accuracy = weapon_info["accuracy"]
        if random.random() > accuracy:
            return {
                "success": True,
                "message": f"You swing {weapon_info['description']} but miss {zombie.description}!",
                "damage": 0,
                "zombie_killed": False
            }
        
        # Calculate damage
        base_damage = weapon_info["damage"]
        damage_variation = random.randint(-3, 3)
        total_damage = max(1, base_damage + damage_variation)
        
        # Apply damage to zombie
        zombie_killed = zombie.take_damage(total_damage)
        
        # Use ammo if applicable
        if "ammo_type" in weapon_info:
            ammo_type = weapon_info["ammo_type"]
            self.ammunition[ammo_type] = max(0, self.ammunition[ammo_type] - 1)
        
        # Create result message
        if zombie_killed:
            message = f"You strike {zombie.description} with {weapon_info['description']} for {total_damage} damage and kill it!"
            game_state.zombie_kills += 1
        else:
            message = f"You hit {zombie.description} with {weapon_info['description']} for {total_damage} damage. It has {zombie.health} health remaining."
        
        return {
            "success": True,
            "message": message,
            "damage": total_damage,
            "zombie_killed": zombie_killed
        }
    
    def zombie_attack_player(self, zombie: Zombie) -> Dict:
        """
        Zombie attacks the player.
        
        Args:
            zombie: Attacking zombie
            
        Returns:
            Dictionary with attack results
        """
        if not zombie.is_alive:
            return {"damage": 0, "message": "The zombie is dead and cannot attack."}
        
        damage = zombie.attack()
        
        # Apply damage to player
        game_state.health = max(0, game_state.health - damage)
        
        message = f"{zombie.description.capitalize()} attacks you for {damage} damage!"
        
        if game_state.health <= 0:
            message += " You have been killed!"
        elif game_state.health <= 20:
            message += " You are badly injured!"
        
        return {
            "damage": damage,
            "message": message
        }
    
    def run_combat_encounter(self, zombie: Zombie) -> Dict:
        """
        Run a complete combat encounter.
        
        Args:
            zombie: The zombie to fight
            
        Returns:
            Dictionary with encounter results
        """
        print(f"\n🧟 ZOMBIE ENCOUNTER! 🧟")
        print(f"You encounter {zombie.description}!")
        print(f"Zombie Health: {zombie.health}/{zombie.max_health}")
        print(f"Your Health: {game_state.health}/100")
        
        combat_log = []
        
        while zombie.is_alive and game_state.health > 0:
            print("\n" + "="*40)
            print("What do you want to do?")
            print("[1] Attack")
            print("[2] Try to run away")
            print("[3] Check inventory")
            
            try:
                choice = input("Enter your choice: ").strip()
                
                if choice == "1":
                    # Show available weapons
                    weapons = self.get_available_weapons()
                    print("\nChoose your weapon:")
                    for i, weapon in enumerate(weapons, 1):
                        weapon_info = self.get_weapon_info(weapon)
                        print(f"[{i}] {weapon} (Damage: {weapon_info['damage']}, Accuracy: {weapon_info['accuracy']*100:.0f}%)")
                    
                    try:
                        weapon_choice = int(input("Enter weapon number: ")) - 1
                        if 0 <= weapon_choice < len(weapons):
                            selected_weapon = weapons[weapon_choice]
                            
                            # Player attacks
                            attack_result = self.attack_zombie(selected_weapon, zombie)
                            print(f"\n{attack_result['message']}")
                            combat_log.append(attack_result['message'])
                            
                            if attack_result['zombie_killed']:
                                print("You have defeated the zombie!")
                                # Gain combat experience for killing zombie
                                game_state.gain_experience(15, "combat")
                                return {
                                    "victory": True,
                                    "fled": False,
                                    "combat_log": combat_log,
                                    "result_message": f"🏆 VICTORY! You defeated {zombie.description}!"
                                }
                            
                            # Zombie attacks back if still alive
                            if zombie.is_alive:
                                zombie_attack = self.zombie_attack_player(zombie)
                                print(f"{zombie_attack['message']}")
                                combat_log.append(zombie_attack['message'])
                                
                                if game_state.health <= 0:
                                    print("You have been defeated!")
                                    return {
                                        "victory": False,
                                        "fled": False,
                                        "combat_log": combat_log,
                                        "player_died": True,
                                        "result_message": f"💀 DEFEAT! You were killed by {zombie.description}!"
                                    }
                        else:
                            print("Invalid weapon choice!")
                    except ValueError:
                        print("Please enter a valid number!")
                
                elif choice == "2":
                    # Try to run away
                    escape_chance = 0.75  # Base 75% chance (increased from 60%)
                    if zombie.speed > 2:
                        escape_chance -= 0.15  # Reduced penalty for fast zombies

                    if random.random() < escape_chance:
                        print("You successfully escape from the zombie!")
                        # Gain survival experience for successful escape
                        game_state.gain_experience(8, "survival")
                        return {
                            "victory": False,
                            "fled": True,
                            "combat_log": combat_log,
                            "result_message": f"🏃 ESCAPED! You successfully fled from {zombie.description}!"
                        }
                    else:
                        print("You failed to escape! The zombie catches up to you.")
                        # Zombie gets a reduced damage attack (since you're running)
                        damage = max(1, zombie.attack() // 2)  # Half damage when running
                        game_state.health = max(0, game_state.health - damage)

                        message = f"{zombie.description.capitalize()} catches you while running and deals {damage} damage!"
                        if game_state.health <= 0:
                            message += " You have been killed!"
                            print(f"{message}")
                            combat_log.append(message)
                            return {
                                "victory": False,
                                "fled": False,
                                "combat_log": combat_log,
                                "player_died": True,
                                "result_message": f"💀 DEFEAT! You were killed while trying to escape from {zombie.description}!"
                            }
                        elif game_state.health <= 20:
                            message += " You are badly injured!"

                        print(f"{message}")
                        combat_log.append(message)
                
                elif choice == "3":
                    # Show inventory
                    from Functions.check_inventory import check_inventory
                    print(check_inventory(game_state.inventory))
                
                else:
                    print("Invalid choice! Please choose 1, 2, or 3.")
                    
            except KeyboardInterrupt:
                print("\nCombat interrupted!")
                return {
                    "victory": False,
                    "fled": True,
                    "combat_log": combat_log
                }
        
        # This shouldn't be reached, but just in case
        return {
            "victory": zombie.is_alive == False,
            "fled": False,
            "combat_log": combat_log
        }


# Global combat system instance
combat_system = CombatSystem()
