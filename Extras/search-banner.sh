#!/bin/bash
#
# search-banner.sh — draw the App Store search results banner, and upload it.
#
# Copies the iPhone captures of shots 1, 2 and 3 that screenshots.sh wrote to
# screenshots/<version>/captures/<locale>/ into fastlane/creative_assets/source/screens/<lang>/
# (ignored by git, like the captures), draws fastlane/creative_assets/source/search-3x2.html
# with headless Chrome, and writes fastlane/creative_assets/search-3x2-<lang>.png (3840 × 2560).
#
set -Eeuo pipefail

readonly PROGRAM="${0##*/}"
HERE="$(cd "$(dirname "$0")" && pwd)"
readonly HERE
readonly ASSETS="${HERE}/fastlane/creative_assets"
readonly TEMPLATE="${ASSETS}/source/search-3x2.html"
readonly CAPTIONS="${HERE}/fastlane/store_screenshots/captions"
readonly CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

readonly EXIT_FAILED=1
readonly EXIT_USAGE=2
readonly EXIT_ENVIRONMENT=3

# code | App Store Connect folder | text direction
readonly LANGUAGES=(
    "en|en-US|ltr"
    "he|he|rtl"
    "de|de-DE|ltr"
    "es|es-ES|ltr"
    "fr|fr-FR|ltr"
    "it|it|ltr"
    "pt-BR|pt-BR|ltr"
    "ar|ar-SA|rtl"
    "ja|ja|ltr"
    "ko|ko|ltr"
    "zh-Hans|zh-Hans|ltr"
)

# capture | the banner's file for it
readonly PHONES=(
    "iphone-01-home.png|home.png"
    "iphone-02-ai-filtering.png|ai.png"
    "iphone-03-blocked-texts.png|blocked.png"
)

output_root="${HERE}/screenshots"
version=""
selected_languages=()
upload=false


#MARK: - Output -

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    bold=$'\033[1m' red=$'\033[31m' green=$'\033[32m' reset=$'\033[0m'
else
    bold="" red="" green="" reset=""
fi

step() { printf '%s▸ %s%s\n' "${bold}" "$1" "${reset}"; }
ok()   { printf '  %s✓%s %s\n' "${green}" "${reset}" "$1"; }
fail() { printf '  %s✗%s %s\n' "${red}" "${reset}" "$1"; }
die()  { printf '%s%s: %s%s\n' "${red}" "${PROGRAM}" "$1" "${reset}" >&2; exit "${2:-${EXIT_ENVIRONMENT}}"; }

usage() {
    cat <<EOF
Usage: ${PROGRAM} [options]

Draw the App Store search results banner in every language from the latest
captured screenshots, and optionally upload it to the App Asset Library.

Options:
  -v, --version VERSION  The app version whose captures to use. Default: latest,
                         the one captured last (Extras/screenshots/latest).
  -l, --language CODE    Only this language (en, he, de, es, fr, it, pt-BR, ar, ja,
                         ko, zh-Hans). Repeat for more. Default: all 11.
      --upload           After drawing, upload each banner as
                         search-3x2-<lang>-<version>.png (the library skips a name it
                         already holds, so every release needs its own names), then
                         set them as that version's search banner in App Store
                         Connect. The version must already exist there.
  -h, --help             Show this help, then exit.

The banners land in Extras/fastlane/creative_assets/search-3x2-<lang>.png. Open
one to check it before uploading. Setting them is the same as running
  fastlane place_search_banner version:<version> suffix:<version>

Examples:
  ${PROGRAM} -l en                 Draw English only, to check it.
  ${PROGRAM}                       Draw all 11 languages.
  ${PROGRAM} --upload              Draw all 11, upload them and set them.

Exit status:
  0  every banner was drawn (and uploaded)
  1  at least one banner failed
  2  invalid usage
  3  the environment is not ready
EOF
}


#MARK: - Arguments -

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version)  [[ $# -ge 2 ]] || die "$1 needs a value" "${EXIT_USAGE}"; version="$2"; shift 2 ;;
        -l|--language) [[ $# -ge 2 ]] || die "$1 needs a value" "${EXIT_USAGE}"; selected_languages+=("$2"); shift 2 ;;
        --upload)      upload=true; shift ;;
        -h|--help)     usage; exit 0 ;;
        *)             die "unknown option: $1 (see --help)" "${EXIT_USAGE}" ;;
    esac
