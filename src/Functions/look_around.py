import random


def look_around(location, inventory):
  # Code to describe the current location
  print("You look around and see that you are at an " + location + ".")
  
  # Check if the player finds any items
  items = ["water bottle", "food rations", "first aid kit"]
  found_items = []
  num_items_found = random.randint(0, 3)
  for i in range(num_items_found):
    item = random.choice(items)
    if item not in inventory:
      inventory.append(item)
      found_items.append(item)
      
  # Print a message about the items found
  if found_items:
    previous_output =f"You found the following items: " + ", ".join(found_items)
  else:
    previous_output ="You didn't find any items."
  return previous_output
