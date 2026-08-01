You are verifying the RobocubsMissionControl project end-to-end after a change, before it gets committed and pushed. The goal is regression confidence: confirm nothing that currently works has broken, with extra scrutiny on the two paths the team has called out as most critical — **the YouTube stream playing** and **the match status board updating on both Mission Controller and Match Status Display**.

## Architecture recap

Three independently-deployed pieces glued together by a JSON `{"type", "data"}` websocket protocol:

- **`CartInformationDisplays/`** — a Raspberry Pi. FastAPI backend (`main.py` + `communicationBus.py` + `communicationBuilder.py`) at `ws://<pi>:1701/{cartL,cartR,missionController}`, plus a Svelte/Vite frontend (`frontend/`) built to the git-tracked `frontend/prod/` and shown full-screen in two kiosk Chromium tabs.
- **`PitMissionController`** — the pit crew's iPad app (Xcode target). Connects to the Pi over websocket, drives cart state.
- **`MatchStatusDisplay`** — the "Sign" iPad app (Xcode target). Has **no websocket connection at all** — its only inbound data path is Bluetooth LE from `PitMissionController` (`BluetoothCentralManager.swift` → `BluetoothPeripheralManager.swift`).

Keep that last point in mind for step 4 — it's a hard tooling limitation, not something more setup fixes.

## Prerequisites

Two things unlock full coverage; note whichever is missing and degrade gracefully rather than skipping the section silently:

- **Full Xcode** (not just Command Line Tools) — required for steps 3 and 4. Check with `xcrun --sdk iphonesimulator --show-sdk-path` and `xcrun simctl list devices`; if either errors, only Command Line Tools are installed and those steps fall back to static review (documented in each step below).
- **Claude in Chrome extension connected** — optional, upgrades step 2's frontend check from protocol-level (curl/websocket driving) to actually seeing the YouTube iframe play and the local-video `<video>` element render. Falls back cleanly to protocol-level checks if unavailable. Also note: visually confirming YouTube playback requires real internet egress to youtube.com from wherever the dev server runs — say so if that's not available either.

If either is missing, tell the user exactly what to install/connect and why, then proceed with everything that doesn't need it. Don't block the whole verification on tooling that only one section needs.

## Steps

### 1. Backend — `CartInformationDisplays/*.py`

1. `python3 -m py_compile` every `.py` file in `CartInformationDisplays/` (excluding `frontend/` and `WIP/`).
2. Spin up a throwaway venv, install `requirements.txt` (pin mismatches against the real PyPI index are a known pre-existing issue — install unpinned equivalents if the exact pins 404, and note it rather than let it block verification).
3. Start `main.py`, confirm a clean startup log: both `matchUpdate` and `mediaJanitor` background tasks start, no traceback, `Application startup complete`.
4. **Full existing-protocol regression**, driven by connecting to `/missionController`, `/cartL`, `/cartR` directly (no need for a browser for this part):
   - `state` / `stateL` / `stateR` → forwarded to both carts unchanged, `confirm: true`.
   - `youtubeLUpdate` / `youtubeRUpdate` → forwarded as `youtubeUpdate` to the correct cart only, cached, and replayed on that cart's reconnect. **This is the YouTube-critical path — confirm it byte-for-byte, not just "no exception."**
   - `twitchLUpdate` / `twitchRUpdate` → same pattern.
   - `matchCode` → cached, `confirm: true`.
   - `matchPackage` fetch on mission-controller connect doesn't crash without a real `TBA_API_KEY` (a `matchPackageError` is an acceptable response, a Python traceback is not).
   - Unknown message type → `confirm: false`, no exception.
5. **New local-video protocol**: upload → select → transport command → status forwarded to controller (sided, e.g. `localVideoLStatus`) → library push → delete → reconnect replay on both the cart side (`stateX` + `localVideoResume` with the last known position/paused/muted/loop) and the controller side (library + selection + status).
6. **Media HTTP API**: upload, list, delete, and — the one that matters most for the `<video>` element — a `Range: bytes=0-1023` request against `/media/<id>.mp4` returns `206` with a `Content-Range` header, not `200`.
7. **Janitor**, tested directly against `mediaLibrary.pruneExpired`: an artificially-aged file gets removed; the same file with its id passed in `protectedIds` does *not* get removed even though it's expired; a size cap evicts oldest-first.
8. Clean up: kill the server, `rm -rf CartInformationDisplays/media CartInformationDisplays/__pycache__`, remove the throwaway venv.

