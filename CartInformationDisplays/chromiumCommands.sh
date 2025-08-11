#!/bin/bash
sleep 5

# Set display and auth environment
export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority

chromium-browser --enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist --enable-features=VaapiVideoDecoder --use-gl=egl --window-position=3840,0 --kiosk --user-data-dir="/tmp/chrome1" "http://localhost:1701/prod/right.html" &
chromium-browser --enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist --enable-features=VaapiVideoDecoder --use-gl=egl --window-position=0,0 --kiosk --user-data-dir="/tmp/chrome2" "http://localhost:1701/prod/left.html" &

wait