#!/bin/bash
#
# screenshots.sh — capture the App Store screenshots of Simply Filter SMS.
#
# Runs the Screenshots Automation tests once per language on dedicated
# simulators, with the simulator's system language switched for each run, and
# writes the shots to <output>/<app version>/<App Store Connect locale>/.
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
readonly ATTEMPTS=2
readonly STALL_SECONDS=420
readonly TEST_TIME_ALLOWANCE=300
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

# key | simulator name | device type | screens (file name prefixes)
readonly DEVICES=(
    "iphone|Screenshots iPhone|com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max|iphone"
    "ipad|Screenshots iPad|com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB|ipad"
    "duo|Screenshots Duo|com.apple.CoreSimulator.SimDeviceType.iPhone-Duo|duo-outer duo-inner"
)

# number | file name | test | screens
readonly SHOTS=(
    "1|home|testHome|iphone duo-outer"
    "2|ai-filtering|testAIFiltering|iphone ipad duo-outer duo-inner"
    "3|blocked-texts|testBlockedTexts|iphone ipad duo-outer duo-inner"
    "4|allowed-texts|testAllowedTexts|iphone ipad duo-outer duo-inner"
    "5|add-filter|testAddFilter|iphone ipad duo-outer duo-inner"
    "6|blocked-languages|testBlockedLanguages|iphone ipad duo-outer duo-inner"
    "7|test-your-filters|testFilterTester|iphone ipad duo-outer duo-inner"
    "8|countries|testCountries|iphone ipad duo-outer duo-inner"
    "9|community-lists|testCommunityLists|iphone ipad duo-outer duo-inner"
)

output_root="${HERE}/Screenshots"
version_dir=""
skip_build=false
selected_languages=()
selected_devices=()
selected_shots=()
device_ids=()
device_keys=()

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
  -o, --output DIR      The folder that keeps every app version. Default: Extras/Screenshots
      --skip-build      Reuse the previous build instead of building again.
      --list            List the languages, devices and shots, then exit.
  -h, --help            Show this help, then exit.

Each app version has its own folder, DIR/<app version>/<App Store Connect locale>/.
A language is written there only after all of its shots were captured, so a
failed language keeps its previous screenshots. A run of every shot on every
device replaces that version's whole language folder; any narrower run
replaces only the shots it captured.

A shot that runs longer than ${TEST_TIME_ALLOWANCE} seconds fails, and a test run that prints
nothing for $((STALL_SECONDS / 60)) minutes is stopped. Either way the language is tried
again on restarted simulators, up to ${ATTEMPTS} attempts in all.

Examples:
  ${PROGRAM}                          Every shot, every language, every device.
  ${PROGRAM} -l he -l ar              Hebrew and Arabic only.
  ${PROGRAM} -l en -d ipad -s 8       One shot, to check a change.

Exit status:
  0  every language was captured
  1  at least one language failed (see the log it names)
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
        IFS='|' read -r key sim_name _ screens <<<"${entry}"
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
        IFS='|' read -r _ _ _ screens <<<"${entry}"
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

