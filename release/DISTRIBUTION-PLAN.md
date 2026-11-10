# Development archive and future TestFlight batch (2026-11-10)

## Scope decision

The owner has no paid Apple Developer account and wants to continue product development. This batch builds the packaging foundation and verifies an **unsigned development archive** in the cloud. Actual signing, upload, tester distribution and App Store submission are deferred. No publisher identity, registered Bundle ID, Team ID or signing credential will be invented.

## Architecture and impact

The app is native SwiftUI with local SwiftData storage. Its existing simulator workflow has verified the core flow and gallery using Xcode 16.4. The shared scheme already archives the app in Release and excludes test targets from archiving. The checked-in Bundle ID remains a development placeholder. Repository/environment secret-name inventory found no signing setup.

New distribution tooling is independent of journal/domain code. A checked-in nonsecret policy defines the selected toolchain and archive expectations. Python standard-library helpers validate inputs, inspect built products and manage temporary signing state; no Fastlane or third-party Python package is needed. Manual GitHub workflows own the order of audits, SDK verification, simulator tests, archive inspection and artifact upload. Existing developer CI remains available.

## Sequential execution plan

| Order | Goal and scope | Depends on | Completion evidence |
|---|---|---|---|
| 1 | Inspect release gaps, Apple SDK requirements and credential availability; record owner's development-only boundary | None | This plan; current Apple/GitHub references below |
| 2 | Add nonsecret distribution policy, validated version/build inputs, signing configuration guards and product inspection | Task 1 | Behavioral unit tests, including invalid/simulator/incomplete archives and disabled uploads |
| 3 | Add reusable unsigned archive workflow and separate future manual TestFlight workflow | Task 2 | Secrets absent from unsigned jobs; native temporary-keychain signing path isolated behind explicit configuration |
| 4 | Run the unsigned workflow with selected Xcode 26.2, simulator tests and generic iOS-device Release archive | Task 3 | Successful cloud run; actual archive/SDK/resources/architecture report and downloadable archive ZIP |
| 5 | Inspect artifacts, document Windows usage, future credential setup and remaining product/release gates; push final records | Task 4 | Verified results and clean committed repository |

## Risks and boundaries

- The current Apple upload minimum is Xcode 26 / iOS 26 SDK. Simulator success with Xcode 16.4 does not satisfy that requirement. The new workflow explicitly selects Xcode 26.2 and verifies the actual SDK; it must fail instead of silently using the runner default.
- Building with a newer SDK can change SwiftUI/system controls. The new workflow runs the core UI suite and exports its bilingual gallery; any regression must be investigated before recording success.
- An unsigned `.xcarchive` is a development inspection artifact, not an installable or TestFlight-ready IPA. It retains the placeholder identity and contains no signing secrets.
- The future signed/upload path can be implemented and its guards tested now, but it cannot be certified end-to-end without a paid account, real matching certificate/profile, API key and App Store Connect app record.
- Public privacy/support URLs, legal publisher details, export-compliance answers, final product copy, physical-device privacy/VoiceOver checks and beta feedback remain future work. This batch does not mark the product release-ready.
- macOS hosted-runner capacity previously caused queued jobs to be cancelled. Retry only the affected job when the remaining results are valid.

## Verified primary references

