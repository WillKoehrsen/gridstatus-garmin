#!/usr/bin/env bash
# Builds the store package, bin/GridStatus.iq, for every watch in manifest.xml. It has no API key; each person enters theirs in Garmin Connect.
# Usage: scripts/package.sh [--beta]
# --beta builds bin/GridStatusBeta.iq under a separate app ID, for uploading as a Connect IQ beta app that only your account can install.
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

production_app_id="eb7f66df14b24636b9e6913e1c78a77b"
beta_app_id="594e9a405bcc4edcb7a68d9997294cf9"
developer_key="${CONNECTIQ_DEVELOPER_KEY:-$HOME/.connectiq/developer_key.der}"

jungles="monkey.jungle"
output_path="bin/GridStatus.iq"
if [[ "${1:-}" == "--beta" ]]; then
    # A jungle can't override another's manifest, so the beta gets its own copy of both files.
    sed "s/$production_app_id/$beta_app_id/" manifest.xml > manifest-beta.xml
    sed "s/^project.manifest = manifest.xml$/project.manifest = manifest-beta.xml/" monkey.jungle > beta.jungle
    jungles="beta.jungle"
    output_path="bin/GridStatusBeta.iq"
fi

mkdir -p bin
monkeyc --package-app --release -f "$jungles" -o "$output_path" -y "$developer_key" -l 2 -w
echo "Wrote $output_path"
