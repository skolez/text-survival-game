"""
Text Adventure Game - Main Entry Point

A zombie survival text-based adventure game.
"""

from game_engine import GameEngine


def main():
    """Main function to start the game."""
    print("Welcome to Zombie Survival Story!")
    print("=" * 40)

    game = GameEngine()
    game.start_game()

if __name__ == "__main__":
    main()
