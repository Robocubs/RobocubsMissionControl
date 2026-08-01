#!/bin/bash
#
# deployBranch.sh — switch the Pi's checkout to a known branch and restart
# missionControlServer.service.
#
# Run manually over SSH, e.g.:
#   ssh missioncontrol@192.168.105.10 '~/deployBranch.sh ground-control'
#
# IMPORTANT: install and run the copy at ~/deployBranch.sh, NOT this in-repo
# path. Bash reads scripts incrementally from an open fd, so a script
# executing from inside the tree it is about to check out can have itself
# rewritten mid-run by the very checkout it's performing.
#
# IMPORTANT: the restart below is a plain, blocking `systemctl restart`. That
# is only correct because this script is invoked over SSH, where it runs in
# the login session's cgroup, not the service's — systemd's default
# KillMode=control-group never touches it, and blocking lets you see the
# restart actually finish before the command returns. If this is ever wired
# up to be spawned FROM missionControlServer.service itself (e.g. triggered
# by a websocket message), a blocking restart will DEADLOCK: the manager
# waits for the unit's cgroup to empty before restarting it, and that cgroup
# would contain this script, which is itself waiting on `systemctl`. Don't
# copy this pattern into that context without switching to
# `systemctl restart --no-block` and rethinking the rest.
#
# Usage: deployBranch.sh <ground-control|main>

set -euo pipefail

# --- configuration -----------------------------------------------------
# Paths below are taken from missionControlServer.service (WorkingDirectory /
# ExecStart), not verified against the actual Pi. Adjust here if they differ.
repoRoot="/home/missioncontrol/RobocubsMissionControl"
serverDirectory="$repoRoot/CartInformationDisplays"
serviceName="missionControlServer.service"

export GIT_TERMINAL_PROMPT=0   # never hang on a credential prompt

# --- validate argument ---------------------------------------------------
targetBranch="${1:-}"
case "$targetBranch" in
    ground-control|main)
        ;;
    *)
        echo "usage: $0 <ground-control|main>" >&2
        echo "refusing unknown branch: '$targetBranch'" >&2
        exit 1
        ;;
esac

cd "$repoRoot"

echo "==> requested branch: $targetBranch"

# --- preflight on current state ------------------------------------------
currentBranch="$(git branch --show-current)"
if [[ -z "$currentBranch" ]]; then
    echo "refusing: repo is in a detached HEAD state" >&2
    exit 1
fi

if [[ "$currentBranch" == "$targetBranch" ]]; then
    echo "already on $targetBranch, nothing to do"
    exit 0
fi

if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
    echo "refusing: working tree has local modifications:" >&2
    git status --porcelain --untracked-files=no >&2
    exit 1
fi

# --- fetch + checkout ------------------------------------------------------
# The competition hotspot usually has no WAN. Fall back to whatever refs were
# fetched last time we had internet rather than failing the deploy outright.
if timeout 60 git fetch --prune origin; then
    git checkout -B "$targetBranch" "origin/$targetBranch"
else
    echo "WARNING: git fetch failed (offline?), falling back to local refs" >&2
    git checkout "$targetBranch"
fi

echo "==> checked out $targetBranch at $(git rev-parse --short HEAD)"

# --- anti-bricking preflight -----------------------------------------------
# main.py mounts frontend/prod as StaticFiles at import time, so a missing
# build directory or a syntax error means the server crash-loops on restart
# (Restart=always) with no websocket left to switch back with. Verify first,
# and roll back rather than restart into a branch that cannot boot.
rollback() {
    echo "PREFLIGHT FAILED: $*" >&2
    echo "==> rolling back to $currentBranch" >&2
    if git checkout -f "$currentBranch"; then
        echo "rolled back to $currentBranch; service was NOT restarted" >&2
    else
        echo "ROLLBACK TO $currentBranch ALSO FAILED - manual SSH required" >&2
    fi
    exit 1
}

[[ -f "$serverDirectory/frontend/prod/left.html" ]] \
    || rollback "frontend/prod/left.html missing on $targetBranch"
[[ -f "$serverDirectory/frontend/prod/right.html" ]] \
    || rollback "frontend/prod/right.html missing on $targetBranch"

"$serverDirectory/venv/bin/python" -m py_compile "$serverDirectory"/*.py \
    || rollback "python syntax check failed on $targetBranch"

echo "==> preflight passed"

# --- restart -----------------------------------------------------------
# See the block comment at the top of this file: blocking is correct here
# because we are outside the service's cgroup (invoked over SSH).
sudo systemctl restart "$serviceName"

echo "==> now on $(git branch --show-current), service is $(systemctl is-active "$serviceName")"
