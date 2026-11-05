#!/usr/bin/env bash
# Usage: set-wallpaper.sh /path/to/image.jpg
# Sets the wallpaper with awww and regenerates the Quickshell theme with matugen.
set -euo pipefail

WALL="${1:?usage: set-wallpaper.sh /path/to/image}"
WALL="$(realpath "$WALL")"

# make sure the wallpaper daemon is running
pgrep -x awww-daemon >/dev/null || { awww-daemon & sleep 0.5; }

awww img "$WALL" --transition-type fade --transition-duration 1

# generate colors -> ~/.cache/qs-colors.json (the bar reloads it live)
matugen image "$WALL" --mode dark --source-color-index 0

# remember it so it can be restored on login
echo "$WALL" > "$HOME/.cache/current-wall"

