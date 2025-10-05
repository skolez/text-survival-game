import re


def wrap_text(text: str, max_length: int = None) -> str:
    # If no maximum line length is specified, return the text as-is
    if max_length is None:
        return text
    
    # Split the text into paragraphs
    paragraphs = re.split(r'---', text)

    # Initialize a list to store the wrapped paragraphs
    wrapped_paragraphs = []

    # Iterate over the paragraphs
    for paragraph in paragraphs:
        # Remove newline characters from the paragraph
        paragraph = re.sub(r'\n', ' ', paragraph)

        # Split the paragraph into words
        words = paragraph.split()

        # Initialize variables to keep track of the current line and the wrapped paragraph
        current_line = []
        wrapped_paragraph = []

        # Iterate over the words
        for word in words:
            # If the current line plus the next word would be too long,
            # append the current line to the wrapped paragraph and start a new line
            if len(' '.join(current_line + [word])) > max_length:
                wrapped_paragraph.append(' '.join(current_line))
                current_line = []
            
            # Otherwise, add the word to the current line
            current_line.append(word)

        # Add the remaining current line to the wrapped paragraph
        wrapped_paragraph.append(' '.join(current_line))

        # Add the wrapped paragraph to the list of wrapped paragraphs
        wrapped_paragraphs.append(wrapped_paragraph)

    # Join the wrapped paragraphs into a single string with newline characters and the --- delimiter,
    # preserving newlines between paragraphs if there are no other characters on the line
    wrapped_text = '\n\n'.join(['\n'.join([line for line in paragraph if line]) for paragraph in wrapped_paragraphs])

    return wrapped_text
