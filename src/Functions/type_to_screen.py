import os
import select
import sys
import time

from Functions.wrap_text import wrap_text


def type_to_screen(typedtext, typedelay, wait=0, max_length=None, skip_check=None):
    """
    Print a string of text to the screen, simulating the process of typing.

    Parameters:
        typedtext (str): The text to be printed.
        typedelay (int): The delay between each character being printed, in milliseconds.
        wait (int, optional): The number of seconds to wait after the text has been printed. Default is 0.
        skip_check (callable, optional): Function to check if typing should be skipped.

    Example:
        type_to_screen("Hello, World!", 50, 1)
    """
    # Wrap the text
    typedtext = wrap_text(typedtext, max_length)

    # Type out the wrapped text
    for i, char in enumerate(typedtext):
        if skip_check and skip_check():
            # Print remaining text instantly
            print(typedtext[i:], end='', flush=True)
            break
        print(char, end='', flush=True)
        time.sleep(typedelay / 1000)
    time.sleep(wait)
