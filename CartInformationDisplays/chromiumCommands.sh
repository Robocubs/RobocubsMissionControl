#!/bin/bash
sleep 5

# Launch on workspace 1 (left)
swaymsg "workspace 1"
sleep 0.5
chromium-browser --kiosk --user-data-dir="/tmp/chrome2" "http://localhost:1701/prod/right.html" &

sleep 0.5

# Launch on workspace 2 (right)
swaymsg "workspace 2"
sleep 0.5
chromium-browser --kiosk --user-data-dir="/tmp/chrome1" "http://localhost:1701/prod/left.html" &

wait