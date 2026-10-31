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
- [ ] Review the attached screenshots in Xcode or download the `.xcresult`; CI success does not establish visual quality across devices or accessibility sizes.

## Developer and policy setup

- [ ] Fill legal publisher name, privacy contact email, and policy effective date.
- [ ] Review the privacy policy against the final archive and any SDKs.
- [ ] Host the English and Simplified Chinese policy at a public HTTPS URL.
- [ ] Put the privacy policy URL in App Store Connect and make the in-app privacy entry open the hosted policy; the current in-app page is a privacy summary.
- [ ] Provide a support URL and reviewer contact details.
- [ ] Confirm the App Privacy questionnaire against the exact archived build and every third-party partner. The draft answer assumes no developer-accessible off-device data collection.
- [ ] Complete App Store Connect's current age-rating questionnaire based on the actual UI and content.
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
