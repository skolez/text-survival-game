from typing import List

from game_state import game_state


def check_inventory(inventory: List[str]) -> str:
    """
    Display player inventory with categorization and item details.

    Args:
        inventory: List of items in inventory

    Returns:
        Formatted inventory string
    """
    if not inventory:
        return "Your inventory is empty."

    # Define item categories and their properties
    item_categories = {
        "Weapons": {
            "items": ["hunting knife", "baseball bat", "pistol", "hunting rifle", "shotgun", "crowbar", "axe"],
            "icon": "⚔️"
        },
        "Medical": {
            "items": ["first aid kit", "medicine", "painkillers", "antibiotics", "bandages", "medical supplies"],
            "icon": "🏥"
        },
        "Food & Drink": {
            "items": ["water bottle", "food rations", "canned food", "energy drink", "snack bar", "berries"],
            "icon": "🍽️"
        },
        "Tools & Equipment": {
            "items": ["flashlight", "rope", "compass", "radio", "batteries", "tools", "jumper cables"],
            "icon": "🔧"
        },
        "Clothing & Gear": {
            "items": ["backpack", "sleeping bag", "warm jacket", "boots", "bulletproof vest", "blanket"],
            "icon": "👕"
        },
        "Fuel & Automotive": {
            "items": ["can of motor oil", "gasoline", "diesel fuel", "spare tire", "car keys"],
            "icon": "⛽"
        },
        "Miscellaneous": {
            "items": [],  # Will catch anything not in other categories
            "icon": "📦"
        }
    }

    # Categorize inventory items
    categorized_inventory = {}
    uncategorized_items = []

    for item in inventory:
        categorized = False
        for category, data in item_categories.items():
            if item in data["items"]:
                if category not in categorized_inventory:
                    categorized_inventory[category] = []
                categorized_inventory[category].append(item)
                categorized = True
                break

        if not categorized:
            uncategorized_items.append(item)

    # Add uncategorized items to miscellaneous
    if uncategorized_items:
        categorized_inventory["Miscellaneous"] = uncategorized_items

    # Build inventory display string
    inventory_lines = []
    inventory_lines.append("=" * 50)
    inventory_lines.append("📋 INVENTORY")
    inventory_lines.append("=" * 50)

    # Show weight information
    inventory_lines.append(f"Weight: {game_state.current_weight:.1f}/{game_state.max_inventory_weight} kg")
    inventory_lines.append(f"Items: {len(inventory)}")
    inventory_lines.append("")

    # Display items by category
    for category, data in item_categories.items():
        if category in categorized_inventory:
            items = categorized_inventory[category]
            inventory_lines.append(f"{data['icon']} {category}:")

            for item in items:
                # Add item details if available
                item_info = get_item_info(item)
                if item_info:
                    inventory_lines.append(f"  • {item} - {item_info}")
                else:
                    inventory_lines.append(f"  • {item}")

            inventory_lines.append("")

    inventory_lines.append("=" * 50)
    inventory_lines.append("💡 Tip: Use items by typing 'use [item name]' or selecting the use action")

    return "\n".join(inventory_lines)


def get_item_info(item: str) -> str:
    """
    Get additional information about an item.

    Args:
        item: Name of the item

    Returns:
        Information string about the item
    """
    item_info = {
        # Weapons
        "hunting knife": "15 damage, 80% accuracy",
        "baseball bat": "20 damage, 75% accuracy",
        "pistol": "35 damage, 60% accuracy (needs bullets)",
        "hunting rifle": "50 damage, 80% accuracy (needs rifle rounds)",
        "shotgun": "45 damage, 70% accuracy (needs shells)",
        "crowbar": "18 damage, 80% accuracy",
        "axe": "25 damage, 70% accuracy",

        # Medical
        "first aid kit": "Restores 25 health",
        "medicine": "Restores 15 health",
        "painkillers": "Restores 10 health, reduces fatigue",
        "antibiotics": "Prevents infection, restores 20 health",
        "water bottle": "Restores 30 thirst",
        "energy drink": "Reduces 20 fatigue, restores 10 thirst",

        # Food
        "food rations": "Restores 40 hunger",
        "canned food": "Restores 30 hunger",
        "snack bar": "Restores 15 hunger",
        "berries": "Restores 10 hunger, 5 thirst",

        # Tools
        "flashlight": "Illuminates dark areas",
        "rope": "Useful for climbing and securing items",
        "compass": "Helps with navigation",
        "radio": "Can contact other survivors",
        "batteries": "Powers electronic devices",

        # Gear
        "backpack": "Increases carrying capacity",
        "sleeping bag": "Improves rest quality",
        "warm jacket": "Protection from cold",
        "bulletproof vest": "Reduces damage from attacks",

        # Automotive
        "can of motor oil": "Vehicle maintenance",
        "gasoline": "Fuel for vehicles",
        "diesel fuel": "Fuel for trucks and generators",
        "car keys": "Starts specific vehicles"
    }

    return item_info.get(item, "")
