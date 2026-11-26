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
INPUT_ONLY="${PRIVATE_MOMENTS_UI_INPUT_ONLY:-0}"
PERFORMANCE_ONLY="${PRIVATE_MOMENTS_UI_PERFORMANCE_ONLY:-0}"
WEEK_REVIEW_ONLY="${PRIVATE_MOMENTS_UI_WEEK_REVIEW_ONLY:-0}"
BACKUP_LANGUAGE="${PRIVATE_MOMENTS_UI_BACKUP_LANGUAGE:-en}"
ROTATION_ONLY="${PRIVATE_MOMENTS_UI_ROTATION_ONLY:-0}"
IPAD_TESTS="${PRIVATE_MOMENTS_UI_IPAD_TESTS:-0}"
ROTATION_START="${PRIVATE_MOMENTS_UI_ROTATION_START:-reference}"
ACCEPTANCE_PART="${PRIVATE_MOMENTS_UI_ACCEPTANCE_PART:-}"
GALLERY_ONLY="${PRIVATE_MOMENTS_UI_GALLERY_ONLY:-0}"
case "$ACCEPTANCE_PART" in
    ''|gallery|core|reading|journal-features) ;;
    *) fail "Unknown acceptance part: $ACCEPTANCE_PART." ;;
esac
[[ "$ACCEPTANCE_PART" == "" || ( "$BACKUP_ONLY" == "0" && "$INPUT_ONLY" == "0" && "$PERFORMANCE_ONLY" == "0" && "$WEEK_REVIEW_ONLY" == "0" && "$ROTATION_ONLY" == "0" && "$GALLERY_ONLY" == "0" ) ]] || fail "An acceptance part excludes other verification scopes."
[[ "$BACKUP_ONLY" == "0" || "$BACKUP_ONLY" == "1" ]] || fail "PRIVATE_MOMENTS_UI_BACKUP_ONLY must be 0 or 1."
[[ "$INPUT_ONLY" == "0" || "$INPUT_ONLY" == "1" ]] || fail "PRIVATE_MOMENTS_UI_INPUT_ONLY must be 0 or 1."
[[ "$PERFORMANCE_ONLY" == "0" || "$PERFORMANCE_ONLY" == "1" ]] || fail "Performance scope must be 0 or 1."
[[ "$PERFORMANCE_ONLY" != "1" || ( "$INPUT_ONLY" == "0" && "$BACKUP_ONLY" == "0" && "$ROTATION_ONLY" == "0" && "$IPAD_TESTS" == "0" ) ]] || fail "Performance smoke requires a phone and excludes other smoke modes."
[[ "$WEEK_REVIEW_ONLY" == "0" || "$WEEK_REVIEW_ONLY" == "1" ]] || fail "Week in review scope must be 0 or 1."
[[ "$WEEK_REVIEW_ONLY" != "1" || ( "$INPUT_ONLY" == "0" && "$BACKUP_ONLY" == "0" && "$ROTATION_ONLY" == "0" && "$PERFORMANCE_ONLY" == "0" ) ]] || fail "Week in review excludes other smoke modes."
[[ "$BACKUP_ONLY" != "1" || "$INPUT_ONLY" != "1" ]] || fail "Input and backup smoke modes are mutually exclusive."
[[ "$BACKUP_LANGUAGE" == "en" || "$BACKUP_LANGUAGE" == "zh-Hans" ]] || fail "Backup language must be en or zh-Hans."
[[ "$BACKUP_LANGUAGE" != "zh-Hans" || "$BACKUP_ONLY" == "1" ]] || fail "Chinese backup selection requires explicit backup smoke."
[[ "$ROTATION_ONLY" == "0" || "$ROTATION_ONLY" == "1" ]] || fail "Rotation scope must be 0 or 1."
[[ "$IPAD_TESTS" == "0" || "$IPAD_TESTS" == "1" ]] || fail "iPad test selection must be 0 or 1."
[[ "$ROTATION_ONLY" != "1" || ( "$IPAD_TESTS" == "1" && "$BACKUP_ONLY" == "0" && "$INPUT_ONLY" == "0" ) ]] || fail "Rotation smoke requires iPad and excludes input/backup smoke."
[[ "$ROTATION_START" == "reference" || "$ROTATION_START" == "cold-en" || "$ROTATION_START" == "cold-zh-Hans" || "$ROTATION_START" == "window-resize" || "$ROTATION_START" == "window-resize-keyboard" ]] || fail "Rotation start must be reference, cold-en, cold-zh-Hans, window-resize or window-resize-keyboard."
[[ "$ROTATION_START" == "reference" || "$ROTATION_ONLY" == "1" ]] || fail "Cold rotation and window resizing require explicit iPad diagnostics."
if [[ "$ROTATION_START" != "window-resize" ]]; then
    TEST_SCOPE_ARGUMENTS+=(-skip-testing:PrivateMomentsUITests/PrivateMomentsUITests/testIPadWindowResizeContinuity)