### 2. Frontend — `CartInformationDisplays/frontend/`

1. `npm install` if `node_modules` is stale or missing.
2. `npm run check` (svelte-check + tsc) — must be clean. This catches real type errors that `vite build`'s esbuild pass does not (esbuild only strips types, it doesn't check them).
3. `npm run build` — must be clean. Note `frontend/prod/` is git-tracked and Vite content-hashes filenames, so a real deploy needs `git add -A CartInformationDisplays/frontend/prod` (not `git add .`) to stage deletions of stale hashed assets.
4. **Protocol-level regression** (works without a browser): run the Pi backend + `npm run dev`, then drive `/missionController` by hand through every `CartStates` value — `sponsors`, `youtube`, `twitch`, `localvideo`, `screensaver` — confirming `LogicView.svelte`'s view switch lands on the right component each time, and that fetching a video through the dev server's `/media` proxy still returns `206` for a Range request (confirms the proxy config didn't regress it).
5. **If Claude in Chrome is connected**: load `left.html`/`right.html` for real, confirm the YouTube iframe actually renders and plays, the local-video `<video>` element plays with visible controls responding to iPad-sent commands, and the console has no new errors. This is the closest this project gets to an automated check of "the YouTube stream plays."
6. Clean up dev server + test venv.

### 3. PitMissionController (iPad app)

1. Confirm Xcode via the prerequisites check above.
2. **If available**:
   - `xcodebuild build -project RobocubsMissionControl.xcodeproj -scheme PitMissionController -configuration Beta -destination 'platform=iOS Simulator,name=<a booted device>'`
   - Boot a simulator, install and launch the app pointed at a locally-running Pi backend (temporarily edit `serverHost` in `WebsocketEngine.swift`, or run the backend reachable at that address — revert the edit after testing, don't leave it in the diff).
   - Exercise by hand: the YouTube popover (paste a link, confirm the cart state updates), Twitch (same), Local Video (library sheet opens, upload flow completes, transport controls send commands), and the Match Board button (confirms `MatchStore` populates and renders — this is the mission-controller half of the match-board-critical path).
   - Confirm no crash and no new runtime console errors.
3. **If not available**: fall back to a structural review — diff every changed Swift file against `main`, confirm the YouTube/Twitch/`matchPackage`/Bluetooth code paths are behaviorally untouched (same case labels, same function bodies, no signature changes to anything they call), and confirm every new AVFoundation/PhotosUI/URLSession API call has been checked against actual Apple documentation rather than assumed from memory. State plainly in the report that this is not equivalent to a real build and a compile error is still possible.

### 4. MatchStatusDisplay (iPad app)

1. Same Xcode prerequisite as step 3.
2. **If available**: build and run in Simulator, confirm the MatchBoard and Screensaver views render correctly on their own.
3. **Hard limitation regardless of Xcode**: this app's only inbound data path is Bluetooth LE (`BluetoothPeripheralManager.swift` receiving from `PitMissionController`'s `BluetoothCentralManager.swift`). **iOS Simulator does not support CoreBluetooth central/peripheral roles at all** — two simulator instances cannot exchange BLE data with each other. This means the actual "match board updates on both apps" sync can only be *fully* verified on two physical iPads, no matter what's installed on this machine. Say so explicitly rather than implying Simulator testing covers it.
4. Mitigate by checking scope, not by trying to fake BLE: `git diff main -- PitMissionController/BluetoothCentralManager.swift MatchStatusDisplay/BluetoothPeripheralManager.swift Shared/Views/MatchBoard.swift PitMissionController/MatchStore.swift` (adjust paths to whatever the actual match-data files are). If this feature branch touches none of them, say so plainly — that's a real, high-confidence reason to believe the BLE sync path is unaffected, not a shrug.

### 5. Report

Summarize pass/fail per section in one place, list anything skipped and exactly why (missing Xcode, no Chrome extension, no physical iPad), and end with a clear go/no-go recommendation before anything gets committed. Don't bury a skipped check inside a wall of passing ones — call it out where the reader will see it.
