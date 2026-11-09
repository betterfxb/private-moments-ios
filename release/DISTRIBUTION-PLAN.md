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

Tasks 2–5 pending execution. This section will record actual results, not planned upload success.
