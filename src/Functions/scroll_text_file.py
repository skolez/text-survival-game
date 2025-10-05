import sys
import threading
import time

from Functions.type_to_screen import type_to_screen
from Functions.wrap_text import wrap_text

# Global variable to track if user wants to skip
skip_intro = False


def check_for_skip():
    """Check if user pressed Enter to skip intro."""
    global skip_intro
    try:
        input()  # Wait for Enter key
        skip_intro = True
    except:
        pass


def scroll_text_file(filename, typespeed, speed, max_length=None, allow_skip=False):
    """
    Read and print the contents of a text file to the screen, simulating the process of typing.

    Parameters:
        filename (str): The name of the file to be read.
        typespeed (int): The delay between each character being printed, in milliseconds.
        speed (int): The number of seconds to wait between each line.
        max_length (int, optional): The maximum line length to wrap the text at. Default is None.
        allow_skip (bool): Whether to allow skipping with Enter key.

    Example:
        scroll_text_file("intro.txt", 50, 1, 80, True)
    """
    global skip_intro
    skip_intro = False

    # Start skip detection thread if allowed
    skip_thread = None
    if allow_skip:
        skip_thread = threading.Thread(target=check_for_skip, daemon=True)
        skip_thread.start()

    def skip_check():
        return skip_intro

    with open(filename, 'r') as f:
        # Read the entire contents of the file into a string
        text = f.read()

        # Wrap the text if a maximum line length is specified
        if max_length is not None:
            text = wrap_text(text, max_length)

        # Split the wrapped text into lines
        lines = text.split('\n')

        # Iterate through the lines of the file, printing each line with a delay
        for line in lines:
            if skip_intro:
                # Print remaining lines instantly
                for remaining_line in lines[lines.index(line):]:
                    print(remaining_line)
                break

            type_to_screen(line, typespeed, speed, max_length, skip_check if allow_skip else None)
            print()
            if not skip_intro:
                time.sleep(speed)

    # Don't wait if skipped
    if not skip_intro:
        time.sleep(speed * 2)
