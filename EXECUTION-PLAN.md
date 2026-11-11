# Private Moments — Project Execution Plan

## Latest batch: large text and result feedback — native acceptance blocked

The ordered [batch-nine plan](release/BATCH-09-PLAN.md) has implemented tasks1–4: bounded architecture review, large-text settings/short warnings, dismissible outcome feedback and actual native-flow test updates. Task5 remains incomplete. Two focused runs and one full run ended `startup_failure` before creating any job; the latest source `adf8545674c35e4c4bde4f3c492b843ab2f14ee6` is not established as compiled or accepted. Local audits pass, with release placeholders retained. See [status and reproducible startup diagnostics](release/BATCH-09-STATUS.md). Restore the execution channel, pass the same-source four-profile matrix, then inspect originals and publish acceptance. Do not substitute prior screenshots, skip failed assertions or mark the batch complete.

## Historical batch: backup review and authentication continuity

The [batch-eight plan](release/BATCH-08-PLAN.md) is complete: architecture review → validated backup review/background file work → serialized device authentication → unit and actual system-file tests → four-profile regression and original evidence. See [acceptance](release/UX-ACCEPTANCE-08.md). Backup schema and repository transaction behavior remain compatible. Physical authentication/privacy, external file providers, older runtimes and distribution remain separate.

## Historical batch: editing continuity and failure recovery

The [batch-seven plan](release/BATCH-07-PLAN.md) is complete: architecture review → retained-draft reload/retry → reachable detail editing → isolated native fault tests → four-profile regression and original evidence. [Acceptance](release/UX-ACCEPTANCE-07.md) records exact source, test counts, limits and follow-up priorities. Release Simulator binary checks exclude Debug-only test hooks. Backup schema, domain, storage transactions, timer and privacy services remain compatible; physical-device/system-picker and distribution work remain open.

## Historical batch: core interaction experience

The ordered [batch-six plan](release/BATCH-06-PLAN.md) is complete: architecture review → editor/save/discard improvements → browsing and recovery clarity → four-profile native regression → original-image review and retained evidence. [Acceptance](release/UX-ACCEPTANCE-06.md) identifies the exact tested source, corrected toolbar target issue, actual test counts and limits. Storage, backup schema, timer and privacy services were not changed. Work remains in draft PR #1; physical-device/older-runtime acceptance and distribution remain separate.

## Goal

Deliver a polished, privacy-first iPhone app with an offline record flow, then add Apple ecosystem features only after their data and sharing rules are explicit. The current Windows checkout can produce and inspect source, web prototypes, and documents. A supported Mac/Xcode environment is required to compile, simulate, sign, test on Apple devices, and submit.

