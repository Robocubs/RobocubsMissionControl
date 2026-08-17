# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app does

PitMissionController is the operator control panel iPad app. It is the hub of the entire system — it connects via WebSocket to the Python server and controls all display surfaces:
- **Left/Right cart screens** — commands sent via WebSocket → server → Chromium
- **Sign** (MatchStatusDisplay iPad) — commands sent directly over Bluetooth LE
- **The controller iPad itself** — local idle/sleep mode switching, no network message sent

## Build & run

Open `RobocubsMissionControl.xcodeproj` in Xcode and select the **PitMissionController** target. Must be deployed to a physical iPad for BLE — the Xcode Simulator can run the app but BLE central mode won't work, so the Sign column will be non-functional.

The server IP is hardcoded in `WebsocketEngine.swift:86`:
```swift
public var socket = WebSocketManager(urlString: "ws://192.168.105.10:1701/missionController")
```
`192.168.105.10` is the Pi's stable address on the team's dedicated competition hotspot. Change this to your local machine's IP when developing against a local server. A commented-out alternate address is already in the same file.

## Architecture

```
ViewController
├── TimeoutManager (5s inactivity → overlay)
├── Control (active)
│   ├── ControlButton × N  →  socket.sendMessage / BluetoothCentralManager.sendData
│   └── TextFieldPopover (sheets for URL/code entry)
└── MatchBoard or Screensaver (idle overlay, from Shared/)
```

### WebSocket (`WebsocketEngine.swift`)

`WebSocketManager` connects on `ViewController.onAppear`. It uses a recursive `listen()` call — each successful receive calls `routeRequest(text)` then re-calls `listen()`. On error it reconnects with a flat 2-second delay (no backoff). `isConnected` is set optimistically on `connect()` before handshake.

On reconnect, `connect()` resets `sharedStates.stateL` and `.stateR` to `.Screensaver` — the UI resets to screensaver state after any reconnect even though the actual cart screens are unaffected.

### Bluetooth Central (`BluetoothCentralManager.swift`)

Singleton initialized lazily on first access. Scans for the service UUID `A12BBDA7-05D4-431B-B3B9-10846BA909FB`, connects to the first peripheral found (the sign iPad), and auto-resumes scanning on disconnect.

Data is sent in 20-byte chunks with a 4-byte big-endian length prefix (matches the reassembly logic in `BluetoothPeripheralManager`). The MTU is hardcoded at 20 (the BLE minimum) rather than negotiated — a known inefficiency.

`prepareData<T: Codable>(type:data:)` encodes a `mainPayload<T>` into JSON `Data` for BLE transmission.

### Message routing (`RequestRouter.swift`)

Free function called on each incoming WebSocket message:

| `type` | Action |
|---|---|
| `"matchPackage"` | Updates `MatchStore.shared.matches` on main thread; **also passes the raw UTF-8 bytes directly to BLE** (no re-encoding) |
| `"confirm"` | Prints the ack string; no UI effect |
| `"twitchLUpdate"`, `"twitchRUpdate"`, `"youtubeLUpdate"`, `"youtubeRUpdate"`, `"matchBoard"`, `"matchCode"` | Stores value in `PopoverCache.shared` (server-replayed cached state on reconnect) |

### State (`SharedStates.swift`)

Module-level global `let sharedStates = SharedStates()` with four `@Published` properties:
- `stateL: CartStates` / `stateR: CartStates` — left/right cart states
- `sign: SignStates` — sign state
- `controllerSleep: ControllerSleepStates` — the iPad's own idle view

`PopoverCache.shared` caches the last-submitted value per popover type (`twitchLUpdate`, `youtubeLUpdate`, etc.) so `TextFieldPopover` can pre-populate fields. Updated both by user submission and by server replay on reconnect.

### Views

**`ViewController`** owns `TimeoutManager` (5s timeout). On timeout it crossfades (0.6s) to the idle overlay; tapping wakes it (0.2s crossfade back). Popovers pause the timer. Transition uses cancellable `Task` — tapping mid-fade cancels and reverses.

**`Control`** has four columns (Left, Right, Sign, Controller), each containing `ControlButton`s. The `matchCodePopover` binding is shared between the Sign and Controller "Match Board" buttons.

**`ControlButton<State: DisplayState>`** — generic over any `DisplayState` type. Tap behavior varies by `Target`:
- `.left` / `.right` → update local state + `socket.sendMessage`
- `.sign` → encode `mainPayload<SignStates>` + `BluetoothCentralManager.shared.sendData` (no WebSocket)
- `.controller` → update local `controllerSleep` only (no network message)

Long-press (0.5s) opens the popover via `popoverControl?.wrappedValue = true`.

**`TextFieldPopover`** handles smart URL parsing: YouTube extracts `?v=` param (or `lastPathComponent` for `/live/` and `youtu.be/` URLs), Twitch extracts `lastPathComponent`. Stores and sends only the bare ID, but displays the full URL to the user.

## Shared/ code

`Shared/` is compiled into this target. Key files:
- `MessageStructures.swift` — `mainPayload<T>`, `matchPackage`; `matchUpdate` is dead code (incremental updates were planned but never implemented — whole-array `matchPackage` is the permanent design)
- `StateStructures.swift` — `CartStates`, `SignStates`, `ControllerSleepStates`
- `Matches.swift` — `MatchStore` singleton
- `Views/MatchBoard.swift` — scrollable match schedule (highlights team 1701 with dark-red pill)
- `Views/Screensaver.swift` — full-screen screensaver; accepts optional `buttonInteraction` closure

## Known issues / notes

- BLE MTU hardcoded at 20 bytes; `peripheral.maximumWriteValueLength(for:)` would yield 182+ bytes on modern iOS, reducing packet count significantly.
- `ControlButton` uses force-casts (`as! CartStates`, etc.) — relies on `Control.swift` always pairing types and targets correctly.
- `BluetoothCentralManager.shared` is lazily initialized on first access; scanning doesn't begin until something first touches the singleton.
- Auto-scroll in `MatchBoard` is implemented but commented out.
- `MatchStore.init()` has a commented-out block of 14 sample matches for dev testing.
