from Functions.read_location_data import read_location_data


def move_location(current_location: str) -> str:
    """
    Handle player movement to a new location with improved error handling.

    Args:
        current_location: Name of the current location

    Returns:
        Name of the new location, or current location if move failed
    """
    try:
        locations = read_location_data()
        if not locations:
            print("Error: No location data available!")
            return current_location

        # Get available locations (excluding current)
        available_locations = [loc for loc in locations if loc["name"] != current_location]

        if not available_locations:
            print("No other locations available to move to!")
            return current_location

        # Display available locations
        print("\nChoose a new location:")
        for i, location in enumerate(available_locations, 1):
            print(f"[{i}] {location['name']}")

        print("[0] Cancel (stay here)")

        # Get player choice with validation
        while True:
            try:
                choice_input = input("\nEnter the number of the location you want to move to: ").strip()

                if not choice_input:
                    print("Please enter a number.")
                    continue

                choice = int(choice_input)

                # Handle cancel option
                if choice == 0:
                    print("You decide to stay where you are.")
                    return current_location

                # Validate choice range
                if 1 <= choice <= len(available_locations):
                    selected_location = available_locations[choice - 1]["name"]
                    print(f"You travel to {selected_location}.")
                    return selected_location
                else:
                    print(f"Please enter a number between 0 and {len(available_locations)}.")

            except ValueError:
                print("Please enter a valid number.")
            except KeyboardInterrupt:
                print("\nMovement cancelled.")
                return current_location
            except Exception as e:
                print(f"An error occurred: {e}")
                return current_location

    except Exception as e:
        print(f"Error during location movement: {e}")
        return current_location
