#!/bin/bash
#
# screenshots.sh — capture the App Store screenshots of Simply Filter SMS.
#
# Runs the Screenshots Automation tests on dedicated simulators, several of each
# device at once, each working through its own share of the languages with its
# system language switched for every run. Each shot is written to
# <output>/<app version>/<App Store Connect locale>/ as soon as its test passes.
# The iPhone Duo is shot folded and unfolded; hinge
# (brew install artemnovichkov/tap/hinge) folds it between the two runs.
#
set -Eeuo pipefail

readonly PROGRAM="${0##*/}"
HERE="$(cd "$(dirname "$0")" && pwd)"
readonly HERE
readonly PROJECT="${HERE}/../Simply Filter SMS.xcodeproj"
readonly SCHEME="Screenshots Automation"
readonly TEST_CLASS="Screenshots Automation/AppStoreShots"
readonly WORK="${TMPDIR:-/tmp}/simply-filter-sms-screenshots"
readonly DERIVED_DATA="${WORK}/DerivedData"
readonly LOGS="${WORK}/logs"
readonly LOCK="${WORK}/lock"
readonly START_LOCK="${WORK}/start-lock"
readonly FILTER_LISTS="${WORK}/filter-lists"
# The app's production catalog (URL.filterListCatalogURL); its lists are
# downloaded once per run and fed to every launch instead of each one downloading.
readonly CATALOG_URL="https://grizz-apps-dev.s3.us-east-2.amazonaws.com/simply-filter-sms/4.0.0/catalog.json"
readonly ATTEMPTS=2
readonly STALL_SECONDS=420
readonly TEST_TIME_ALLOWANCE=300
readonly QUIET_CPU=50
readonly QUIET_SECONDS=5
readonly QUIET_LIMIT=120
readonly APP_INFO_PLIST="${DERIVED_DATA}/Build/Products/Debug-iphonesimulator/Simply Filter SMS.app/Info.plist"

readonly EXIT_FAILED_LANGUAGE=1
readonly EXIT_USAGE=2
readonly EXIT_ENVIRONMENT=3

# code | AppleLocale | App Store Connect folder | name
readonly LANGUAGES=(
    "en|en_US|en-US|English"
    "he|he_IL|he|Hebrew"
    "de|de_DE|de-DE|German"
    "es|es_ES|es-ES|Spanish"
    "fr|fr_FR|fr-FR|French"
    "it|it_IT|it|Italian"
    "pt-BR|pt_BR|pt-BR|Portuguese (Brazil)"
    "ar|ar_SA|ar-SA|Arabic"
    "ja|ja_JP|ja|Japanese"
    "ko|ko_KR|ko|Korean"
    "zh-Hans|zh_CN|zh-Hans|Chinese (Simplified)"
)

# key | simulator name | device type | simulators at once | screens (file name prefixes)
# More than one simulator of a device at once overloads the Mac: every running
# simulator keeps iOS's own services busy, and UI queries time out under it.
readonly DEVICES=(
    "iphone|Screenshots iPhone|com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max|1|iphone"
    "ipad|Screenshots iPad|com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB|1|ipad"
    "duo|Screenshots Duo|com.apple.CoreSimulator.SimDeviceType.iPhone-Duo|1|duo-outer duo-inner"
)

# number | file name | test | screens
readonly SHOTS=(
    "1|home|testHome|iphone duo-outer"
    "2|ai-filtering|testAIFiltering|iphone ipad duo-inner"
    "3|blocked-texts|testBlockedTexts|iphone ipad duo-inner"
    "4|allowed-texts|testAllowedTexts|iphone ipad duo-inner"
    "5|add-filter|testAddFilter|iphone ipad duo-inner"
    "6|blocked-languages|testBlockedLanguages|iphone ipad duo-inner"
    "7|test-your-filters|testFilterTester|iphone ipad duo-inner"
    "8|countries|testCountries|iphone ipad duo-inner"
    "9|community-lists|testCommunityLists|iphone ipad duo-inner"
)

output_root="${HERE}/screenshots"
version_dir=""
skip_build=false
parallel=0
selected_languages=()
selected_devices=()
selected_shots=()
workers=()

#MARK: - Output -

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    bold=$'\033[1m' dim=$'\033[2m' red=$'\033[31m' green=$'\033[32m' yellow=$'\033[33m' reset=$'\033[0m'
else
    bold="" dim="" red="" green="" yellow="" reset=""
