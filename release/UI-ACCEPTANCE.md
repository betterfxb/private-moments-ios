# Simulator UI acceptance

## Latest verification (2026-11-10)

Complete: source `5fdd3cf`, run [42665863317](https://github.com/betterfxb/private-moments-ios/actions/runs/42665863317), overall success on attempt 2. The full compact-light suite passes Debug/Release builds, 23 unit tests and all three UI tests; the other three profiles each pass the bilingual gallery. This is six UI-test executions in total. All profiles used Xcode 16.4 and the iOS 26.2 Simulator runtime.

| Profile | Actual simulator / pixels | Result | Final PNG review |
|---|---|---|---|
| compact-light | iPhone SE (3rd generation), 750×1334 | Passed, attempt 1 | 28 captures checked; contact sheet and session title opened |
| compact-dark-accessibility | iPhone SE (3rd generation), 750×1334; largest accessibility text | Passed, attempt 1 | 28 captures checked; kind/rating, full English Save, Chinese edit/delete, footer and Timeline title reviewed |
| ipad-light | iPad Pro 13-inch (M5), 2064×2752 | Passed, attempt 1 | 28 captures checked; contact sheet and dark session navigation title opened |
| phone-dark | iPhone 17 Pro, 1206×2622 | Passed, targeted attempt 2 | 28 captures checked; contact sheet, full edit/delete controls and Timeline navigation/search opened |

All captures use synthetic, isolated journal data. Review checks cover the six core screens in both languages, normal scroll behavior, native navigation/search, dark-surface text, and complete control framing. Long accessibility-size pages remain scrollable; the gallery captures selected sections rather than every possible state or one stitched full-page image.

The first phone-dark job was cancelled after 15 minutes in the queue. Its annotations report that a hosted runner could not be acquired and macOS arm64 capacity was constrained. The other three jobs succeeded. The targeted phone-dark rerun passed in attempt 2; other passed results and artifacts were retained. This was an infrastructure scheduling failure, with no phone-dark test execution on attempt 1.

All 112 original gallery PNGs were checked against the expected capture names and pixel dimensions. All four contact sheets were opened. Critical original images were also opened for light-system session titles, accessibility-size Save, edit/delete controls, Settings footer and Timeline navigation/search. Local evidence is under the attached visualization workspace's `private-moments-quality-2026-11-10/run-42665863317` directory. `QA-EVIDENCE.json` records the actual source, successful job IDs/attempts, devices, dimensions and archive hashes. The uploaded `private-moments-ui-screenshots-<profile>` and `private-moments-xcresult-<profile>` artifacts have seven-day retention; local downloaded copies remain available after that expiry.

| Observed issue | Change | Final evidence |
|---|---|---|
| Timeline native title/search missing | Separate NavigationStack and route path for each tab | Full search/filter UI test and gallery pass |
| Keyboard covers Save after entering a note | Localized keyboard Done action clears focus; interactive keyboard dismissal retained | Typed note → Done → Save → edit → relaunch preserves the note/rating |
| Dark foregrounds on accent/session surfaces; crowded accessibility layouts | Dedicated light foreground tokens, adaptive stacks/grids, scrolling and full-word CTA wrapping | Two semantic contrast tests and four-profile gallery pass |
| Native session title dark on the always-dark surface under light appearance | Force visible navigation-bar background with preferred dark bar scheme | Light compact-phone and iPad original screenshots show a clear light title |
| English Timeline title truncated at largest accessibility text | Use native inline title at accessibility sizes | Full title and search entry visible in accessibility gallery |
| Off-screen lazy controls or partly visible gallery actions | Scroll before requiring lazy controls; fit complete capture ranges below the navigation bar; wait for stable geometry | Full kind/rating, Save, edit/delete and footer captures accepted in both languages |

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
| 2026-11-10 | Network approval restored; historical run 41460567621 inspected | Keyboard dismissal and editing progressed successfully; full editing test failed at the missing Timeline search field. Accessibility gallery failed at a lazy rating button queried before scrolling. All 23 unit tests, phone-dark gallery and ipad-light gallery passed. |
| 2026-11-10 | Source `267f4b5`, run [42659232768](https://github.com/betterfxb/private-moments-ios/actions/runs/42659232768) | Pending commits pushed; lazy-control lookup corrected to scroll before requiring existence. This run validates the combined navigation, keyboard and gallery fixes. |
| 2026-11-10 | Run 42659232768 completed successfully | All four jobs passed: Debug/Release builds, 23 unit tests, all three full-suite UI tests and three additional bilingual gallery executions. All 112 gallery captures were downloaded, checked against expected names and dimensions, and opened in four contact sheets. Visual review found a dark session navigation title under light system appearance, an ellipsized accessibility-size Timeline title, and partly visible kind/rating sections in some gallery captures. |
| 2026-11-10 | Source `47ea5e3`, run [42663178514](https://github.com/betterfxb/private-moments-ios/actions/runs/42663178514) | All four jobs passed. Session navigation-title contrast and accessibility-size Timeline title verified; kind/rating sections captured fully. Review identified remaining framing improvements for Save, detail actions and Settings footer. |
| 2026-11-10 | Final source `5fdd3cf`, run 42665863317 | All four profiles passed; phone-dark succeeded after a targeted capacity-related retry. Debug/Release builds, 23 unit tests, three full-suite UI tests and three additional galleries pass. All 112 PNG captures downloaded, names/dimensions checked, four contact sheets and critical original images reviewed. Current batch complete. |

## Completion gate for the UI quality batch

Met on 2026-11-10: approved network execution and pushing recovered; the final full suite and all gallery jobs passed; all screenshot artifacts were exported, downloaded and reviewed. Publisher setup, signing, manual VoiceOver, app-lock lifecycle, physical file protection, startup/failure-screen rendering and full backup/restore UI acceptance remain separate release gates.

## Xcode 26.2 development archive verification (2026-11-10)

Source `0d24c3b`, [run 42726665523](https://github.com/betterfxb/private-moments-ios/actions/runs/42726665523), passed all 23 app unit tests and all three UI tests using Xcode 26.2 / iOS 26.2, iPhone SE (3rd generation), light appearance and standard Large text. Native SDK-26 confirmation popovers omit role-cancel buttons; the test now taps a visible cancel button when available or outside the actual popover frame, asserts dismissal and retains the original data-preservation checks. No app behavior was changed.

The latest 28 gallery PNGs (14 per language, 750×1334) and `.xcresult` were downloaded from artifact `13722874893`. Expected names/dimensions were checked, the complete contact sheet was reviewed and four originals were opened: Session-en, Detail-controls-en, Recap-controls-zh-Hans, Settings-bottom-zh-Hans. The session title, full save button, edit/delete actions and settings footer are readable and reachable in these captures. Local originals and review files are in `build/distribution-evidence-2026-11-10/run-42726665523/tests/DistributionScreenshots`.

This new-SDK result covers one compact-light iPhone profile. The earlier 112-capture four-profile matrix used Xcode 16.4 with the iOS 26.2 runtime, so iPad, dark and maximum accessibility text still need a new-SDK visual pass. Existing MVP/technical copy, backup/failure-screen UI and physical-device/VoiceOver checks remain development work. Packaging evidence and unsigned-distribution boundaries are in `DISTRIBUTION-PLAN.md`.
