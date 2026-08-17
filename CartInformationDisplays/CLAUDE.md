# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this component does

Runs on the Raspberry Pi at competition. A single Python process serves as the WebSocket hub between the PitMissionController iPad app and the two pit-cart browser displays. It also polls The Blue Alliance API every 10 seconds and pushes match schedule data to the controller. Two Chromium windows (one per physical screen) connect via WebSocket and render a Svelte frontend.

## Build & run

### Python server
```bash
# from CartInformationDisplays/
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
# create .env with: TBA_API_KEY=<your key>
python main.py   # listens on 0.0.0.0:1701
```
In production, `missioncontrol.service` (systemd) runs this as user `missioncontrol`, restarting every 5 seconds on failure.

### Svelte frontend
```bash
# from CartInformationDisplays/frontend/
npm install
npm run dev      # dev server (see proxy caveat below)
npm run build    # outputs to frontend/prod/ — Python serves this path
npm run check    # svelte-check + tsc
```

### Chromium displays
`chromiumCommands.sh` uses `swaymsg` (Sway compositor) to launch two Chromium kiosk windows after a 5-second boot delay — workspace 1 loads `left.html`, workspace 2 loads `right.html`, both served from `localhost:1701/prod/`.

## Architecture

```
MissionController (iPad)
    │ WebSocket /missionController
    ▼
Python server (port 1701)
    ├─ CommunicationBus (in-memory singleton)
    │   ├─ WebSocket /cartL → Left Svelte (Chromium)
    │   └─ WebSocket /cartR → Right Svelte (Chromium)
    └─ TBA polling loop (asyncio, 10s interval)
```

### Python layer

**`communicationBus.py`** — the central singleton. Holds live WebSocket references for all three clients and caches the last-known values for `youtubeL`, `twitchL`, `youtubeR`, `twitchR`, and `matchCode`. All business logic lives in `recieveMissionController()`.

**`communicationBuilder.py`** — three `WebSocketEndpoint` classes wired up in `main.py`. Each slot is single-occupancy: a new connection force-closes the old one before registering. On reconnect, the server replays cached state so the controller never needs to re-send everything.

**Message routing** (`recieveMissionController`):

| Incoming `type` | Action |
|---|---|
| `state` / `stateL` / `stateR` | Forward `data` to both carts; confirm |
| `youtubeLUpdate` / `youtubeRUpdate` | Cache URL, forward as `youtubeUpdate` to the target cart |
| `twitchLUpdate` / `twitchRUpdate` | Cache channel, forward as `twitchUpdate` to the target cart |
| `matchCode` | Cache event code; confirm (no immediate TBA fetch) |

**`tba.py`** — fetches `frc1701`'s matches for the given event code. Uses ETag caching (`If-None-Match`) to skip unchanged responses; pass `fresh=True` to bypass. Returns matches sorted by `predicted_time`. Requires `TBA_API_KEY` in `.env`.

### Svelte frontend

Two symmetric entry points (`left.html` / `right.html`) each mount a thin root component (`Left.svelte` / `Right.svelte`) that passes `wsEndpoint` and a hardcoded Google Slides `presentationId` to `LogicView.svelte`.

**`LogicView.svelte`** is the real logic. It opens `ws://localhost:1701/{wsEndpoint}` via `websocketTunnel.js` and switches between four views based on incoming messages:

| `type` received | Effect |
|---|---|
| `state` / `stateL` / `stateR` | Sets `currentView` to the `data` value (`screensaver`, `sponsors`, `youtube`, `twitch`) |
| `youtubeUpdate` | Updates `videoID` |
| `twitchUpdate` | Updates `channel` |

Views: `Screensaver` (fullscreen image), `Sponsors` (Google Slides iframe, auto-advancing), `YouTube` (nocookie embed, autoplay muted), `Twitch` (player embed, muted).

## Non-obvious details

**Monkey-patch on line 2 of `main.py`:** `WebSocket.__init__.__defaults__` is patched to fix a Starlette/websockets version incompatibility. Don't remove it without verifying the dependency versions are aligned.

**`stateL`/`stateR` differentiation is client-side:** The server forwards all three state types to both carts. `LogicView.svelte` ignores messages not matching its side. A `stateR` message sent to the left cart is silently dropped.

**Vite dev proxy is broken (`vite.config.ts`):** The dev server proxies `/cartL` and `/cartR` WebSocket traffic to `ws://localhost:8010`, but the Python server runs on port `1701`. This is a stale config — change the proxy target to `ws://localhost:1701` before running `npm run dev`, or open `http://localhost:5173/prod/left.html` and let `LogicView.svelte` connect to port 1701 directly (it hardcodes `localhost:1701`).

**`base: '/prod/'` in Vite config:** All built asset paths are prefixed with `/prod/` to match the FastAPI static mount. This is why `Screensaver.svelte` uses `/prod/pitCart-${position}.png` as an absolute path.

**`CurrentMatch.svelte` is orphaned:** It renders a static mock and is not referenced in `LogicView.svelte`. The `WIP/` directory contains a scrapped Qt/QML implementation — both are dead code.

**Twitch `parent=localhost`:** The Twitch embed only works when the page is served from `localhost`. It will not load if the server IP is used directly.

## Local development

- Run the Python server locally (`python main.py`) and use `npm run dev` for the Svelte frontend. Fix the proxy port (see above) or connect directly to `localhost:1701`.
- The Xcode iOS targets can be run in the Simulator for UI work, but BLE is unavailable in simulation. Use the commented-out sample data in `MatchStore.init()` to stub match data.

## Environment

- `TBA_API_KEY` — required in `.env`; without it all TBA fetches return `[]`
- Team number `frc1701` and server port `1701` are hardcoded (not env-configurable)
- Google Slides presentation IDs are hardcoded in `Left.svelte` and `Right.svelte`
- Server IP `192.168.105.10` is stable — the Pi is always at this address on the team's dedicated competition hotspot. Change it in `WebsocketEngine.swift` only for local dev.
- `matchUpdate` in `MessageStructures.swift` is dead code — incremental match updates were planned but never implemented. Whole-array replacement via `matchPackage` is the permanent design.