fi

step()    { printf '%s▸ %s%s\n' "${bold}" "$1" "${reset}"; }
ok()      { printf '  %s✓%s %s\n' "${green}" "${reset}" "$1"; }
fail()    { printf '  %s✗%s %s\n' "${red}" "${reset}" "$1"; }
warn()    { printf '  %s!%s %s\n' "${yellow}" "${reset}" "$1"; }
note()    { printf '  %s%s%s\n' "${dim}" "$1" "${reset}"; }
die()     { printf '%s%s: %s%s\n' "${red}" "${PROGRAM}" "$1" "${reset}" >&2; exit "${2:-${EXIT_ENVIRONMENT}}"; }
elapsed() { local seconds=$(( $(date +%s) - $1 )); printf '%dm%02ds' $((seconds / 60)) $((seconds % 60)); }

usage() {
    cat <<EOF
Usage: ${PROGRAM} [options]

Capture the App Store screenshots for every language on iPhone, iPad and
iPhone Duo (folded and unfolded).

Options:
  -l, --language CODE   Capture only this language. Repeat for more. Default: all.
  -d, --device DEVICE   iphone, ipad or duo. Repeat for more. Default: all.
  -s, --shot NUMBER     Capture only this shot (1-9). Repeat for more. Default: all.
  -o, --output DIR      The folder that keeps every app version. Default: Extras/screenshots
  -p, --parallel N      Simulators per selected device, instead of one each. Only for a
                        run of one device: the Mac copes with three simulators in all.
      --skip-build      Reuse the previous build instead of building again.
      --list            List the languages, devices and shots, then exit.
  -h, --help            Show this help, then exit.

Each app version has its own folder, DIR/<app version>/<App Store Connect locale>/.
Every shot is written there as soon as its test passes, replacing the file of
the same name; a shot whose test failed keeps its previous file.

A shot that runs longer than ${TEST_TIME_ALLOWANCE} seconds fails, and a test run that prints
nothing for $((STALL_SECONDS / 60)) minutes is stopped. Either way that language is tried
again on that device after restarting its simulator, up to ${ATTEMPTS} attempts in all.

Examples:
  ${PROGRAM}                          Every shot, every language, every device.
  ${PROGRAM} -l he -l ar              Hebrew and Arabic only.
  ${PROGRAM} -l en -d ipad -s 8       One shot, to check a change.

Exit status:
  0  every language was captured
  1  at least one language failed on a device (see the log it names)
  2  invalid usage
  3  the environment or the build is not ready
EOF
}

list() {
    printf '%sLanguages%s\n' "${bold}" "${reset}"
    local entry code folder name
    for entry in "${LANGUAGES[@]}"; do
        IFS='|' read -r code _ folder name <<<"${entry}"
        printf '  %-8s %-22s → %s\n' "${code}" "${name}" "${folder}"
    done
    printf '%sDevices%s\n' "${bold}" "${reset}"
    local key sim_name screens screen counts
    for entry in "${DEVICES[@]}"; do
        IFS='|' read -r key sim_name _ _ screens <<<"${entry}"
        counts=""
        for screen in ${screens}; do
            counts="${counts:+${counts}, }${screen} $(shot_count "${screen}" "${SHOTS[@]}") shots"
        done
        printf '  %-8s %-22s %s\n' "${key}" "${sim_name}" "${counts}"
    done
    printf '%sShots%s\n' "${bold}" "${reset}"
    local number file
    for entry in "${SHOTS[@]}"; do
        IFS='|' read -r number file _ screens <<<"${entry}"
        printf '  %-8s %-22s %s\n' "${number}" "${file}" "${screens}"
    done
}

#MARK: - Arguments -

language_entry() {
    local entry
    for entry in "${LANGUAGES[@]}"; do
        if [[ "${entry%%|*}" = "$1" ]]; then
            echo "${entry}"
            return 0
        fi
    done
    return 1
}

shot_entry() {
    local entry
    for entry in "${SHOTS[@]}"; do
        if [[ "${entry%%|*}" = "$1" ]]; then
            echo "${entry}"
            return 0
        fi
    done
    return 1
}

shot_count() {
    local screen="$1" entry screens count=0
    shift
    for entry in "$@"; do
        IFS='|' read -r _ _ _ screens <<<"${entry}"
        [[ " ${screens} " = *" ${screen} "* ]] && count=$((count + 1))
    done
    echo "${count}"
}

