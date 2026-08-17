# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

Mission control system for FRC team 1701 (Robocubs) pit displays at competitions. It coordinates three types of displays:
- **Cart screens** (left/right) — Chromium browsers running a Svelte app on rolling carts
- **Sign** — an iPad running `MatchStatusDisplay`, showing the match board or screensaver
- **Controller** — an iPad running `PitMissionController`, used by a human operator to control all of the above

## Repository structure

```
CartInformationDisplays/   # Python server + Svelte frontend for cart browsers
PitMissionController/      # iOS app: operator control panel (BT Central + WebSocket client)
MatchStatusDisplay/        # iOS app: sign display (BT Peripheral)
Shared/                    # Swift code compiled into both iOS targets
```

## Build & run

### iOS apps (Xcode)
Open `RobocubsMissionControl.xcodeproj` in Xcode. Two targets: **PitMissionController** and **MatchStatusDisplay**. Build and run each to a physical iPad — Bluetooth requires a real device.

### Python server
```bash
cd CartInformationDisplays
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
# Create .env with TBA_API_KEY=<your key from thebluealliance.com>
python main.py          # runs on port 1701
```

On the competition server it runs as a systemd service (`missioncontrol.service`) under the `missioncontrol` user.

### Svelte frontend (cart displays)
```bash
cd CartInformationDisplays/frontend
npm install
npm run dev             # dev server
npm run build           # outputs to frontend/prod/
```
The server statically serves `frontend/prod/` at `/prod`. Cart displays load `left.html` or `right.html` via Chromium (see `chromiumCommands.sh`).

## Architecture & communication flow

```
TBA API ──(HTTP, every 10s)──▶ Python server (port 1701)
                                    │
                         WebSocket /missionController
                                    │
                         PitMissionController (iPad)
                         ┌──────────┴──────────┐
                   BLE (Central)         WebSocket (upstream)
                         │                     │
               MatchStatusDisplay      Python server again
               (Sign iPad, Peripheral)  │            │
                                  /cartL ws     /cartR ws
                                     │               │
                               Left Svelte      Right Svelte
                               (Chromium)       (Chromium)
```

**PitMissionController** is the hub: it connects to the Python server via WebSocket, receives `matchPackage` data, then relays it to `MatchStatusDisplay` over BLE. It also sends cart state changes upstream to the server, which forwards them to the cart browsers.

## Key patterns

### Shared message envelope
All WebSocket and BLE messages use `mainPayload<T>` (in `Shared/MessageStructures.swift`):
```json
{ "type": "matchPackage", "data": [...] }
```
`routeRequest()` in each target decodes the `type` field and dispatches accordingly.

### State enums
`Shared/StateStructures.swift` defines `CartStates`, `SignStates`, and `ControllerSleepStates`. These determine what each display shows. `sharedStates` (a global `SharedStates` instance per target) drives the SwiftUI view hierarchy reactively.

### BLE framing
BLE packets from `BluetoothCentralManager` are length-prefixed: 4-byte big-endian `UInt32` length, then the JSON payload. `BluetoothPeripheralManager` reassembles chunks into complete messages using `incomingBuffer`.

### PopoverCache
`PopoverCache.shared` in PitMissionController caches the last-sent video ID for each popover type (`youtubeLUpdate`, `twitchLUpdate`, etc.). The server also caches these and resends them on reconnect.

## Server state (Python)
`communicationBus` (singleton in `communicationBus.py`) holds live WebSocket references and the last-known values for YouTube/Twitch URLs and `matchCode`. `matchCode` is a TBA event code (e.g. `2025miket`) set by the operator via a popover in the controller app. Match data polls TBA every 10 seconds while a match code is set.

## Network
WebSocket URL is hardcoded in `PitMissionController/WebsocketEngine.swift`:
```swift
public var socket = WebSocketManager(urlString: "ws://192.168.105.10:1701/missionController")
```
This is the competition field network IP. Change it for local development (a commented-out alternative is present in the file).

## Team number
The team is **1701**. `MatchBoard.swift` highlights team 1701 with a special maroon background in the match lineup. `tba.py` queries `frc1701`'s matches from TBA.
