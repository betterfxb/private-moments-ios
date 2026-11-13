# Private Moments — Native iOS MVP

Current batch (2026-11-13) — **large-text input and pending feedback acceptance complete**: source `204387dbc1b2b3de135a6901a2a8907e4ad353d5` passes [run 43381177893](https://github.com/betterfxb/private-moments-ios/actions/runs/43381177893) on four profiles, including 50 unit tests, five main UI methods, two UI methods per other profile and Release test-hook exclusion. Notes grow with text size, Done has a 44 pt target, compact keyboard metadata stays clear of the floating action, and bilingual draft continuity is checked through actual typing, keyboard dismissal, Edit and discard. 267 PNGs verified; 75 final originals opened. [Acceptance and limits](release/UX-ACCEPTANCE-10.md) · [unmodified originals](release/evidence/batch-10/index.html). This same-source result closes the pending batch-nine presentation acceptance; prior failures remain historical. Draft only; no main merge or Apple upload.

Historical backup and lock UX upgrade (2026-11-11): source `d4a6a83d5ab4c2d2c650bbe9309ae3e998989779` passed [run 43001370010](https://github.com/betterfxb/private-moments-ios/actions/runs/43001370010) on four profiles: 50 unit tests, five main-profile UI tests, two UI methods on each other profile, and actual Release Simulator Debug-hook exclusion. Restore now previews validated record counts before merge or separately confirmed replacement. File encoding/reading has progress feedback; authentication is serialized and stale background callbacks are ignored. Actual English system-file roundtrips and bilingual galleries pass on all four profiles. No source-copy reselection was needed in the final run; earlier diagnostic runs exercised that explicit recovery action with unchanged-count checks. 219 PNGs checked; 21 selected originals opened. [Acceptance and limits](release/UX-ACCEPTANCE-08.md) · [unmodified originals](release/evidence/batch-08/index.html).

Historical editing and recovery upgrade (2026-11-11): source `9070f3d89def44a79ba169c9c963567caad10dbe` passed [run 42900233189](https://github.com/betterfxb/private-moments-ios/actions/runs/42900233189) across four profiles: Debug/Release, actual Release Simulator Debug-hook exclusion, 32 unit tests, four main-profile UI tests and three bilingual galleries with save-failure recovery. Drafts survive an injected first write failure, toolbar reload and explicit retry; long-record details offer toolbar editing. 175 PNGs downloaded; 17 selected final originals opened. [Acceptance and limits](release/UX-ACCEPTANCE-07.md) · [unmodified originals](release/evidence/batch-07/index.html).

Historical core interaction upgrade (2026-11-11): source `02e4c07506ab8caa52cfb90210d9f5114ceeddd7` passed [run 42885697214](https://github.com/betterfxb/private-moments-ios/actions/runs/42885697214) across all four profiles: Debug/Release, 30 unit tests, four main-profile UI tests and three additional bilingual galleries. Reachable toolbar Save, clean manual cancellation, guarded changed/timed drafts, filter/search reset, shorter accessible week dates and explicit all-time statistics are implemented. 158 PNGs downloaded; 17 selected final originals opened. See [acceptance and remaining limits](release/UX-ACCEPTANCE-06.md) and [original-image evidence](release/evidence/batch-06/index.html). Development-only, without signing, upload or main merge.

Historical native visual upgrade (2026-11-10): source `dd8b6fe37274b707fadca13430bd9441eccd8c7f` passed [run 42828824461](https://github.com/betterfxb/private-moments-ios/actions/runs/42828824461) across all four profiles with Xcode26.2 / iOS26.2: Debug/Release builds, 30 unit tests, four main-profile UI tests and three additional bilingual galleries. All 150 PNGs were downloaded; 22 selected originals were opened. The implemented Rose system, core screens, corrections and limits are in [visual acceptance](release/VISUAL-UPGRADE-ACCEPTANCE.md); [originals and before/after gallery](release/evidence/batch-05/index.html) are retained in the repository. This does not establish user aesthetic approval, physical-device acceptance or release readiness.

Historical development archive verification (2026-11-10): source `0d24c3b` passed [run 42726665523](https://github.com/betterfxb/private-moments-ios/actions/runs/42726665523) on Xcode 26.2 / iOS 26.2: 25 packaging-tool tests, Debug/Release Simulator builds, 23 app unit tests, all three core UI tests and a validated arm64 iOS-device Release archive. The unsigned archive was downloaded and its SHA-256 matched the report. It is not installable or TestFlight-ready; no Apple upload occurred. See [DISTRIBUTION-PLAN.md](release/DISTRIBUTION-PLAN.md) for evidence and the owner's development-only boundary.

Historical four-profile visual baseline (2026-11-10): source `5fdd3cf` passed the [four-profile cloud run](https://github.com/betterfxb/private-moments-ios/actions/runs/42665863317), including Debug/Release Simulator builds, 23 unit tests and all three core UI tests. All 112 English/Simplified Chinese gallery captures were downloaded and reviewed. That matrix used Xcode 16.4 with the iOS 26.2 runtime; it does not establish four-profile acceptance for the Xcode 26.2 UI. See [UI-ACCEPTANCE.md](release/UI-ACCEPTANCE.md) for evidence and remaining manual/release gates.

## Current scope

This is the first native SwiftUI implementation slice for iPhone and iPad. It contains an offline journal flow:

`Today → Live session → Private recap → Timeline → Moment details`

Included: direct manual entry, editable occurrence date and exact minute/second duration, local calendar-day filtering, a pausable monotonic session timer, Together/Solo selection, mood/rating/tag/private-note capture, validated SwiftData local records, timeline search and Together/Solo filtering, record editing and deletion, empty states, local-storage failure feedback, an optional device-authentication app lock, explicit file protection, schema version 1, and a warm design-token/component layer. Settings also supports an explicit JSON backup, validated restore preview, merge restore, separately confirmed replacement restore with background file work and progress feedback, and a localized privacy information page.

Not included: HealthKit, Apple Watch, partner accounts/sharing, photos, location permission, widgets, or Live Activities. The app does not seed sample records. SwiftData is configured with CloudKit sync explicitly disabled. The local store is placed in Application Support, configured with `NSFileProtectionComplete`, and requests exclusion from device backup; Apple documents this backup flag as guidance rather than a guarantee. OS file protection encrypts files at rest while the device is locked, but this is not end-to-end encryption. Manual JSON backups are not encrypted by this app and include private notes. An active session is not recovered after the process is force-quit.

## Architecture

```text
SwiftUI feature views
        ↓
MomentStore + SessionClock + AppLockController (application state)
        ↓
Moment / MomentRepository (domain)
        ↓
SwiftDataMomentRepository + validated JSON backup codec
        ↓
Versioned SwiftData MomentEntity (local-only)
```

The UI depends on `MomentStore`; the store depends on the repository protocol; only the data adapter knows about `ModelContext`. The domain model does not import SwiftUI or SwiftData. Persisted enum values, tags, and record fields are validated on read; invalid rows fail the load rather than being silently changed to defaults. Repository mutations save explicitly and roll back the model context on failure. Backup imports validate version, size, record count, IDs, and field bounds before mutation; merge updates matching IDs, while replacement is a separate destructive action.

Each tab owns a NavigationStack. Today and Timeline keep independent route paths so their titles, search presentation and back navigation belong to the active tab. Session, recap and detail destinations hide the tab bar during their focused flows.

The store also tracks whether its journal can be read safely. If a read or persistence operation fails, write, delete, import, and export actions stay unavailable until a retry succeeds. Previously loaded entries can remain visible as a read-only snapshot; the app does not present an unknown record count as zero. If SwiftData container creation fails at launch, the startup screen offers an in-app retry. See [STORAGE-FAILURE-ACCEPTANCE.md](release/STORAGE-FAILURE-ACCEPTANCE.md) for pending iOS runtime checks.

## Open and run

1. Open `PrivateMoments.xcodeproj` on a Mac with Xcode 26.2. The UI matrix pins this version through `release/distribution-config.json`; the app deployment target remains iOS 17. New toolbar APIs have an iOS-availability fallback.
2. Select the `PrivateMoments` scheme and an iOS 26.2 simulator for the verified toolchain baseline. iOS 17 remains the minimum deployment target; older-runtime acceptance is a separate check.
3. Run the Mac acceptance script below, then walk the manual checklist in `EXECUTION-PLAN.md`.
4. Set a real bundle identifier and signing team before installing on a device or archiving.

### Static checks on Windows

From this directory, run the source localization and Xcode project-structure audits:

```sh
node tools/audit-localization.mjs
node tools/audit-xcode-project.mjs
node tools/audit-release-materials.mjs
```

The project audit checks that the hand-managed `.pbxproj` parses, object references resolve, app, unit-test, and UI-test targets are wired to the expected Swift files, build settings include the intended platforms, and the shared scheme references each target. It also checks the privacy manifest's declared API reasons and the app icon's asset reference, 1024×1024 dimensions, and opaque RGB encoding. The release audit checks English/Simplified Chinese store-field limits and keeps the in-app privacy summary and publication placeholders visible. It warns while the app bundle identifier is still the `com.example` placeholder. These static checks complement the cloud builds and XCTest; consult the verified source revision in [UI-ACCEPTANCE.md](release/UI-ACCEPTANCE.md) and finish the remaining physical-device/release gates before distribution.

The iOS app icon is in `Resources/Assets.xcassets/AppIcon.appiconset`. To regenerate its 1024×1024 source image on Windows, run `.\tools\generate-app-icon.ps1` from PowerShell in this directory. The current icon uses the app's warm paper and terracotta palette; inspect the rendered icon in Xcode Simulator before release.

## Mac build and test

The automated acceptance script requires macOS and full Xcode 26.2 with the matching iOS Simulator runtime. Apple ships `xcodebuild` with Xcode; the standalone Command Line Tools package does not include it. [Apple Xcode command-line tool reference](https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference?changes=la)

From this directory on the Mac:

```sh
xcodebuild -showdestinations -project PrivateMoments.xcodeproj -scheme PrivateMoments
IOS_SIMULATOR_DESTINATION="platform=iOS Simulator,id=REPLACE_WITH_SIMULATOR_UDID" bash scripts/verify-mac.sh
```

The script checks the active Xcode, builds Debug and Release for the generic iOS Simulator, then checks the Release binary for Debug-only hooks and runs 50 unit tests and five UI tests on the selected simulator. The unit suite covers validation, exact timing drafts, calendar-day/DST boundaries, backup/import and bounded file reads, authentication concurrency/background cancellation, isolated preferences, semantic color contrast, storage recovery, and real in-memory SwiftData rollback. The UI suite covers the bilingual screen gallery, session/recap discard confirmations, editing/filtering/search/reset/relaunch/deletion, clean and changed manual drafts, toolbar validation/save, manual-entry timing/date/persistence, and a real system backup-file roundtrip with preview/cancel/merge/replace/relaunch checks. UI tests use a UUID-specific persistent store in Debug; they never reset the normal journal, and Release does not accept this test-store argument. Open the `.xcresult` in Xcode and review failures, screenshots, and logs; Apple documents command-line test result bundles in its [test report guide](https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results). Automated checks do not replace VoiceOver, physical-device, signing, or App Store acceptance. See [UI-ACCEPTANCE.md](release/UI-ACCEPTANCE.md) for the latest verified revision and pending checks.

### GitHub Actions cloud verification

`.github/workflows/ios-ci.yml` runs on pushes and pull requests targeting `main`, plus manual dispatch. It runs four GitHub-hosted macOS simulator profiles:

| Profile | Device selection | Appearance / text size | Scope |
|---|---|---|---|
| `compact-light` | Compact iPhone, preferring iPhone SE (3rd generation) when available | Light / standard Large | Static audits, Debug and Release builds, all unit and UI tests |
| `phone-dark` | Available iPhone | Dark / standard Large | Static audits, Debug UI-test build, bilingual gallery and real English file roundtrip |
| `ipad-light` | Available iPad | Light / standard Large | Static audits, Debug UI-test build, bilingual gallery and real English file roundtrip |
| `compact-dark-accessibility` | Compact iPhone | Dark / largest accessibility size | Static audits, Debug UI-test build, bilingual gallery and real English file roundtrip |

The gallery requests 23 captures per language at standard text sizes and 25 at accessibility sizes, including six core screens, manual entry, calendar/filter states, filtered-empty and injected save-failure recovery states plus controls reached by scrolling. Seven actual system-file/restore captures per profile and three extra compact-light functional captures bring the base matrix coverage target to 219 PNGs, plus any explicitly recorded source-unavailable recovery captures; this is a target, not a claim that every revision has passed. The workflow selects the pinned Xcode 26.2 and a matching SDK runtime, then exports PNG files and uploads `private-moments-ui-screenshots-<profile>` and `private-moments-xcresult-<profile>` for seven days. Actual devices/runtime are recorded in job logs. This workflow disables code signing and does not archive or distribute the app; it requires no signing secrets. View runs and download artifacts from the repository's **Actions** tab. See [UI-ACCEPTANCE.md](release/UI-ACCEPTANCE.md) for execution records and manual coverage.

For focused backup diagnosis, manually dispatch **iOS validation** with `backup_smoke` enabled and choose `backup_smoke_profile`. This runs only nine backup unit tests and one real system-file UI roundtrip on the chosen profile (compact-light by default); it skips Release validation and is not full acceptance. Leave the option disabled for the complete four-profile suite. `tools/ui-test-matrix.py` is the single source for matrix profiles.

The project targets iOS 17 because this implementation uses SwiftData and Observation, which Apple documents for iOS 17 and later. SwiftData's `.none` CloudKit configuration explicitly disables managed iCloud sync. Native compilation and XCTest cannot run directly in this Windows workspace; the GitHub Actions workflow above performs them in the cloud. Interactive simulator review, physical-device validation, signing, and App Store archiving still require the relevant Mac environment and developer-account configuration. Check the **Actions** tab for the latest cloud build result.

## Development archives from Windows

The project remains in development; the owner has deferred paid Apple enrollment and distribution. A separate manual **iOS development archive** workflow selects Xcode 26.2, runs the core tests, creates a Release iOS-device archive without signing, and checks its identity, SDK, arm64 Mach-O platform, resources, privacy manifest, localizations, dSYM and absence of Debug test hooks. It requires no Apple secrets and produces an explicitly **unsigned, non-installable development archive**, not a TestFlight-ready IPA.

See [云端开发归档说明](release/CLOUD-DISTRIBUTION.md) for the Windows Actions UI steps and future opt-in TestFlight configuration, and [DISTRIBUTION-PLAN.md](release/DISTRIBUTION-PLAN.md) for this batch's scope/evidence. The future upload workflow is separate and disabled without explicit configuration. Real signing/upload, Apple processing and tester availability remain unverified until a paid account and matching credentials exist. Current simulator-only CI also pins Xcode26.2, but it still does not create a signed uploadable build.

## Languages

The app supports English and Simplified Chinese and follows the language selected by iOS, including per-app language settings. It does not keep a separate in-app language preference. `Resources/Localizable.xcstrings` contains app text; `Resources/en.lproj` and `Resources/zh-Hans.lproj` contain localized app metadata. Dates follow the device's regional formatting. User-entered notes and custom tags remain in the language in which they were written, and saved enum values remain stable across language changes.

`Resources/PrivacyInfo.xcprivacy` declares the app's app-private `UserDefaults` use (`CA92.1`) and file metadata access for a document selected by the user (`3B52.1`). The app does not track users or transmit journal records to a service. The explicit JSON export remains a user-initiated file and can include private notes; the person chooses its destination.

To add another language, add translations to the string catalog, provide that locale's `InfoPlist.strings`, add the locale identifier to the Xcode project's known regions, then check the full flow at standard and accessibility text sizes in the iOS Simulator.

The localization audit checks source-string coverage, catalog translations and format placeholders, localized metadata, and Xcode resource references without needing Xcode.

The `release` directory contains the store listing, privacy facts, bilingual privacy policy draft, App Review notes, and release checklist. The policy and review notes contain publisher-supplied placeholders. The in-app **Privacy information** page is currently a summary; before submission, host the approved localized policy and update the in-app entry to open its public URL.

Apple references: [SwiftData model container](https://developer.apple.com/documentation/swiftdata/modelcontainer), [SwiftData schema migration](https://developer.apple.com/documentation/swiftdata/schemamigrationplan), [SwiftData local persistence](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches), [SwiftData CloudKit configuration](https://developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct/none), [LocalAuthentication](https://developer.apple.com/documentation/localauthentication), [file protection](https://developer.apple.com/documentation/foundation/fileprotectiontype/complete), [backup exclusion](https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup), [privacy manifest format](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files?changes=latest_m_3&language=objc), [required-reason API values](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype), [App Icon asset catalogs](https://developer.apple.com/documentation/xcode/configuring-your-app-icon?changes=_3), and [Xcode system requirements](https://developer.apple.com/xcode/system-requirements).

## Data and release gates

Recap confirms cancellation when a timed record or edits are unsaved. The note editor and persistence validator share both the 10,000-character and 60 KB UTF-8 limits, and the editor explicitly states that backups include notes. The note-boundary unit tests passed in cloud run [41456362003](https://github.com/betterfxb/private-moments-ios/actions/runs/41456362003). Follow [RECAP-ACCEPTANCE.md](release/RECAP-ACCEPTANCE.md) and [UI-ACCEPTANCE.md](release/UI-ACCEPTANCE.md) for remaining runtime and device checks.

- `privateNote` remains local and is not included in any share payload; partner sharing has not been implemented.
- The initial store is explicitly versioned as schema V1. Add a new schema and migration stage before changing persisted fields after users have stored data.
- Device backup exclusion is best effort; use the explicit JSON export to move records. Protect the backup file yourself because it includes private notes and this app does not encrypt it.
- Run Xcode build, iPhone/iPad simulator checks, Dynamic Type/VoiceOver review, app-lock lifecycle, backup restore, persistence relaunch, file protection, and failure-path review on macOS before treating this as a runnable app.
- Complete [STORAGE-FAILURE-ACCEPTANCE.md](release/STORAGE-FAILURE-ACCEPTANCE.md) with a disposable simulator store before release.

## Project plan

See [EXECUTION-PLAN.md](EXECUTION-PLAN.md) for the staged roadmap, product decisions, completion gates, and Mac handoff checklist.
