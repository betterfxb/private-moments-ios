import SwiftUI
import UniformTypeIdentifiers
import OSLog
import UIKit

private enum BackupStatus: Equatable {
    case success(String)
    case notice(String)
    case error(String)
    case unavailable(String)

    var isBrief: Bool {
        switch self {
        case .success, .notice: return true
        case .error, .unavailable: return false
        }
    }
}

struct SettingsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @Environment(MomentStore.self) private var store
    @Environment(AppLockController.self) private var privacyLock
    @State private var showingDeleteAllConfirmation = false
    @State private var deletionCompleted = false
    @State private var showingExportWarning = false
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingImportReview = false
    @State private var showingReplaceConfirmation = false
    @State private var backupDocument = MomentBackupDocument(data: Data())
    @State private var pendingImport: MomentBackupEnvelope?
    @State private var backupStatus: BackupStatus?
    @State private var isPreparingBackup = false
    @State private var isReadingBackup = false
    @State private var backupPickerDismissed = true
    @State private var backupPickerID = UUID()
    private static let contentMaxWidth: CGFloat = 680
    private let logger = Logger(subsystem: "com.example.PrivateMoments", category: "backup")

    private var isWorking: Bool { isPreparingBackup || isReadingBackup }

    var body: some View {
        VStack(spacing: 0) {
            if let backupStatus, backupStatus.isBrief {
                backupBanner(backupStatus)
            }
            settingsScrollContent
                .frame(maxHeight: .infinity)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete all local moments?",
            isPresented: $showingDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete all moments", role: .destructive) {
                backupStatus = nil
                deletionCompleted = store.deleteAll()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes current journal entries and private notes from this app's local database. Any JSON backup remains unchanged.")
        }
        .alert("Backup", isPresented: $showingExportWarning) {
            Button("Export") { prepareBackupExport() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Includes private notes.")
        }
        .sheet(isPresented: $showingImportReview, onDismiss: { pendingImport = nil }) {
            if let pendingImport {
                backupReview(pendingImport)
            }
        }
        .task { store.reload() }
        .onChange(of: store.moments.count) { _, count in
            if count > 0 { deletionCompleted = false }
        }
    }

    private var settingsScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                VStack(alignment: .leading, spacing: 8) {
                    PrivateBadge()
                    Text("Your space, your choice.")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    Text("Your journal stays on this device. Manage its privacy and backups here.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                }

                settingsCard(title: "ON THIS DEVICE") {
                    Label("Local journal", systemImage: "iphone")
                    Divider().overlay(AppColors.separator)
                    valueLayout {
                        Label("Saved moments", systemImage: "heart.text.square")
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("settings.savedCountTitle")
                        if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                        Text(store.isStorageAvailable ? "\(store.moments.count)" : AppLocalization.string("Unknown"))
                            .foregroundStyle(AppColors.secondaryText)
                            .accessibilityIdentifier("settings.savedCount")
                    }
                    Divider().overlay(AppColors.separator)
                    Label("No cloud sync configured", systemImage: "icloud.slash")
                    Divider().overlay(AppColors.separator)
                    Label("Files protected while device is locked", systemImage: "lock.fill")
                    Text("The app requests exclusion from device backups. Use the JSON backup controls below to move records to another device.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                    if !store.isStorageAvailable {
                        StorageRecoveryCard(
                            message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                            onRetry: store.reload
                        )
                    }
                }

                settingsCard(title: "DATA MANAGEMENT") {
                    Text("Create a portable JSON backup or restore one you made earlier.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                    if let backupStatus, !backupStatus.isBrief {
                        backupFeedback(backupStatus)
                    }
                    Button {
                        backupStatus = nil
                        showingExportWarning = true
                    } label: {
                        Group {
                            if isPreparingBackup { ProgressView("Preparing backup…") }
                            else { Label("Export private backup", systemImage: "square.and.arrow.up") }
                        }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.accentText)
                    .disabled(!store.isStorageAvailable || isWorking)
                    .accessibilityIdentifier("settings.export")
                    .fileExporter(
                        isPresented: $isExporting,
                        document: backupDocument,
                        contentType: .json,
                        defaultFilename: AppLocalization.string("Private-Moments-Backup")
                    ) { result in
                        switch result {
                        case .success:
                            logger.notice("Backup exporter completed.")
                            backupStatus = .success(AppLocalization.string("Backup saved."))
                        case .failure(let error):
                            logger.error("Backup exporter failed: \(String(describing: error), privacy: .private)")
                            let isCancelled = (error as? CocoaError)?.code == .userCancelled
                            backupStatus = isCancelled ? nil : .error(AppLocalization.string("Couldn't save the backup. Please try again."))
                        }
                    }

                    Button(action: beginBackupImport) {
                        Group {
                            if isReadingBackup { ProgressView("Reading backup…") }
                            else { Label("Restore from JSON", systemImage: "square.and.arrow.down") }
                        }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.accentText)
                    .disabled(!store.isStorageAvailable || isWorking)
                    .accessibilityIdentifier("settings.restore")
                    .sheet(isPresented: $isImporting, onDismiss: {
                        backupPickerDismissed = true
                        logger.notice("Backup picker dismissed.")
                        // Interactive/system dismissal need not deliver the
                        // document-picker delegate's cancellation callback.
                        // Never replace an in-flight read or a delivered result.
                        if !isImporting, !isReadingBackup, pendingImport == nil, backupStatus == nil {
                            logger.notice("Backup picker closed without delivering a file; journal unchanged.")
                            backupStatus = .notice(AppLocalization.string("Import cancelled. Records unchanged."))
                        }
                        presentBackupReviewIfReady()
                    }) {
                        let requestID = backupPickerID
                        BackupFilePicker(onBeginReading: {
                            guard requestID == backupPickerID else { return }
                            // Files may dismiss the sheet before delivering its
                            // URL. Reading is the current outcome once delivered.
                            backupStatus = nil
                            isReadingBackup = true
                            logger.notice("Backup picker delivered a file for validation.")
                        }) { result in
                            guard requestID == backupPickerID else {
                                logger.notice("Ignored stale backup picker completion.")
                                return
                            }
                            isImporting = false
                            handleBackupImport(result)
                        }
                        .id(requestID)
                        .presentationDragIndicator(.visible)
                    }

                    Text("Backups include private notes. Keep the file somewhere only you can access.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                }

                settingsCard(title: "APP LOCK") {
                    Text("Use this device's Face ID, Touch ID, or passcode before opening the journal.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                    Button {
                        Task { await privacyLock.setEnabled(!privacyLock.isEnabled) }
                    } label: {
                        valueLayout {
                            Label("Lock journal", systemImage: "lock.fill")
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("settings.lockTitle")
                            if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                            if privacyLock.isAuthenticating {
                                ProgressView().accessibilityLabel("Authenticating…")
                            } else {
                                Text(privacyLock.isEnabled ? "On" : "Off")
                                    .foregroundStyle(AppColors.accentText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(privacyLock.isAuthenticating)
                    .accessibilityIdentifier("settings.lock")
                    .accessibilityHint(privacyLock.isEnabled ? "Requires device authentication to turn off" : "Requires device authentication to turn on")

                    if let lockError = privacyLock.errorMessage {
                        ErrorNotice(message: lockError)
                            .accessibilityIdentifier("settings.lockError")
                    }
                    Text("Authentication stays on this device. The app never receives biometric data.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                }

                settingsCard(title: "PRIVACY") {
                    Text("Understand what stays on this device, how authentication works, and what a backup contains.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                    NavigationLink {
                        PrivacyInformationView()
                    } label: {
                        Label("Privacy information", systemImage: "hand.raised.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .tint(AppColors.accentText)
                    .accessibilityHint("Explains how the app stores your records, authentication, and backups.")
                }

                if store.isStorageAvailable, let errorMessage = store.errorMessage {
                    ErrorNotice(message: errorMessage)
                }

                Button(role: .destructive) {
                    showingDeleteAllConfirmation = true
                } label: {
                    Label("Delete all local moments", systemImage: "trash")
                        .foregroundStyle(AppColors.destructive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .tint(AppColors.destructive)
                .disabled(!store.isStorageAvailable || isWorking)
                .accessibilityIdentifier("settings.deleteAll")

                if deletionCompleted {
                    Label("Local entries deleted.", systemImage: "checkmark.circle.fill")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppColors.success)
                }

                Text("Your backups can contain private notes. Keep them somewhere you trust.")
                    .accessibilityIdentifier("settings.footer")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.top, 18)
            .padding(.bottom, 30)
            .frame(maxWidth: Self.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private var valueLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    private func backupBanner(_ status: BackupStatus) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if dynamicTypeSize.isAccessibilitySize {
                HStack {
                    Spacer()
                    dismissBackupFeedback
                }
                backupFeedback(status)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    backupFeedback(status)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    dismissBackupFeedback
                }
            }
        }
        .modifier(JournalPanel())
        .padding(.horizontal, AppSpacing.page)
        .padding(.vertical, 8)
        .frame(maxWidth: Self.contentMaxWidth)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var dismissBackupFeedback: some View {
        Button { backupStatus = nil } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(AppColors.accentWash, in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColors.accentText)
        .accessibilityLabel("Dismiss message")
        .accessibilityIdentifier("settings.dismissBackupStatus")
    }

    private func backupFeedback(_ status: BackupStatus) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            switch status {
            case .success(let message):
                backupMessage(message, systemImage: "checkmark.circle.fill", color: AppColors.success)
            case .notice(let message):
                backupMessage(message, systemImage: "xmark.circle", color: AppColors.secondaryText)
            case .error(let message):
                ErrorNotice(message: message)
                    .accessibilityIdentifier("settings.backupStatus")
            case .unavailable(let message):
                ErrorNotice(message: message)
                    .accessibilityIdentifier("settings.backupUnavailableMessage")
                Button(action: beginBackupImport) {
                    Label("Choose backup", systemImage: "folder")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.accentText)
                .disabled(!store.isStorageAvailable || isWorking)
                .accessibilityIdentifier("settings.chooseBackupAgain")
            }
        }
    }

    private func backupMessage(_ message: String, systemImage: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: systemImage)
                .accessibilityHidden(true)
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("settings.backupStatus")
        }
        .font(.system(.footnote, design: .rounded))
        .foregroundStyle(color)
    }

    private func settingsCard<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(AppColors.accentText)
            content()
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.text)
        }
        .modifier(JournalPanel())
    }

    private func prepareBackupExport() {
        guard !isWorking, store.isStorageAvailable else { return }
        let snapshot = store.moments
        isPreparingBackup = true
        logger.notice("Preparing backup export.")
        Task { @MainActor in
            defer { isPreparingBackup = false }
            do {
                let data = try await Task.detached(priority: .userInitiated) {
                    try MomentBackupCodec.encode(snapshot)
                }.value
                backupDocument = MomentBackupDocument(data: data)
                backupStatus = nil
                logger.notice("Prepared backup; presenting exporter.")
                isExporting = true
            } catch {
                logger.error("Backup encoding failed: \(String(describing: error), privacy: .private)")
                let message = (error as? LocalizedError)?.errorDescription
                    ?? AppLocalization.string("Couldn't prepare the backup. Your saved records are unchanged.")
                backupStatus = .error(message)
            }
        }
    }

    private func beginBackupImport() {
        guard !isWorking, store.isStorageAvailable else { return }
        backupStatus = nil
        pendingImport = nil
        backupPickerID = UUID()
        backupPickerDismissed = false
        isImporting = true
    }

    private func handleBackupImport(_ result: Result<MomentBackupEnvelope, Error>) {
        isReadingBackup = false
        switch result {
        case .success(let envelope):
            pendingImport = envelope
            backupStatus = nil
            logger.notice("Backup file validated.")
            presentBackupReviewIfReady()
        case .failure(let error):
            if (error as? CocoaError)?.code == .userCancelled {
                logger.notice("Backup import cancelled by picker delegate.")
                backupStatus = .notice(AppLocalization.string("Import cancelled. Records unchanged."))
                return
            }
            logger.error("Backup reading failed: \(String(describing: error), privacy: .private)")
            if case .sourceUnavailable? = error as? MomentBackupError {
                backupStatus = .unavailable(error.localizedDescription)
                return
            }
            let message: String
            switch error {
            case let backupError as MomentBackupError:
                message = backupError.localizedDescription
            case let validationError as MomentValidationError:
                message = validationError.localizedDescription
            case let fileError as CocoaError where fileError.code == .fileReadUnknown:
                message = AppLocalization.string("Couldn't open that backup. Please try another JSON file.")
            default:
                message = AppLocalization.string("Couldn't read this file. Choose a valid Private Moments JSON backup.")
            }
            backupStatus = .error(message)
        }
    }

    private func presentBackupReviewIfReady() {
        guard backupPickerDismissed, pendingImport != nil else { return }
        logger.notice("Presenting validated backup review.")
        showingImportReview = true
    }

    private func mergeImportedBackup() {
        guard let pendingImport else { return }
        if let addedCount = store.mergeBackup(pendingImport.moments) {
            deletionCompleted = false
            backupStatus = .success(AppLocalization.format("Backup merged; %lld new records added.", addedCount))
            showingImportReview = false
        }
    }

    private func replaceImportedBackup() {
        guard let pendingImport else { return }
        if store.replaceWithBackup(pendingImport.moments) {
            deletionCompleted = false
            backupStatus = .success(AppLocalization.string("Local journal replaced from backup."))
            showingImportReview = false
        }
    }

    private func backupReview(_ backup: MomentBackupEnvelope) -> some View {
        let summary = BackupImportSummary(backup: backup, existing: store.moments)
        let hidden = scenePhase != .active || privacyLock.isLocked
        return NavigationStack {
            Group {
                if hidden {
                    PrivacyLockView()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.section) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(AppLocalization.momentCount(summary.totalCount))
                                    .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                                    .foregroundStyle(AppColors.accentText)
                                    .accessibilityIdentifier("backup.totalCount")
                                Text(AppLocalization.format("Created %@", backup.createdAt.formatted(date: .abbreviated, time: .shortened)))
                                    .foregroundStyle(AppColors.secondaryText)
                                Text("Merge adds new records and updates matching records. Other local records stay.")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(AppColors.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            VStack(alignment: .leading, spacing: 18) {
                                reviewMetric("New records", value: summary.newCount, identifier: "backup.newCount")
                                Divider()
                                reviewMetric("Matching records", value: summary.updatedCount, identifier: "backup.updatedCount")
                                Divider()
                                reviewMetric("Private notes", value: summary.noteCount, identifier: "backup.noteCount")
                                Divider()
                                reviewMetric("Other local records", value: summary.removedCount, identifier: "backup.otherCount")
                            }
                            .modifier(JournalPanel())
                            if !store.isStorageAvailable {
                                StorageRecoveryCard(message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."), onRetry: store.reload)
                            }
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Replace uses only this backup. Other local records are removed. Exported files stay unchanged.")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundStyle(AppColors.secondaryText)
                                Button(role: .destructive) { showingReplaceConfirmation = true } label: {
                                    Text("Replace all local records")
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(AppColors.destructive)
                                .disabled(!store.isStorageAvailable)
                                .accessibilityIdentifier("backup.replace")
                            }
                            .modifier(JournalPanel())
                        }
                        .padding(AppSpacing.page)
                        .frame(maxWidth: 680)
                        .frame(maxWidth: .infinity)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Button(action: mergeImportedBackup) {
                            Label("Merge", systemImage: "arrow.triangle.merge")
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        .accessibilityLabel(Text("Merge backup"))
                        .disabled(!store.isStorageAvailable)
                        .accessibilityIdentifier("backup.merge")
                        .frame(maxWidth: 640)
                        .padding(.horizontal, AppSpacing.page)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.surface)
                    }
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Review backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingImportReview = false }
                        .accessibilityIdentifier("backup.cancel")
                }
            }
            .alert("Replace?", isPresented: $showingReplaceConfirmation) {
                Button("Replace", role: .destructive, action: replaceImportedBackup)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(AppLocalization.format("Local records: %lld. Backup records: %lld.", summary.localCount, summary.totalCount))
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { showingReplaceConfirmation = false }
            }
            .onAppear { logger.notice("Backup review appeared.") }
        }
    }

    private func reviewMetric(_ title: LocalizedStringKey, value: Int, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(.subheadline, design: .rounded)).foregroundStyle(AppColors.secondaryText)
            Text(value, format: .number)
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.text)
                .accessibilityIdentifier(identifier)
        }
    }
}

