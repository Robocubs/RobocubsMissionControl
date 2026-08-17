#!/bin/bash
#
# checkStatus.sh — report which branch/commit the Pi is running and whether
# missioncontrol.service is healthy, without SSHing in.
#
# Intended to run as a remote.it Scripting entry (Devices > missioncontrol >
# Scripting > Run Script) so it's a one-tap check from the app instead of a
# full SSH session. Read-only: does not fetch, checkout, or restart anything.
#
# remote.it Scripting does NOT capture plain stdout/echo. Values only show
# up in the "Device Results" / Attributes panel if explicitly POSTed via the
# job/attribute API, using the JOB_DEVICE_ID / GRAPHQL_API_PATH env vars the
# remote.it agent injects into the script's environment. See:
# https://docs.remote.it/developer-tools/device-scripting
#
# Attribute names are numbered (1-status, 2-branch, ...) as an attempt to
# force a readable display order. It didn't work — verified the Device
# Results panel renders them in some order that's neither post order nor
# alphabetical nor numeric — but the numbers are harmless and each value is
# self-labeled regardless, so this is left in rather than ripped back out.
#
# Always exits 0. remote.it hides the Attributes/Device Results panel
# entirely for a FAILED run (verified: attributes posted right before a
# non-zero exit never showed up, even via the run's download button), so
# a hard failure here would throw away the very detail this script exists
# to surface. `1-status` (OK / NEEDS ATTENTION: ...) is the signal instead
# — read it after opening the run rather than from the Runs list color.
#
# Usage: checkStatus.sh

set -uo pipefail   # no -e: keep reporting remaining attributes even if one step errors

repoRoot="/home/missioncontrol/RobocubsMissionControl"
serviceName="missioncontrol.service"
knownBranches=("ground-control" "main")   # kept in sync with deployBranch.sh's targetBranch check

report() {
    curl -sf -X POST "https://${GRAPHQL_API_PATH}/job/attribute/${JOB_DEVICE_ID}/$1" \
        -H "Content-Type: text/plain" --data "$2" >/dev/null
}

# remote.it runs this script as a different user than missioncontrol (who
# owns the repo), which trips git's dubious-ownership check. Scope the
# exception to this invocation with -c instead of writing a persistent
# `git config --global` on the Pi under an unknown user's $HOME.
gitC() { git -c safe.directory="$repoRoot" "$@"; }

issues=()

if ! cd "$repoRoot" 2>&1; then
    report "1-status" "NEEDS ATTENTION: repo not found at $repoRoot"
    report "2-branch" "error: cd failed"
    exit 0
fi

branch="$(gitC branch --show-current 2>&1)"
if [[ "$branch" == fatal:* || "$branch" == error:* ]]; then
    issues+=("git error reading branch: $branch")
elif [[ -z "$branch" ]]; then
    issues+=("detached HEAD")
elif ! printf '%s\n' "${knownBranches[@]}" | grep -qx "$branch"; then
    issues+=("unexpected branch '$branch' (expected: ${knownBranches[*]})")
fi
report "2-branch" "${branch:-(detached HEAD)}"

statusOutput="$(gitC status --porcelain --untracked-files=no 2>&1)"
if [[ $? -ne 0 ]]; then
    issues+=("git status failed: $statusOutput")
    report "3-tree" "error"
elif [[ -n "$statusOutput" ]]; then
    issues+=("working tree has local modifications")
    report "3-tree" "dirty"
else
    report "3-tree" "clean"
fi

serviceState="$(systemctl is-active "$serviceName" 2>&1)"
serviceEnabled="$(systemctl is-enabled "$serviceName" 2>&1)"
[[ "$serviceState" == "active" ]] || issues+=("$serviceName is $serviceState")
report "4-service" "$serviceState, $serviceEnabled"

report "5-since" "$(systemctl show "$serviceName" --property=ActiveEnterTimestamp --value 2>&1)"
report "6-commit" "$(gitC rev-parse --short HEAD 2>&1): $(gitC log -1 --format=%s 2>&1)"

if [[ ${#issues[@]} -gt 0 ]]; then
    report "1-status" "NEEDS ATTENTION: $(IFS='; '; echo "${issues[*]}")"
else
    report "1-status" "OK"
fi
