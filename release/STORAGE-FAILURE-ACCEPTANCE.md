# Local storage failure acceptance

Status: source safeguards and Windows static audits complete. Runtime behavior still needs a Mac/Xcode and iOS Simulator or device.

| Scenario | Expected result | Runtime result |
|---|---|---|
| SwiftData container creation fails at launch | Startup failure screen offers a localized retry action and explains the existing journal was not intentionally deleted | Pending Mac |
| Startup retry is in progress | Progress is visible and the action cannot be triggered repeatedly; check that the screen remains responsive during container creation | Pending Mac |
| Startup retry succeeds | The app enters Today and the existing journal loads normally | Pending Mac |
| Startup retry fails | The failure screen stays visible, logs the error, and allows another retry | Pending Mac |
| First journal read fails | Today and Timeline show a load failure with a retry action; neither presents a false empty-journal state or a zero-record count | Pending Mac |
| Start while the journal is unavailable | Session start is disabled until a successful reload | Pending Mac |
| Save, edit, delete, merge, or replace while unavailable | Application state rejects the mutation; no success message is shown and stored records are not intentionally changed | Pending Mac |
| Settings while unavailable | Record count is shown as unknown; export, import, and delete-all controls are disabled; retry remains available | Pending Mac |
| Previously loaded snapshot, then a read failure | Existing cached entries remain readable, but edit/delete and backup mutation actions are unavailable until a successful retry | Pending Mac |
| Persistence operation fails | The failed operation reports no success, repository rollback is preserved, and further mutations are gated until a successful reload | Pending Mac |
| Persisted row contains an unknown mood/kind, malformed tag JSON, or out-of-range fields | The app reports that a saved entry cannot be safely read, preserves the stored data, keeps mutations disabled, and does not substitute defaults or present an empty tag list | Pending Mac |
| Retry succeeds | The store reloads from the repository, clears the load error, and re-enables the actions appropriate to the current screen | Pending Mac |
| Retry fails repeatedly | The app remains read-only and continues to state that the journal could not be loaded | Pending Mac |
| English/Simplified Chinese, Dynamic Type, VoiceOver | Error, retry action, disabled-state hints, and unknown count are localized, readable, and announced clearly | Pending Mac |

Also verify that a failed first fetch followed by a successful retry shows existing persisted records. Use a disposable simulator store; do not simulate failures against a personal journal. This checklist covers application-level gating only; SwiftData rollback and file protection still require the existing Mac release checks. Repeated container initialization failures may still require diagnosing the underlying store or device issue; retry does not repair corrupted data.