@MainActor
private struct BackupFilePicker: UIViewControllerRepresentable {
    let onBeginReading: () -> Void
    let completion: (Result<MomentBackupEnvelope, Error>) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onBeginReading: onBeginReading, completion: completion) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Restore consumes a validated snapshot rather than editing a live
        // provider document or retaining its external security-scoped bookmark.
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) { }

    @MainActor
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onBeginReading: () -> Void
        private let completion: (Result<MomentBackupEnvelope, Error>) -> Void
        private var didComplete = false

        init(onBeginReading: @escaping () -> Void, completion: @escaping (Result<MomentBackupEnvelope, Error>) -> Void) {
            self.onBeginReading = onBeginReading
            self.completion = completion
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard !didComplete else { return }
            didComplete = true
            guard let url = urls.first else {
                completion(.failure(CocoaError(.fileReadUnknown)))
                return
            }
            onBeginReading()
            Task { @MainActor [controller] in
                let result: Result<MomentBackupEnvelope, Error>
                do {
                    let envelope = try await Task.detached(priority: .userInitiated) {
                        try MomentBackupFileReader.readPickerSnapshot(url)
                    }.value
                    result = .success(envelope)
                } catch { result = .failure(error) }
                // The picker remains alive through snapshot capture/read;
                // teardown must not race delivery of its temporary document.
                withExtendedLifetime(controller) { self.completion(result) }
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            finish(.failure(CocoaError(.userCancelled)))
        }

        private func finish(_ result: Result<MomentBackupEnvelope, Error>) {
            guard !didComplete else { return }
            didComplete = true
            completion(result)
        }
    }
}
