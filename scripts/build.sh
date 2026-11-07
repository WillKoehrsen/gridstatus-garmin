#!/usr/bin/env bash
# Builds the keyless app, which reads its API key from the app setting.
# Usage: scripts/build.sh [output path] [extra monkeyc arguments]
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

output_path="${1:-bin/GridStatus.prg}"
shift $(($# > 0 ? 1 : 0))
device="${GRIDSTATUS_DEVICE:-fr255m}"
developer_key="${CONNECTIQ_DEVELOPER_KEY:-$HOME/.connectiq/developer_key.der}"

mkdir -p "$(dirname "$output_path")"
monkeyc -d "$device" -f monkey.jungle -o "$output_path" -y "$developer_key" -l 2 -w "$@"
