# Restore confirmation acceptance

Source implemented; runtime verification is pending Mac/Xcode.

| Scenario | Expected result | Status |
|---|---|---|
| Select a valid backup, choose Merge | Existing merge behavior; no replacement alert | Pending Mac |
| Choose Replace all local records | A separate alert displays current local count and imported count before any mutation | Pending Mac |
| Cancel replacement alert | No repository mutation; local records unchanged; selected backup is cleared | Pending Mac |
| Confirm replacement | Existing validated transactional replacement runs; success is shown only if persistence succeeds | Pending Mac |
| Restore an empty backup | Confirmation states zero imported records; clearing the journal still requires explicit confirmation | Pending Mac |
| Storage write failure | Existing rollback preserves data and reports failure | Pending Mac |
| English/Chinese and VoiceOver | Counts, destructive/cancel buttons and messages are translated and readable | Pending Mac |

Specifically verify the transition from the import-choice confirmation dialog to the replacement alert on iPhone and iPad; Windows static checks cannot establish presentation behavior.
