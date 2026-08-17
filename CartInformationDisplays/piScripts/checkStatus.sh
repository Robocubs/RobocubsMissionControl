#!/bin/bash
#
# checkStatus.sh — report which branch/commit the Pi is running and whether
# missioncontrol.service is healthy, without SSHing in.
#
# Intended to run as a remote.it Scripting entry (Devices > missioncontrol >
# Scripting > Run Script) so it's a one-tap check from the app instead of a
# full SSH session. Read-only: does not fetch, checkout, or restart anything.
#
# Also runnable directly over SSH for a manual check. remote.it Scripting
# does NOT capture plain stdout/echo — values only show up in the "Device
# Results" / Attributes panel if explicitly POSTed via the job/attribute
# API, using the JOB_DEVICE_ID / GRAPHQL_API_PATH env vars the remote.it
# agent injects into the script's environment (see:
# https://docs.remote.it/developer-tools/device-scripting). Those env vars
# don't exist outside that context, so report() below falls back to a
# plain echo when they're unset — which also sidesteps the display-order
# problem entirely, since a terminal prints in the order you tell it to.
#
# Device Results display order is NOT controllable. Verified against two
# different post orders (neither reproduced), and confirmed against
# remote.it's docs: the underlying Device Attributes model is just
# id/name/value/created — no order/sortOrder/index/position field exists,
# and the docs don't say how the UI sorts what it shows. Reported as
# separate attributes anyway (rather than one preformatted blob) because
# that's the more useful read in the Device Results panel; just don't
# expect them in a particular order.
#
# Always exits 0. remote.it hides the Attributes/Device Results panel
# entirely for a FAILED run (verified: attributes posted right before a
# non-zero exit never showed up, even via the run's download button), so
# a hard failure here would throw away the very detail this script exists
# to surface. `status` (OK / NEEDS ATTENTION: ...) is the signal instead
# — read it after opening the run rather than from the Runs list color.
#
# Usage: checkStatus.sh

set -uo pipefail   # no -e: keep gathering remaining values even if one step errors

repoRoot="/home/missioncontrol/RobocubsMissionControl"
serviceName="missioncontrol.service"
knownBranches=("ground-control" "main")   # kept in sync with redeploy.sh's targetBranch check

if [[ -n "${GRAPHQL_API_PATH:-}" && -n "${JOB_DEVICE_ID:-}" ]]; then
    report() {
        curl -sf -X POST "https://${GRAPHQL_API_PATH}/job/attribute/${JOB_DEVICE_ID}/$1" \
            -H "Content-Type: text/plain" --data "$2" >/dev/null
    }
else
    report() {
        printf '%-8s %s\n' "$1:" "$2"
    }
fi

# remote.it runs this script as a different user than missioncontrol (who
# owns the repo), which trips git's dubious-ownership check. Scope the
# exception to this invocation with -c instead of writing a persistent
# `git config --global` on the Pi under an unknown user's $HOME.
gitC() { git -c safe.directory="$repoRoot" "$@"; }

if ! cd "$repoRoot" 2>&1; then
    report "status" "NEEDS ATTENTION: repo not found at $repoRoot"
    exit 0
fi

issues=()

branch="$(gitC branch --show-current 2>&1)"
if [[ "$branch" == fatal:* || "$branch" == error:* ]]; then
    issues+=("git error reading branch: $branch")
elif [[ -z "$branch" ]]; then
    issues+=("detached HEAD")
elif ! printf '%s\n' "${knownBranches[@]}" | grep -qx "$branch"; then
    issues+=("unexpected branch '$branch' (expected: ${knownBranches[*]})")
fi
branch="${branch:-(detached HEAD)}"

statusOutput="$(gitC status --porcelain --untracked-files=no 2>&1)"
if [[ $? -ne 0 ]]; then
    issues+=("git status failed: $statusOutput")
    tree="error"
elif [[ -n "$statusOutput" ]]; then
    issues+=("working tree has local modifications")
    tree="dirty"
else
    tree="clean"
fi

commit="$(gitC rev-parse --short HEAD 2>&1): $(gitC log -1 --format=%s 2>&1)"

serviceState="$(systemctl is-active "$serviceName" 2>&1)"
serviceEnabled="$(systemctl is-enabled "$serviceName" 2>&1)"
[[ "$serviceState" == "active" ]] || issues+=("$serviceName is $serviceState")
service="$serviceState, $serviceEnabled"

since="$(systemctl show "$serviceName" --property=ActiveEnterTimestamp --value 2>&1)"

if [[ ${#issues[@]} -gt 0 ]]; then
    status="NEEDS ATTENTION: $(IFS='; '; echo "${issues[*]}")"
else
    status="OK"
fi

report "status" "$status"
report "branch" "$branch"
report "tree" "$tree"
report "commit" "$commit"
report "service" "$service"
report "since" "$since"
