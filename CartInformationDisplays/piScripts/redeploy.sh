#!/bin/bash
#
# redeploy.sh — switch the Pi's checkout to a known branch and reboot so
# missioncontrol.service AND the two cart Chromium kiosk windows both come
# back up fresh.
#
# A plain `systemctl restart` (the old behavior — see git history) only
# refreshes the Python server process. The two Chromium kiosk windows on
# the cart screens keep whatever frontend/prod/ assets they already loaded
# into memory; a server restart alone does not make them reload the page,
# so a frontend-only change would silently not show up on the carts.
# Rebooting is the simplest way to also relaunch Chromium, because how
# those kiosk windows get launched on boot (some sway/systemd autostart
# config) lives on the Pi itself, outside this repo — this script has no
# way to drive that directly, only to trigger the boot sequence that does.
#
# Run manually over SSH, e.g.:
#   ssh missioncontrol@192.168.105.10 '~/redeploy.sh ground-control'
#
# Also runnable as a remote.it Scripting entry (Devices > missioncontrol >
# Scripting > Run Script) with a script argument named "targetBranch"
# (remote.it injects defined script arguments as same-named shell
# variables). Every exit path goes through finish() below, which always
# exits 0 when run via remote.it — a non-zero exit hides the Attributes/
# Device Results panel entirely (verified in checkStatus.sh), and for a
# deploy script that would mean a real failure is invisible with no other
# way to see it short of SSHing in anyway, defeating the point. Over plain
# SSH, finish() still exits with the real status.
#
# CAUTION: test over SSH first, where you can watch it happen, before
# trusting this via remote.it. A reboot takes the Pi off the network for
# the boot duration, so remote.it itself goes unreachable during that
# window — you won't get to watch it come back up, only find out after
# the fact whether it did. This is a bigger blast radius than the old
# restart-only version: a boot failure (bad SD card, power issue, anything
# unrelated to the checked-out code) has no rollback path from here, and
# the only recovery from a bricked boot is physical access, not remote.it.
#
# IMPORTANT: install and run the copy at ~/redeploy.sh, NOT this in-repo
# path. Bash reads scripts incrementally from an open fd, so a script
# executing from inside the tree it is about to check out can have itself
# rewritten mid-run by the very checkout it's performing.
#
# UNVERIFIED: `sudo systemctl reboot` is assumed to work under remote.it
# (unlike over SSH, remote.it likely runs this as root already, in which
# case sudo is a harmless no-op) — not yet confirmed against the live
# device.
#
# Usage: redeploy.sh <ground-control|main>
# remote.it: pass targetBranch as the script argument of the same name.

set -uo pipefail   # no -e: every failure is handled explicitly so finish() always runs

# --- configuration -----------------------------------------------------
# Verified against the actual Pi on 2026-08-17 (repoRoot via `ls ~`).
repoRoot="/home/missioncontrol/RobocubsMissionControl"
serverDirectory="$repoRoot/CartInformationDisplays"

export GIT_TERMINAL_PROMPT=0   # never hang on a credential prompt

viaRemoteIt=0
[[ -n "${GRAPHQL_API_PATH:-}" && -n "${JOB_DEVICE_ID:-}" ]] && viaRemoteIt=1

report() {
    if [[ "$viaRemoteIt" -eq 1 ]]; then
        curl -sf -X POST "https://${GRAPHQL_API_PATH}/job/attribute/${JOB_DEVICE_ID}/$1" \
            -H "Content-Type: text/plain" --data "$2" >/dev/null
    else
        printf '%-8s %s\n' "$1:" "$2"
    fi
}

# finish <exitStatus> <message> — the only way this script should end.
finish() {
    local exitStatus="$1" message="$2"
    report "status" "$message"
    if [[ "$viaRemoteIt" -eq 1 ]]; then
        exit 0
    else
        exit "$exitStatus"
    fi
}

# remote.it runs this script as a different user than missioncontrol (who
# owns the repo), which trips git's dubious-ownership check. Scope the
# exception to this invocation with -c instead of writing a persistent
# `git config --global` on the Pi under an unknown user's $HOME.
gitC() { git -c safe.directory="$repoRoot" "$@"; }

