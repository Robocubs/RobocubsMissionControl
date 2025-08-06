sleep 5

# Set display and auth environment
export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority

chromium-browser --window-position=3840,0 --kiosk https://www.apple.com
chromium-browser --window-position=0,0 --kiosk https://www.apple.com