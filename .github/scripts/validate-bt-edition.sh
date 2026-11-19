#!/usr/bin/env bash
# Compile the BT Edition with ESPHome to prove the merged file actually builds.
# The device is provisioned via Improv so the file has no Wi-Fi credentials;
# a throwaway wrapper adds dummy ones purely so validation can run.
# Usage: validate-bt-edition.sh [config|compile]   (default: compile)
set -euo pipefail

MODE="${1:-compile}"
BT="home-assistant-voice-BT-Edition.yaml"
WRAPPER="_ci_bt_validate.yaml"

trap 'rm -f "$WRAPPER"' EXIT
cat > "$WRAPPER" <<EOF
packages:
  bt: !include $BT
wifi:
  ssid: ci-dummy-ssid
  password: ci-dummy-password
EOF

if grep -qE '^(<<<<<<<|>>>>>>>)' "$BT"; then
  echo "::error::$BT still contains merge conflict markers"
  exit 1
fi

esphome "$MODE" "$WRAPPER"
