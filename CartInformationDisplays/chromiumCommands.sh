#!/bin/bash
# --autoplay-policy=no-user-gesture-required: without it, Chromium blocks a
# JS-initiated video.muted = false with no user gesture, so the local-video
# unmute control would silently no-op.
sleep 5

# Launch on workspace 1 (left)
swaymsg "workspace 1"
sleep 0.5
chromium-browser --kiosk --autoplay-policy=no-user-gesture-required --user-data-dir="/tmp/chrome2" "http://localhost:1701/prod/left.html" &

sleep 0.5

# Launch on workspace 2 (right)
swaymsg "workspace 2"
sleep 0.5
chromium-browser --kiosk --autoplay-policy=no-user-gesture-required --user-data-dir="/tmp/chrome1" "http://localhost:1701/prod/right.html" &

wait