#!/usr/bin/env bash
# Builds a personal copy with the API key compiled in, because a sideloaded app's settings can't be edited.
# Never share or publish the output.
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

output_path="bin/GridStatusSideload.prg"
device="${GRIDSTATUS_DEVICE:-fr255m}"
developer_key="${CONNECTIQ_DEVELOPER_KEY:-$HOME/.connectiq/developer_key.der}"
fallback_environment_file="$repository_root/.env"

api_key="${GRIDSTATUS_API_KEY:-}"
if [[ -z "$api_key" && -f "$fallback_environment_file" ]]; then
    api_key="$(grep '^GRIDSTATUS_API_KEY=' "$fallback_environment_file" | head -1 | cut -d= -f2- | tr -d '"' || true)"
fi
if [[ ! "$api_key" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo "GRIDSTATUS_API_KEY is missing or has unexpected characters" >&2
    exit 1
fi

mkdir -p resources-local bin
(
    umask 077
    printf '<properties>\n    <property id="apiKey" type="string">%s</property>\n</properties>\n' "$api_key" > resources-local/properties.xml
)

monkeyc -d "$device" -f "monkey.jungle;sideload.jungle" -o "$output_path" -y "$developer_key" -l 2 -w
