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

1. Confirm Xcode via the prerequisites check above. If `xcode-select -p` prints `/Library/Developer/CommandLineTools` instead of an Xcode.app path even though Xcode is installed, it needs `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` — **and that must be run by the user in a real terminal window they opened themselves**, not via a `!`-prefixed command in this session; `sudo` there has no TTY to prompt on and fails every time.
2. **If available**:
   - Real build command (tested, works as of Xcode 26.6):
     ```
     xcodebuild build -project RobocubsMissionControl.xcodeproj -scheme PitMissionController \
       -configuration Beta -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'
     ```
     Swap the device name for whatever `xcrun simctl list devices available` shows. Grep the output for `error:` — don't trust "BUILD SUCCEEDED" alone if you scrolled past a failed-then-recovered step; grep is more reliable than reading tail output.
   - Boot + install + launch + screenshot, tested pattern:
     ```
     xcrun simctl boot "iPad Pro 13-inch (M5)"
     xcrun simctl install "iPad Pro 13-inch (M5)" <path to .app in DerivedData/Build/Products/Beta-iphonesimulator/>
     xcrun simctl launch "iPad Pro 13-inch (M5)" $(plutil -extract CFBundleIdentifier raw <app>/Info.plist)
     xcrun simctl io "iPad Pro 13-inch (M5)" screenshot /tmp/shot.png   # then Read the PNG
     ```
     Screenshot immediately (within ~1.5s of launch) if you want the live `Control` view — `ViewController.swift` has a 5-second idle `TimeoutManager` that fades to the branded Screensaver view, which looks identical to a stuck launch screen at a glance. Don't mistake one for the other.
   - Point the app at a locally-running Pi backend by temporarily editing `serverHost` in `WebsocketEngine.swift` to `127.0.0.1:1701` — Simulator shares the host Mac's network stack, so `localhost`/`127.0.0.1` reaches a backend running right there on the Mac directly, no LAN IP needed. **Revert this edit before finishing** (`git checkout -- PitMissionController/WebsocketEngine.swift` if nothing else in that file changed, otherwise edit it back by hand) — never leave a `127.0.0.1` serverHost in a commit.
   - Confirm the connection is real, not just "no crash": `xcrun simctl spawn <device> log show --predicate 'process == "PitMissionController"' --last 1m | grep -i "101\|switching protocols"` — a successful websocket handshake shows `status 101`. Also grep that same log for `fail|error|crash` (excluding the benign `UIFocus`/`EventDeferring` noise every app produces) as a general crash/exception check.
   - To exercise the local-video / library-decode path without UI automation: hit the real HTTP upload endpoint (`curl -X POST --data-binary @clip.mp4 ...`) while the app is connected as the mission controller — the backend pushes a real `localVideoLibrary` message to the live app over its existing websocket, which is a genuine end-to-end test of the actual `MediaItem`/`mainPayload<[MediaItem]>` Swift decode path, not just something type-checked in isolation.
   - There is no XCUITest target in this project and `simctl` cannot synthesize taps, so fully automated button-tap testing (pasting into the YouTube popover, walking through the upload sheet) isn't possible without adding one. Say this plainly rather than claiming interactive flows were "tested" when only launch, connection, rendering, and live decode were.
3. **If not available**: fall back to a structural review — diff every changed Swift file against `main`, confirm the YouTube/Twitch/`matchPackage`/Bluetooth code paths are behaviorally untouched (same case labels, same function bodies, no signature changes to anything they call), and confirm every new AVFoundation/PhotosUI/URLSession API call has been checked against actual Apple documentation rather than assumed from memory. State plainly in the report that this is not equivalent to a real build and a compile error is still possible — SourceKit's live diagnostics in this environment are unreliable for cross-file symbols in new/uncommitted files (confirmed: it flags pre-existing, working symbols like `mainPayload` and `BluetoothCentralManager` as unresolved too) and cannot be trusted as a build substitute either way.

### 4. MatchStatusDisplay (iPad app)

1. Same Xcode prerequisite as step 3, same build/install/launch pattern (bundle id differs — extract it the same way via `plutil -extract CFBundleIdentifier raw`).
2. **If available**: build and run in Simulator, confirm the MatchBoard and Screensaver views render correctly on their own (no websocket to point anywhere for this one — its only inbound path is BLE, see below).
3. **Hard limitation regardless of Xcode, confirmed empirically**: this app's only inbound data path is Bluetooth LE (`BluetoothPeripheralManager.swift` receiving from `PitMissionController`'s `BluetoothCentralManager.swift`). **iOS Simulator does not support CoreBluetooth central/peripheral roles at all.** Launching `MatchStatusDisplay` in Simulator produces `(CoreBluetooth) XPC connection invalid` in the device log every time — this is expected, not a bug, and does not crash the app. Two simulator instances cannot exchange BLE data with each other. The actual "match board updates on both apps" sync can only be *fully* verified on two physical iPads, no matter what's installed on this machine. Say so explicitly rather than implying Simulator testing covers it.
4. Mitigate by checking scope, not by trying to fake BLE: `git diff main -- PitMissionController/BluetoothCentralManager.swift MatchStatusDisplay/BluetoothPeripheralManager.swift Shared/Views/MatchBoard.swift PitMissionController/MatchStore.swift` (adjust paths to whatever the actual match-data files are). If this feature branch touches none of them, say so plainly — that's a real, high-confidence reason to believe the BLE sync path is unaffected, not a shrug.

### 5. Report

Summarize pass/fail per section in one place, list anything skipped and exactly why (missing Xcode, no Chrome extension, no physical iPad), and end with a clear go/no-go recommendation before anything gets committed. Don't bury a skipped check inside a wall of passing ones — call it out where the reader will see it.