done

[[ -x "${CHROME}" ]] || die "Google Chrome is not installed at ${CHROME}"
command -v python3 >/dev/null || die "python3 is not installed"

if [[ -z "${version}" ]]; then
    [[ -L "${output_root}/latest" ]] || die "no ${output_root}/latest; pass -v VERSION"
    version="$(readlink "${output_root}/latest")"
fi
[[ -d "${output_root}/${version}/captures" ]] || die "no captures for ${version} in ${output_root}"


#MARK: - Drawing -

is_selected() {
    local code="$1"
    [[ ${#selected_languages[@]} -eq 0 ]] && return 0
    local selected
    for selected in "${selected_languages[@]}"; do
        [[ "${selected}" == "${code}" ]] && return 0
    done
    return 1
}

banner_url() {
    python3 -I - "$@" <<'EOF'
import json, sys, urllib.parse
template, captions, lang, direction = sys.argv[1:5]
caption = json.load(open(captions))
query = urllib.parse.urlencode({
    "lang": lang,
    "dir": direction,
    "title": caption["tagline"],
    "private": caption["private"],
    "openSource": caption["openSource"],
}, quote_via=urllib.parse.quote)
print("file://" + urllib.parse.quote(template) + "?" + query)
EOF
}

draw() {
    local code="$1" folder="$2" direction="$3"
    local captures="${output_root}/${version}/captures/${folder}"
    local screens="${ASSETS}/source/screens/${code}"
    local entry capture name
    mkdir -p "${screens}"
    for entry in "${PHONES[@]}"; do
        IFS='|' read -r capture name <<<"${entry}"
        [[ -f "${captures}/${capture}" ]] || { fail "${code}: missing ${captures}/${capture}"; return 1; }
        cp "${captures}/${capture}" "${screens}/${name}"
    done
    local captions="${CAPTIONS}/${folder}.json"
    [[ -f "${captions}" ]] || { fail "${code}: missing ${captions}"; return 1; }
    local url
    url="$(banner_url "${TEMPLATE}" "${captions}" "${code}" "${direction}")"
    local output="${ASSETS}/search-3x2-${code}.png"
    "${CHROME}" --headless --disable-gpu --hide-scrollbars --allow-file-access-from-files \
        --force-device-scale-factor=1 --window-size=3840,2560 --virtual-time-budget=5000 \
        --screenshot="${output}" "${url}" >/dev/null 2>&1 || { fail "${code}: Chrome failed"; return 1; }
    ok "${code} → ${output#"${HERE}"/}"
}

step "Drawing the search banner from the ${version} captures"
drawn=()
failed=0
for entry in "${LANGUAGES[@]}"; do
    IFS='|' read -r code folder direction <<<"${entry}"
    is_selected "${code}" || continue
    if draw "${code}" "${folder}" "${direction}"; then
        drawn+=("${code}")
    else
        failed=1
    fi
done
[[ ${#drawn[@]} -gt 0 ]] || die "nothing drawn" "${EXIT_FAILED}"


#MARK: - Upload -

if [[ "${upload}" == true ]]; then
    [[ "${failed}" -eq 0 ]] || die "not uploading: a banner failed" "${EXIT_FAILED}"
    step "Uploading as search-3x2-<lang>-${version}.png"
    copies=()
    for code in "${drawn[@]}"; do
        copy="search-3x2-${code}-${version}.png"
        cp "${ASSETS}/search-3x2-${code}.png" "${ASSETS}/${copy}"
        copies+=("${copy}")
    done
    remove_copies() { local copy; for copy in "${copies[@]}"; do rm -f "${ASSETS}/${copy}"; done; }
    trap remove_copies EXIT
    files="$(IFS=,; echo "${copies[*]}")"
    (cd "${HERE}" && fastlane upload_creative_assets "files:${files}") || die "the upload failed" "${EXIT_FAILED}"
    ok "uploaded"
    step "Setting them as ${version}'s search banner"
    (cd "${HERE}" && fastlane place_search_banner "version:${version}" "suffix:${version}") || die "setting the banner failed" "${EXIT_FAILED}"
    ok "set; App Store Connect now shows them on ${version}"
fi

exit "${failed}"