selected_screens() {
    local entry screens
    for entry in "${selected_devices[@]}"; do
        IFS='|' read -r _ _ _ _ screens <<<"${entry}"
        read -ra screens <<<"${screens}"
        printf '%s\n' "${screens[@]}"
    done
}

device_entry() {
    local entry
    for entry in "${DEVICES[@]}"; do
        if [[ "${entry%%|*}" = "$1" ]]; then
            echo "${entry}"
            return 0
        fi
    done
    return 1
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--language)
                [[ $# -ge 2 ]] || die "$1 needs a language code (see --list)" "${EXIT_USAGE}"
                language_entry "$2" >/dev/null || die "unknown language '$2' (see --list)" "${EXIT_USAGE}"
                selected_languages+=("$(language_entry "$2")")
                shift 2 ;;
            -d|--device)
                [[ $# -ge 2 ]] || die "$1 needs iphone, ipad or duo" "${EXIT_USAGE}"
                device_entry "$2" >/dev/null || die "unknown device '$2' (use iphone, ipad or duo)" "${EXIT_USAGE}"
                selected_devices+=("$(device_entry "$2")")
                shift 2 ;;
            -s|--shot)
                [[ $# -ge 2 ]] || die "$1 needs a shot number (see --list)" "${EXIT_USAGE}"
                shot_entry "$2" >/dev/null || die "unknown shot '$2' (see --list)" "${EXIT_USAGE}"
                selected_shots+=("$(shot_entry "$2")")
                shift 2 ;;
            -o|--output)
                [[ $# -ge 2 ]] || die "$1 needs a directory" "${EXIT_USAGE}"
                output_root="$2"
                shift 2 ;;
            -p|--parallel)
                [[ $# -ge 2 ]] && [[ "$2" =~ ^[1-9][0-9]*$ ]] || die "$1 needs a number of simulators" "${EXIT_USAGE}"
                parallel="$2"
                shift 2 ;;
            --skip-build)
                skip_build=true
                shift ;;
            --list)
                list
                exit 0 ;;
            -h|--help)
                usage
                exit 0 ;;
            *)
                die "unknown option '$1' (see --help)" "${EXIT_USAGE}" ;;
        esac
    done
    [[ ${#selected_languages[@]} -gt 0 ]] || selected_languages=("${LANGUAGES[@]}")
    [[ ${#selected_devices[@]} -gt 0 ]] || selected_devices=("${DEVICES[@]}")
    [[ ${#selected_shots[@]} -gt 0 ]] || selected_shots=("${SHOTS[@]}")
    local screen total=0
    for screen in $(selected_screens); do
        total=$((total + $(shot_count "${screen}" "${selected_shots[@]}")))
    done
    [[ ${total} -gt 0 ]] || die "the selected shots don't exist on the selected devices (see --list)" "${EXIT_USAGE}"
}

device_screens() {
    local entry screens
    entry=$(device_entry "$1")
    IFS='|' read -r _ _ _ _ screens <<<"${entry}"
    echo "${screens}"
}

# The tests for the given screen that still have to run: every selected shot
# whose file was not delivered after the marker (a retry redoes only those).
# The whole class when every shot is selected and none was delivered yet.
test_filters() {
    local screen="$1" delivery="${2:-}" marker="${3:-}"
    local entry number file test screens file_path pending=0 total=0 lines=()
    for entry in "${selected_shots[@]}"; do
        IFS='|' read -r number file test screens <<<"${entry}"
        [[ " ${screens} " = *" ${screen} "* ]] || continue
        total=$((total + 1))
        file_path="${delivery}/${screen}-$(printf '%02d' "${number}")-${file}.png"
        if [[ -n "${marker}" ]] && [[ "${file_path}" -nt "${marker}" ]]; then
            continue
        fi
        pending=$((pending + 1))
        lines+=("-only-testing" "${TEST_CLASS}/${test}")
    done
    if [[ ${pending} -gt 0 ]] && [[ ${pending} -eq ${total} ]] && [[ ${total} -eq ${#SHOTS[@]} ]]; then
        printf -- '-only-testing\n%s\n' "${TEST_CLASS}"
    elif [[ ${pending} -gt 0 ]]; then
        printf '%s\n' "${lines[@]}"
    fi
}

#MARK: - Environment -

acquire_lock() {
    mkdir -p "${WORK}"
    if ! mkdir "${LOCK}" 2>/dev/null; then
        die "another run is in progress (remove ${LOCK} if it isn't)"
    fi
}

cleanup() {
    local status=$?
    trap - EXIT INT TERM
    local child
    for child in $(pgrep -P $$); do
        stop_tree "${child}"
    done
    rmdir "${START_LOCK}" "${LOCK}" 2>/dev/null || true
    exit "${status}"
}

interrupted() {
    printf '\n%sInterrupted.%s\n' "${yellow}" "${reset}" >&2
    exit 130
}

preflight() {
    local tool
    for tool in xcodebuild xcrun python3; do
        command -v "${tool}" >/dev/null || die "${tool} not found; install Xcode and its command line tools"
    done
    [[ -d "${PROJECT}" ]] || die "project not found at ${PROJECT}"
    local entry key type
    for entry in "${selected_devices[@]}"; do
        IFS='|' read -r key _ type _ <<<"${entry}"
        xcrun simctl list devicetypes | grep -q "(${type})" || die "this Xcode has no simulator type ${type}"
        [[ -n "$(runtime_for "${type}")" ]] || die "no installed iOS runtime runs ${type} (Xcode ▸ Settings ▸ Components)"
        if [[ "${key}" = "duo" ]]; then
            command -v hinge >/dev/null || die "the iPhone Duo needs hinge to fold it: brew install artemnovichkov/tap/hinge"
        fi
    done
}

# The newest installed iOS runtime that runs the device type. The iPhone Duo has
# a runtime build of its own that runs no other device.
runtime_for() {
    xcrun simctl list runtimes -j | python3 -I -c '
import json, sys
runtimes = [r for r in json.load(sys.stdin)["runtimes"]
            if r.get("isAvailable") and r["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-")
            and any(d["identifier"] == sys.argv[1] for d in r.get("supportedDeviceTypes", []))]
if runtimes:
    print(runtimes[-1]["identifier"])
' "$1"
}

ensure_simulator() {
    local name="$1" type="$2" runtime="$3" udid
    udid=$(xcrun simctl list devices | grep -F "    ${name} (" | grep -oE '[0-9A-F-]{36}' | head -1 || true)
    if [[ -z "${udid}" ]]; then
        udid=$(xcrun simctl create "${name}" "${type}" "${runtime}") || die "could not create the simulator '${name}'"
    fi
    echo "${udid}"
}

# The language is written into the simulator's settings while it is off, so it
# starts only once per language, and one simulator starts at a time: a start
# launches every built-in app and service and is the heaviest moment of a run.
prepare_simulator() {
    local udid="$1" key="$2" language="$3" locale="$4"
    local preferences="${HOME}/Library/Developer/CoreSimulator/Devices/${udid}/data/Library/Preferences"
    xcrun simctl shutdown "${udid}" >/dev/null 2>&1 || true
    if [[ ! -d "${preferences}" ]]; then
        start_simulator "${udid}"
        xcrun simctl shutdown "${udid}"
    fi
    set_preference "${preferences}/.GlobalPreferences.plist" AppleLanguages -json "[\"${language}\"]"
    set_preference "${preferences}/.GlobalPreferences.plist" AppleLocale -string "${locale}"
    if [[ "${key}" = "ipad" ]]; then
        set_preference "${preferences}/com.apple.springboard.plist" SBChamoisWindowingEnabled -bool false
        set_preference "${preferences}/com.apple.springboard.plist" SBMedusaMultitaskingEnabled -bool false
    fi
    start_simulator "${udid}"
    xcrun simctl ui "${udid}" appearance light
    xcrun simctl status_bar "${udid}" clear
    xcrun simctl status_bar "${udid}" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
    wait_until_quiet "${udid}"
}

set_preference() {
    local file="$1" key="$2" type="$3" value="$4"
    [[ -f "${file}" ]] || plutil -create binary1 "${file}"
    plutil -replace "${key}" "${type}" "${value}" "${file}"
}

# The CPU percent used by everything running inside the simulator.
simulator_cpu() {
    local root
    root=$(pgrep -f "launchd_sim .*$1" | head -1)
    [[ -n "${root}" ]] || { echo 0; return; }
    ps -A -o pid=,ppid=,%cpu= | awk -v root="${root}" '
        { parent[$1] = $2; cpu[$1] = $3 }
        END {
            for (pid in parent) {
                ancestor = pid
                while (ancestor != "" && ancestor != 0 && ancestor != root) ancestor = parent[ancestor]
                if (ancestor == root) sum += cpu[pid]
            }
            printf "%d", sum
        }'
}

# A booted simulator keeps launching its own services for a minute or two; the
# first test started in that burst times out on its first query.
wait_until_quiet() {
    local udid="$1" quiet=0 waited=0
    while [[ ${quiet} -lt ${QUIET_SECONDS} ]] && [[ ${waited} -lt ${QUIET_LIMIT} ]]; do
        if [[ $(simulator_cpu "${udid}") -lt ${QUIET_CPU} ]]; then
            quiet=$((quiet + 1))
        else
            quiet=0
        fi
        waited=$((waited + 1))
        sleep 1
    done
    echo "simulator ${udid} quiet after ${waited}s"
}

start_simulator() {
    local udid="$1" status=0
    until mkdir "${START_LOCK}" 2>/dev/null; do
        sleep 1
    done
    xcrun simctl boot "${udid}" && xcrun simctl bootstatus "${udid}" >/dev/null || status=$?
    rmdir "${START_LOCK}"
    return "${status}"
}

# Folds (close) or unfolds (open) the iPhone Duo, then waits until the screen
# that goes with it hosts the UI: the outer one is the primary display.
fold() {
    local udid="$1" pose="$2" expected primary attempt
    hinge -d "${udid}" -t 5 "${pose}" || return 1
    [[ "${pose}" = "close" ]] && expected=true || expected=false
    for (( attempt = 0; attempt < 20; attempt++ )); do
        primary=$(hinge -d "${udid}" posture --json | python3 -I -c '
import json, sys
print(str(next((d["primary"] for d in json.load(sys.stdin)["displays"] if d["active"]), "")).lower())')
        [[ "${primary}" = "${expected}" ]] && return 0
        sleep 0.5
    done
    return 1
}

# Every running process started under the given one, deepest first.
stop_tree() {
    local pid="$1" child
    for child in $(pgrep -P "${pid}" 2>/dev/null); do
        stop_tree "${child}"
    done
    kill "${pid}" 2>/dev/null || true
}

#MARK: - Steps -

# One simulator per lane of each selected device; each runs its own languages.
prepare_simulators() {
    step "Simulators"
    local entry key sim_name type count runtime udid lane name lanes
    for entry in "${selected_devices[@]}"; do
        IFS='|' read -r key sim_name type count _ <<<"${entry}"
        runtime=$(runtime_for "${type}")
        [[ ${parallel} -gt 0 ]] && count=${parallel}
        lanes=$(( count < ${#selected_languages[@]} ? count : ${#selected_languages[@]} ))
        for (( lane = 1; lane <= lanes; lane++ )); do
            [[ ${lane} -eq 1 ]] && name="${sim_name}" || name="${sim_name} ${lane}"
            udid=$(ensure_simulator "${name}" "${type}" "${runtime}") || exit "${EXIT_ENVIRONMENT}"
            workers+=("${key}|${udid}|${name}|${lane}|${lanes}")
            ok "${name} ${dim}(${udid}, ${runtime##*.})${reset}"
        done
    done
}

build() {
    step "Build"
    if ${skip_build}; then
        [[ -d "${DERIVED_DATA}/Build/Products" ]] || die "--skip-build needs a previous build in ${DERIVED_DATA}"
        ok "reusing the previous build"
        return
    fi
    local started log="${LOGS}/build.log"
    started=$(date +%s)
    if xcodebuild build-for-testing -project "${PROJECT}" -scheme "${SCHEME}" \
        -destination "generic/platform=iOS Simulator" \
        -derivedDataPath "${DERIVED_DATA}" >"${log}" 2>&1; then
        ok "built in $(elapsed "${started}")"
    else
        fail "build failed"
        note "${log}"
        exit "${EXIT_ENVIRONMENT}"
    fi
}

fetch_filter_lists() {
    step "Filter lists"
    rm -rf "${FILTER_LISTS}" && mkdir -p "${FILTER_LISTS}"
    curl -fsSL "${CATALOG_URL}" -o "${FILTER_LISTS}/catalog.json" || die "could not download the catalog ${CATALOG_URL}"
    local url count=0
    while IFS= read -r url; do
        curl -fsSL "${url}" -o "${FILTER_LISTS}/${url##*/}" || die "could not download the list ${url}"
        count=$((count + 1))
    done < <(python3 -I - "${FILTER_LISTS}/catalog.json" "${CATALOG_URL}" <<'PYTHON'
import json, sys, urllib.parse
for entry in json.load(open(sys.argv[1]))["lists"]:
    print(urllib.parse.urljoin(sys.argv[2], entry["url"]))
PYTHON
)
    ok "${count} lists"
}

choose_version_dir() {
    local version
    version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${APP_INFO_PLIST}" 2>/dev/null) \
        || die "could not read the app version from ${APP_INFO_PLIST}"
    version_dir="${output_root}/${version}"
}

file_size() {
    stat -f %z "$1" 2>/dev/null || echo 0
}

stop_process() {
    local pid="$1"
    kill "${pid}" 2>/dev/null || return 0
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        kill -0 "${pid}" 2>/dev/null || return 0
        sleep 1
    done
    kill -9 "${pid}" 2>/dev/null || true
}

# Each shot is written straight to the delivery folder as soon as its test passes.
# Returns 0 when every test passed, 1 when one failed, 2 when the run stalled.
run_tests() {
    local bundle="$1" log="$2" delivery="$3"
    shift 3
    rm -rf "${bundle}"
    TEST_RUNNER_SCREENSHOT_DELIVERY_FOLDER="${delivery}" TEST_RUNNER_SCREENSHOT_FILTER_LISTS="${FILTER_LISTS}" \
    xcodebuild test-without-building -project "${PROJECT}" -scheme "${SCHEME}" "$@" \
        -derivedDataPath "${DERIVED_DATA}" -resultBundlePath "${bundle}" \
        -test-timeouts-enabled YES -default-test-execution-time-allowance "${TEST_TIME_ALLOWANCE}" \
        -maximum-test-execution-time-allowance "${TEST_TIME_ALLOWANCE}" >>"${log}" 2>&1 &
    local pid=$! size last_size=-1 quiet_since
    quiet_since=$(date +%s)
    while kill -0 "${pid}" 2>/dev/null; do
        sleep 5
        size=$(file_size "${log}")
        if [[ "${size}" != "${last_size}" ]]; then
            last_size="${size}"
            quiet_since=$(date +%s)
        elif [[ $(( $(date +%s) - quiet_since )) -ge ${STALL_SECONDS} ]]; then
            stop_process "${pid}"
            wait "${pid}" 2>/dev/null || true
            return 2
        fi
    done
    wait "${pid}" || return 1
}

# Runs the tests for one screen on one simulator. Prints why it failed, or nothing.
run_screen() {
    local bundle="$1" log="$2" udid="$3" delivery="$4" screen="$5" marker="$6"
    local args=() line status=0
    while IFS= read -r line; do args+=("${line}"); done < <(test_filters "${screen}" "${delivery}" "${marker}")
    [[ ${#args[@]} -gt 0 ]] || return 0
    run_tests "${bundle}" "${log}" "${delivery}" "${args[@]}" -destination "id=${udid}" || status=$?
    case "${status}" in
        0) ;;
        2) echo "the test run printed nothing for $((STALL_SECONDS / 60)) minutes and was stopped" ;;
        *) echo "a shot failed on ${screen}" ;;
    esac
}

# Prints why an attempt failed, or nothing when every shot was delivered.
attempt_device() {
    local code="$1" locale="$2" name="$3" key="$4" udid="$5" delivery="$6" log="$7" results="$8" began="$9"
    if ! prepare_simulator "${udid}" "${key}" "${code}" "${locale}" >>"${log}" 2>&1; then
        echo "could not set the simulator to ${name}"
        return
    fi

    local screen pose reason
    for screen in $(device_screens "${key}"); do
        [[ $(shot_count "${screen}" "${selected_shots[@]}") -gt 0 ]] || continue
        if [[ "${key}" = "duo" ]]; then
            [[ "${screen}" = "duo-outer" ]] && pose="close" || pose="open"
            if ! fold "${udid}" "${pose}" >>"${log}" 2>&1; then
                echo "hinge could not ${pose} the iPhone Duo"
                return
            fi
        fi
        reason=$(run_screen "${results}.${screen}.xcresult" "${log}" "${udid}" "${delivery}" "${screen}" "${began}")
        [[ -z "${reason}" ]] || { echo "${reason}"; return; }
    done

    local shots captured missing=()
    for screen in $(device_screens "${key}"); do
        shots=$(shot_count "${screen}" "${selected_shots[@]}")
        [[ ${shots} -gt 0 ]] || continue
        captured=$(find "${delivery}" -name "${screen}-*.png" -newer "${began}" | wc -l | tr -d ' ')
        [[ "${captured}" -eq "${shots}" ]] || missing+=("${screen} ${captured}/${shots}")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "shots missing: ${missing[*]}"
    fi
}

# Captures one language on one simulator, trying again on a restarted simulator.
capture() {
    local entry="$1" key="$2" udid="$3" sim_name="$4"
    local code locale folder name
    IFS='|' read -r code locale folder name <<<"${entry}"
    local started delivery="${version_dir}/${folder}" log="${LOGS}/${code}-${key}.log"
    started=$(date +%s)
    mkdir -p "${delivery}"

    local attempt reason results began="${WORK}/results/${code}.${key}.began"
    touch "${began}"
    for (( attempt = 1; attempt <= ATTEMPTS; attempt++ )); do
        results="${WORK}/results/${code}.${key}.${attempt}"
        printf '\n=== attempt %d of %d on %s ===\n' "${attempt}" "${ATTEMPTS}" "${sim_name}" >>"${log}"
        reason=$(attempt_device "${code}" "${locale}" "${name}" "${key}" "${udid}" "${delivery}" "${log}" "${results}" "${began}")
        [[ -n "${reason}" ]] || break
        if [[ ${attempt} -lt ${ATTEMPTS} ]]; then
            warn "${name} on ${sim_name}: ${reason}; trying again on a restarted simulator"
        else
            fail "${name} on ${sim_name}: ${reason}"
            note "${log}"
            note "${results}.*.xcresult"
            echo "${code} ${key}" >>"${WORK}/failed"
            return 1
        fi
    done

    local screen counts=""
    for screen in $(device_screens "${key}"); do
        [[ $(shot_count "${screen}" "${selected_shots[@]}") -gt 0 ]] || continue
        counts="${counts:+${counts}, }${screen} $(shot_count "${screen}" "${selected_shots[@]}")"
    done
    ok "${name} on ${sim_name}: ${counts} ${dim}($(elapsed "${started}"))${reset}"
}

# A simulator's share of the languages: every lanes-th one, from its lane.
run_worker() {
    local key="$1" udid="$2" sim_name="$3" lane="$4" lanes="$5" index
    for index in "${!selected_languages[@]}"; do
        [[ $(( index % lanes + 1 )) -eq ${lane} ]] || continue
        capture "${selected_languages[${index}]}" "${key}" "${udid}" "${sim_name}" || true
    done
}

#MARK: - Main -

main() {
    parse_arguments "$@"
    acquire_lock
    trap cleanup EXIT
    trap interrupted INT TERM
    preflight
    rm -rf "${LOGS}" "${WORK}/results" "${WORK}/failed" && mkdir -p "${LOGS}" "${WORK}/results"

    local started
    started=$(date +%s)
    prepare_simulators
    build
    fetch_filter_lists
    choose_version_dir

    step "Capturing ${#selected_languages[@]} languages on ${#workers[@]} simulators → ${version_dir}"
    local worker key udid sim_name lane lanes pids=()
    for worker in "${workers[@]}"; do
        IFS='|' read -r key udid sim_name lane lanes <<<"${worker}"
        run_worker "${key}" "${udid}" "${sim_name}" "${lane}" "${lanes}" &
        pids+=($!)
    done
    local pid
    for pid in "${pids[@]}"; do
        wait "${pid}" || true
    done

    echo
    if [[ -s "${WORK}/failed" ]]; then
        printf '%s%d of %d language and device runs failed:%s\n' "${red}" "$(wc -l <"${WORK}/failed" | tr -d ' ')" \
            $(( ${#selected_languages[@]} * ${#selected_devices[@]} )) "${reset}"
        sed 's/^/  /' "${WORK}/failed"
        exit "${EXIT_FAILED_LANGUAGE}"
    fi
    printf '%sAll %d languages captured in %s%s → %s\n' "${green}" ${#selected_languages[@]} "$(elapsed "${started}")" "${reset}" "${version_dir}"
}

main "$@"
