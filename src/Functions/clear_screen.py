import os
import platform


def clear_screen():
    # Clear the screen
    if platform.system() == "Windows":
      os.system("cls")
    else:
      os.system("clear")
    pass
