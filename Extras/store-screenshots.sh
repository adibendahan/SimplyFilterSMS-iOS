#!/bin/bash
#
# store-screenshots.sh — turn the captured App Store screenshots into store images.
#
# Reads the captures that screenshots.sh writes to <output>/<version>/<locale>/,
# puts each one in Apple's device frame on the store background with its
# caption, and writes the result to <output>/<version>-store/<locale>/ under
# the same file name, ready for fastlane upload_screenshots.
#
set -Eeuo pipefail

readonly PROGRAM="${0##*/}"
HERE="$(cd "$(dirname "$0")" && pwd)"
readonly HERE
readonly TEMPLATE="${HERE}/fastlane/store_screenshots/frame.html"
readonly CAPTIONS="${HERE}/fastlane/store_screenshots/captions"
readonly BEZELS="${HERE}/local/bezels"
readonly CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
readonly BEZELS_URL="https://developer.apple.com/design/resources/#product-bezels"

readonly EXIT_FAILED=1
readonly EXIT_USAGE=2
readonly EXIT_ENVIRONMENT=3

# Languages and shots mirror the tables in screenshots.sh.
# code | App Store Connect folder | text direction | name
readonly LANGUAGES=(
    "en|en-US|ltr|English"
    "he|he|rtl|Hebrew"
    "de|de-DE|ltr|German"
    "es|es-ES|ltr|Spanish"
    "fr|fr-FR|ltr|French"
    "it|it|ltr|Italian"
    "pt-BR|pt-BR|ltr|Portuguese (Brazil)"
    "ar|ar-SA|rtl|Arabic"
    "ja|ja|ltr|Japanese"
    "ko|ko|ltr|Korean"
    "zh-Hans|zh-Hans|ltr|Chinese (Simplified)"
)

# key | screens (file name prefixes)
readonly DEVICES=(
    "iphone|iphone"
    "ipad|ipad"
    "duo|duo-outer duo-inner"
)

# screen | width | height | Apple frame file in local/bezels
readonly SCREENS=(
    "iphone|1320|2868|iPhone 18 Pro Max - Black - Portrait.png"
    "ipad|2752|2064|iPad Pro (M5) 13\" - Space Black - Landscape.png"
    "duo-outer|1398|2034|iPhone Duo - Night Sky - Outer Closed Portrait.png"
    "duo-inner|2853|2007|iPhone Duo - Night Sky - Inner Open Landscape.png"
)

# number | file name | screens
readonly SHOTS=(
    "1|home|iphone duo-outer"
    "2|ai-filtering|iphone ipad duo-outer duo-inner"
    "3|blocked-texts|iphone ipad duo-outer duo-inner"
    "4|allowed-texts|iphone ipad duo-outer duo-inner"
    "5|add-filter|iphone ipad duo-outer duo-inner"
    "6|blocked-languages|iphone ipad duo-outer duo-inner"
    "7|test-your-filters|iphone ipad duo-outer duo-inner"
    "8|countries|iphone ipad duo-outer duo-inner"
    "9|community-lists|iphone ipad duo-outer duo-inner"
)

output_root="${HERE}/Screenshots"
version=""
selected_languages=()
selected_devices=()
selected_shots=()
profile=""

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

usage() {
    cat <<EOF
Usage: ${PROGRAM} [options]

Turn the captured App Store screenshots into store images: each capture in
Apple's device frame, on the store background, with its caption.

Options:
  -v, --version VERSION  The app version to frame. Default: the newest one captured.
  -l, --language CODE    Frame only this language. Repeat for more. Default: every
                         language that has a captions file.
  -d, --device DEVICE    iphone, ipad or duo. Repeat for more. Default: all.
  -s, --shot NUMBER      Frame only this shot (1-9). Repeat for more. Default: all.
  -o, --output DIR       The folder that keeps every app version. Default: Extras/Screenshots
      --list             List the languages, devices and shots, then exit.
  -h, --help             Show this help, then exit.

Reads DIR/<version>/<App Store Connect locale>/ and writes the store images to
DIR/<version>-store/<App Store Connect locale>/ under the same file names.
Upload them with: cd Extras && fastlane upload_screenshots path:Screenshots/<version>-store

Captions come from fastlane/store_screenshots/captions/<locale>.json, keyed by
shot number, plus "private" and "openSource", the two labels of the privacy
row under caption 1 on each screen's first image. Words between asterisks are
drawn in green (*simply filter*ed). A screen without a Home shot opens on
shot 2, which then carries caption 1 and the privacy row instead of caption 2.

Apple's device frames are not in the repository: their license forbids
redistributing them. Download them from ${BEZELS_URL}
and copy the frames listed by --list into Extras/local/bezels/.

Examples:
  ${PROGRAM}                          Every captured language, device and shot.
  ${PROGRAM} -l en -d iphone -s 1     One image, to check a change.

Exit status:
  0  every image was written
  1  at least one image failed (its capture is missing or the render failed)
  2  invalid usage
  3  the environment is not ready
EOF
}