Automated Mac verification runs in GitHub Actions. The last fully accepted backup/authentication source `d4a6a83d5ab4c2d2c650bbe9309ae3e998989779` passed [run 43001370010](https://github.com/betterfxb/private-moments-ios/actions/runs/43001370010) with Xcode26.2 / SDK26.2 / iOS26.2 in four profiles: 50 unit tests, five main-profile UI tests, two UI methods per other profile and actual Release hook exclusion. All 219 PNGs downloaded; 21 selected originals opened. See [historical acceptance](release/UX-ACCEPTANCE-08.md); this does not establish acceptance of the current batch. Earlier verification records below describe their own source revisions.

## Historical batch: native visual upgrade

The ordered [five-task plan](release/BATCH-05-PLAN.md) is complete: official-reference study → UI foundations → native core-screen upgrade → cloud regression → original-image review, correction and evidence. The [UI system](release/UI-SYSTEM-05.md) defines semantic Rose colors, system typography, content/input/selection/record structures and interaction states. Six core pages and privacy surfaces now use that system. Storage, backup schema, domain and application services were not changed by this batch.

The final original screenshots cover both languages, iPhone/iPad, dark appearance and maximum accessibility text; [the comparison gallery](release/evidence/batch-05/index.html) retains the source images. The theme is implemented, while user aesthetic judgment remains open. Physical VoiceOver/privacy, older-runtime acceptance, AppIcon/multiple themes and signing remain separate work. Work stays in draft PR #1 without merging main.

## Historical batch: native manual entry and day browsing

The ordered [five-task plan](release/BATCH-04-PLAN.md) is complete: architecture review → draft/day rules → native manual entry/editing/filtering → localization and regression → screenshot review and evidence. Direct manual entry bypasses the timer; date and exact minute/second duration are editable; saving returns to the actual occurrence day. No storage-schema or backup-format change was made. Maximum-accessibility Chinese form clipping and nested-scroll reachability were corrected and revalidated.

Work is on `feat/native-manual-entry`, draft [PR #1](https://github.com/betterfxb/private-moments-ios/pull/1); main has not been merged. At the end of that functional batch, the old theme remained in place. The later visual batch above supersedes that UI status; aesthetic approval remains open. Physical-device VoiceOver/privacy lifecycle, signing and TestFlight remain separate gates. That manual-entry batch audited 215 keys; the later visual batch audits 209 after removing unused placeholder copy.

## Product decisions for the first release

- **Core promise:** a private, local journal that remains useful without HealthKit, iCloud, a partner account, location, or a network connection.
- **Record fields:** occurrence date, duration, together/solo kind, mood, 1–5 rating, tags, and optional private note. `approximatePlace` remains a reserved model field but is not collected or shown in the first release. Health samples, photos, and location are outside the first release.
- **Privacy defaults:** notes and all records stay local; no analytics or share payload is created; biometric/device-passcode app lock is opt-in; backups are explicit user-created JSON files and may contain private notes.
- **Sharing:** no partner sharing in the first release. Later sharing must use a field allowlist, a preview generated from the exact outgoing payload, explicit consent, expiry/revocation states, and no note/health/location fields by default.
- **Data behavior:** imported backups are validated before mutation; merge is the default; full replacement requires a separate confirmation; malformed or unsupported backups leave existing records intact.
- **HealthKit:** defer until a concrete user-facing metric is selected. Sexual-activity and reproductive-health samples are sensitive and must never be requested just because the framework is available.

## Execution sequence and completion criteria

| Phase | Work | Completion criteria | Current status |
|---|---|---|---|
| 0. Inventory and plan | Reconcile prototype, native source, data flow, platform/tool constraints, and privacy boundaries | This plan is written; unrelated `care-nav-platform` remains untouched | Complete |
| 1. Native visual system | Reconcile the warm visual direction with reusable SwiftUI tokens/components and the main flows | Shared tokens; coherent Today/Session/Recap/Timeline/Detail/Settings; adaptive layouts and accessibility labels | Rose semantic system and six core screens implemented; four-profile Xcode26.2 matrix and 22 selected final originals reviewed; aesthetic approval remains open |
| 2. Offline core | Complete record creation/edit/delete, together/solo selection, validation, timer lifecycle, storage error behavior | All first-release records can be created, reopened, edited, filtered, and deleted locally; no false success state | Core create/edit/filter/search/delete/relaunch and pause/resume/discard flows passed in cloud; active-session process recovery remains outside the first release |
| 3. Privacy and data lifecycle | Add optional app lock, at-rest file protection policy, schema versioning, JSON export/import, safe restore behavior | Lock/restore policies are explicit; export/import validate and preserve existing data on failure; no unsupported security claims | Domain/import, recovery, bounded file reads and authentication state-machine tests passed; actual English system-file roundtrips and bilingual background-authentication cancellation pass on four profiles. Physical authentication/file protection and external providers remain pending |
| 4. Accessibility and resilience | Review VoiceOver, Dynamic Type, contrast, keyboard/privacy exposure, background behavior, and failure states | Every primary flow has a defined accessible and failure state; device review record exists | Dark/large-text layouts, semantic contrast, keyboard save and injected save-failure recovery verified; physical VoiceOver/privacy lifecycle and wider failure acceptance remain pending |
| 5. System localization | Localize the user-facing experience and app metadata for English and Simplified Chinese; follow the user's iOS app language | UI text, dynamic counts/errors, VoiceOver, system authentication, app name, and backup filename are localized; saved model/backup values remain stable | 230-key audit and bilingual recovery/authentication-cancellation gallery pass; in-place language switching and successful physical authentication remain manual gates |
| 6. Mac/Xcode verification | Build Debug/Release, run XCTest, validate simulator installation and resolve platform-only issues | Scripted build and test pass on a supported Mac; `.xcresult` is reviewed; failures are fixed before adding Apple integrations | Xcode26.2 Debug/Release, Release test-hook exclusion, 50 unit tests, five full-suite UI tests and two UI methods per other profile pass; physical signing/distribution remain separate gates |
| 7. Optional HealthKit | Choose and disclose only a specific needed data type; implement opt-in adapter | Denial/unavailability leaves core flow intact; permission text and data use are documented; verified on device | Deferred pending a concrete product metric, consent design, and Apple-platform validation |
| 8. Apple Watch | Add companion timer controls and clear disconnect/recovery behavior | Separate watch target builds; iPhone remains complete; disconnect does not lose a saved record | Deferred pending Mac/Xcode, device access, and Watch workflow definition |
| 9. Sync and partner sharing | Design CloudKit record sync and per-record field-allowlist sharing with conflict/expiry/revoke behavior | Exact payload preview, explicit consent, recoverable conflict states, and integration tests | Deferred pending data ownership, sharing policy, service/account design, and Mac/Xcode validation |
| 10. Release readiness | Build, test, sign, localized store metadata, privacy disclosures, TestFlight, accessibility and store review | Reproducible archive and signed TestFlight build; English and Simplified Chinese App Store listings and all release gates documented | App icon, manifest, bilingual listing/policy drafts, and in-app privacy summary prepared; hosted policy URL, archive, signing, age rating, store screenshots, and device gates remain pending |

## Current implementation order

1. **Complete:** freeze the local-first product and privacy rules above.
2. **Complete in source:** finish first-release UI and offline domain flow with Together/Solo selection, validation, explicit session discard, privacy handling, search and filtering.
3. **Complete in source:** add a versioned backup format, transactional repository operations, JSON export, merge import, and confirmed replace import.
4. **Complete in source:** add an opt-in LocalAuthentication gate and configure file protection before creating the SwiftData store. This is not end-to-end encryption.
5. **Complete in source:** add English and Simplified Chinese system localization for UI text, formatted/dynamic content, validation and storage errors, biometric reasons, accessibility labels, app display name, and backup filename. Keep stored enum and tag values stable.
6. **Cloud verified:** `scripts/verify-mac.sh` builds Debug and Release for Simulator and runs XCTest on the selected Mac runner. Windows remains the editing and screenshot-review host.
7. **Complete on Windows and CI:** `node tools/audit-localization.mjs`, `node tools/audit-xcode-project.mjs`, and `node tools/audit-release-materials.mjs` pass. Current checks cover 230 source keys, English/Simplified Chinese metadata and 109 project objects, including target membership, resources, configurations, scheme, manifest and icon. Existing publisher/Bundle ID warnings remain. Native build and test results are recorded separately in `release/UI-ACCEPTANCE.md`.
8. **Complete:** document the Mac handoff checklist for build, simulator, both languages, VoiceOver, data relaunch, failure-path, signing, and TestFlight work.
9. **Complete in source:** add the opaque 1024×1024 iOS AppIcon asset, a privacy manifest for the app-private UserDefaults preference and user-selected backup-file metadata access, and an in-app localized privacy summary. Confirm every declared API and reason against the source and current Apple documentation; review the icon and built manifest in Xcode before release.
10. **Deferred by scope:** hold HealthKit, Watch, CloudKit, and partner-sharing behind explicit product/privacy decision gates; do not collect sensitive data without concrete value and an Apple validation environment.

## Windows release-preparation follow-up (2026-10-30)

| Order | Goal and scope | Dependency | Outcome |
|---|---|---|---|
| 1 | Compare current App target APIs and release assets with Apple documentation | None | Complete: confirmed app-private `UserDefaults`, metadata access to a document selected by the user, and missing icon/manifest resources |
| 2 | Add an accurate `PrivacyInfo.xcprivacy` and wire it into App resources | Task 1 | Complete: declared `CA92.1` for app-private defaults and `3B52.1` for metadata of a user-selected file; no tracking or app-collected data declared |
| 3 | Create a reproducible warm AppIcon and attach its asset catalog to Debug/Release | Task 1 | Complete: opaque 1024×1024 RGB PNG, `AppIcon.appiconset`, Windows PowerShell generator, and target build settings added |
| 4 | Extend Windows static audit and update Mac handoff/release documentation | Tasks 2–3 | Complete: checks project references, manifest reasons, asset catalog, image dimensions/encoding, and records the Mac review steps |
| 5 | Run all checks available on Windows and record external blockers | Task 4 | Complete: both Node syntax checks, both audits, PowerShell parser check, and privacy-manifest XML parsing pass; Xcode build and XCTest remain blocked by the missing Apple toolchain |

**Issues handled:** the first icon output had an alpha channel; the generator now emits 24-bit RGB and the audit rejects PNGs with alpha. Windows' XML reader initially rejected the plist DTD; validation was rerun with DTD resolution disabled and the manifest parsed successfully. Neither issue required changing the privacy declarations or app behavior.

**Still blocked:** this Windows host has no `xcodebuild`, `swift`, `swiftc`, or `bash`. Asset Catalog compilation, the built app's manifest location, XCTest, simulator appearance, and device signing remain unverified until the Mac handoff checklist is run.

## Windows privacy and store-preparation follow-up (2026-10-30)

| Order | Goal and scope | Dependency | Outcome |
|---|---|---|---|
| 1 | Verify record fields, storage, authentication, backup/export behavior, network dependencies, and current Apple store requirements | None | Complete: no app network client or third-party package; identified that an imported backup can carry the optional `approximatePlace` label even though the current UI does not collect it |
| 2 | Add a localized privacy information page reachable from Settings | Task 1 | Complete: covers locally stored fields, device authentication, backups, deletion, and best-effort backup exclusion; English and Simplified Chinese strings pass the localization audit |
| 3 | Write a data-flow facts table and bilingual privacy policy draft | Tasks 1–2 | Complete: includes imported place labels, unencrypted user-directed exports, deletion boundaries, and explicit publisher/contact/URL/date placeholders |
| 4 | Prepare bilingual App Store text, reviewer steps, and release gates | Tasks 1–3 | Complete: metadata draft covers current functionality, review path is documented, and age-rating/name/URL/screenshots remain owner-verified |
| 5 | Add a Windows release-materials audit and verify the package | Task 4 | Complete: app names match localized display names; en and zh-Hans field limits pass; project and localization audits pass |

**Still blocked:** Apple requires a public privacy-policy URL in App Store Connect and accessible from inside the app. The repo contains a policy draft and an in-app privacy summary, but no publisher identity, contact email, public hosting URL, or final clickable policy URL is available. The current summary must be connected to the hosted policy before submission. The age-rating questionnaire, App Review contact, support URL, name availability, screenshots, and final App Privacy responses also require publisher/account input and a verified Mac build.

## Recap safeguards follow-up

| Order | Goal and scope | Dependency | Outcome |
|---|---|---|---|
| 1 | Review recap cancellation, note validation, and backup disclosure against domain/storage behavior | None | Confirmed immediate cancellation discarded edits, the editor omitted the UTF-8 bound, and its note label omitted backup inclusion |
| 2 | Add discard confirmation, shared note validation, and accurate backup wording | Task 1 | Source complete: new sessions always confirm discard; existing edits compare mood/kind/rating/tags/note with the original; unchanged edits exit directly; accessibility escape uses the same flow |
| 3 | Localize the new states and cover validation boundaries | Task 2 | English and Simplified Chinese pass the audit; two XCTest cases cover empty/exact/over character and UTF-8 byte boundaries; XCTest execution awaits Mac |
| 4 | Validate and record release evidence | Task 3 | Windows localization/project/release audits pass; `release/RECAP-ACCEPTANCE.md` records pending runtime scenarios |

No persistence schema or backup format change is required. The shared `validatePrivateNote` method is called by both the editor and full-moment validator. Source inspection confirms the discard actions invoke cancellation only after confirmation when there is unsaved content. Runtime navigation, layout, VoiceOver, and XCTest remain unverified on Windows. Existing policy/contact/Bundle ID and Mac/Xcode blockers still apply.

## System localization scope

### Restore safeguards follow-up (2026-10-31)

Executed sequentially: (1) inspect restore selection and mutation boundaries; (2) add a separate destructive replacement alert with local/imported record counts; (3) add English/Simplified Chinese text and audit it; (4) record runtime acceptance scenarios. The first restore dialog previously invoked replacement directly. Replacement now requires a second explicit action; cancel clears the pending import without changing journal records. Repository validation, transactional save, and rollback remain the mutation boundary.

The latest localization audit passes for 193 source keys. Project and release-material audits pass with the existing Bundle ID/publisher-information warnings. No new schema or backup format was introduced. Runtime dialog-to-alert presentation, VoiceOver, and restoration on Apple platforms remain pending; see `release/RESTORE-ACCEPTANCE.md`.

### Local-storage read failure safeguards (2026-10-31)

Executed in order: (1) trace load and mutation behavior through `MomentStore`, SwiftData repository, and Today/Timeline/Detail/Recap/Settings; (2) add an explicit storage-availability state and reject record/backup mutations until a fetch succeeds; persistence failures also trigger the read-only state, while validation errors remain ordinary user-correctable errors; (3) add retry UI, show record count as unknown, keep cached data read-only after a failure, and disable dependent actions; (4) localize retry/accessibility text and document simulator acceptance; (5) run the available Windows audits.

No persistence schema or backup format changed. Source safeguards and static audits are complete; fetch-failure injection, retry recovery, VoiceOver, and disabled-state rendering remain pending on Mac/iOS. See `release/STORAGE-FAILURE-ACCEPTANCE.md`.

### Startup container retry (2026-10-31)

Executed sequentially: (1) inspect `PrivateMomentsApp` startup ownership and `PrivateStoreFactory`; (2) make the optional `ModelContainer` and startup failure message observable app state; (3) add a localized retry action with progress feedback and duplicate-tap protection, entering the normal app on success and keeping the failure screen/private error log on failure; (4) extend storage acceptance and README; (5) run Windows static audits.

No model, schema, project-file, or backup changes were made. Retry behavior and startup responsiveness still require Mac/iOS runtime verification; container creation itself is synchronous, and a persistent or corrupt-store failure is reported but not repaired automatically. See `release/STORAGE-FAILURE-ACCEPTANCE.md`.

### Persisted-record decoding safeguards (2026-10-31)

Executed in order: (1) inspect SwiftData-to-domain mapping and all repository call sites; (2) reject unknown mood/kind identifiers, malformed tag JSON, and records outside domain bounds rather than substituting defaults; (3) make tag serialization errors propagate and wrap repository mutations in save/rollback handling; (4) map unsafe stored rows to a localized read-only error and add acceptance/documentation; (5) run Windows static audits.

No schema or backup-format migration was needed. A single invalid row currently blocks access to the full journal to avoid silently omitting or rewriting user data; automated repair/export of corrupt rows is not implemented. Verify conversion failures, rollback, and recovery on Mac/iOS before release; see `release/STORAGE-FAILURE-ACCEPTANCE.md`.

### GitHub macOS CI setup (2026-10-31)

Planned order: (1) inspect project root, scripts, credentials, Git tooling, and the supplied remote; (2) add generated-file ignore rules and a macOS GitHub Actions workflow for static audits, Debug/Release simulator builds, XCTest, and a short-lived result artifact; (3) validate configuration locally; (4) initialize and commit the iOS project, attach the supplied GitHub remote, push `main`, and inspect the first cloud run.

Completed: added `.gitignore`, `.gitattributes`, GitHub Actions workflow, and README instructions; initialized the app folder as a Git repository and pushed initial commit `d5c3b31` to `origin/main`. The first cloud run ([Actions run 41168231819](https://github.com/betterfxb/private-moments-ios/actions/runs/41168231819)) reached Swift compilation and failed on a missing one-string `AppLocalization.format` overload. The overload was added and pushed in `0aa5bd1`; all 13 existing domain XCTest passed in [Actions run 41168794346](https://github.com/betterfxb/private-moments-ios/actions/runs/41168794346). Debug/Release simulator builds and all static audits also passed. No signing or distribution secrets are required for simulator builds.

### Simulator UI smoke coverage follow-up (2026-10-31)

| Order | Goal and scope | Dependency | Outcome |
|---|---|---|---|
| 1 | Inspect app navigation, accessibility hooks, test target wiring, and simulator CI boundaries | Green domain-test workflow | Complete: XCTest previously exercised domain/storage/backup logic only; it did not launch SwiftUI screens |
| 2 | Add an XCUITest target for the English create-to-detail path and Simplified Chinese home screen; attach review screenshots | Task 1 | Complete locally: stable identifiers added to primary controls and record rows; test target and shared scheme wired |
| 3 | Extend project audits and document the automated/manual acceptance boundary | Task 2 | Complete locally: Xcode project, localization, and release-material audits pass; `release/UI-ACCEPTANCE.md` records coverage |
| 4 | Commit, push, and confirm simulator UI tests on the macOS runner | Task 3 | Complete: first run [41169419016](https://github.com/betterfxb/private-moments-ios/actions/runs/41169419016) exposed an unsupported navigation-bar accessibility query; after changing the test to assert the translated primary-action label, run [41169968664](https://github.com/betterfxb/private-moments-ios/actions/runs/41169968664) passed Debug/Release simulator builds, 13 domain tests, and both UI tests. The `.xcresult` screenshot artifact was uploaded. |

Manual VoiceOver, Dynamic Type, multi-device layout, privacy lifecycle, and storage-failure acceptance remain necessary. The UI smoke tests do not claim to replace those checks.

### Windows-accessible screenshot export follow-up (2026-10-31)

| Order | Goal and scope | Dependency | Outcome |
|---|---|---|---|
| 1 | Confirm Apple/Xcode supports extracting XCTest attachments from an `.xcresult` | Green UI-test run | Complete: the cloud runner uses Xcode 16.4, which includes `xcresulttool export attachments` |
| 2 | Export XCTest screenshots as PNG files and upload a separate short-lived artifact | Task 1 | Implemented locally: the workflow exports PNG attachments and uploads them for seven days |
| 3 | Push the workflow/documentation update and verify artifact export on the macOS runner | Task 2 | Complete: run [41170621499](https://github.com/betterfxb/private-moments-ios/actions/runs/41170621499) passed all builds, 13 domain tests, 2 UI tests, screenshot export, and both artifact uploads; three iPhone 17 Pro PNGs were downloaded and opened on Windows. |

- **Languages:** English (`en`, source language) and Simplified Chinese (`zh-Hans`). Additional languages can be added as catalog translations without changing stored records or enum cases.
- **Language selection:** follow iOS system and per-app language settings. Do not force a locale or add a separate in-app language preference; system authentication follows the same language choice.
- **Resources:** `Resources/Localizable.xcstrings` contains application strings; localized `InfoPlist.strings` supplies the app name and Face ID purpose text. The project declares `zh-Hans` as a known region and packages both resource types in the app target.
- **Coverage:** navigation, empty states, settings, import/export/restore, validation and storage failures, session/duration labels, VoiceOver hints, mood/kind names, built-in tags, lock prompts, and app metadata. Dates use Foundation formatting to respect regional date conventions.
- **Data compatibility:** mood and kind raw values remain persisted and exported identifiers. Standard tags are localized only for display and search; user-created text remains as entered. No SwiftData migration or backup-format change is required.
- **Layout requirements:** inspect both languages at standard and accessibility text sizes. Allow controls and cards to grow; verify segmented filters, tag wrapping, dialogs, long backup names, and VoiceOver labels for clipping or ambiguity.

## Risks and gates

- **No local Apple toolchain on Windows:** GitHub macOS runners provide the verified simulator builds and automated tests. Interactive simulator review, physical-device acceptance, signing and App Store distribution still need an appropriate Apple environment and account setup.
- **Sensitive local records:** file protection reduces at-rest exposure but is not end-to-end encryption. Device backup and migration behavior must be decided and verified before real user data is collected.
- **Plain JSON backups:** backups include notes by design so the user can recover their journal; the export screen must warn before the document picker opens, and imported data must be strictly validated.
- **Unclear HealthKit value:** defer data collection until the app can explain the user-facing benefit and request only the necessary type.
- **Partner sharing risk:** never send private notes, precise places, or raw health samples by default; revoke and conflict behavior needs a real CloudKit design and testing.

## Decision gates for deferred Apple integrations

Each integration starts only after its prerequisites are written down and approved as product requirements:

1. **User value:** name the user problem and measurable outcome that local journaling cannot already provide; do not add an integration solely to match a competitor checklist.
2. **Data and consent:** list exact HealthKit types or record fields, read/write direction, collection frequency, retention, deletion behavior, and the permission copy. Keep access opt-in and make denial a normal state.
3. **Failure behavior:** define offline, permission denied/revoked, unavailable hardware, account sign-out, partial sync, duplicate/conflicting edits, and recovery flows before wiring an adapter.
4. **Privacy and ownership:** define who owns each record, who can see it, how sharing is previewed, how expiry/revocation works, and which fields are never shared. Keep notes, precise places, and raw health samples excluded by default.
5. **Platform and operating cost:** confirm minimum OS, supported devices, Apple entitlements/accounts, service costs, support burden, and a Mac/Xcode test environment.
6. **Release gate:** add domain tests and device acceptance for both granted and denied permissions; do not make an external integration a dependency for the offline core.

## Mac handoff checklist

1. Install a full Xcode version supported by the Mac and its iOS Simulator runtime; command-line tools alone do not provide `xcodebuild`.
2. From `ios/PrivateMoments`, run `node tools/audit-localization.mjs` and `node tools/audit-xcode-project.mjs` to catch string, icon, privacy-manifest, and project-file wiring errors before opening Xcode.
3. Run `xcodebuild -showdestinations -project PrivateMoments.xcodeproj -scheme PrivateMoments` and select an available iOS Simulator UDID.
4. Set `IOS_SIMULATOR_DESTINATION="platform=iOS Simulator,id=<UDID>"` and run `bash scripts/verify-mac.sh`. The script builds Debug and Release for the generic iOS Simulator, runs the XCTest scheme on the selected simulator, and writes an `.xcresult` bundle under the Mac temporary directory. Fix every compiler, linker, test, SwiftData migration, and runtime failure before continuing.
5. Review the `.xcresult` report in Xcode; save the outcome and Xcode/macOS/simulator versions in the release checklist.
6. Confirm the AppIcon appears in simulator builds and remains legible in supported system appearances; verify `PrivacyInfo.xcprivacy` is present in the built app and compare its API declarations with the APIs used by the final dependency set.
7. Set a unique bundle identifier and signing team before installing on a physical device or archiving; the checked-in `com.example.PrivateMoments` value is only a placeholder.
8. Walk through start/pause/resume/finish/cancel, add/edit/delete, search/filter, export/import merge, replacement confirmation, app-lock enable/disable, and force-quit/relaunch.
9. Run with English and Simplified Chinese selected in iOS per-app language settings. Confirm in-app text, errors, accessibility labels, Face ID purpose prompt, home-screen name, and exported backup filename follow the selected language; switch languages without losing records.
10. Validate lock-screen/background privacy, file protection behavior, backup policy, Dynamic Type, VoiceOver, contrast, keyboard, and error recovery on iPhone and iPad in both languages. Check translated text at the largest accessibility sizes.
11. Localize the App Store Connect name, subtitle, description, screenshots, and privacy disclosures for English and Simplified Chinese; then archive/sign and distribute a TestFlight build before any App Store submission.

## UI quality and reliability batch (2026-11-02)

Authorized scope: tasks 1–4 from the current backlog. Execute implementation in order, then validate the dependent work together on the macOS runner.

| Order | Goal / scope | Dependency | Current result |
|---|---|---|---|
| 1 | Fix accent/session foregrounds in both appearances; adapt recap, rows, summary, filters and session scrolling for accessibility text | Inspect tokens and view ownership | Complete: contrast tests and final four-profile gallery pass; CTA wrapping, keyboard dismissal, native navigation/search and session-title contrast fixes verified |
| 2 | Capture both languages across six core screens, empty/saved states and controls; include compact phone, dark phone, iPad, and largest accessibility text | Task 1 | Complete: 14 captures per language per profile, 112 total; names/dimensions checked, four contact sheets and critical original images opened; isolated Debug-only UUID stores preserved |
| 3 | Verify pause/resume, discard/keep, edit/save/discard, filtering/search, relaunch persistence and delete/cancel | Task 2 helpers and stable identifiers | Complete: all three core UI tests pass in final run 42665863317, including typed note/Done/save, rating edit/discard, search/filter, relaunch and delete/cancel |
| 4 | Verify failed first/cached reads, mutation gating, successful/repeated retries, validation boundaries, corrupt rows and SwiftData rollback | Existing MomentStore/repository boundary | Complete at unit/repository level: all five store-recovery and three real in-memory SwiftData tests pass in final run. Failure-screen rendering, physical files and container startup remain manual acceptance |

Added two semantic-color contrast tests. The internal repository save closure defaults to ModelContext.save; injection lets tests trigger failure after real SwiftData changes and verify rollback from a fresh context. Production schema and backup format are unchanged. UI-test paths are compiled only in Debug; Release keeps the normal storage path.

The localization scanner now excludes accessibility identifiers, which are automation metadata, from translation checks. All three local audits pass with existing publisher/Bundle ID warnings.

Runtime gate met on 2026-11-10: all four CI profiles passed, 112 screenshots were exported and downloaded, and all four contact sheets plus critical original images were opened. Physical-device file protection, biometric authentication and manual VoiceOver review remain external acceptance work.

### Execution evidence and interruption

- Run [41456362003](https://github.com/betterfxb/private-moments-ios/actions/runs/41456362003), source `af4c81a`: all 23 unit tests passed. The bilingual gallery and session/recap discard UI test passed; the editing UI test failed when the software keyboard covered Save. The dark-phone, iPad-light and compact-dark-accessibility gallery jobs succeeded. This run is **not** an overall pass.
- Source `8dadd99` adds the keyboard dismissal action and waits for stable screen geometry before screenshot capture; run [41460567621](https://github.com/betterfxb/private-moments-ios/actions/runs/41460567621) had started, but its result could not be read at the 2026-11-02 interruption. The later investigation is recorded in the resumed verification below.
- Source `7ebfb79` gives Today, Timeline and Settings independent navigation stacks, addressing the missing native Timeline title/search presentation observed in first-pass screenshots. At that interruption it was committed locally but not pushed or compiled; pushing and cloud verification completed on 2026-11-10.
- Windows localization (201 source keys), Xcode-project and release-material audits pass. Existing Bundle ID and publisher-information warnings remain.
- **External blocker, 2026-11-02:** automatic approval review returned HTTP 403 on two read-only GitHub status requests and the subsequent authorized `git push origin main`. These commands were not executed. This is an approval-service failure, not a reported unsafe-code determination. No alternate route was used to bypass it.

The interruption's resume sequence was completed on 2026-11-10: approved network execution recovered, pending commits were pushed, all four final jobs passed, PNG artifacts were downloaded and inspected, and the verified outcomes were recorded here and in `release/UI-ACCEPTANCE.md`.

### Resumed cloud verification (2026-11-10)

Network approval recovered and the two pending local commits were pushed successfully. Retrieved run 41460567621: all 23 unit tests passed; the editing UI test passed keyboard dismissal and editing, then failed because the Timeline search field was absent. The compact accessibility gallery separately failed because the test required an off-screen lazy-grid rating button to exist before scrolling. The independent navigation stacks address the search presentation; test helper commit `267f4b5` scrolls while checking for lazy controls. Run [42658846976](https://github.com/betterfxb/private-moments-ios/actions/runs/42658846976) was superseded and cancelled. Run [42659232768](https://github.com/betterfxb/private-moments-ios/actions/runs/42659232768) passed the combined fixes; final visual corrections and acceptance are recorded below.

### Final outcome (2026-11-10)

Run 42659232768 passed all four jobs, then visual review identified a dark native session title under light appearance, a truncated accessibility-size Timeline title and incomplete control framing. Commit `47ea5e3` fixed the navigation appearance and recap framing; run 42663178514 passed all four jobs. Commit `5fdd3cf` completed Save, detail edit/delete and Settings-footer framing without changing application behavior.

Final source `5fdd3cf`, run [42665863317](https://github.com/betterfxb/private-moments-ios/actions/runs/42665863317), passed Debug/Release builds, all 23 unit tests, all three full-suite UI tests and three additional gallery executions. All profiles used Xcode 16.4 with iOS 26.2 Simulator runtime. Each produced 28 captures (14 English and 14 Simplified Chinese), for 112 total; the four contact sheets and key original images confirm the targeted fixes. See `release/UI-ACCEPTANCE.md` for devices, pixel dimensions and visual-review scope.

The first phone-dark job never acquired a hosted runner and was cancelled after 15 minutes; GitHub reported constrained macOS arm64 capacity. Only that job was rerun, successfully in attempt 2, retaining the other three passed results and artifacts. No application failure occurred in that unstarted job.

Local evidence is saved under the attached visualization workspace at `private-moments-quality-2026-11-10/run-42665863317`, including original PNGs, four contact sheets, per-profile review manifests and `QA-EVIDENCE.json` with job IDs, source revision, devices and archive SHA-256 values. Actions retains the uploaded PNG and result-bundle artifacts for seven days; the downloaded copies remain available locally. This closes authorized tasks 1–4; the manual device, backup/failure-screen, signing and distribution gates remain separate.

## Development archive foundation batch (2026-11-10)

The owner confirmed that no paid Apple Developer account exists and the product needs further development. Actual distribution is deferred. Tasks 1–5 in `release/DISTRIBUTION-PLAN.md` are complete: validated packaging/inspection tooling, separate unsigned and future TestFlight workflows, real account-free iOS-device archive verification, downloaded evidence and Windows usage documentation. No legal identity, registered Bundle ID or credentials were invented, and no Apple upload was performed.

Final source `0d24c3b`, [run 42726665523](https://github.com/betterfxb/private-moments-ios/actions/runs/42726665523), passed 25 tooling tests, Debug/Release Simulator builds, 23 application unit tests, three UI tests and an arm64 iOS-device Release archive on Xcode 26.2 / SDK 26.2. Both artifacts were downloaded; the archive SHA-256 matches its report and all 28 bilingual compact-light gallery images were checked by name/dimensions and reviewed via contact sheet and four critical originals. Evidence is in ignored `build/distribution-evidence-2026-11-10/run-42726665523`. Earlier workflow/destination issues and SDK-specific confirmation-popover test fixes are recorded in the distribution plan.

The archive is unsigned, non-installable and not TestFlight-ready. The future signed path remains unexecuted, and real signing/export/upload/Apple processing is deferred. No app business/UI source was modified. Next-development goals and dependency order are documented in `release/CLOUD-DISTRIBUTION.md`; backup/restore and failure-screen UI, interrupted-session recovery, broader new-SDK visual coverage and physical-device checks remain open.
