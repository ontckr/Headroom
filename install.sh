#!/bin/bash
# Installs the latest Headroom release into /Applications and opens it.
set -euo pipefail

APP="Headroom.app"
URL="https://github.com/ontckr/Headroom/releases/latest/download/Headroom.zip"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ ! -w /Applications ]]; then
    echo "Can't write to /Applications. Run this from an admin account." >&2
    exit 1
fi

echo "Downloading Headroom..."
curl -fsSL "$URL" -o "$TMP/Headroom.zip"
ditto -x -k "$TMP/Headroom.zip" "$TMP"

pkill -x Headroom 2>/dev/null || true
rm -rf "/Applications/$APP"
mv "$TMP/$APP" /Applications/
xattr -dr com.apple.quarantine "/Applications/$APP" 2>/dev/null || true

open "/Applications/$APP"
echo "Headroom is running. Look for ✦ in your menu bar."
