# Simulator UI acceptance

## Supplementary iPad maximum-text portrait gallery (2026-11-13)

Source `5c0a63757a8ff3d60f5a247a69c146884f973785`, [run 43419507000](https://github.com/betterfxb/private-moments-ios/actions/runs/43419507000), passes one bilingual input-gallery UI method on iPad Pro 13-inch (M5), Xcode/Simulator26.2, light appearance and system accessibility-extra-extra-extra-large. All 60 final original PNGs opened and retained at2064×2752. Keyboard visibility assertions were corrected after two archived failures; application code remains unchanged from the full result below. No new full matrix, 50 unit tests, Release or system-file roundtrip was performed in this supplement. [Report and limits](UX-ACCEPTANCE-11.md) · [all originals](evidence/batch-11/index.html) · [receipt](evidence/batch-11/verification.json). This closes only the previously unverified iPad light/max-text portrait gallery; physical IME/accessibility and remaining layouts stay open.

## Current input and large-text verification (2026-11-13)

Source `204387dbc1b2b3de135a6901a2a8907e4ad353d5`, [run 43381177893](https://github.com/betterfxb/private-moments-ios/actions/runs/43381177893), passes four profiles with 50 unit tests,5 main UI methods and2 UI methods on each other profile; Release Debug-hook exclusion verified. 267 exact-name PNGs verified and75 final originals opened. [Report](UX-ACCEPTANCE-10.md) · [originals](evidence/batch-10/index.html) · [receipt](evidence/batch-10/verification.json). This closes the earlier pending presentation validation without declaring old failed runs successful. Physical-device/IME/authentication/distribution limits remain explicit in the report.

## Historical backup and lock verification (2026-11-11)

Source `d4a6a83d5ab4c2d2c650bbe9309ae3e998989779`, [run 43001370010](https://github.com/betterfxb/private-moments-ios/actions/runs/43001370010), passes four profiles on Xcode26.2 / SDK26.2 / iOS26.2: 50 unit tests, five main-profile UI tests and two UI methods per other profile, with Release hook exclusion. Actual English system exporter/importer roundtrips verify preview cancellation, merge, separately confirmed replacement and exact data after relaunch. Bilingual galleries cover short export warnings and authentication cancellation recovery feedback. 219 PNGs checked; 21 selected originals opened. See [acceptance and limits](UX-ACCEPTANCE-08.md), [originals](evidence/batch-08/index.html) and [receipt](evidence/batch-08/verification.json). Physical authentication/VoiceOver, external file providers and older runtimes remain open; prior sections are historical.

## Historical editing and recovery verification (2026-11-11)

Source `9070f3d89def44a79ba169c9c963567caad10dbe`, [run 42900233189](https://github.com/betterfxb/private-moments-ios/actions/runs/42900233189), passes all four profiles on Xcode26.2 / SDK26.2 / iOS26.2. Compact-light includes Debug/Release builds, actual Release Simulator test-hook exclusion, 32 unit tests and four UI tests. Other profiles run a bilingual gallery including injected first-save failure, retained draft, toolbar reload and explicit retry. All 175 PNGs downloaded; 17 selected final originals opened.

Details now have a reachable toolbar Edit, and the editor offers reload without losing the draft. New coverage exercises selection revert/discard, notes and exact timing through failure/relaunch. See [acceptance](UX-ACCEPTANCE-07.md), [raw evidence](evidence/batch-07/index.html) and [receipt](evidence/batch-07/verification.json). Debug UUID-only fault injection is not a physical disk-failure certification; device privacy/accessibility, older runtimes and system backup-picker flows remain separate. Historical revisions below retain their own limits.

## Historical core interaction verification (2026-11-11)

Source `02e4c07506ab8caa52cfb90210d9f5114ceeddd7`, [run 42885697214](https://github.com/betterfxb/private-moments-ios/actions/runs/42885697214), passes four profiles with Xcode26.2 / SDK26.2 / iOS26.2: Debug/Release, 30 unit tests and four main-profile UI tests, plus three bilingual galleries. The editor adds a reachable toolbar Save with shared validation, clean manual-entry cancellation and preserved changed/timed draft protection. Timeline has truthful filtered-empty states and one-action query/type reset with keyboard dismissal; the week menu uses shorter visible dates and Today labels all-time statistics.

All 158 PNGs were downloaded and expected names checked; 17 selected final originals were opened. See [interaction acceptance](UX-ACCEPTANCE-06.md), [unmodified originals](evidence/batch-06/index.html) and [receipt](evidence/batch-06/verification.json). Native code matches the tested source; physical accessibility/privacy/feel, older runtimes and UI fault injection remain separate. Historical results below apply only to their revisions.

## Historical native visual-system verification (2026-11-10)

Source `dd8b6fe37274b707fadca13430bd9441eccd8c7f`, run [42828824461](https://github.com/betterfxb/private-moments-ios/actions/runs/42828824461), passed all four profiles using Xcode26.2, Simulator SDK26.2 and iOS26.2 runtime. Compact-light passes Debug/Release builds, 30 unit tests and four UI tests; the other profiles pass their bilingual gallery. All 150 PNGs were downloaded and expected capture names checked. 22 selected final-source originals were opened, including six core screens and maximum-text/date/control states. This is not manual review of every PNG or a physical-device accessibility certification.

The Rose theme, grouped editor/detail, compact record anatomy, native system navigation, accessible week menu and readable calendar selection are implemented in SwiftUI. Earlier green screenshots were rejected for visible defects and corrected. [Visual acceptance](VISUAL-UPGRADE-ACCEPTANCE.md), [unmodified images and comparison](evidence/batch-05/index.html), and [verification receipt](evidence/batch-05/verification.json) identify exact evidence and limits. Historical counts below apply only to their own revisions. Signing, physical VoiceOver/privacy, and user aesthetic approval remain separate.

## Historical native manual-entry verification (2026-11-10)

Source `b1225b5e065e81a5847c969d68278363780de9bd`, run [42801899567](https://github.com/betterfxb/private-moments-ios/actions/runs/42801899567), passed all four profiles. Compact-light passes Debug/Release builds, 30 unit tests and all four UI tests; the other three profiles pass the bilingual gallery. The 148 exported PNGs comprise 38 compact-light, 38 compact-dark-accessibility, 36 phone-dark and 36 ipad-light captures. Logs identify Xcode 16.4, iPhoneSimulator 18.5 SDK and iOS 26.2 Simulator runtime. This is not a new-SDK matrix result.

New coverage includes direct manual entry, exact minute/second editing, saved-day selection, empty-day filtering, cancel safeguards and relaunch persistence. Screenshot review rejected an earlier green run for Chinese maximum-text clipping. The final implementation uses a wrapping date row and a separate date panel at accessibility sizes, with input-frame boundary assertions. Twenty selected final-source originals were opened; this is not manual review of all 148 images. Retained unmodified images, hashes, profile details and limitations are in [the manual-entry acceptance record](MANUAL-ENTRY-ACCEPTANCE.md) and [verification receipt](evidence/batch-04/verification.json).

All evidence uses isolated synthetic stores. The existing global theme remains in place; these functional checks do not establish visual approval, physical VoiceOver/privacy acceptance or distribution readiness. Historical counts below describe their own source revisions only.

## Historical verification (2026-11-10, source 5fdd3cf)

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

## Historical automated coverage (source 5fdd3cf)

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
