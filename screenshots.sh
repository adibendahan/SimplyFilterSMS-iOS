#!/bin/bash
set -e

PROJECT="Simply Filter SMS.xcodeproj"
SCHEME="UI Tests"
TEST_ID="UI Tests/SnapshotsTestCase/testCreateSnapshots"
LANGUAGES=("he" "ar" "de" "es" "pt-BR" "fr" "it" "ja" "ko" "en")
IPHONE_ID="52CD8CF3-38E9-44DA-91F7-B18E7E3DD7EE"
IPAD_ID="2B6B42CA-E327-44B4-B97F-6E6F3C1AD039"

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
    xcrun simctl spawn "$device_id" defaults write .GlobalPreferences AppleLanguages -array "$lang"
    xcrun simctl spawn "$device_id" defaults write .GlobalPreferences AppleLocale -string "$lang"
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
            2>&1 | grep -E "error:|warning:|Test Case|📸|failed|passed" || true
    done
}

run_screenshots "$IPHONE_ID" "iPhone 17 Pro Max (26.1)"
#run_screenshots "$IPAD_ID" "iPad Pro 13-inch (M5) (26.1)"

echo "Done. Screenshots saved to Screenshots/"