# --- validate argument ---------------------------------------------------
# Positional (SSH) takes priority over $targetBranch (remote.it argument)
# so a manual override always works even if the saved script argument
# is stale.
targetBranch="${1:-${targetBranch:-}}"
case "$targetBranch" in
    ground-control|main)
        ;;
    *)
        finish 1 "refusing: unknown branch '$targetBranch' (usage: redeploy.sh <ground-control|main>)"
        ;;
esac

if ! cd "$repoRoot" 2>&1; then
    finish 1 "repo not found at $repoRoot"
fi

echo "==> requested branch: $targetBranch"

# --- preflight on current state ------------------------------------------
currentBranch="$(gitC branch --show-current 2>&1)"
if [[ -z "$currentBranch" || "$currentBranch" == fatal:* ]]; then
    finish 1 "refusing: repo is in a detached HEAD state or git error: $currentBranch"
fi

if [[ "$currentBranch" == "$targetBranch" ]]; then
    finish 0 "already on $targetBranch, nothing to do (no reboot)"
fi

dirty="$(gitC status --porcelain --untracked-files=no 2>&1)"
if [[ -n "$dirty" ]]; then
    finish 1 "refusing: working tree has local modifications: $dirty"
fi

# --- fetch + checkout ------------------------------------------------------
# The competition hotspot usually has no WAN. Fall back to whatever refs were
# fetched last time we had internet rather than failing the deploy outright.
# Uses `git` directly rather than the gitC wrapper: `timeout` execs its
# argument as a real program, and gitC is a shell function that doesn't
# exist as one, so `timeout 60 gitC ...` would always fail immediately
# with "failed to run command" and silently take the offline fallback path
# every time regardless of actual connectivity.
if timeout 60 git -c safe.directory="$repoRoot" fetch --prune origin; then
    gitC checkout -B "$targetBranch" "origin/$targetBranch" \
        || finish 1 "checkout of origin/$targetBranch failed"
else
    echo "WARNING: git fetch failed (offline?), falling back to local refs" >&2
    gitC checkout "$targetBranch" \
        || finish 1 "checkout of local $targetBranch failed (offline, no cached ref?)"
fi

echo "==> checked out $targetBranch at $(gitC rev-parse --short HEAD 2>&1)"

# --- anti-bricking preflight -----------------------------------------------
# main.py mounts frontend/prod as StaticFiles at import time, so a missing
# build directory or a syntax error means the server crash-loops on boot
# (Restart=always) with no websocket left to switch back with. Verify first,
# and roll back rather than reboot into a branch that cannot boot.
rollback() {
    local reason="$1"
    echo "PREFLIGHT FAILED: $reason" >&2
    if gitC checkout -f "$currentBranch"; then
        finish 1 "PREFLIGHT FAILED: $reason; rolled back to $currentBranch, no reboot triggered"
    else
        finish 1 "PREFLIGHT FAILED: $reason; ROLLBACK TO $currentBranch ALSO FAILED - manual SSH required"
    fi
}

[[ -f "$serverDirectory/frontend/prod/left.html" ]] \
    || rollback "frontend/prod/left.html missing on $targetBranch"
[[ -f "$serverDirectory/frontend/prod/right.html" ]] \
    || rollback "frontend/prod/right.html missing on $targetBranch"

"$serverDirectory/venv/bin/python" -m py_compile "$serverDirectory"/*.py \
    || rollback "python syntax check failed on $targetBranch"

echo "==> preflight passed"

# --- reboot -----------------------------------------------------------
# Report before rebooting, not just after: once `systemctl reboot` starts
# tearing things down, a report() call after it may not complete in time.
report "status" "checked out $targetBranch at $(gitC rev-parse --short HEAD 2>&1), rebooting now"

if ! sudo systemctl reboot; then
    finish 1 "checked out $targetBranch but reboot failed to initiate — manual SSH required"
fi

finish 0 "reboot initiated for $targetBranch"