list() {
    printf '%sLanguages%s\n' "${bold}" "${reset}"
    local entry code folder name captions
    for entry in "${LANGUAGES[@]}"; do
        IFS='|' read -r code folder _ name <<<"${entry}"
        captions="no captions yet"
        [[ -f "${CAPTIONS}/${folder}.json" ]] && captions="captions"
        printf '  %-8s %-22s → %-8s %s\n' "${code}" "${name}" "${folder}" "${captions}"
    done
    printf '%sDevices%s\n' "${bold}" "${reset}"
    local key screens
    for entry in "${DEVICES[@]}"; do
        IFS='|' read -r key screens <<<"${entry}"
        printf '  %-8s %s\n' "${key}" "${screens}"
    done
    printf '%sFrames%s (Extras/local/bezels/)\n' "${bold}" "${reset}"
    local screen frame
    for entry in "${SCREENS[@]}"; do
        IFS='|' read -r screen _ _ frame <<<"${entry}"
        printf '  %-10s %s\n' "${screen}" "${frame}"
    done
    printf '%sShots%s\n' "${bold}" "${reset}"
    local number file
    for entry in "${SHOTS[@]}"; do
        IFS='|' read -r number file screens <<<"${entry}"
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

screen_entry() {
    local entry
    for entry in "${SCREENS[@]}"; do
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

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--version)
                [[ $# -ge 2 ]] || die "$1 needs a version" "${EXIT_USAGE}"
                version="$2"
                shift 2
                ;;
            -l|--language)
                [[ $# -ge 2 ]] || die "$1 needs a language code" "${EXIT_USAGE}"
                language_entry "$2" >/dev/null || die "unknown language '$2' (see --list)" "${EXIT_USAGE}"
                selected_languages+=("$2")
                shift 2
                ;;
            -d|--device)
                [[ $# -ge 2 ]] || die "$1 needs a device" "${EXIT_USAGE}"
                device_entry "$2" >/dev/null || die "unknown device '$2' (see --list)" "${EXIT_USAGE}"
                selected_devices+=("$2")
                shift 2
                ;;
            -s|--shot)
                [[ $# -ge 2 ]] || die "$1 needs a shot number" "${EXIT_USAGE}"
                shot_entry "$2" >/dev/null || die "unknown shot '$2' (see --list)" "${EXIT_USAGE}"
                selected_shots+=("$2")
                shift 2
                ;;
            -o|--output)
                [[ $# -ge 2 ]] || die "$1 needs a folder" "${EXIT_USAGE}"
                output_root="$2"
                shift 2
                ;;
            --list)
                list
                exit 0
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "unknown option '$1' (see --help)" "${EXIT_USAGE}"
                ;;
        esac
    done
}

#MARK: - Environment -

newest_version() {
    local folder name newest=""
    for folder in "${output_root}"/*/; do
        name="$(basename "${folder}")"
        [[ "${name}" =~ ^[0-9]+(\.[0-9]+)*$ ]] || continue
        if [[ -z "${newest}" ]] || [[ "$(printf '%s\n%s\n' "${newest}" "${name}" | sort -V | tail -1)" = "${name}" ]]; then
            newest="${name}"
        fi
    done
    echo "${newest}"
}

check_environment() {
    [[ -x "${CHROME}" ]] || die "Google Chrome is not installed at ${CHROME}"
    command -v jq >/dev/null || die "jq is not installed"
    [[ -f "${TEMPLATE}" ]] || die "the template is missing: ${TEMPLATE}"

    local entry screen frame missing=()
    for entry in "${SCREENS[@]}"; do
        IFS='|' read -r screen _ _ frame <<<"${entry}"
        [[ -f "${BEZELS}/${frame}" ]] || missing+=("${frame}")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        printf '%s%s: Apple device frames are missing from %s:%s\n' "${red}" "${PROGRAM}" "${BEZELS}" "${reset}" >&2
        printf '  %s\n' "${missing[@]}" >&2
        die "download them from ${BEZELS_URL}"
    fi

    if [[ -z "${version}" ]]; then
        version="$(newest_version)"
        [[ -n "${version}" ]] || die "no captured version in ${output_root}; run screenshots.sh first"
    fi
    [[ -d "${output_root}/${version}" ]] || die "no captures for version ${version} in ${output_root}"

    profile="$(mktemp -d "${TMPDIR:-/tmp}/store-screenshots.XXXXXX")"
    trap 'rm -rf "${profile}"' EXIT
}

#MARK: - Rendering -

uri() {
    jq -rn --arg value "$1" '$value | @uri'
}

caption() {
    jq -r --arg key "$2" '.[$key] // empty' "$1"
}

render() {
    local screen="$1" input="$2" output="$3" title="$4" private="$5" open_source="$6" language="$7" direction="$8"
    local entry width height
    entry="$(screen_entry "${screen}")"
    IFS='|' read -r _ width height _ <<<"${entry}"

    local query
    query="device=${screen}&lang=$(uri "${language}")&dir=${direction}"
    query="${query}&title=$(uri "${title}")&private=$(uri "${private}")&openSource=$(uri "${open_source}")"
    query="${query}&shot=$(uri "file://${input}")"

    local rendered="${profile}/render.png"
    rm -f "${rendered}"
    "${CHROME}" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
        --user-data-dir="${profile}/chrome" --allow-file-access-from-files --virtual-time-budget=5000 \
        --window-size="${width},${height}" --screenshot="${rendered}" \
        "file://${TEMPLATE}?${query}" >/dev/null 2>&1 || return 1
    [[ -f "${rendered}" ]] || return 1

    local size
    size="$(sips -g pixelWidth -g pixelHeight -g hasAlpha "${rendered}" | awk 'NR > 1 { printf "%s ", $2 }')"
    [[ "${size}" = "${width} ${height} no " ]] || return 1

    mv "${rendered}" "${output}"
}

frame_language() {
    local code="$1" entry folder direction
    entry="$(language_entry "${code}")"
    IFS='|' read -r _ folder direction _ <<<"${entry}"

    local captions="${CAPTIONS}/${folder}.json"
    local input_dir="${output_root}/${version}/${folder}"
    local output_dir="${output_root}/${version}-store/${folder}"
    step "${code} → ${version}-store/${folder}"
    mkdir -p "${output_dir}"

    local device_key device screens screen shot number file shot_screens
    for device_key in "${selected_devices[@]}"; do
        device="$(device_entry "${device_key}")"
        IFS='|' read -r _ screens <<<"${device}"
        for screen in ${screens}; do
            local opens_on_home=false
            [[ " $(shot_entry 1 | cut -d'|' -f3) " = *" ${screen} "* ]] && opens_on_home=true
            for number in "${selected_shots[@]}"; do
                shot="$(shot_entry "${number}")"
                IFS='|' read -r _ file shot_screens <<<"${shot}"
                [[ " ${shot_screens} " = *" ${screen} "* ]] || continue

                local name
                name="$(printf '%s-%02d-%s.png' "${screen}" "${number}" "${file}")"
                local title private="" open_source=""
                local opens_here=false
                [[ "${number}" = "1" ]] && opens_here=true
                [[ "${number}" = "2" ]] && [[ "${opens_on_home}" = false ]] && opens_here=true
                if [[ "${opens_here}" = true ]]; then
                    title="$(caption "${captions}" 1)"
                    private="$(caption "${captions}" private)"
                    open_source="$(caption "${captions}" openSource)"
                else
                    title="$(caption "${captions}" "${number}")"
                fi

                if [[ ! -f "${input_dir}/${name}" ]]; then
                    fail "${name}: no capture"
                    failures=$((failures + 1))
                elif [[ -z "${title}" ]]; then
                    fail "${name}: no caption for shot ${number} in ${folder}.json"
                    failures=$((failures + 1))
                elif render "${screen}" "${input_dir}/${name}" "${output_dir}/${name}" "${title}" "${private}" "${open_source}" "${code}" "${direction}"; then
                    ok "${name}"
                    written=$((written + 1))
                else
                    fail "${name}: the render failed"
                    failures=$((failures + 1))
                fi
            done
        done
    done
}

#MARK: - Main -

main() {
    parse_arguments "$@"
    check_environment

    local entry code folder
    if [[ ${#selected_languages[@]} -eq 0 ]]; then
        for entry in "${LANGUAGES[@]}"; do
            IFS='|' read -r code folder _ _ <<<"${entry}"
            if [[ -f "${CAPTIONS}/${folder}.json" ]]; then
                selected_languages+=("${code}")
            fi
        done
    fi
    if [[ ${#selected_devices[@]} -eq 0 ]]; then
        for entry in "${DEVICES[@]}"; do
            selected_devices+=("${entry%%|*}")
        done
    fi
    if [[ ${#selected_shots[@]} -eq 0 ]]; then
        for entry in "${SHOTS[@]}"; do
            selected_shots+=("${entry%%|*}")
        done
    fi

    written=0
    failures=0
    note "Version ${version}"
    for code in "${selected_languages[@]}"; do
        entry="$(language_entry "${code}")"
        IFS='|' read -r _ folder _ _ <<<"${entry}"
        if [[ ! -f "${CAPTIONS}/${folder}.json" ]]; then
            warn "${code}: no captions file (fastlane/store_screenshots/captions/${folder}.json), skipped"
            failures=$((failures + 1))
            continue
        fi
        frame_language "${code}"
    done

    printf '\n'
    if [[ ${failures} -gt 0 ]]; then
        fail "${written} written, ${failures} failed"
        exit "${EXIT_FAILED}"
    fi
    ok "${written} written to ${output_root}/${version}-store"
}

main "$@"
