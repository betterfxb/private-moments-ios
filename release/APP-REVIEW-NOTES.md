# App Review Notes — Draft

## Reviewer path

1. Launch the app. No account or sign-in is required.
2. On **Today**, tap **Start a moment**, then **Finish**.
3. On **Quick recap**, choose a mood and rating, optionally add tags and a dummy private note, then tap **Save privately**.
   Cancelling an unsaved recap or changed reflection asks for confirmation. Oversized notes show the character/UTF-8 limit and cannot be saved until shortened.
4. Open **Timeline** to review the new entry; tap it to view, edit, or delete it.
5. Open **Settings → Privacy information** to review local storage, authentication, backup, and deletion disclosures.
6. In Settings, optionally enable App Lock to exercise the system authentication flow. A device passcode must be configured in the test environment.
7. Settings also offers explicit JSON export and restore. Exported backups are not encrypted by the app and can contain private notes; use synthetic review content only.

## Review facts

- This build has no account, advertising, analytics, health integration, partner sharing, app-run cloud sync, or third-party SDK.
- It requests no location, contacts, photo library, camera, or microphone permission.
- Journal entries stay in the app's local store. The user can explicitly export a JSON file to a destination selected in the system file interface.
- There are no seeded sample records. The reviewer can create a synthetic entry using the path above.
- The optional App Lock uses iOS LocalAuthentication. The app receives an authentication result, not biometric data.

## App Store Connect values still required

- Build number and tested Xcode/iOS versions: **[Fill after Mac verification]**
- App Review contact name, phone, and email: **[Developer to provide]**
- Public, localized privacy-policy URL: **[Host the approved policy and provide URL]**
- Support URL: **[Developer to provide]**
- Age-rating questionnaire: **[Answer for the exact submitted build; do not infer a rating from this draft]**
- App name availability and trademark review: **[Check in App Store Connect]**

Apple asks developers to describe new functionality specifically in Notes for Review and to keep metadata accurate; see [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).
