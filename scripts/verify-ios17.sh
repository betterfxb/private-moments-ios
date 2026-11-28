#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'Run this verification on macOS with full Xcode.\n' >&2
    exit 1
fi

project="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_directory="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/private-moments-ios17.XXXXXX")"
result_bundle="${PRIVATE_MOMENTS_RESULT_BUNDLE:-$work_directory/PrivateMoments-iOS17.xcresult}"

select_ios17() {
    xcrun simctl list runtimes --json | python3 -c '
import json
import sys

runtimes = [
    runtime for runtime in json.load(sys.stdin)["runtimes"]
    if runtime.get("isAvailable") and runtime["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-17-")
]
if runtimes:
    def version(runtime):
        return tuple(map(int, runtime["version"].split(".")))
    print(max(runtimes, key=version)["identifier"])
'
}

download_ios17() {
    python3 - "$1" <<'PY'
import subprocess
import sys

try:
    result = subprocess.run(
        ['xcodebuild', '-downloadPlatform', 'iOS', '-buildVersion', '17.5', '-exportPath', sys.argv[1]],
        timeout=8 * 60,
    )
except subprocess.TimeoutExpired:
    print('The iOS 17.5 runtime download did not finish within 8 minutes.', file=sys.stderr)
    raise SystemExit(124)
raise SystemExit(result.returncode)
PY
}

printf 'Inspecting the cloud runner and its installed simulator runtimes.\n'
uname -m
sw_vers
xcodebuild -version
df -h "$work_directory"
xcrun simctl list runtimes
runtime="$(select_ios17)"

printf '\nVerifying the unsigned Release simulator product and deployment floor.\n'
build_arguments=(
    -project "$project/PrivateMoments.xcodeproj"
    -scheme PrivateMoments
    -derivedDataPath "$work_directory/DerivedData"
    CODE_SIGNING_ALLOWED=NO
)
xcodebuild "${build_arguments[@]}" -configuration Release \
    -destination 'generic/platform=iOS Simulator' -quiet build
release_app="$work_directory/DerivedData/Build/Products/Release-iphonesimulator/PrivateMoments.app"
minimum="$(plutil -extract MinimumOSVersion raw -o - "$release_app/Info.plist")"
printf 'Compiled minimum iOS version: %s\n' "$minimum"
[[ "$minimum" == '17.0' ]] || exit 1
python3 - "$project/tools" "$release_app/PrivateMoments" <<'PY'
from pathlib import Path
import sys

sys.path.insert(0, sys.argv[1])
from distribution.archive import validate_release_test_hooks

validate_release_test_hooks(Path(sys.argv[2]).read_bytes())
print("Unsigned Release excludes the Debug test and timeline trace hooks.")
PY

if [[ -z "$runtime" ]]; then
    printf '\nNo available iOS 17 runtime. Downloading iOS 17.5 from Apple.\n'
    archive_directory="$work_directory/runtime"
    mkdir -p "$archive_directory"
    if ! download_ios17 "$archive_directory"; then
        older_developer='/Applications/Xcode_16.4.app/Contents/Developer'
        if [[ ! -d "$older_developer" ]]; then exit 1; fi
        printf 'Retrying the official download through the installed Xcode 16.4.\n'
        archive_directory="$work_directory/runtime-xcode16"
        mkdir -p "$archive_directory"
        DEVELOPER_DIR="$older_developer" download_ios17 "$archive_directory"
    fi
    shopt -s nullglob
    images=("$archive_directory"/*.dmg)
    if [[ "${#images[@]}" -ne 1 ]]; then
        printf 'The official download did not produce one simulator disk image.\n' >&2
        exit 1
    fi
    xcodebuild -importPlatform "${images[0]}"
    xcrun simctl list runtimes
    runtime="$(select_ios17)"
fi

if [[ -z "$runtime" ]]; then
    printf 'iOS 17 runtime unavailable. No legacy UI test was executed.\n' >&2
    exit 1
fi

simulator="$(xcrun simctl create 'Private Moments iOS 17 compatibility' \
    com.apple.CoreSimulator.SimDeviceType.iPhone-15 "$runtime")"
cleanup() {
    if ! xcrun simctl delete "$simulator"; then
        printf 'Unable to remove the disposable compatibility simulator %s.\n' "$simulator" >&2
    fi
}
trap cleanup EXIT

printf '\nTesting the actual runtime %s on a disposable iPhone 15 (%s).\n' "$runtime" "$simulator"
xcrun simctl bootstatus "$simulator" -b
xcrun simctl ui "$simulator" appearance light
xcrun simctl ui "$simulator" content_size large

test_target='PrivateMomentsUITests/PrivateMomentsUITests'
xcodebuild "${build_arguments[@]}" -configuration Debug \
    -destination "platform=iOS Simulator,id=$simulator" \
    -resultBundlePath "$result_bundle" -parallel-testing-enabled NO \
    "-only-testing:$test_target/testCalendarEntryReturnsToMonthTags" \
    "-only-testing:$test_target/testTimelineSearchReflectsEditAndDeletion" \
    "-only-testing:$test_target/testTimelineDateAndTagFiltersCombineAndSurviveNavigation" \
    "-only-testing:$test_target/testManualEntryTimingDateFilterAndPersistence" \
    "-only-testing:$test_target/testReviewTabBrowsesPeriodsAndOpensFilteredRecord" \
    "-only-testing:$test_target/testReviewComparisonOpensRecordsFromPreviousMonth" \
    "-only-testing:PrivateMomentsTests/FavoritePersistenceTests" \
    "-only-testing:PrivateMomentsTests/RecapDraftRecoveryTests" \
    test
