# Simulator UI acceptance

## Automated coverage

The `PrivateMomentsUITests` target runs as part of `scripts/verify-mac.sh` and the GitHub macOS workflow. Coverage below describes the implemented assertions; the execution record identifies which source revisions have passed.

| Flow | Automated checks | Evidence |
|---|---|---|
| Bilingual gallery | English and Simplified Chinese Today → session → recap → saved Today → Timeline → detail → Settings; capture both top content and controls reached by scrolling | 14 requested captures per language; `.xcresult` and PNG artifact per profile |
| Discard safeguards | Session Cancel → Keep going / Discard; recap Cancel → Keep editing / Discard; discarded entries do not create journal rows | UI assertions |
| Edit and persistence | Pause/resume labels change; save a Solo entry with a synthetic note; save a rating edit; discard a later edit; terminate/relaunch with the same test-store UUID | UI assertions on preserved rating and note |
| Filtering, search, deletion | Together has no matching row; Solo has one; no-match and mood searches update results; delete Cancel preserves entry and confirmed delete removes it | UI assertions |

Every test launch uses a separate UUID store, reused only for that test's relaunch check. Every gallery locale also gets its own empty store. This path is compiled only in Debug and does not reset the normal journal. The matrix covers compact-light (full suite), phone-dark, ipad-light, and compact-dark-accessibility (gallery only). The expected total is 112 gallery captures across four profiles. Actual device names and runtimes are selected from runner availability and recorded in job logs.

The main profile also runs 23 unit tests, including two semantic contrast tests, five application-state recovery tests and three real in-memory SwiftData recovery/rollback tests. Repository tests inject a save error after mutating a real ModelContext and verify rollback through a fresh context. They do not simulate physical disk failure or replace device file-protection checks.

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
| 2026-11-02 | Run [41456362003](https://github.com/betterfxb/private-moments-ios/actions/runs/41456362003), source `af4c81a`, Xcode 16.4; compact profile selected iPhone SE (3rd generation), iOS 26.2 runtime | All 23 unit tests passed. Gallery passed on all four profiles; session/recap discard test passed on compact-light. Full run failed because the editing test could not reach Save with the software keyboard open. This first gallery version requested 12 captures per locale, before kind/rating captures were added. |
| 2026-11-02 | First-pass phone-dark and compact-dark-accessibility PNG artifacts from run 41456362003, downloaded and opened on Windows | Review found CTA word wrapping at the largest text size, captures taken during navigation transitions, and missing native Timeline title/search presentation. Normal dark text contrast was improved, but this is not final visual acceptance. |
| 2026-11-02 | Source `8dadd99`, run [41460567621](https://github.com/betterfxb/private-moments-ios/actions/runs/41460567621) | Keyboard Done action, clearer large-text CTA and stable-frame screenshot waits implemented. Final run status could not be read because automatic approval review returned HTTP 403 before the status requests executed. |
| 2026-11-02 | Local source `7ebfb79` | Independent per-tab navigation stacks implemented to restore native Timeline title/search. Local static audits pass; push was not executed because the same approval-service error blocked it. Swift compilation, full UI rerun and final screenshot review remain pending. |

## Completion gate for the current batch

Restore normal approved network execution, push the local fixes, and inspect the resulting four-profile run. Confirm the full compact suite passes, gallery artifacts are exported for every profile, and review the final screenshots before changing this batch to complete. Keep the publisher, signing, manual VoiceOver, app-lock lifecycle, physical file protection and backup/restore acceptance gates separate.