is_full_run() {
    [[ ${#selected_devices[@]} -eq ${#DEVICES[@]} ]] && [[ ${#selected_shots[@]} -eq ${#SHOTS[@]} ]]
}

# The tests for the given screens: the whole class when every shot is selected.
test_filters() {
    if [[ ${#selected_shots[@]} -eq ${#SHOTS[@]} ]]; then
        printf -- '-only-testing\n%s\n' "${TEST_CLASS}"
        return
    fi
    local entry test screens screen
    for entry in "${selected_shots[@]}"; do
        IFS='|' read -r _ _ test screens <<<"${entry}"
        for screen in "$@"; do
            if [[ " ${screens} " = *" ${screen} "* ]]; then
                printf -- '-only-testing\n%s/%s\n' "${TEST_CLASS}" "${test}"
                break
            fi
        done
    done
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
    local job
    for job in $(jobs -p); do
        kill "${job}" 2>/dev/null || true
    done
    rmdir "${LOCK}" 2>/dev/null || true
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

prepare_simulator() {
    local udid="$1" key="$2" language="$3" locale="$4"
    xcrun simctl shutdown "${udid}" >/dev/null 2>&1 || true
    xcrun simctl boot "${udid}"
    xcrun simctl bootstatus "${udid}" >/dev/null
    xcrun simctl spawn "${udid}" defaults write .GlobalPreferences AppleLanguages -array "${language}"
    xcrun simctl spawn "${udid}" defaults write .GlobalPreferences AppleLocale -string "${locale}"
    if [[ "${key}" = "ipad" ]]; then
        xcrun simctl spawn "${udid}" defaults write com.apple.springboard SBChamoisWindowingEnabled -bool false
        xcrun simctl spawn "${udid}" defaults write com.apple.springboard SBMedusaMultitaskingEnabled -bool false
    fi
    xcrun simctl shutdown "${udid}"
    xcrun simctl boot "${udid}"
    xcrun simctl bootstatus "${udid}" >/dev/null
    xcrun simctl ui "${udid}" appearance light
    xcrun simctl status_bar "${udid}" clear
    xcrun simctl status_bar "${udid}" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
}

# Destinations for the given device keys, or for every selected device.
destinations() {
    local index
    for index in "${!device_ids[@]}"; do
        if [[ $# -eq 0 ]] || [[ " $* " = *" ${device_keys[${index}]} "* ]]; then
            printf -- '-destination\nid=%s\n' "${device_ids[${index}]}"
        fi
    done
}

udid_for() {
    local index
    for index in "${!device_keys[@]}"; do
        if [[ "${device_keys[${index}]}" = "$1" ]]; then
            echo "${device_ids[${index}]}"
            return 0
        fi
    done
    return 1
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

#MARK: - Steps -

prepare_simulators() {
    step "Simulators"
    local entry key sim_name type runtime udid
    for entry in "${selected_devices[@]}"; do
        IFS='|' read -r key sim_name type _ <<<"${entry}"
        runtime=$(runtime_for "${type}")
        udid=$(ensure_simulator "${sim_name}" "${type}" "${runtime}") || exit "${EXIT_ENVIRONMENT}"
        device_ids+=("${udid}")
        device_keys+=("${key}")
        ok "${sim_name} ${dim}(${udid}, ${runtime##*.})${reset}"
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
    local args=()
    while IFS= read -r line; do args+=("${line}"); done < <(destinations)
    if xcodebuild build-for-testing -project "${PROJECT}" -scheme "${SCHEME}" "${args[@]}" \
        -derivedDataPath "${DERIVED_DATA}" >"${log}" 2>&1; then
        ok "built in $(elapsed "${started}")"
    else
        fail "build failed"
        note "${log}"
        exit "${EXIT_ENVIRONMENT}"
    fi
}

choose_version_dir() {
    local version
    version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${APP_INFO_PLIST}" 2>/dev/null) \
        || die "could not read the app version from ${APP_INFO_PLIST}"
    version_dir="${output_root}/${version}"
}

collect() {
    local bundle="$1" staging="$2"
    local export="${WORK}/export"
    rm -rf "${export}" && mkdir -p "${export}" "${staging}"
    xcrun xcresulttool export attachments --path "${bundle}" --output-path "${export}" >/dev/null
    python3 -I - "${export}" "${staging}" <<'PYTHON'
import json, shutil, sys
export, staging = sys.argv[1], sys.argv[2]
for test in json.load(open(f"{export}/manifest.json")):
    for attachment in test["attachments"]:
        name = attachment.get("suggestedHumanReadableName", "")
        if name.startswith("screenshot~"):
            _, _, device, shot = name.split("_0_")[0].split("~")
            shutil.copy(f"{export}/{attachment['exportedFileName']}", f"{staging}/{device}-{shot}.png")
PYTHON
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

# Returns 0 when every test passed, 1 when one failed, 2 when the run stalled.
run_tests() {
    local bundle="$1" log="$2"
    shift 2
    rm -rf "${bundle}"
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

prepare_language() {
    local code="$1" locale="$2" log="$3"
    local index pid pids=() status=0
    for index in "${!device_ids[@]}"; do
        prepare_simulator "${device_ids[${index}]}" "${device_keys[${index}]}" "${code}" "${locale}" >>"${log}" 2>&1 &
        pids+=($!)
    done
    for pid in "${pids[@]}"; do
        wait "${pid}" || status=1
    done
    return "${status}"
}

# Runs the tests for the given screens on the given devices into one bundle.
# Prints why it failed, or nothing.
run_screens() {
    local bundle="$1" log="$2" devices="$3"
    shift 3
    local args=() line status=0
    while IFS= read -r line; do args+=("${line}"); done < <(test_filters "$@")
    [[ ${#args[@]} -gt 0 ]] || return 0
    local device_list
    read -ra device_list <<<"${devices}"
    while IFS= read -r line; do args+=("${line}"); done < <(destinations "${device_list[@]}")
    run_tests "${bundle}" "${log}" "${args[@]}" || status=$?
    case "${status}" in
        0) collect "${bundle}" "${WORK}/staging/current" ;;
        2) echo "the test run printed nothing for $((STALL_SECONDS / 60)) minutes and was stopped" ;;
        *) echo "a shot failed on $*" ;;
    esac
}

# Prints why an attempt failed, or nothing when every shot was captured.
attempt_language() {
    local code="$1" locale="$2" name="$3" log="$4" bundle="$5" staging="$6"
    rm -rf "${staging}" "${WORK}/staging/current"
    if ! prepare_language "${code}" "${locale}" "${log}"; then
        echo "could not set the simulators to ${name}"
        return
    fi

    local flat=() screens=() reason
    udid_for iphone >/dev/null && flat+=(iphone) && screens+=(iphone)
    udid_for ipad >/dev/null && flat+=(ipad) && screens+=(ipad)
    if [[ ${#flat[@]} -gt 0 ]]; then
        reason=$(run_screens "${bundle}" "${log}" "${flat[*]}" "${screens[@]}")
        [[ -z "${reason}" ]] || { echo "${reason}"; return; }
    fi

    local duo pose screen
    if duo=$(udid_for duo); then
        for pose in close open; do
            [[ "${pose}" = "close" ]] && screen="duo-outer" || screen="duo-inner"
            [[ $(shot_count "${screen}" "${selected_shots[@]}") -gt 0 ]] || continue
            if ! fold "${duo}" "${pose}" >>"${log}" 2>&1; then
                echo "hinge could not ${pose} the iPhone Duo"
                return
            fi
            reason=$(run_screens "${bundle%.xcresult}.${screen}.xcresult" "${log}" duo "${screen}")
            [[ -z "${reason}" ]] || { echo "${reason}"; return; }
        done
    fi

    mkdir -p "${WORK}/staging/current"
    mv "${WORK}/staging/current" "${staging}"
    local shots captured missing=()
    for screen in $(selected_screens); do
        shots=$(shot_count "${screen}" "${selected_shots[@]}")
        [[ ${shots} -gt 0 ]] || continue
        captured=$(find "${staging}" -name "${screen}-*.png" | wc -l | tr -d ' ')
        [[ "${captured}" -eq "${shots}" ]] || missing+=("${screen} ${captured}/${shots}")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "shots missing: ${missing[*]}"
    fi
}

capture_language() {
    local entry="$1" code locale folder name
    IFS='|' read -r code locale folder name <<<"${entry}"
    local started log="${LOGS}/${code}.log" staging="${WORK}/staging/${folder}"
    started=$(date +%s)
    step "${name}"
    rm -rf "${WORK}/results/${code}".*xcresult

    local attempt reason bundle
    for (( attempt = 1; attempt <= ATTEMPTS; attempt++ )); do
        bundle="${WORK}/results/${code}.${attempt}.xcresult"
        printf '\n=== attempt %d of %d ===\n' "${attempt}" "${ATTEMPTS}" >>"${log}"
        reason=$(attempt_language "${code}" "${locale}" "${name}" "${log}" "${bundle}" "${staging}")
        [[ -n "${reason}" ]] || break
        if [[ ${attempt} -lt ${ATTEMPTS} ]]; then
            warn "${reason}; trying again on restarted simulators"
            note "${bundle}"
        else
            fail "${reason}"
            note "${log}"
            note "${bundle}"
            return 1
        fi
    done

    local screen
    for screen in $(selected_screens); do
        [[ $(shot_count "${screen}" "${selected_shots[@]}") -gt 0 ]] || continue
        ok "${screen} $(find "${staging}" -name "${screen}-*.png" | wc -l | tr -d ' ')/$(shot_count "${screen}" "${selected_shots[@]}")"
    done

    mkdir -p "${version_dir}/${folder}"
    if is_full_run; then
        rm -f "${version_dir}/${folder}"/*.png
    else
        local file
        for file in "${staging}"/*.png; do
            rm -f "${version_dir}/${folder}/${file##*/}"
        done
    fi
    mv "${staging}"/*.png "${version_dir}/${folder}/"
    note "${version_dir}/${folder} ($(elapsed "${started}"))"
}

#MARK: - Main -

main() {
    parse_arguments "$@"
    acquire_lock
    trap cleanup EXIT
    trap interrupted INT TERM
    preflight
    rm -rf "${LOGS}" && mkdir -p "${LOGS}" "${WORK}/results" "${WORK}/staging"

    local started failed=()
    started=$(date +%s)
    prepare_simulators
    build
    choose_version_dir
    local entry
    for entry in "${selected_languages[@]}"; do
        capture_language "${entry}" || failed+=("${entry%%|*}")
    done

    echo
    if [[ ${#failed[@]} -gt 0 ]]; then
        printf '%s%d of %d languages failed:%s %s\n' "${red}" ${#failed[@]} ${#selected_languages[@]} "${reset}" "${failed[*]}"
        exit "${EXIT_FAILED_LANGUAGE}"
    fi
    printf '%sAll %d languages captured in %s%s → %s\n' "${green}" ${#selected_languages[@]} "$(elapsed "${started}")" "${reset}" "${version_dir}"
}

main "$@"
