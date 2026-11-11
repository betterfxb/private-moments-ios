#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PROJECT_DIRECTORY="$(cd "${SCRIPT_DIRECTORY}/.." && pwd)"
PROJECT_PATH="${APP_PROJECT_DIRECTORY}/PrivateMoments.xcodeproj"
SCHEME_NAME="PrivateMoments"
SIMULATOR_DESTINATION="${IOS_SIMULATOR_DESTINATION:-}"
DERIVED_DATA_DIRECTORY="${PRIVATE_MOMENTS_DERIVED_DATA:-${TMPDIR:-/tmp}/PrivateMomentsDerivedData}"
RESULT_BUNDLE_PATH="${PRIVATE_MOMENTS_RESULT_BUNDLE:-${TMPDIR:-/tmp}/PrivateMoments-$(date +%Y%m%d-%H%M%S)-$$.xcresult}"

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

if [[ "$(uname -s)" != "Darwin" ]]; then
    fail "Run this script on macOS with a full Xcode installation."
fi

for required_tool in xcodebuild xcode-select xcrun python3; do
    command -v "$required_tool" >/dev/null 2>&1 || fail "Required Xcode tool not found: ${required_tool}"
done

[[ -d "$PROJECT_PATH" ]] || fail "Xcode project not found: ${PROJECT_PATH}"

printf 'Xcode developer directory: '
xcode-select -p
xcodebuild -version

printf '\nAvailable project schemes and targets:\n'
xcodebuild -list -project "$PROJECT_PATH"

if [[ -z "$SIMULATOR_DESTINATION" ]]; then
    printf '\nAvailable destinations for scheme %s:\n' "$SCHEME_NAME"
    xcodebuild -showdestinations -project "$PROJECT_PATH" -scheme "$SCHEME_NAME"
    fail "Set IOS_SIMULATOR_DESTINATION to an available iOS Simulator destination and rerun."
fi

if [[ -e "$RESULT_BUNDLE_PATH" ]]; then
    fail "The result bundle path already exists; set PRIVATE_MOMENTS_RESULT_BUNDLE to a new path: ${RESULT_BUNDLE_PATH}"
fi
mkdir -p "$(dirname "$RESULT_BUNDLE_PATH")"

if grep -Fq 'PRODUCT_BUNDLE_IDENTIFIER = com.example.PrivateMoments;' \
    "${PROJECT_PATH}/project.pbxproj"; then
    printf '\nWARNING: the app still uses the placeholder bundle identifier. Simulator checks can run, but device signing and distribution require a unique identifier.\n'
fi

# Keep the array nonempty for macOS Bash 3.2 with `set -u`, and run on the
# configured simulator rather than parallel clones with different UI settings.
TEST_SCOPE_ARGUMENTS=(-parallel-testing-enabled NO)
BACKUP_ONLY="${PRIVATE_MOMENTS_UI_BACKUP_ONLY:-0}"
[[ "$BACKUP_ONLY" == "0" || "$BACKUP_ONLY" == "1" ]] || fail "PRIVATE_MOMENTS_UI_BACKUP_ONLY must be 0 or 1."
if [[ "$BACKUP_ONLY" == "1" ]]; then
    printf '\nFocused backup smoke only; this is not full simulator acceptance.\n'
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsTests/BackupUXTests)
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testBackupFileRoundTrip)
elif [[ "${PRIVATE_MOMENTS_UI_GALLERY_ONLY:-0}" == "1" ]]; then
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testScreenGallery)
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testBackupFileRoundTrip)
else
printf '\nBuilding Debug for the generic iOS Simulator destination...\n'
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Debug \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA_DIRECTORY" \
    CODE_SIGNING_ALLOWED=NO \
    build

printf '\nBuilding Release for the generic iOS Simulator destination...\n'
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA_DIRECTORY" \
    CODE_SIGNING_ALLOWED=NO \
    build

printf '\nChecking the Release Simulator executable for Debug-only test hooks...\n'
python3 - "${APP_PROJECT_DIRECTORY}/tools" "${DERIVED_DATA_DIRECTORY}/Build/Products/Release-iphonesimulator/PrivateMoments.app/PrivateMoments" <<'PY'
from pathlib import Path
import sys
sys.path.insert(0, sys.argv[1])
from distribution.archive import validate_release_test_hooks
validate_release_test_hooks(Path(sys.argv[2]).read_bytes())
print("Release Simulator executable excludes Debug-only UI-test hooks.")
PY

fi
printf '\nRunning XCTest on destination: %s\n' "$SIMULATOR_DESTINATION"
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Debug \
    -destination "$SIMULATOR_DESTINATION" \
    -derivedDataPath "$DERIVED_DATA_DIRECTORY" \
    -resultBundlePath "$RESULT_BUNDLE_PATH" \
    "${TEST_SCOPE_ARGUMENTS[@]}" \
    CODE_SIGNING_ALLOWED=NO \
    test

if [[ "$BACKUP_ONLY" == "1" ]]; then
    printf '\nFocused backup smoke passed; full regression is still required.\n'
else
    printf '\nMac simulator acceptance passed.\n'
fi
printf 'Xcode result bundle: %s\n' "$RESULT_BUNDLE_PATH"
printf 'This script does not replace manual iPhone/iPad, localization, accessibility, privacy, or signing review.\n'
