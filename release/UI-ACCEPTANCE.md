# Simulator UI acceptance

## Automated smoke coverage

The `PrivateMomentsUITests` target runs as part of `scripts/verify-mac.sh` and the GitHub macOS workflow. Its tests launch the app on the selected iPhone Simulator and verify:

| Flow | Automated checks | Evidence |
|---|---|---|
| English primary flow | Today action is enabled → start session → pause/resume control is present → finish → recap is saveable → return to Today → open Timeline → open saved entry → detail empty-note state appears | XCTest assertions and screenshots attached to `.xcresult` |
| Simplified Chinese | Today navigation title and primary action use Simplified Chinese; primary action retains a stable accessibility identifier | XCTest assertions and screenshot attached to `.xcresult` |

The UI test creates one local journal entry. GitHub-hosted runners are ephemeral; on a developer Mac, run it in a disposable Simulator if a test record in the local simulator would be confusing.

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
| 2026-10-31 | Windows static checks | Project/localization/release audits pass; simulator UI tests are awaiting the GitHub macOS run. |