fi
if [[ "$ROTATION_START" != "window-resize-keyboard" ]]; then
    TEST_SCOPE_ARGUMENTS+=(-skip-testing:PrivateMomentsUITests/PrivateMomentsUITests/testIPadWindowResizeWithKeyboard)
fi
if [[ "$ROTATION_START" != "cold-en" ]]; then
    TEST_SCOPE_ARGUMENTS+=(-skip-testing:PrivateMomentsUITests/PrivateMomentsUITests/testIPadColdEnglishRotationContinuity)
fi
if [[ "$ROTATION_START" != "cold-zh-Hans" ]]; then
    TEST_SCOPE_ARGUMENTS+=(-skip-testing:PrivateMomentsUITests/PrivateMomentsUITests/testIPadColdChineseRotationContinuity)
fi
if [[ "$IPAD_TESTS" == "0" || "$ACCEPTANCE_PART" == "core" ]]; then
    TEST_SCOPE_ARGUMENTS+=(-skip-testing:PrivateMomentsUITests/PrivateMomentsUITests/testIPadRotationContinuity)
fi
if [[ "$INPUT_ONLY" != "1" ]]; then
    # The full gallery already exercises this flow inline.
    TEST_SCOPE_ARGUMENTS+=(-skip-testing:PrivateMomentsUITests/PrivateMomentsUITests/testTimelineSearchLayoutInBothLanguages)
fi
if [[ "$ACCEPTANCE_PART" != "reading" ]]; then
    TEST_SCOPE_ARGUMENTS+=(-skip-testing:PrivateMomentsUITests/PrivateMomentsUITests/testQuickJournalJourney)
fi
UI_SUITE=PrivateMomentsUITests/PrivateMomentsUITests
JOURNAL_METHODS=(
    testFavoriteCanBeFoundWithSearchAfterRelaunch
    testWeekReviewShowsLocalRecords
    testReviewTabBrowsesPeriodsAndOpensFilteredRecord
    testReviewComparisonOpensRecordsFromPreviousMonth
    testUnfinishedDraftSurvivesTerminationAndCanBeSavedOrDiscarded
)
JOURNAL_FEATURE_METHODS=(
    testTimelineDateAndTagFiltersCombineAndSurviveNavigation
    testRecordAgainCopiesOnlyTypeAndTags
    testMonthHighlightsOpenFavoritesAndMatchingFeelings
    testQuickRecordCanBeCompletedLaterAndReusesCustomTags
    testMonthCalendarOpensTheDayAndUpdatesAfterDeletion
)
if [[ "$ROTATION_ONLY" == "1" ]]; then
    printf '\nFocused iPad system-window diagnostic.\n'
    case "$ROTATION_START" in
        cold-en) ROTATION_METHOD=testIPadColdEnglishRotationContinuity ;;
        cold-zh-Hans) ROTATION_METHOD=testIPadColdChineseRotationContinuity ;;
        window-resize) ROTATION_METHOD=testIPadWindowResizeContinuity ;;
        window-resize-keyboard) ROTATION_METHOD=testIPadWindowResizeWithKeyboard ;;
        reference) ROTATION_METHOD=testIPadRotationContinuity ;;
    esac
    printf 'Rotation start: %s; selected method: %s\n' "$ROTATION_START" "$ROTATION_METHOD"
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/"$ROTATION_METHOD")
elif [[ "$PERFORMANCE_ONLY" == "1" ]]; then
    printf '\nFocused 1,000-record timeline measurement.\n'
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testLargeJournalInteractionBaseline)
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testTimelineSearchReflectsEditAndDeletion)
elif [[ "$WEEK_REVIEW_ONLY" == "1" ]]; then
    printf '\nFocused local Review and record retrieval validation.\n'
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsTests/MomentDateQueryTests)
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsTests/FavoritePersistenceTests)
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsTests/RecapDraftRecoveryTests)
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsTests/SemanticColorTests)
    for method in "${JOURNAL_METHODS[@]}"; do
        TEST_SCOPE_ARGUMENTS+=("-only-testing:$UI_SUITE/$method")
    done
