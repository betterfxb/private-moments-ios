import SwiftUI
import UniformTypeIdentifiers

private enum BackupStatus {
    case success(String)
    case error(String)
}

struct SettingsView: View {
    @Environment(MomentStore.self) private var store
    @Environment(AppLockController.self) private var privacyLock
    @State private var showingDeleteAllConfirmation = false
    @State private var deletionCompleted = false
    @State private var showingExportWarning = false
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingImportChoices = false
    @State private var showingReplaceConfirmation = false
    @State private var backupDocument = MomentBackupDocument(data: Data())
    @State private var pendingImport: MomentBackupEnvelope?
    @State private var backupStatus: BackupStatus?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                VStack(alignment: .leading, spacing: 8) {
                    PrivateBadge()
                    Text("Your privacy,\nyour rules.")
                        .font(.system(.largeTitle, design: .serif))
                        .tracking(-1)
                        .foregroundStyle(AppColors.ink)
                    Text("Core journaling works offline. Optional Apple services are not connected in this MVP.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppColors.inkSoft)
                }

                settingsCard(title: "ON THIS DEVICE") {
                    Label("Local journal", systemImage: "iphone")
                    Divider().overlay(AppColors.line)
                    HStack {
                        Label("Saved moments", systemImage: "heart.text.square")
                        Spacer()
                        Text(store.isStorageAvailable ? "\(store.moments.count)" : AppLocalization.string("Unknown"))
                            .foregroundStyle(AppColors.inkSoft)
                    }
                    Divider().overlay(AppColors.line)
                    Label("No cloud sync configured", systemImage: "icloud.slash")
                    Divider().overlay(AppColors.line)
                    Label("Files protected while device is locked", systemImage: "lock.fill")
                    Text("The app requests exclusion from device backups. Use the JSON backup controls below to move records to another device.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppColors.inkSoft)
                    if !store.isStorageAvailable {
                        StorageRecoveryCard(
                            message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                            onRetry: store.reload
                        )
                    }
                }

                settingsCard(title: "NOT CONNECTED") {
                    Label("HealthKit and Apple Watch", systemImage: "heart")
                    Divider().overlay(AppColors.line)
                    Label("Partner sharing", systemImage: "person.2")
                    Text("This starter keeps all entries on this device. No health readings or partner payloads are created.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppColors.inkSoft)
                }

                settingsCard(title: "DATA MANAGEMENT") {
                    Text("Create a portable JSON backup or restore one you made earlier.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppColors.inkSoft)
                    Button {
                        showingExportWarning = true
                    } label: {
                        Label("Export private backup", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.terracottaDark)
                    .disabled(!store.isStorageAvailable)

                    Button {
                        isImporting = true
                    } label: {
                        Label("Restore from JSON", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.terracottaDark)
                    .disabled(!store.isStorageAvailable)

                    if let backupStatus {
                        switch backupStatus {
                        case .success(let message):
                            Label(message, systemImage: "checkmark.circle.fill")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(AppColors.sage)
                        case .error(let message):
                            ErrorNotice(message: message)
                        }
                    }
                    Text("Backups include private notes. Keep the file somewhere only you can access.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppColors.inkSoft)
                }

                settingsCard(title: "APP LOCK") {
                    Text("Use this device's Face ID, Touch ID, or passcode before opening the journal.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppColors.inkSoft)
                    Button {
                        Task { await privacyLock.setEnabled(!privacyLock.isEnabled) }
                    } label: {
                        HStack {
                            Label("Lock journal", systemImage: "lock.fill")
                            Spacer()
                            Text(privacyLock.isEnabled ? "On" : "Off")
                                .foregroundStyle(AppColors.terracottaDark)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(privacyLock.isEnabled ? "Requires device authentication to turn off" : "Requires device authentication to turn on")

                    if let lockError = privacyLock.errorMessage {
                        ErrorNotice(message: lockError)
                    }
                    Text("Authentication stays on this device. The app never receives biometric data.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppColors.inkSoft)
                }

                settingsCard(title: "PRIVACY") {
                    Text("Understand what stays on this device, how authentication works, and what a backup contains.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppColors.inkSoft)
                    NavigationLink {
                        PrivacyInformationView()
                    } label: {
                        Label("Privacy information", systemImage: "hand.raised.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .tint(AppColors.terracottaDark)
                    .accessibilityHint("Explains how the app stores your records, authentication, and backups.")
                }

                if store.isStorageAvailable, let errorMessage = store.errorMessage {
                    ErrorNotice(message: errorMessage)
                }

                Button(role: .destructive) {
                    showingDeleteAllConfirmation = true
                } label: {
                    Label("Delete all local moments", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.terracottaDark)
                .disabled(!store.isStorageAvailable)

                if deletionCompleted {
                    Label("Local entries deleted.", systemImage: "checkmark.circle.fill")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppColors.sage)
                }

                Text("Verify file protection and backup behavior on an iPhone before release.")
                    .accessibilityIdentifier("settings.footer")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(AppColors.inkSoft)
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.top, 18)
            .padding(.bottom, 30)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.cream.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete all local moments?",
            isPresented: $showingDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete all moments", role: .destructive) {
                deletionCompleted = store.deleteAll()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes current journal entries and private notes from this app's local database. Any JSON backup remains unchanged.")
        }
        .alert("Backup includes private notes", isPresented: $showingExportWarning) {
            Button("Continue to export") { prepareBackupExport() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The JSON file contains your journal entries and notes. Anyone who can open the file may be able to read them.")
        }
        .confirmationDialog(
            "Restore \(pendingImport?.moments.count ?? 0) records?",
            isPresented: $showingImportChoices,
            titleVisibility: .visible
        ) {
            Button("Merge into this journal") { mergeImportedBackup() }
                .disabled(!store.isStorageAvailable)
            Button("Replace all local records", role: .destructive) { showingReplaceConfirmation = true }
                .disabled(!store.isStorageAvailable)
            Button("Cancel", role: .cancel) { pendingImport = nil }
        } message: {
            Text("Merge keeps other local records and updates matching IDs. Replace removes every current local record first.")
        }
        .alert("Replace your entire journal?", isPresented: $showingReplaceConfirmation) {
            Button("Replace journal", role: .destructive) { replaceImportedBackup() }
            Button("Cancel", role: .cancel) { pendingImport = nil }
        } message: {
            Text(AppLocalization.format("This deletes %lld local records and restores %lld records from the backup. Exported backup files will not change.", store.moments.count, pendingImport?.moments.count ?? 0))
        }
        .fileExporter(
            isPresented: $isExporting,
            document: backupDocument,
            contentType: .json,
            defaultFilename: AppLocalization.string("Private-Moments-Backup")
        ) { result in
            switch result {
            case .success:
                backupStatus = .success(AppLocalization.string("Backup saved."))
            case .failure(let error):
                let isCancelled = (error as? CocoaError)?.code == .userCancelled
                backupStatus = isCancelled ? nil : .error(AppLocalization.string("Couldn't save the backup. Please try again."))
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleBackupImport(result)
        }
        .task { store.reload() }
    }

    private func settingsCard<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .tracking(1.2)
                .foregroundStyle(AppColors.terracottaDark)
            content()
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.ink)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.paper, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.card).stroke(AppColors.line.opacity(0.8), lineWidth: 1))
    }

    private func prepareBackupExport() {
        do {
            backupDocument = MomentBackupDocument(data: try MomentBackupCodec.encode(store.moments))
            backupStatus = nil
            isExporting = true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription
                ?? AppLocalization.string("Couldn't prepare the backup. Your saved records are unchanged.")
            backupStatus = .error(message)
        }
    }

    private func handleBackupImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else {
            if case .failure(let error) = result,
               (error as? CocoaError)?.code != .userCancelled {
                backupStatus = .error(AppLocalization.string("Couldn't open that backup. Please try another JSON file."))
            }
            return
        }
        guard let url = urls.first else { return }

        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasScopedAccess { url.stopAccessingSecurityScopedResource() }
        }

        do {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attributes[.size] as? NSNumber,
               size.intValue > MomentBackupCodec.maximumFileSize {
                throw MomentBackupError.fileTooLarge
            }
            let fileHandle = try FileHandle(forReadingFrom: url)
            defer { try? fileHandle.close() }
            let data = try fileHandle.read(upToCount: MomentBackupCodec.maximumFileSize + 1) ?? Data()
            let envelope = try MomentBackupCodec.decode(data)
            pendingImport = envelope
            backupStatus = nil
            showingImportChoices = true
        } catch {
            let message: String
            switch error {
            case let backupError as MomentBackupError:
                message = backupError.localizedDescription
            case let validationError as MomentValidationError:
                message = validationError.localizedDescription
            default:
                message = AppLocalization.string("Couldn't read this file. Choose a valid Private Moments JSON backup.")
            }
            backupStatus = .error(message)
        }
    }

    private func mergeImportedBackup() {
        guard let pendingImport else { return }
        if let addedCount = store.mergeBackup(pendingImport.moments) {
            backupStatus = .success(AppLocalization.format("Backup merged; %lld new records added.", addedCount))
        }
        self.pendingImport = nil
    }

    private func replaceImportedBackup() {
        guard let pendingImport else { return }
        if store.replaceWithBackup(pendingImport.moments) {
            backupStatus = .success(AppLocalization.string("Local journal replaced from backup."))
        }
        self.pendingImport = nil
    }
}
