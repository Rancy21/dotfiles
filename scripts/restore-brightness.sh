STATEFILE="/tmp/hypridle_brightness"


# restore previous brightness (if file still exists)
if [ -f "$STATEFILE" ]; then
  OLD=$(cat "$STATEFILE")
  brightnessctl set "$OLD" >/dev/null 2>&1
  rm -f "$STATEFILE"
fi