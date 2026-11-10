# Release Checklist

## Windows-prepared

- [x] English and Simplified Chinese App Store metadata draft is present in `APP-STORE-METADATA.json`.
- [x] Privacy facts, bilingual policy draft, and reviewer path are present in this directory.
- [x] App has a localized **Settings → Privacy information** screen.
- [x] App privacy manifest and opaque 1024×1024 AppIcon are part of the Xcode project.
- [x] Windows localization, Xcode-project, and metadata audits pass.

## Cloud-verified

- [x] GitHub macOS run [41169968664](https://github.com/betterfxb/private-moments-ios/actions/runs/41169968664) passes Debug and Release iOS Simulator builds, all 13 domain tests, and both UI smoke tests on Xcode 16.4.
- [x] English start → finish → save → timeline → detail path and Simplified Chinese primary action pass in XCUITest; screenshots are in the Actions `private-moments-xcresult` artifact (available for seven days after the run).
- [x] Verify the separate `private-moments-ui-screenshots` PNG artifact: run [41170621499](https://github.com/betterfxb/private-moments-ios/actions/runs/41170621499) exported and uploaded three 1206×2622 screenshots from an iPhone 17 Pro; they were downloaded and opened successfully on Windows.
- [x] Review exported screenshots for the configured phone/iPad, appearance and text-size profiles: all 112 final gallery captures were checked on 2026-11-10. Manual VoiceOver and physical-device acceptance remain separate.

### UI quality batch, 2026-11-02

- [x] Run 23 unit tests, including semantic contrast, storage-state recovery and real in-memory SwiftData rollback: all passed in run [41456362003](https://github.com/betterfxb/private-moments-ios/actions/runs/41456362003), source `af4c81a`.
- [x] Run the first bilingual gallery on compact-light, phone-dark, ipad-light and compact-dark-accessibility; all gallery tests passed. The overall run failed in the separate full editing test.
- [x] Download and inspect first-pass phone-dark and compact-dark-accessibility screenshots; record and address observed CTA wrapping, transition captures, keyboard reachability and navigation/search presentation.
- [x] Push local per-tab navigation fix `7ebfb79`: approved execution recovered on 2026-11-10 and the pending commits were pushed successfully.
- [x] Verify all four profiles on final source `5fdd3cf`, run [42665863317](https://github.com/betterfxb/private-moments-ios/actions/runs/42665863317): Debug/Release builds, all 23 unit tests and the full editing/search/relaunch/deletion and discard UI suite pass. Phone-dark succeeded in targeted attempt 2 after the first job could not acquire a macOS runner; other results were retained.
- [x] Download and inspect the final 14-capture-per-language gallery for all four profiles: 112 original PNGs checked by name/dimensions, four contact sheets and critical original images opened. Source fixes include session-title contrast, native Timeline/search, keyboard dismissal and accessibility layouts. These are test evidence, not final App Store marketing assets.

See `UI-ACCEPTANCE.md`, `STORAGE-FAILURE-ACCEPTANCE.md` and `EXECUTION-PLAN.md` for the exact automated/manual boundaries and resume order.

## Development archive foundation (2026-11-10)

The owner has deferred paid Apple enrollment and wants further product development. This batch validates packaging infrastructure and unsigned development artifacts; it does not mark the product ready for TestFlight or App Store release.

- [x] Record the development-only decision and sequential plan in `DISTRIBUTION-PLAN.md`.
- [x] Add a nonsecret pinned toolchain policy and behavioral checks for versions, archive identity/resources, signing guards and cleanup.
- [x] Separate account-free development archiving from the future manual opt-in TestFlight upload workflow; document Windows usage in `CLOUD-DISTRIBUTION.md`.
- [x] Verify Xcode 26.2 / iOS 26.2 in [run 42726665523](https://github.com/betterfxb/private-moments-ios/actions/runs/42726665523), source `0d24c3b`: 25 tooling tests, Debug/Release Simulator builds, 23 app unit tests, all three UI tests and an actual arm64 iOS-device Release archive. Downloaded archive SHA-256 matches its report; resources, privacy manifest, bilingual metadata, English source fallback / Chinese UI table, dSYM and absence of Debug test hooks passed inspection. It remains unsigned and non-installable; no upload occurred.
- [ ] Before real distribution, enroll, register the final identity and app record, configure the `testflight` environment, then verify real signing/export/upload and Apple processing.

## Developer and policy setup

- [ ] Fill legal publisher name, privacy contact email, and policy effective date.
- [ ] Review the privacy policy against the final archive and any SDKs.
- [ ] Host the English and Simplified Chinese policy at a public HTTPS URL.
- [ ] Put the privacy policy URL in App Store Connect and make the in-app privacy entry open the hosted policy; the current in-app page is a privacy summary.
- [ ] Provide a support URL and reviewer contact details.
- [ ] Confirm the App Privacy questionnaire against the exact archived build and every third-party partner. The draft answer assumes no developer-accessible off-device data collection.
- [ ] Complete App Store Connect's current age-rating questionnaire based on the actual UI and content.
- [ ] Review export-compliance/encryption questions for the exact build; no automatic legal declaration is added by the development archive tooling.
- [ ] Check the app name and trademark availability in the target storefronts.
- [ ] If offering the app in mainland China, verify whether the app requires an ICP filing or other regional documentation.

## Mac build and product acceptance

- [ ] Complete `RESTORE-ACCEPTANCE.md`, including dialog-to-alert presentation, cancellation, empty backup replacement, and failure preservation.
- [ ] Complete `STORAGE-FAILURE-ACCEPTANCE.md`, including first-load failure, read-only cached data, retry recovery, and blocked mutation paths.

- [ ] Run `node tools/audit-localization.mjs` and `node tools/audit-xcode-project.mjs` from `ios/PrivateMoments`.
- [ ] On a Mac, run `xcodebuild -showdestinations -project PrivateMoments.xcodeproj -scheme PrivateMoments` and select the device/OS combinations needed for manual acceptance.
- [ ] Review and retain the cloud `.xcresult`; repeat `IOS_SIMULATOR_DESTINATION="platform=iOS Simulator,id=<UDID>" bash scripts/verify-mac.sh` locally when a Mac is available.
- [ ] Replace `com.example.PrivateMoments` with the publisher's final unique Bundle ID; configure the signing team.
- [ ] Confirm the built app contains `PrivacyInfo.xcprivacy` and AppIcon; inspect the icon in light/dark/tinted appearances.
- [ ] Test first launch, create/save/edit/delete, search/filter, app lock, backup export/import, relaunch persistence, both languages, Dynamic Type, VoiceOver, and privacy/failure states on iPhone and iPad.
- [ ] Complete `RECAP-ACCEPTANCE.md`, including discard confirmation, unchanged edits, character/UTF-8 limits, and VoiceOver escape; run the added note-boundary XCTest cases.
- [ ] Capture genuine App Store screenshots from the verified build in English and Simplified Chinese. Because this app supports iPad, include at least one 13-inch iPad screenshot and at least one iPhone with Dynamic Island (medium display) screenshot; confirm the exact accepted pixel sizes in Apple's current [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) when preparing the assets. Suggested sequence: Today, timer, recap, timeline, privacy/settings. Do not mock controls or show real personal records.
- [ ] Recheck every store description and screenshot against the submitted build; submit through TestFlight before App Review.

The app name and subtitle must each be at most 30 characters; promotional text at most 170; description at most 4,000; keywords at most 100. This draft is checked by `node tools/audit-release-materials.mjs`. See Apple's [App information reference](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information), [product page guidance](https://developer.apple.com/app-store/product-page/), [privacy requirements](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/), and [age-rating process](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating).
