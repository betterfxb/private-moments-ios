# Recap Acceptance Record

## Current editor verification (2026-11-11)

The [batch-six interaction report](UX-ACCEPTANCE-06.md) supersedes the historical status below for clean manual cancellation, changed/reverted manual drafts, toolbar Save and timing validation. Timed recap cancellation remains guarded. The latest four-profile evidence and exact source are linked there; per-field VoiceOver and injected save-failure UI acceptance remain open. The older table records its own revision only.

Status: source review and Windows audits complete. Final cloud run [42665863317](https://github.com/betterfxb/private-moments-ios/actions/runs/42665863317), source `5fdd3cf`, passed all 23 unit tests and all three core UI tests. The keyboard-covered Save issue is fixed: the test enters a synthetic note, dismisses the keyboard with Done, saves it, edits the rating, discards a later change, and verifies the original note/rating after relaunch. Basic new-reflection keep/discard confirmations also pass. The broader field-by-field and VoiceOver scenarios below still require manual acceptance.

| Scenario | Steps | Expected result | Runtime result |
|---|---|---|---|
| New timed record | Start a session, finish, cancel on recap | Confirmation appears even before changing recap fields, because the timed record is unsaved | Basic flow passed in final run 42665863317 |
| Keep new reflection | Enter a note and selections, cancel, choose Keep editing | Same screen and values remain; no journal entry is created | Pending Mac |
| Discard new reflection | Cancel and choose Discard reflection | Return to Today; no new entry is saved | Passed in final run 42665863317 |
| Unchanged existing entry | Open an entry, choose Edit reflection, immediately cancel | Return to details without a discard dialog; saved data stays unchanged | Pending Mac |
| Changed existing entry | Change mood, kind, rating, tag, or note separately; cancel | Every field change triggers confirmation; Keep editing preserves values; Discard leaves the stored entry unchanged | Rating change/discard passed in final run; other fields and Keep editing remain manual |
| Reverted changes | Edit an existing entry, then restore all original values | Cancel leaves without a discard dialog | Pending Mac |
| Save edit | Change a valid entry and save | Updated entry is persisted and recap exits without a discard prompt | Rating edit/save passed in final run 42665863317; other fields remain manual |
| Character limit | Enter 10,000 ASCII characters, then add one character | Exact boundary can save; over-limit text shows a validation message and disables save | Pending Mac |
| Byte limit | Run the UTF-8 boundary XCTest below | A note with few graphemes and exactly 61,440 UTF-8 bytes is accepted; one byte more is rejected | Validator XCTest passed in final run 42665863317 |
| Accessibility exit | Use VoiceOver escape on a new or modified recap | Same confirmation as Cancel; no immediate data loss | Pending Mac |
| Localization and layout | Repeat in English and Simplified Chinese, including largest accessibility text sizes | Dialogs, validation message, note counter, and backup label are readable and translated | Core layouts, empty-note counter, kind/rating and Save gallery accepted in four profiles; dialogs/validation states and VoiceOver remain manual |

`MomentValidationTests.testPrivateNoteAllowsEmptyAndExactCharacterLimit` and `testPrivateNoteUTF8BoundaryIsIndependentOfCharacterCount` exercise the shared validator. The existing full-moment validation tests still exercise the persistence/import validation entry point. Run all tests through `scripts/verify-mac.sh`; retain the `.xcresult` and update this record with device, OS, Xcode version, date, and pass/fail evidence.
