#!/bin/bash
DEV=intel_backlight

CUR=$(brightnessctl -m | cut -d, -f4)

# set target brightnes
TARGET_RAW=30

# store current raw in a temp file
STATEFILE="/tmp/hypridle_brightness"
echo "$CUR" > "$STATEFILE"

# dim to target
brightnessctl -d "$DEV" set "$TARGET_RAW" >/dev/null 2>&1