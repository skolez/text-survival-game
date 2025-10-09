#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Setup Flutter PATH for macOS/Linux (bash/zsh)
# Usage:
#   1) Edit FLUTTER_DIR below if Flutter is installed elsewhere
#   2) Run: bash scripts/setup_flutter_path_unix.sh
#   3) Restart your terminal or source your shell profile
# ------------------------------------------------------------

FLUTTER_DIR="$HOME/flutter"
FLUTTER_BIN="$FLUTTER_DIR/bin"

SHELL_RC="$HOME/.bashrc"
if [ -n "${ZSH_VERSION-}" ]; then
  SHELL_RC="$HOME/.zshrc"
fi

LINE_TO_ADD="export PATH=\"$PATH:$FLUTTER_BIN\""

if grep -Fq "$LINE_TO_ADD" "$SHELL_RC"; then
  echo "Flutter bin already in PATH in $SHELL_RC"
else
  echo "$LINE_TO_ADD" >> "$SHELL_RC"
  echo "Added Flutter bin to PATH in $SHELL_RC"
fi

echo "Reload your shell config: source $SHELL_RC"
echo "Then verify: flutter --version && flutter doctor"

