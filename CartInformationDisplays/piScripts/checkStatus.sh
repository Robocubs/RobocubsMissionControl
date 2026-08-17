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
# Usage: checkStatus.sh

set -uo pipefail   # no -e: keep reporting remaining attributes even if one step errors

repoRoot="/home/missioncontrol/RobocubsMissionControl"
serviceName="missioncontrol.service"

report() {
    curl -sf -X POST "https://${GRAPHQL_API_PATH}/job/attribute/${JOB_DEVICE_ID}/$1" \
        -H "Content-Type: text/plain" --data "$2" >/dev/null
}

# remote.it runs this script as a different user than missioncontrol (who
# owns the repo), which trips git's dubious-ownership check. Scope the
# exception to this invocation with -c instead of writing a persistent
# `git config --global` on the Pi under an unknown user's $HOME.
gitC() { git -c safe.directory="$repoRoot" "$@"; }

if ! cd "$repoRoot" 2>&1; then
    report "error" "cd to $repoRoot failed"
    exit 1
fi

branch="$(gitC branch --show-current 2>&1)"
report "branch" "${branch:-(detached HEAD or error: $branch)}"

report "commit" "$(gitC rev-parse --short HEAD 2>&1) - $(gitC log -1 --format=%s 2>&1)"

statusOutput="$(gitC status --porcelain --untracked-files=no 2>&1)"
if [[ $? -ne 0 ]]; then
    report "tree" "error: $statusOutput"
elif [[ -n "$statusOutput" ]]; then
    report "tree" "dirty"
else
    report "tree" "clean"
fi

report "service" "$(systemctl is-active "$serviceName" 2>&1) (enabled: $(systemctl is-enabled "$serviceName" 2>&1))"
report "since" "$(systemctl show "$serviceName" --property=ActiveEnterTimestamp --value 2>&1)"