- [Apple SDK minimum, effective April 28, 2026](https://developer.apple.com/news/upcoming-requirements/?id=04282026a)
- [Apple build upload and processing](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [Apple archive/export distribution](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [GitHub macOS 15 arm64 image: installed Xcode 26.2 and SDKs](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)
- [GitHub temporary certificate/profile installation](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications)

## Execution result

Task 1 complete. Initial task-2 checks passed in [run 42721228486](https://github.com/betterfxb/private-moments-ios/actions/runs/42721228486), source `9ce5a0a`: 20 behavioral tests plus existing audits. Task 3 added the reusable development archive workflow and separate future TestFlight workflow. The first dispatch was rejected before execution because `runner.temp` is not available in job-level `env`; commit `be1251a` initializes those paths in runner steps instead.

Task-4 run [42722434702](https://github.com/betterfxb/private-moments-ios/actions/runs/42722434702), source `be1251a`, passed 22 tooling checks and Debug/Release simulator builds with Xcode 26.2 / SDK 26.2. Tests then stopped because UUID normalization lowercased the destination, while Xcode enumerated the same simulator ID in uppercase. Commit `1df29e9` preserves uppercase destination IDs and adds a regression test for the environment/boot command boundary.

Run [42723455857](https://github.com/betterfxb/private-moments-ios/actions/runs/42723455857) passed 23 tooling tests, both simulator builds, all 23 app unit tests and the bilingual 28-capture gallery. Two interaction tests failed because SDK 26 confirmation popovers omit the cancel button. Exported accessibility hierarchies showed a real popover and destructive action; scrolling while searching for cancel dismissed the popover. Commit `39f5858` tests either a hittable cancel button or a tap outside the actual popover frame, then asserts dismissal and preserves the original data-state assertions. No application behavior changed. Apple's [SwiftUI new-design session](https://developer.apple.com/videos/play/wwdc2025/323/) describes the changed confirmation presentation; [confirmationDialog documentation](https://developer.apple.com/documentation/swiftui/view/confirmationDialog(_:isPresented:titleVisibility:actions:)) describes outside-tap dismissal for popovers.

Actual Xcode logs also show `xcstringstool` emitting only the translated Chinese UI table: English source keys need no redundant table. Commit `0d24c3b` accepts that fallback only when catalog source language and archived development region match and the catalog has no explicit translations for that locale. Chinese UI strings and both locales' display-name/Face ID metadata remain required. The report records which source each locale uses; two new behavior cases cover accepted and rejected fallback. Run 42726392413 was superseded and cancelled before completion to test both fixes together.

Final run [42726665523](https://github.com/betterfxb/private-moments-ios/actions/runs/42726665523), source `0d24c3b`, **passed** both jobs: tooling `129533940761` and native archive `129534002945`. This completes tasks 1–5 within the owner's development-only scope.

- Xcode 26.2 / iOS SDK 26.2 were explicitly selected and verified. Three source audits and all **25 tooling tests** passed.
- Debug and Release Simulator builds, all **23 application unit tests** and all **three core UI tests** passed. The simulator was iPhone SE (3rd generation), iOS 26.2, light appearance, standard Large text.
- A real `generic/platform=iOS` Release archive passed identity/version, arm64 Mach-O iOS platform, minimum OS 17.0, iPhone/iPad capabilities, AppIcon, privacy manifest, localized resources/metadata, dSYM and absent Debug test-hook checks. Version/build is `0.1.0 (4.1)` with the intentional development placeholder Bundle ID.
- Artifact `13722769104`, `private-moments-unsigned-development-4-1`, was downloaded. Its inner `PrivateMoments-UNSIGNED.xcarchive.zip` SHA-256 is `0198df165eb67cf191548344183a62f0778eaaeb2eb83f9dcc26bc071002b94c`, matching `distribution-report.json`. Windows ZIP inspection also confirmed the expected resources/dSYM and no `.p8`, `.p12` or provisioning profile.
- Artifact `13722874893`, `private-moments-distribution-tests-4-1`, was downloaded. All **28** gallery PNGs (14 per locale, 750×1334) matched expected names and dimensions. The full contact sheet and Session-en, Detail-controls-en, Recap-controls-zh-Hans and Settings-bottom-zh-Hans originals were opened. Session title, save control, detail actions and footer remain readable/reachable in this profile. This is not new-SDK iPad/dark/accessibility-size acceptance.
- Reports, both downloaded ZIPs, original screenshots, contact sheet, review manifest and `QA-EVIDENCE.json` are saved locally under `build/distribution-evidence-2026-11-10/run-42726665523` (ignored build evidence). Actions retains its artifacts for seven days; local downloaded copies remain available.

The report explicitly records `testflightReady: false`, `uploaded: false` and `signingPathEndToEndVerified: false`. TestFlight workflow execution count remains **zero**. No app/domain/data/UI production sources or Xcode project settings were changed in this batch; new packaging tools and UI-test compatibility are isolated from journal behavior. The future native signing/export/upload path is prepared and guarded, but still unverified with real credentials and intentionally deferred.

The next development backlog and dependency order are in `CLOUD-DISTRIBUTION.md`: backup/restore UI evidence, failure/retry UI evidence, designed session/draft recovery, new-SDK multi-device visual polish, physical-device privacy/accessibility, then a separate decision about beta distribution. Existing technical/MVP product copy and manual acceptance items remain open; this batch does not declare the product finished or ready for release.
