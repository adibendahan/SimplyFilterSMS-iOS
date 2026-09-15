#!/bin/bash
set -euo pipefail

PROJECT="Simply Filter SMS.xcodeproj"
SCHEME="UI Tests"
TEST_ID="UI Tests/SnapshotsTestCase/testCreateSnapshots"
LANGUAGES=("he" "ar" "de" "es" "pt-BR" "fr" "it" "ja" "ko" "zh-Hans" "en")
IPHONE_ID="9ED787DE-787F-4A3B-BACD-4EF1C865823C"
IPAD_ID="6768A5CF-0788-438D-B12B-8E3FA2EF355C"
LOGFILE="/tmp/sfs-screenshots.log"
FAILURES=()
: > "$LOGFILE"

override_status_bar() {
    local device_id="$1"
    xcrun simctl status_bar "$device_id" override \
        --time "9:41" \
        --dataNetwork wifi \
        --wifiMode active \
        --wifiBars 3 \
        --cellularMode active \
        --cellularBars 4 \
        --batteryState charged \
        --batteryLevel 100 >/dev/null 2>&1 || true
}

boot_simulator() {
    local device_id="$1"
    local state
    state=$(xcrun simctl list devices | grep "$device_id" | grep -o "(Booted)\|(Shutdown)" | head -1)
    if [ "$state" != "(Booted)" ]; then
        echo "Booting simulator $device_id..."
        xcrun simctl boot "$device_id"
        sleep 3
    fi
    override_status_bar "$device_id"
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
    override_status_bar "$device_id"
}

run_screenshots() {
    local device_id="$1"
    local device_name="$2"
    echo "=== $device_name ==="
    boot_simulator "$device_id"
    for lang in "${LANGUAGES[@]}"; do
        echo "--- $lang ---"
        set_simulator_language "$device_id" "$lang"
        set +e
        xcodebuild test \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,id=$device_id" \
            -only-testing "$TEST_ID" \
            2>&1 | tee -a "$LOGFILE" | grep -E "error:|warning:|Test Case|📸|failed|passed"
        status=${PIPESTATUS[0]}
        set -e
        if [ "$status" -ne 0 ]; then
            echo "!!! FAILED: $device_name / $lang (xcodebuild exit $status) - continuing"
            FAILURES+=("$device_name/$lang")
        fi
    done
}

run_screenshots "$IPHONE_ID" "iPhone 18 Pro Max (27.0)"
run_screenshots "$IPAD_ID" "iPad Pro 13-inch (M5) (27.0)"

echo "Done. Screenshots saved to .screenshots/"
echo "Full log: $LOGFILE"
if [ ${#FAILURES[@]} -gt 0 ]; then
    echo "FAILED RUNS (${#FAILURES[@]}):"
    for f in "${FAILURES[@]}"; do echo "  - $f"; done
    exit 1
fi
echo "All runs succeeded."