elif [[ "$INPUT_ONLY" == "1" ]]; then
    printf '\nFocused input gallery and native search layout.\n'
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testScreenGallery)
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testTimelineSearchLayoutInBothLanguages)
elif [[ "$BACKUP_ONLY" == "1" ]]; then
    printf '\nFocused backup smoke only; this is not full simulator acceptance.\n'
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsTests/BackupUXTests)
    if [[ "$BACKUP_LANGUAGE" == "zh-Hans" ]]; then
        TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testChineseBackupFileRoundTrip)
    else
        TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testBackupFileRoundTrip)
    fi
elif [[ "$ACCEPTANCE_PART" == "gallery" ]]; then
    TEST_SCOPE_ARGUMENTS+=("-only-testing:$UI_SUITE/testScreenGallery")
elif [[ "$ACCEPTANCE_PART" == "reading" ]]; then
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsTests/SemanticColorTests)
    TEST_SCOPE_ARGUMENTS+=("-only-testing:$UI_SUITE/testJournalReadingSample")
    TEST_SCOPE_ARGUMENTS+=("-only-testing:$UI_SUITE/testQuickJournalJourney")
elif [[ "$ACCEPTANCE_PART" == "journal-features" ]]; then
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsTests/MomentDateQueryTests)
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsTests/MomentTagTests)
    for method in "${JOURNAL_FEATURE_METHODS[@]}"; do
        TEST_SCOPE_ARGUMENTS+=("-only-testing:$UI_SUITE/$method")
    done
elif [[ "$GALLERY_ONLY" == "1" ]]; then
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testScreenGallery)
    for method in "${JOURNAL_METHODS[@]}"; do
        TEST_SCOPE_ARGUMENTS+=("-only-testing:$UI_SUITE/$method")
    done
    TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testBackupFileRoundTrip)
    if [[ "$IPAD_TESTS" == "1" ]]; then
        TEST_SCOPE_ARGUMENTS+=(-only-testing:PrivateMomentsUITests/PrivateMomentsUITests/testIPadRotationContinuity)
    fi
else
if [[ "$ACCEPTANCE_PART" == "core" ]]; then
    for method in testScreenGallery "${JOURNAL_METHODS[@]}" "${JOURNAL_FEATURE_METHODS[@]}" testBackupFileRoundTrip testChineseBackupFileRoundTrip; do
        TEST_SCOPE_ARGUMENTS+=("-skip-testing:$UI_SUITE/$method")
    done
fi
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

if [[ "$ROTATION_ONLY" == "1" ]]; then
    printf '\nFocused iPad system-window diagnostic passed.\n'
elif [[ "$INPUT_ONLY" == "1" ]]; then
    printf '\nFocused input gallery and search layout passed; full regression is still required.\n'
elif [[ "$BACKUP_ONLY" == "1" ]]; then
    printf '\nFocused backup smoke passed; full regression is still required.\n'
elif [[ "$ACCEPTANCE_PART" != "" ]]; then
    printf '\nSimulator acceptance job passed: %s.\n' "$ACCEPTANCE_PART"
else
    printf '\nMac simulator acceptance passed.\n'
fi
printf 'Xcode result bundle: %s\n' "$RESULT_BUNDLE_PATH"
printf 'This script does not replace manual iPhone/iPad, localization, accessibility, privacy, or signing review.\n'
