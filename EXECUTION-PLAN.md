# Private Moments — Project Execution Plan

## Goal

Deliver a polished, privacy-first iPhone app with an offline record flow, then add Apple ecosystem features only after their data and sharing rules are explicit. The current Windows checkout can produce and inspect source, web prototypes, and documents. A supported Mac/Xcode environment is required to compile, simulate, sign, test on Apple devices, and submit.

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
| 1. Native visual system | Reconcile the warm visual direction with reusable SwiftUI tokens/components and the main flows | Shared tokens; coherent Today/Session/Recap/Timeline/Detail/Settings; adaptive layouts and accessibility labels | Source complete, including dark palette and design spec; runtime review awaits Xcode |
| 2. Offline core | Complete record creation/edit/delete, together/solo selection, validation, timer lifecycle, storage error behavior | All first-release records can be created, reopened, edited, filtered, and deleted locally; no false success state | Source complete; unit tests added, execution awaits Xcode |
| 3. Privacy and data lifecycle | Add optional app lock, at-rest file protection policy, schema versioning, JSON export/import, safe restore behavior | Lock/restore policies are explicit; export/import validate and preserve existing data on failure; no unsupported security claims | Source complete; device file/backup behavior awaits iOS verification |
| 4. Accessibility and resilience | Review VoiceOver, Dynamic Type, contrast, keyboard/privacy exposure, background behavior, and failure states | Every primary flow has a defined accessible and failure state; device review record exists | Source supports Dynamic Type, selection labels, private-note redaction, scene shielding, dark mode; runtime audit awaits Mac/iOS |
| 5. System localization | Localize the user-facing experience and app metadata for English and Simplified Chinese; follow the user's iOS app language | UI text, dynamic counts/errors, VoiceOver, system authentication, app name, and backup filename are localized; saved model/backup values remain stable | Source/resource audit complete; language-switch and layout review awaits Mac/iOS |
| 6. Mac/Xcode verification | Build Debug/Release, run XCTest, validate simulator installation and resolve platform-only issues | Scripted build and test pass on a supported Mac; `.xcresult` is reviewed; failures are fixed before adding Apple integrations | Mac runner and handoff steps prepared; execution awaits Mac/Xcode |
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
6. **Prepared in source:** add `scripts/verify-mac.sh` for Debug and Release simulator builds plus XCTest on a caller-selected simulator; the script itself is not run on this Windows host.
7. **Complete on Windows:** run `node tools/audit-localization.mjs`, `node tools/audit-xcode-project.mjs`, and `node tools/audit-release-materials.mjs`. The localization check passes for 190 source keys and English/Simplified Chinese metadata; the project audit passes for 96 project objects, target source membership, resources, configurations, shared scheme, privacy declarations, and app-icon asset checks. The release audit checks bilingual metadata limits and release placeholders. These are static checks only; Xcode build and XCTest execution remain unavailable on this host.
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

Completed: added `.gitignore`, `.gitattributes`, GitHub Actions workflow, and README instructions; initialized the app folder as a Git repository and pushed initial commit `d5c3b31` to `origin/main`. The first cloud run ([Actions run 41168231819](https://github.com/betterfxb/private-moments-ios/actions/runs/41168231819)) reached Swift compilation and failed on a missing one-string `AppLocalization.format` overload. The overload is now implemented locally and all three Windows static audits pass. Commit/push of the fix and the next cloud run are still pending. No signing or distribution secrets are required for simulator builds.

- **Languages:** English (`en`, source language) and Simplified Chinese (`zh-Hans`). Additional languages can be added as catalog translations without changing stored records or enum cases.
- **Language selection:** follow iOS system and per-app language settings. Do not force a locale or add a separate in-app language preference; system authentication follows the same language choice.
- **Resources:** `Resources/Localizable.xcstrings` contains application strings; localized `InfoPlist.strings` supplies the app name and Face ID purpose text. The project declares `zh-Hans` as a known region and packages both resource types in the app target.
- **Coverage:** navigation, empty states, settings, import/export/restore, validation and storage failures, session/duration labels, VoiceOver hints, mood/kind names, built-in tags, lock prompts, and app metadata. Dates use Foundation formatting to respect regional date conventions.
- **Data compatibility:** mood and kind raw values remain persisted and exported identifiers. Standard tags are localized only for display and search; user-created text remains as entered. No SwiftData migration or backup-format change is required.
- **Layout requirements:** inspect both languages at standard and accessibility text sizes. Allow controls and cards to grow; verify segmented filters, tag wrapping, dialogs, long backup names, and VoiceOver labels for clipping or ambiguity.

## Risks and gates

- **No Apple toolchain on this Windows host:** Swift/Xcode compilation, simulator execution, signing, device behavior, and App Store distribution cannot be confirmed here. Source changes must be reviewed and built on a compatible Mac before being treated as runnable.
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
