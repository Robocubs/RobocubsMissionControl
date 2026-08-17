# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app does

MatchStatusDisplay is an iPad app that functions as a permanently-mounted scoreboard sign during FRC competition events. It has no user interaction — it receives commands over Bluetooth LE from the PitMissionController app and renders either a live match schedule (`MatchBoard`) or a screensaver. The idle timer is disabled so the screen never sleeps.

## Build & run

Open `RobocubsMissionControl.xcodeproj` in Xcode and select the **MatchStatusDisplay** target. Must be deployed to a physical iPad — BLE peripheral mode requires real hardware. The Simulator can render the views but cannot advertise as a BLE peripheral.

## Architecture

```
MatchStatusDisplayApp (@main)
└── WindowGroup
    └── ViewController  ← observes sharedStates
        ├── sign == .MatchBoard  → MatchBoard   (from Shared/)
        └── sign == .Screensaver → Screensaver  (from Shared/)
```

BLE advertising starts immediately in `ViewController.init()` (not `.onAppear`) by forcing `BluetoothPeripheralManager.shared` to initialize. This gets the peripheral advertising before the first SwiftUI render cycle.

### Bluetooth peripheral

`BluetoothPeripheralManager` advertises as `"Match Status Display"`. Incoming BLE writes are chunked (20-byte MTU), so `BluetoothPeripheralManager` reassembles them using `incomingBuffer: Data` with a 4-byte big-endian length prefix. The loop in `didReceiveWrite` extracts complete messages and calls `routeRequest(_:)`.

Service UUID: `A12BBDA7-05D4-431B-B3B9-10846BA909FB`  
Characteristic UUID: `3B06B2B0-DDAC-4A7F-AD9B-85C46CC32FCA`

### Message routing

`routeRequest(_:Data)` is a free function in `RequestRouter.swift`. It decodes the `type` field from the `mainPayload<T>` JSON envelope and dispatches:

| `type` | Action |
|---|---|
| `"matchPackage"` | Replaces `MatchStore.shared.matches` wholesale with the new `[matchPackage]` array |
| `"stateSign"` | Sets `sharedStates.sign` to `.MatchBoard` or `.Screensaver` |

### State

Two global singletons (not SwiftUI environment objects — they must be reachable from the free `routeRequest` function):

- `sharedStates: SharedStates` — holds `@Published var sign: SignStates`, defaults to `.Screensaver`
- `MatchStore.shared` — holds `@Published var matches: [matchPackage]`, defaults to empty

Match data is always replaced in full. The `matchUpdate` struct in `MessageStructures.swift` is dead code — incremental updates were planned but never implemented.

## Shared/ code

`Shared/` is compiled into this target. Key files:
- `MessageStructures.swift` — `mainPayload<T>`, `matchPackage`, `matchUpdate`
- `StateStructures.swift` — `SignStates`, `CartStates`, `ControllerSleepStates`
- `Matches.swift` — `MatchStore` singleton
- `Views/MatchBoard.swift` — scrollable match schedule view; highlights team 1701 with a dark-red pill
- `Views/Screensaver.swift` — full-screen screensaver

Both shared views accept an optional `buttonInteraction: (() -> Void)?` closure (unused / nil in this target; wired up in PitMissionController for tap-to-wake behavior).

## Known issues / latent bugs

- `routeRequest` mutates `MatchStore.shared.matches` and `sharedStates.sign` directly from the BLE callback queue without dispatching to `DispatchQueue.main`. This is a data race with SwiftUI's main-thread rendering.
- The `sendNumber(_:)` method on `BluetoothPeripheralManager` (for notifying centrals) is never called — placeholder for future bidirectional comms.
- Auto-scroll in `MatchBoard` is implemented but commented out.
- Info.plist declares `bluetooth-central` background mode even though only peripheral mode is used.
