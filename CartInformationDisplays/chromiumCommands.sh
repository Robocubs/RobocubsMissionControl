#!/bin/bash

# Set display and auth environment
export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority

chromium-browser --window-position=3840,0 --kiosk --user-data-dir="/tmp/chrome1" "http://localhost:1701/prod/right.html" &
chromium-browser --window-position=0,0 --kiosk --user-data-dir="/tmp/chrome2" "http://localhost:1701/prod/left.html" &

wait