#!/bin/bash
# Builds Headroom, signs it with a Developer ID certificate, has Apple
# notarize it, and packages build/release/Headroom.zip for a GitHub release.
#
# One-time setup, which stores your notary credentials in the keychain:
#   xcrun notarytool store-credentials headroom \
#       --apple-id <your Apple ID> --team-id <your team ID>
#
# Usage:
#   TEAM_ID=<your team ID> scripts/release.sh
set -euo pipefail

: "${TEAM_ID:?Set TEAM_ID to your Apple Developer team ID}"
NOTARY_PROFILE="${NOTARY_PROFILE:-headroom}"

BUILD_DIR="build/release"
APP="$BUILD_DIR/Build/Products/Release/Headroom.app"
ZIP="$BUILD_DIR/Headroom.zip"
RESULT="$BUILD_DIR/notarization.json"

rm -rf "$BUILD_DIR"

echo "==> Building and signing with Developer ID"
xcodebuild -quiet \
    -project Headroom.xcodeproj \
    -scheme Headroom \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    OTHER_CODE_SIGN_FLAGS="--timestamp" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    build
codesign --verify --strict "$APP"

echo "==> Sending to Apple for notarization (usually 1-5 minutes)"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait \
    --output-format json > "$RESULT" || true

status="$(plutil -extract status raw "$RESULT" 2>/dev/null || echo "unknown")"
if [[ "$status" != "Accepted" ]]; then
    rm -f "$ZIP"
    echo "Notarization did not succeed (status: $status)." >&2
    if submission="$(plutil -extract id raw "$RESULT" 2>/dev/null)"; then
        xcrun notarytool log "$submission" --keychain-profile "$NOTARY_PROFILE" >&2
    else
        cat "$RESULT" >&2
    fi
    exit 1
fi

echo "==> Attaching the notarization ticket"
xcrun stapler staple "$APP"
rm "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
spctl --assess --type execute "$APP"

echo "Ready: $ZIP"
