# Recap Acceptance Record

Status: source review and Windows audits complete. The following runtime checks and the XCTest suite have **not** run because the current host has no Xcode/Swift toolchain. Complete this record on Mac before release; use synthetic notes.

| Scenario | Steps | Expected result | Runtime result |
|---|---|---|---|
| New timed record | Start a session, finish, cancel on recap | Confirmation appears even before changing recap fields, because the timed record is unsaved | Pending Mac |
| Keep new reflection | Enter a note and selections, cancel, choose Keep editing | Same screen and values remain; no journal entry is created | Pending Mac |
| Discard new reflection | Cancel and choose Discard reflection | Return to Today; no new entry is saved | Pending Mac |
| Unchanged existing entry | Open an entry, choose Edit reflection, immediately cancel | Return to details without a discard dialog; saved data stays unchanged | Pending Mac |
| Changed existing entry | Change mood, kind, rating, tag, or note separately; cancel | Every field change triggers confirmation; Keep editing preserves values; Discard leaves the stored entry unchanged | Pending Mac |
| Reverted changes | Edit an existing entry, then restore all original values | Cancel leaves without a discard dialog | Pending Mac |
| Save edit | Change a valid entry and save | Updated entry is persisted and recap exits without a discard prompt | Pending Mac |
| Character limit | Enter 10,000 ASCII characters, then add one character | Exact boundary can save; over-limit text shows a validation message and disables save | Pending Mac |
| Byte limit | Run the UTF-8 boundary XCTest below | A note with few graphemes and exactly 61,440 UTF-8 bytes is accepted; one byte more is rejected | Pending Mac |
| Accessibility exit | Use VoiceOver escape on a new or modified recap | Same confirmation as Cancel; no immediate data loss | Pending Mac |
| Localization and layout | Repeat in English and Simplified Chinese, including largest accessibility text sizes | Dialogs, validation message, note counter, and backup label are readable and translated | Pending Mac |

`MomentValidationTests.testPrivateNoteAllowsEmptyAndExactCharacterLimit` and `testPrivateNoteUTF8BoundaryIsIndependentOfCharacterCount` exercise the shared validator. The existing full-moment validation tests still exercise the persistence/import validation entry point. Run all tests through `scripts/verify-mac.sh`; retain the `.xcresult` and update this record with device, OS, Xcode version, date, and pass/fail evidence.
