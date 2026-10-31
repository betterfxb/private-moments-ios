# Simulator UI acceptance

## Automated smoke coverage

The `PrivateMomentsUITests` target runs as part of `scripts/verify-mac.sh` and the GitHub macOS workflow. Its tests launch the app on the selected iPhone Simulator and verify:

| Flow | Automated checks | Evidence |
|---|---|---|
| English primary flow | Today action is enabled → start session → pause/resume control is present → finish → recap is saveable → return to Today → open Timeline → open saved entry → detail empty-note state appears | XCTest assertions; screenshots are attached to `.xcresult` and exported as PNG artifact |
| Simplified Chinese | Primary action label is Simplified Chinese and retains a stable accessibility identifier | XCTest assertion; screenshot is attached to `.xcresult` and exported as PNG artifact |

The UI test creates one local journal entry. GitHub-hosted runners are ephemeral; on a developer Mac, run it in a disposable Simulator if a test record in the local simulator would be confusing.

## Manual acceptance still required

Automated smoke checks do not establish that every screen looks correct or that accessibility works in practice. Review on an iPhone and iPad Simulator and then a physical device where available:

- Inspect layout, contrast, icon rendering, and scrolling at default, dark, and increased text sizes.
- Use VoiceOver to navigate the primary flow, mood/rating/tag controls, dialogs, failure/retry UI, and Settings; confirm focus order, selected state, announcements, and privacy labels.
- Switch between English and Simplified Chinese through iOS language settings on each major screen, including validation, restore, storage failure, and accessibility-sized text.
- Verify VoiceOver and Dynamic Type behavior for long translated labels and dialogs.
- Test background privacy, app lock, force-quit/relaunch, SwiftData read/write failures and retry, backup export/import, merge, and separately confirmed replacement using disposable data.
- Review screenshots at the supported iPhone/iPad sizes; confirm nothing is clipped or hidden behind system bars or keyboard.

## Execution record

| Date | Environment | Result |
|---|---|---|
| 2026-10-31 | GitHub macOS simulator, run [41169419016](https://github.com/betterfxb/private-moments-ios/actions/runs/41169419016) | First run: English create-to-detail flow passed. Chinese primary action was correctly localized, but a navigation-bar query failed because SwiftUI did not expose that title as an `XCUIElementTypeNavigationBar`; the brittle title query was removed before rerun. |
| 2026-10-31 | GitHub macOS simulator, run [41169968664](https://github.com/betterfxb/private-moments-ios/actions/runs/41169968664), Xcode 16.4 | Passed: Debug/Release simulator builds, 13 domain tests, and 2 UI tests (English primary flow and Simplified Chinese primary action). The `.xcresult` screenshots were later exported and opened as standalone PNGs. |
| 2026-10-31 | GitHub macOS simulator, run [41170621499](https://github.com/betterfxb/private-moments-ios/actions/runs/41170621499), Xcode 16.4, iPhone 17 Pro | Passed: Debug/Release builds, 13 domain tests, 2 UI tests, `xcresulttool export attachments`, and both artifact uploads. Three 1206×2622 PNGs were exported (Today English, Moment details English, Today Simplified Chinese), downloaded, and visually opened; English and Chinese text fit the captured layout. Artifacts `private-moments-ui-screenshots` (0.59 MB) and `private-moments-xcresult` (0.76 MB) are retained by Actions for seven days. |
