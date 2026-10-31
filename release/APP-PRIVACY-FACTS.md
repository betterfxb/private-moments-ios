# App Privacy Facts for Release

This is the source-of-truth inventory for the current iOS source. Recheck it against the final archive and every dependency before publishing App Store privacy answers.

## Current data flow

| Data or action | Why the app uses it | Where it lives | Sent to the app publisher? | User control |
|---|---|---|---|---|
| Date, duration, kind, mood, rating, tags, and optional private note | Create, display, search, and edit journal entries | SwiftData in the app's local Application Support directory | No network or server transfer exists in this source | Delete a record or delete all local records in Settings |
| Optional `approximatePlace` label | Preserved for backup compatibility; the first-release UI does not collect it and requests no location permission | Local SwiftData and JSON backup if a backup contains the field | No network or server transfer exists in this source | Delete the containing record or all local records |
| App Lock enabled/disabled preference | Remember the user's local lock setting | App-private `UserDefaults` | No | Change App Lock in Settings |
| Authentication result | Unlock the app through iOS LocalAuthentication | Processed by iOS; the app receives success/failure only | No biometric template or image is available to the app | Disable App Lock in Settings after device authentication |
| User-created JSON backup | Let the user move or restore journal records | File destination selected by the user; the file is unencrypted by this app | The app does not upload it to a service; the selected file provider may store it outside the device | Choose the destination; manage or delete exported copies with that provider |

## App Store privacy answer draft

**Proposed answer for the current source:** “No, we do not collect data from this app.” Apple defines collection for App Store privacy disclosures as transmitting data off device in a way the developer or partners can access. The current app has no account, app-run server, analytics, advertising, health integration, partner sharing, or third-party SDK. Keep this answer only if the final archived build and its dependencies still have those properties. The optional JSON export is an explicit user action to a destination chosen in the system file UI; explain that destination and its retention in the privacy policy and product description.

The privacy manifest's empty `NSPrivacyCollectedDataTypes` array and `NSPrivacyTracking = false` describe the current app source. A manifest does not replace the App Store Connect privacy questionnaire or the public privacy policy.

## Release facts to recheck

- `Sources/Domain/Moment.swift`, `Sources/Data/MomentBackup.swift`, and `Sources/Data/PrivateStoreFactory.swift` define the current fields, backup behavior, and local-store policy.
- `Sources/Application/AppLockController.swift` uses device authentication; it does not read biometric data.
- The project currently has no network client, analytics, advertising, account system, or third-party package reference.
- Do not claim that deletion removes copies stored by an export destination.
- Re-audit the final built app and bundled SDKs before publishing. If a new service or SDK is added, update this inventory, `PrivacyInfo.xcprivacy`, the App Store privacy answers, and both localized policies together.

Apple references: [App privacy details and the definition of collection](https://developer.apple.com/app-store/app-privacy-details/), [managing app privacy in App Store Connect](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/), and [App Review Guideline 5.1.1](https://developer.apple.com/app-store/review/guidelines/).
