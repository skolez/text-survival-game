import json
import os
from typing import Any, Dict, List


def read_location_data() -> List[Dict[str, Any]]:
    """
    Read location data from JSON file with error handling.

    Returns:
        List of location dictionaries, or empty list if error occurs
    """
    try:
        # Try different possible paths for the assets file
        possible_paths = [
            'Assets/locations.json',
            '../Assets/locations.json',
            os.path.join(os.path.dirname(__file__), '..', 'Assets', 'locations.json')
        ]

        for path in possible_paths:
            if os.path.exists(path):
                with open(path, 'r', encoding='utf-8') as f:
                    location_data = json.load(f)

                # Validate the data structure
                if not isinstance(location_data, list):
                    raise ValueError("Location data must be a list")

                for location in location_data:
                    if not isinstance(location, dict):
                        raise ValueError("Each location must be a dictionary")
                    if "name" not in location:
                        raise ValueError("Each location must have a 'name' field")
                    if "description" not in location:
                        raise ValueError("Each location must have a 'description' field")

                return location_data

        # If no file found, return default location data
        print("Warning: locations.json not found, using default locations")
        return get_default_locations()

    except json.JSONDecodeError as e:
        print(f"Error parsing locations.json: {e}")
        return get_default_locations()
    except Exception as e:
        print(f"Error reading location data: {e}")
        return get_default_locations()


def get_default_locations() -> List[Dict[str, Any]]:
    """Return default location data if file cannot be read."""
    return [
        {
            "name": "Abandoned Gas Station",
            "description": "You are at an abandoned gas station. It looks like it has been abandoned for a long time.",
            "actions": [
                {"name": "Look around", "description": "Search the area for useful items"},
                {"name": "Move to a new location", "description": "Travel to another location"},
                {"name": "Check your inventory", "description": "See what items you're carrying"},
                {"name": "Search for supplies", "description": "Look for fuel, food, or other supplies"}
            ],
            "nearby": ["Sporting Goods Store", "Supermarket"]
        }
    ]
