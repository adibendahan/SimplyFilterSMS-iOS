#!/bin/bash
set -euo pipefail

PROJECT="Simply Filter SMS.xcodeproj"
SCHEME="UI Tests"
TEST_ID="UI Tests/SnapshotsTestCase/testCreateSnapshots"
LANGUAGES=("he" "ar" "de" "es" "pt-BR" "fr" "it" "ja" "ko" "en")
IPHONE_ID="CE19B2F6-9245-4858-814B-D2A2E819E912"
IPAD_ID="88F7DBC3-6E7E-4478-A2B0-B4F48D0B58BC"

boot_simulator() {
    local device_id="$1"
    local state
    state=$(xcrun simctl list devices | grep "$device_id" | grep -o "(Booted)\|(Shutdown)" | head -1)
    if [ "$state" != "(Booted)" ]; then
        echo "Booting simulator $device_id..."
        xcrun simctl boot "$device_id"
        sleep 3
    fi
}

set_simulator_language() {
    local device_id="$1"
    local lang="$2"
    xcrun simctl shutdown "$device_id" >/dev/null 2>&1 || true
    xcrun simctl boot "$device_id"
    sleep 2
    xcrun simctl spawn "$device_id" defaults write .GlobalPreferences AppleLanguages -array "$lang"
    xcrun simctl spawn "$device_id" defaults write .GlobalPreferences AppleLocale -string "$lang"
    xcrun simctl shutdown "$device_id"
    xcrun simctl boot "$device_id"
    sleep 3
}

run_screenshots() {
    local device_id="$1"
    local device_name="$2"
    echo "=== $device_name ==="
    boot_simulator "$device_id"
    for lang in "${LANGUAGES[@]}"; do
        echo "--- $lang ---"
        set_simulator_language "$device_id" "$lang"
        xcodebuild test \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,id=$device_id" \
            -only-testing "$TEST_ID" \
            2>&1 | tee /tmp/sfs-screenshots.log | grep -E "error:|warning:|Test Case|📸|failed|passed"
    done
}

run_screenshots "$IPHONE_ID" "iPhone 17 Pro Max (26.1)"
run_screenshots "$IPAD_ID" "iPad Pro 13-inch (M5) (26.1)"

echo "Done. Screenshots saved to .screenshots/"
