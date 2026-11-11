import XCTest

final class PrivateMomentsUITests: XCTestCase {
    private var importRecoveryCount = 0

    override func setUpWithError() throws {
        continueAfterFailure = false
        importRecoveryCount = 0
    }

    override func tearDownWithError() throws {
        let app = XCUIApplication()
        if app.state != .notRunning {
            // A failed picker assertion must not leave a remote system window
            // covering the next test's freshly launched journal.
            if app.collectionViews["File View"].exists,
               let cancel = nativeControl(["Cancel"], app: app) { cancel.tap() }
            app.terminate()
        }
    }

    // The CI profile controls device, system appearance, and system text size.
    // Each locale gets a separate persistent test store; no normal journal is reset.
    func testScreenGallery() throws {
        for language in ["en", "zh-Hans"] {
            let app = makeApp(language: language, failFirstSave: true)
            app.launch()
            let start = app.buttons["today.startMoment"]
            XCTAssertTrue(start.waitForExistence(timeout: 15))
            XCTAssertEqual(start.label, language == "en" ? "Start a moment" : "开始记录")
            let brand = app.staticTexts["today.brand"]
            XCTAssertTrue(brand.waitForExistence(timeout: 5))
            XCTAssertEqual(brand.label, language == "en" ? "Private Moments" : "私密时刻")
            XCTAssertGreaterThanOrEqual(brand.frame.minX, app.windows.firstMatch.frame.minX)
            XCTAssertLessThanOrEqual(brand.frame.maxX, app.windows.firstMatch.frame.maxX)
            if !app.buttons["today.weekMenu"].exists {
                XCTAssertGreaterThanOrEqual(brand.frame.width, language == "en" ? 115 : 60,
                    "The brand must not collapse into an icon-sized toolbar item.")
            }
            XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0, "Each locale must use an isolated empty store.")
            for action in [start, app.buttons["today.addRecord"]] {
                XCTAssertGreaterThanOrEqual(action.frame.minX, app.windows.firstMatch.frame.minX, "Home action is clipped on the left.")
                XCTAssertLessThanOrEqual(action.frame.maxX, app.windows.firstMatch.frame.maxX, "Home action is clipped on the right.")
                XCTAssertGreaterThanOrEqual(action.frame.height, 44, "Home action needs an accessible target height.")
            }
            capture("Today-\(language)", app)
            let weekMenu = app.buttons["today.weekMenu"]
            let usesAccessibilityLayout = weekMenu.exists
            if weekMenu.exists {
                tap(weekMenu, in: app)
                capture("Week-menu-\(language)", app)
                tap(app.buttons["today.week.current"], in: app)
                XCTAssertTrue(app.buttons["today.clearDateFilter"].exists)
                tap(app.buttons["today.clearDateFilter"], in: app)
            }
            tap(app.buttons["today.addRecord"], in: app)
            let quickSave = app.buttons["recap.saveToolbar"]
            XCTAssertTrue(quickSave.isHittable, "Saving must be reachable without scrolling the form.")
            XCTAssertEqual(quickSave.label, language == "en" ? "Save privately" : "私密保存")
            assertToolbarTarget(quickSave)
            capture("Manual-top-\(language)", app)
            let datePanel = app.buttons["recap.date.open"]
            if datePanel.exists {
                tap(datePanel, in: app)
                capture("Manual-date-picker-\(language)", app)
                tap(app.buttons["recap.date.done"], in: app)
            }
            revealFully(from: app.textFields["recap.minutes"], through: app.textFields["recap.seconds"], in: app)
            for field in [app.textFields["recap.minutes"], app.textFields["recap.seconds"]] {
                XCTAssertGreaterThanOrEqual(field.frame.minX, app.windows.firstMatch.frame.minX, "Timing input is clipped on the left.")
                XCTAssertLessThanOrEqual(field.frame.maxX, app.windows.firstMatch.frame.maxX, "Timing input is clipped on the right.")
            }
            capture("Manual-duration-\(language)", app)
            tap(app.buttons["recap.cancel"], in: app)
            XCTAssertTrue(start.waitForExistence(timeout: 10), "Untouched manual entry should close directly.")
            tap(start, in: app)
            capture("Session-\(language)", app)
            reveal(app.buttons["session.finish"], in: app)
            capture("Session-controls-\(language)", app)
            tap(app.buttons["session.finish"], in: app)
            capture("Recap-top-\(language)", app)
            revealFully(from: app.staticTexts["recap.kind.title"], through: app.buttons["recap.kind.Solo"], in: app)
            capture("Recap-kind-\(language)", app)
            revealFully(from: app.staticTexts["recap.rating.title"], through: app.buttons["recap.rating.5"], in: app)
            capture("Recap-rating-\(language)", app)
            revealFully(from: app.buttons["recap.save"], through: app.buttons["recap.save"], in: app)
            capture("Recap-controls-\(language)", app)
            tap(app.buttons["recap.save"], in: app)
            recoverFailedSave(language: language, captureScenes: true, app: app)
            tap(app.buttons["recap.saveToolbar"], in: app)
            XCTAssertTrue(start.waitForExistence(timeout: 10))
            if weekMenu.exists {
                revealFully(from: app.staticTexts["today.brand"], through: app.staticTexts["today.brand"], in: app)
            }
            capture("Today-saved-\(language)", app)
            tap(app.buttons["today.chooseDate"], in: app)
            capture("Calendar-\(language)", app)
            tap(app.buttons["today.applyDate"], in: app)
            capture("Today-filtered-\(language)", app)
            tap(app.buttons["today.clearDateFilter"], in: app)
            app.windows.firstMatch.swipeUp()
            app.windows.firstMatch.swipeUp()
            capture("Today-summary-\(language)", app)
            selectTab("Timeline", "时间线", language: language, app: app)
            capture("Timeline-\(language)", app)
            // Lazy rows outside the large-text viewport are not a record count.
            let total = app.staticTexts["timeline.resultCount"]
            reveal(total, in: app)
            XCTAssertEqual(total.label, language == "en" ? "1 moment" : "1 条记录",
                "Failure and retry must persist exactly one entry.")
            chooseMomentFilter(language == "en" ? "Solo" : "独自", in: app)
            XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0)
            let noMatches = app.staticTexts[language == "en" ? "No matching moments" : "没有找到匹配记录"]
            reveal(noMatches, in: app)
            capture("Timeline-filter-empty-\(language)", app)
            tap(app.buttons["timeline.clearFilters"], in: app)
            XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 1)
            XCTAssertFalse(app.buttons["timeline.clearFilters"].exists)
            tap(app.buttons.matching(identifier: "moment.row").firstMatch, in: app)
            let edit = app.buttons["detail.editToolbar"]
            XCTAssertTrue(edit.isHittable, "Details must offer editing without scrolling past the note.")
            assertToolbarTarget(edit)
            XCTAssertEqual(edit.label, language == "en" ? "Edit reflection" : "编辑感受")
            capture("Detail-top-\(language)", app)
            revealFully(from: app.buttons["detail.edit"], through: app.buttons["detail.delete"], in: app)
            capture("Detail-controls-\(language)", app)
            goBack(app)
            selectTab("Settings", "设置", language: language, app: app)
            capture("Settings-top-\(language)", app)
            let countTitle = app.staticTexts["settings.savedCountTitle"]
            let countValue = app.staticTexts["settings.savedCount"]
            revealFully(from: countTitle, through: countValue, in: app)
            capture("Settings-values-\(language)", app)
            XCTAssertEqual(countTitle.label, language == "en" ? "Saved moments" : "已保存的记录")
            assertValueLayout(title: countTitle, value: countValue, stacked: usesAccessibilityLayout)
            revealFully(from: app.staticTexts["settings.footer"], through: app.staticTexts["settings.footer"], in: app)
            capture("Settings-bottom-\(language)", app)
            let exportAction = app.buttons["settings.export"]
            revealFully(from: exportAction, through: exportAction, in: app)
            tap(exportAction, in: app)
            let warning = app.alerts.firstMatch
            XCTAssertTrue(warning.waitForExistence(timeout: 5))
            capture("Backup-warning-\(language)", app)
            assertExportWarning(warning, language: language, app: app)
            tap(warning.buttons[language == "en" ? "Cancel" : "取消"], in: app)
            tap(app.buttons["settings.lock"], in: app)
            // Simulator policy evaluation may remain pending rather than fail
            // immediately. Exercise real background cancellation, without an
            // authentication-success fixture or an assumed Simulator policy.
            XCUIDevice.shared.press(.home)
            var observedBackgroundState: XCUIApplication.State?
            let backgroundPredicate = NSPredicate { _, _ in
                let state = app.state
                observedBackgroundState = state
                return state == .runningBackground || state == .runningBackgroundSuspended
            }
            let background = XCTNSPredicateExpectation(predicate: backgroundPredicate, object: nil)
            var backgroundOutcome = XCTWaiter.wait(for: [background], timeout: 2)
            if backgroundOutcome == .timedOut {
                // A system authentication surface may consume the first Home
                // event. Only an app still in the foreground gets one more real
                // Home event; the actual background state remains mandatory.
                if app.state == .runningForeground {
                    print("Additional Home press for authentication exit. Locale: \(language).")
                    XCUIDevice.shared.press(.home)
                }
                let settledBackground = XCTNSPredicateExpectation(predicate: backgroundPredicate, object: nil)
                backgroundOutcome = XCTWaiter.wait(for: [settledBackground], timeout: 10)
            }
            if backgroundOutcome != .completed {
                print("Authentication exit state: \(String(describing: observedBackgroundState)); locale: \(language).")
                captureFailure("Lock-background-unavailable-\(language)", app)
            }
            XCTAssertEqual(backgroundOutcome, .completed)
            app.activate()
            let lock = app.buttons["settings.lock"]
            reveal(lock, in: app)
            let recovered = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: lock)
            XCTAssertEqual(XCTWaiter.wait(for: [recovered], timeout: 10), .completed)
            XCTAssertTrue(lock.staticTexts[language == "en" ? "Off" : "关闭"].exists)
            XCTAssertFalse(lock.staticTexts[language == "en" ? "On" : "开启"].exists)
            let lockTitle = lock.staticTexts["settings.lockTitle"]
            XCTAssertEqual(lockTitle.label, language == "en" ? "Lock journal" : "锁定日记")
            assertValueLayout(title: lockTitle,
                value: lock.staticTexts[language == "en" ? "Off" : "关闭"], stacked: usesAccessibilityLayout)
            captureSystem("Lock-recovery-\(language)", app)
            app.terminate()
        }
    }

    func testBackupFileRoundTrip() throws {
        let app = makeApp()
        app.launch()
        tap(app.buttons["today.addRecord"], in: app)
        replaceNumber(app.textFields["recap.minutes"], with: "4", in: app)
        tap(app.buttons["recap.dismissKeyboard"], in: app)
        replaceNumber(app.textFields["recap.seconds"], with: "7", in: app)
        tap(app.buttons["recap.dismissKeyboard"], in: app)
        tap(app.textViews["recap.note"], in: app)
        app.textViews["recap.note"].typeText("Synthetic backup note")
        tap(app.buttons["recap.dismissKeyboard"], in: app)
        tap(app.buttons["recap.saveToolbar"], in: app)
        selectTab("Settings", "设置", app: app)
        tap(app.buttons["settings.export"], in: app)
        tap(app.alerts.firstMatch.buttons["Export"], in: app)
        // The fresh hosted Simulator can take over 45 seconds to launch the
        // DocumentManager extension. Wait for actual controls, not a fixed nap
        // or a blank sheet that merely finished its presentation animation.
        let browserAction = nativeControl(["Save", "On My iPhone", "On My iPad"], app: app, timeout: 90)
        captureSystem("Export-files-en", app)
        XCTAssertNotNil(browserAction, "The system exporter must show a destination or Save action.")
        // Each hosted Simulator is fresh; this test exports exactly one file.
        // iOS may hide Save As on first presentation; use the real default name.
        let filename = "Private-Moments-Backup"
        saveToLocalFiles(app)
        let saved = app.staticTexts["Backup saved."]
        XCTAssertTrue(saved.waitForExistence(timeout: 15), "Only the real exporter completion may report success.")
        assertBackupResultVisible(saved, in: app)
        capture("Backup-exported-en", app)
        let dismissFeedback = app.buttons["settings.dismissBackupStatus"]
        XCTAssertEqual(dismissFeedback.label, "Dismiss message")
        assertToolbarTarget(dismissFeedback)
        dismissFeedback.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !app.staticTexts["settings.backupStatus"].exists
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed,
            "Dismissing feedback must leave the journal available without changing its records.")

        tap(app.buttons["settings.restore"], in: app)
        let cancel = try XCTUnwrap(nativeControl(["Cancel"], app: app, timeout: 10))
        captureSystem("Import-files-en", app)
        cancel.tap()
        assertImportCancelled(in: app)
        capture("Import-cancelled-en", app)
        assertSavedCount("1", app: app)
        tap(app.buttons["settings.deleteAll"], in: app)
        tap(app.buttons["Delete all moments"], in: app)
        assertSavedCount("0", app: app)
        XCTAssertFalse(app.staticTexts["Import cancelled. Records unchanged."].exists,
            "A new destructive operation must clear the earlier cancellation notice.")

        openBackup(filename, app: app)
        capture("Backup-review-en", app)
        assertMetric("backup.newCount", value: "1", app: app)
        assertMetric("backup.updatedCount", value: "0", app: app)
        assertMetric("backup.noteCount", value: "1", app: app)
        revealFully(from: app.buttons["backup.replace"], through: app.buttons["backup.replace"], in: app)
        capture("Backup-review-controls-en", app)
        XCTAssertTrue(app.buttons["backup.merge"].isHittable)
        tap(app.buttons["backup.cancel"], in: app)
        assertSavedCount("0", app: app)
        openBackup(filename, app: app)
        tap(app.buttons["backup.merge"], in: app)
        assertSavedCount("1", app: app)

        selectTab("Today", "今天", app: app)
        tap(app.buttons["today.addRecord"], in: app)
        tap(app.buttons["recap.saveToolbar"], in: app)
        selectTab("Settings", "设置", app: app)
        assertSavedCount("2", app: app)
        openBackup(filename, app: app)
        assertMetric("backup.updatedCount", value: "1", app: app)
        assertMetric("backup.otherCount", value: "1", app: app)
        capture("Replace-review-en", app)
        tap(app.buttons["backup.replace"], in: app)
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        capture("Backup-replace-en", app)
        tap(app.alerts.firstMatch.buttons["Cancel"], in: app)
        tap(app.buttons["backup.cancel"], in: app)
        assertSavedCount("2", app: app)
        openBackup(filename, app: app)
        tap(app.buttons["backup.replace"], in: app)
        tap(app.alerts.firstMatch.buttons["Replace"], in: app)
        let restored = app.staticTexts["Local journal replaced from backup."]
        XCTAssertTrue(restored.waitForExistence(timeout: 15))
        assertBackupResultVisible(restored, in: app)
        capture("Backup-restored-en", app)
        assertSavedCount("1", app: app)
        app.terminate()
        app.launch()
        selectTab("Timeline", "时间线", app: app)
        tap(app.buttons.matching(identifier: "moment.row").firstMatch, in: app)
        reveal(app.staticTexts["detail.note"], in: app)
        XCTAssertEqual(app.staticTexts["detail.note"].label, "Synthetic backup note")
        tap(app.buttons["detail.editToolbar"], in: app)
        XCTAssertEqual(app.textFields["recap.minutes"].value as? String, "4")
        XCTAssertEqual(app.textFields["recap.seconds"].value as? String, "7")
    }

    private func assertSavedCount(_ value: String, app: XCUIApplication) {
        let count = app.staticTexts["settings.savedCount"]
        reveal(count, in: app)
        XCTAssertEqual(count.label, value)
    }

    private func assertImportCancelled(in app: XCUIApplication) {
        let notice = app.staticTexts["Import cancelled. Records unchanged."]
        let exists = notice.waitForExistence(timeout: 15)
        if !exists { captureFailure("Import-cancelled-unavailable-en", app) }
        XCTAssertTrue(exists)
        assertBackupResultVisible(notice, in: app)
    }

    private func assertValueLayout(title: XCUIElement, value: XCUIElement, stacked: Bool) {
        XCTAssertTrue(title.exists)
        XCTAssertTrue(value.exists)
        if stacked {
            XCTAssertGreaterThanOrEqual(value.frame.minY, title.frame.maxY,
                "Accessibility sizes must put the value below its complete title.")
        } else {
            XCTAssertGreaterThanOrEqual(value.frame.minX, title.frame.maxX,
                "Standard sizes retain a trailing value.")
        }
    }

    private func assertExportWarning(_ warning: XCUIElement, language: String, app: XCUIApplication) {
        let message = warning.staticTexts[language == "en" ? "Includes private notes." : "包含私密备注。"]
        let export = warning.buttons[language == "en" ? "Export" : "导出"]
        let cancel = warning.buttons[language == "en" ? "Cancel" : "取消"]
        XCTAssertTrue(message.exists)
        for element in [message, export, cancel] {
            XCTAssertTrue(element.isHittable, "The complete warning must be readable without scrolling.")
            XCTAssertGreaterThan(element.frame.width, 0)
            XCTAssertGreaterThan(element.frame.height, 0)
            XCTAssertGreaterThanOrEqual(element.frame.minX, max(app.windows.firstMatch.frame.minX, warning.frame.minX))
            XCTAssertLessThanOrEqual(element.frame.maxX, min(app.windows.firstMatch.frame.maxX, warning.frame.maxX))
            XCTAssertGreaterThanOrEqual(element.frame.minY, max(app.windows.firstMatch.frame.minY, warning.frame.minY))
            XCTAssertLessThanOrEqual(element.frame.maxY, min(app.windows.firstMatch.frame.maxY, warning.frame.maxY))
        }
        XCTAssertLessThanOrEqual(message.frame.maxY, min(export.frame.minY, cancel.frame.minY),
            "The warning text must finish above the actions, including at the largest text size.")
        assertToolbarTarget(export)
        assertToolbarTarget(cancel)
    }

    private func assertBackupResultVisible(_ result: XCUIElement, in app: XCUIApplication) {
        // No reveal/swipe is allowed here: the actual completion must bring
        // its feedback into view, rather than the test doing that work.
        var lastObservation = "No snapshot received."
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            // This is read-only feedback, not a control to activate. Asking
            // XCTest for a hit point can itself raise an automation failure.
            // Require a foreground, unobscured screen and the whole text frame.
            guard result.exists, app.state == .runningForeground,
                  !app.alerts.firstMatch.exists, !app.sheets.firstMatch.exists,
                  !app.collectionViews["File View"].exists else {
                lastObservation = "Feedback missing, app not foreground, or a modal remains."
                return false
            }
            // Application is an accessibility root, not a visible rectangle.
            // Files can leave that root without a frame while its real window
            // and text remain valid. Measure the window owning this feedback.
            let window = app.windows.containing(.staticText, identifier: "settings.backupStatus").firstMatch
            guard window.exists else {
                lastObservation = "No application window contains the feedback."
                return false
            }
            let viewport = window.frame
            let frame = window.staticTexts["settings.backupStatus"].frame
            guard !frame.isEmpty, !frame.isInfinite, !frame.isNull,
                  !viewport.isEmpty, !viewport.isInfinite, !viewport.isNull else {
                lastObservation = "Invalid feedback or viewport frame: \(frame), \(viewport)."
                return false
            }
            let navigation = window.navigationBars.firstMatch
            let navigationFrame = navigation.exists ? navigation.frame : nil
            let tabBar = window.tabBars.firstMatch
            let tabFrame = tabBar.exists ? tabBar.frame : nil
            let top = navigationFrame?.maxY ?? viewport.minY
            let bottom = tabFrame.map { $0.midY > viewport.midY ? $0.minY : viewport.maxY }
                ?? viewport.maxY
            lastObservation = "Feedback=\(frame), viewport=\(viewport), top=\(top), bottom=\(bottom)."
            return frame.minY >= top && frame.maxY <= bottom
                && frame.minX >= viewport.minX && frame.maxX <= viewport.maxX
        }, object: nil)
        // Files owns a separate accessibility process. A stale snapshot after
        // dismissal can consume a polling cycle; allow a bounded fresh snapshot,
        // without retrying the operation or changing the layout requirements.
        let outcome = XCTWaiter.wait(for: [visible], timeout: 30)
        if outcome != .completed {
            print("Backup feedback visibility: \(lastObservation)")
            captureFailure("Backup-result-unavailable-en", app)
        }
        XCTAssertEqual(outcome, .completed,
            "Backup completion feedback did not become fully visible without a test scroll.")
    }

    private func assertMetric(_ identifier: String, value: String, app: XCUIApplication) {
        let metric = app.staticTexts[identifier]
        reveal(metric, in: app)
        XCTAssertEqual(metric.label, value)
    }

    private func nativeControl(_ labels: [String], app: XCUIApplication, timeout: TimeInterval = 2) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for label in labels {
                let items = app.buttons.matching(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex
                    + app.staticTexts.matching(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex
                for item in items {
                    if item.exists && item.isHittable { return item }
                }
            }
        } while Date() < deadline
        return nil
    }

    private func saveToLocalFiles(_ app: XCUIApplication) {
        if let local = nativeControl(["On My iPhone", "On My iPad"], app: app) { local.tap() }
        let labels = ["Save", "Export", "Move"]
        if let action = nativeControl(labels, app: app), action.isEnabled { action.tap(); return }
        if let more = nativeControl(["More"], app: app) { more.tap() }
        guard let folder = nativeControl(["New Folder"], app: app) else {
            captureSystem("Exporter-unavailable", app)
            return XCTFail("No writable local folder or New Folder action in system exporter.")
        }
        folder.tap()
        let name = app.alerts.firstMatch.exists ? app.alerts.firstMatch.textFields.firstMatch : app.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        replaceNumber(name, with: "PM Tests", in: app)
        guard let create = nativeControl(["Create", "Done"], app: app) else { return XCTFail("Missing native folder creation action") }
        create.tap()
        guard let save = nativeControl(labels, app: app, timeout: 5), save.isEnabled else { return XCTFail("No enabled system save action") }
        save.tap()
    }

    private func openBackup(_ filename: String, app: XCUIApplication) {
        let originalCount = app.staticTexts["settings.savedCount"].label
        tap(app.buttons["settings.restore"], in: app)
        for attempt in 0..<2 {
            let delivered = selectBackupFile(filename, app: app)
            if app.buttons["backup.merge"].exists { return }
            if !delivered {
                // A selected item can remain in the system picker without a
                // delegate URL. Exercise its real Cancel/reopen path once;
                // never infer a successful read or retry the whole test.
                guard attempt == 0, app.collectionViews["File View"].exists,
                      let cancel = nativeControl(["Cancel"], app: app) else {
                    captureSystem("Import-selection-unresolved", app)
                    return XCTFail("The system picker did not deliver a file and has no bounded recovery left.")
                }
                importRecoveryCount += 1
                captureSystem("Import-recovery-\(importRecoveryCount)-en", app)
                cancel.tap()
                assertImportCancelled(in: app)
                XCTAssertEqual(app.staticTexts["settings.savedCount"].label, originalCount)
                print("Explicit system backup reselection \(importRecoveryCount); local record count unchanged. Reason: picker-not-delivered.")
                tap(app.buttons["settings.restore"], in: app)
                continue
            }
            let chooseAgain = app.buttons["settings.chooseBackupAgain"]
            guard attempt == 0, chooseAgain.exists else {
                captureSystem("Import-selection-unresolved", app)
                return XCTFail("The real file selection must reach review after at most one explicit reselection.")
            }
            // A provider can withdraw its temporary URL before capture. Only
            // this typed source error offers recovery; decoder/staging errors
            // still fail. Verify no data write, then use the actual UI again.
            XCTAssertEqual(app.staticTexts["settings.savedCount"].label, originalCount)
            let message = app.descendants(matching: .any).matching(identifier: "settings.backupUnavailableMessage").firstMatch
            revealFully(from: message, through: chooseAgain, in: app)
            importRecoveryCount += 1
            print("Explicit system backup reselection \(importRecoveryCount); local record count unchanged. Reason: source-unavailable.")
            captureSystem("Import-recovery-\(importRecoveryCount)-en", app)
            tap(chooseAgain, in: app)
        }
        XCTFail("Backup review did not open after the explicit recovery action.")
    }

    private func selectBackupFile(_ filename: String, app: XCUIApplication) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS[cd] %@", filename)
        func selectedFile() -> XCUIElement? {
            // Browse can reopen its previous local folder directly. Scope the
            // file to the actual local provider, never a Recents staging copy.
            let localRoots = app.otherElements.matching(NSPredicate(
                format: "identifier BEGINSWITH %@", "DOC.browsingRoot Source: com.apple.FileProvider.LocalStorage,"
            ))
            for root in localRoots.allElementsBoundByIndex {
                for browser in root.collectionViews.matching(identifier: "File View").allElementsBoundByIndex {
                    for item in browser.cells.matching(predicate).allElementsBoundByIndex {
                        if item.exists && item.isHittable { return item }
                    }
                }
            }
            return nil
        }
        var file: XCUIElement?
        for _ in 0..<3 {
            let navigationDeadline = Date().addingTimeInterval(3)
            repeat { file = selectedFile() } while file == nil && Date() < navigationDeadline
            if file != nil { break }
            if let location = localFilesLocation(app, timeout: 1) { location.tap() }
            else if let browse = nativeControl(["Browse"], app: app, timeout: 3) { browse.tap() }
        }
        let deadline = Date().addingTimeInterval(10)
        while file == nil && Date() < deadline { file = selectedFile() }
        guard let file else {
            captureSystem("Import-file-unavailable", app)
            XCTFail("Exported file is not available in the real document picker.")
            return false
        }
        waitForStableFrame(file, requireHittable: true, message: "The system file cell must finish presenting.")
        XCTAssertTrue(file.isEnabled, "The exported JSON must be selectable in the real picker.")
        let thumbnail = file.images.firstMatch
        if thumbnail.exists && !thumbnail.frame.isEmpty {
            // Icon-mode cells include a filename/metadata area below the
            // actual document thumbnail; choose the visible document itself.
            let target = thumbnail.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            XCTAssertTrue(file.frame.contains(target.screenPoint))
            XCTAssertTrue(app.windows.firstMatch.frame.contains(target.screenPoint))
            target.tap()
        } else {
            file.tap()
        }
        if !app.buttons["backup.merge"].waitForExistence(timeout: 5),
           !app.buttons["settings.chooseBackupAgain"].exists,
           let open = nativeControl(["Open"], app: app) { open.tap() }
        let resolved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.buttons["backup.merge"].exists || app.buttons["settings.chooseBackupAgain"].exists
        }, object: nil)
        return XCTWaiter.wait(for: [resolved], timeout: 30) == .completed
    }

    private func localFilesLocation(_ app: XCUIApplication, timeout: TimeInterval) -> XCUIElement? {
        let predicate = NSPredicate(format: "label == %@ OR label == %@", "On My iPhone", "On My iPad")
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let locations = app.buttons.matching(predicate).allElementsBoundByIndex
                + app.cells.matching(predicate).allElementsBoundByIndex
            for location in locations {
                if location.exists && location.isHittable { return location }
            }
        } while Date() < deadline
        return nil
    }

    private func captureSystem(_ name: String, _ app: XCUIApplication) {
        capture(name, app, stableSurface: app.windows.firstMatch)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = name + "-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }

    private func captureFailure(_ name: String, _ app: XCUIApplication) {
        // Capture the physical simulator surface first, even when a failing
        // app cannot provide a stable window or accessibility snapshot.
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = name + "-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }

    func testSessionAndRecapDiscardConfirmations() throws {
        let app = makeApp()
        app.launch()
        tap(app.buttons["today.startMoment"], in: app)
        tap(app.buttons["session.cancel"], in: app)
        cancelConfirmation("Keep going", destructiveAction: "Discard session", in: app)
        XCTAssertTrue(app.buttons["session.finish"].exists)
        tap(app.buttons["session.cancel"], in: app)
        tap(app.buttons["Discard session"], in: app)
        XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0)

        tap(app.buttons["today.startMoment"], in: app)
        tap(app.buttons["session.finish"], in: app)
        tap(app.buttons["recap.cancel"], in: app)
        cancelConfirmation("Keep editing", destructiveAction: "Discard reflection", in: app)
        XCTAssertTrue(app.buttons["recap.save"].exists)
        tap(app.buttons["recap.cancel"], in: app)
        tap(app.buttons["Discard reflection"], in: app)
        XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0)
    }

    func testEditingFilteringDeletionAndRelaunch() throws {
        let app = makeApp()
        app.launch()
        tap(app.buttons["today.startMoment"], in: app)
        let pause = app.buttons["session.pauseResume"]
        tap(pause, in: app)
        XCTAssertEqual(pause.label, "Resume")
        tap(pause, in: app)
        XCTAssertEqual(pause.label, "Pause")
        tap(app.buttons["session.finish"], in: app)
        tap(app.buttons["recap.kind.Solo"], in: app)
        let note = app.textViews["recap.note"]
        tap(note, in: app)
        note.typeText("Synthetic private reflection")
        tap(app.buttons["recap.dismissKeyboard"], in: app)
        tap(app.buttons["recap.save"], in: app)
        XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
        tap(app.buttons.matching(identifier: "moment.row").firstMatch, in: app)
        tap(app.buttons["detail.edit"], in: app)
        tap(app.buttons["recap.rating.5"], in: app)
        tap(app.buttons["recap.save"], in: app)
        XCTAssertTrue(app.staticTexts["5 of 5"].waitForExistence(timeout: 10))
        tap(app.buttons["detail.edit"], in: app)
        tap(app.buttons["recap.rating.2"], in: app)
        tap(app.buttons["recap.cancel"], in: app)
        tap(app.buttons["Discard reflection"], in: app)
        XCTAssertTrue(app.staticTexts["5 of 5"].waitForExistence(timeout: 10))

        app.terminate()
        app.launch() // Same launch UUID, same persistent test store.
        XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
        selectTab("Timeline", "时间线", app: app)
        tap(app.segmentedControls.buttons["Together"], in: app)
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0)
        XCTAssertTrue(app.staticTexts["No matching moments"].exists)
        tap(app.buttons["timeline.clearFilters"], in: app)
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 1)
        tap(app.segmentedControls.buttons["Solo"], in: app)
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 1)
        app.windows.firstMatch.swipeDown()
        let search = app.searchFields.firstMatch
        tap(search, in: app)
        let query = "no-matching-mood"
        search.typeText(query)
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0)
        tap(app.buttons["timeline.clearFilters"], in: app)
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 1)
        XCTAssertFalse(app.keyboards.firstMatch.exists, "Clearing filters should also dismiss search input.")
        tap(search, in: app)
        search.typeText(query)
        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: query.count))
        waitForTimelineRows(1, in: app)
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 1)
        search.typeText("Calm")
        waitForTimelineRows(1, in: app)
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 1)
        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4))
        // Dismiss search so the keyboard cannot cover the entry row.
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        tap(app.buttons.matching(identifier: "moment.row").firstMatch, in: app)
        XCTAssertTrue(app.staticTexts["5 of 5"].waitForExistence(timeout: 10))
        let savedNote = app.staticTexts["Synthetic private reflection"]
        XCTAssertTrue(savedNote.exists)
        tap(app.buttons["detail.delete"], in: app)
        cancelConfirmation("Cancel", destructiveAction: "Delete moment", in: app)
        XCTAssertTrue(app.buttons["detail.edit"].exists)
        tap(app.buttons["detail.delete"], in: app)
        tap(app.buttons["Delete moment"], in: app)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0)
    }

    func testManualEntryTimingDateFilterAndPersistence() throws {
        let app = makeApp(failFirstSave: true)
        app.launch()
        tap(app.buttons["today.addRecord"], in: app)
        tap(app.buttons["recap.cancel"], in: app)
        XCTAssertTrue(app.buttons["today.addRecord"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Discard reflection"].exists)
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0)
        tap(app.buttons["today.addRecord"], in: app)
        tap(app.buttons["recap.kind.Solo"], in: app)
        tap(app.buttons["recap.cancel"], in: app)
        cancelConfirmation("Keep editing", destructiveAction: "Discard reflection", in: app)
        XCTAssertTrue(app.buttons["recap.saveToolbar"].isHittable)
        tap(app.buttons["recap.kind.Together"], in: app)
        tap(app.buttons["recap.cancel"], in: app)
        XCTAssertTrue(app.buttons["today.addRecord"].waitForExistence(timeout: 10), "Reverting all changes should restore a clean draft.")
        tap(app.buttons["today.addRecord"], in: app)
        for (changed, original) in [
            ("recap.mood.Happy", "recap.mood.Calm"),
            ("recap.rating.5", "recap.rating.4"),
            ("recap.tag.Relaxed", "recap.tag.Relaxed")
        ] {
            tap(app.buttons[changed], in: app)
            tap(app.buttons["recap.cancel"], in: app)
            cancelConfirmation("Keep editing", destructiveAction: "Discard reflection", in: app)
            XCTAssertTrue(app.buttons[changed].isSelected, "Keeping the draft must preserve the selection.")
            tap(app.buttons[original], in: app)
            tap(app.buttons["recap.cancel"], in: app)
            XCTAssertTrue(app.buttons["today.addRecord"].waitForExistence(timeout: 10))
            tap(app.buttons["today.addRecord"], in: app)
        }
        let shortNote = "Synthetic kept draft"
        tap(app.textViews["recap.note"], in: app)
        app.textViews["recap.note"].typeText(shortNote)
        tap(app.buttons["recap.dismissKeyboard"], in: app)
        tap(app.buttons["recap.cancel"], in: app)
        cancelConfirmation("Keep editing", destructiveAction: "Discard reflection", in: app)
        XCTAssertEqual(app.textViews["recap.note"].value as? String, shortNote)
        tap(app.buttons["recap.cancel"], in: app)
        tap(app.buttons["Discard reflection"], in: app)
        XCTAssertTrue(app.buttons["today.addRecord"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0)
        tap(app.buttons["today.addRecord"], in: app)
        XCTAssertFalse(app.buttons["session.finish"].exists, "Manual entry must not start the timer.")
        tap(app.buttons["recap.yesterday"], in: app)
        replaceNumber(app.textFields["recap.minutes"], with: "17", in: app)
        replaceNumber(app.textFields["recap.seconds"], with: "60", in: app)
        XCTAssertFalse(app.buttons["recap.saveToolbar"].isEnabled, "Toolbar saving must enforce the same timing validation.")
        replaceNumber(app.textFields["recap.seconds"], with: "9", in: app)
        tap(app.buttons["recap.dismissKeyboard"], in: app)
        let longNote = Array(repeating: "Synthetic recovery note.", count: 18).joined(separator: "\n")
        tap(app.textViews["recap.note"], in: app)
        app.textViews["recap.note"].typeText(longNote)
        tap(app.buttons["recap.dismissKeyboard"], in: app)
        revealFully(from: app.textFields["recap.minutes"], through: app.textFields["recap.seconds"], in: app)
        capture("Manual-entered-en", app)
        tap(app.buttons["recap.saveToolbar"], in: app)
        recoverFailedSave(app: app)
        XCTAssertEqual(app.textFields["recap.minutes"].value as? String, "17")
        XCTAssertEqual(app.textFields["recap.seconds"].value as? String, "9")
        reveal(app.textViews["recap.note"], in: app)
        XCTAssertEqual(app.textViews["recap.note"].value as? String, longNote)
        tap(app.buttons["recap.saveToolbar"], in: app)
        XCTAssertTrue(app.buttons["today.addRecord"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["today.clearDateFilter"].exists, "A saved past entry must be shown on its actual date, even outside the three recent entries.")
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 1)

        tap(app.buttons["today.chooseDate"], in: app)
        tap(app.buttons["today.selectToday"], in: app)
        tap(app.buttons["today.applyDate"], in: app)
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0)
        capture("Today-filter-empty-en", app)
        tap(app.buttons["today.clearDateFilter"], in: app)
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 1)

        app.terminate()
        app.launch()
        tap(app.buttons.matching(identifier: "moment.row").firstMatch, in: app)
        XCTAssertTrue(app.buttons["detail.editToolbar"].isHittable)
        capture("Long-detail-top-en", app)
        tap(app.buttons["detail.editToolbar"], in: app)
        XCTAssertEqual(app.textFields["recap.minutes"].value as? String, "17")
        XCTAssertEqual(app.textFields["recap.seconds"].value as? String, "9")
        reveal(app.textViews["recap.note"], in: app)
        XCTAssertEqual(app.textViews["recap.note"].value as? String, longNote)
        replaceNumber(app.textFields["recap.minutes"], with: "18", in: app)
        tap(app.buttons["recap.dismissKeyboard"], in: app)
        tap(app.buttons["recap.cancel"], in: app)
        tap(app.buttons["Discard reflection"], in: app)
        tap(app.buttons["detail.editToolbar"], in: app)
        XCTAssertEqual(app.textFields["recap.minutes"].value as? String, "17")
        XCTAssertEqual(app.textFields["recap.seconds"].value as? String, "9")
        tap(app.buttons["recap.cancel"], in: app) // Unchanged edit exits directly.
        XCTAssertTrue(app.buttons["detail.editToolbar"].waitForExistence(timeout: 10))
    }

    private func replaceNumber(_ field: XCUIElement, with value: String, in app: XCUIApplication) {
        tap(field, in: app)
        let current = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + value)
    }

    private func chooseMomentFilter(_ label: String, in app: XCUIApplication) {
        let segment = app.segmentedControls.buttons[label]
        if segment.exists {
            tap(segment, in: app)
        } else {
            tap(app.buttons["timeline.filter"], in: app)
            tap(app.buttons[label].firstMatch, in: app)
        }
    }

    private func makeApp(language: String = "en", storeID: UUID = UUID(), failFirstSave: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", language == "en" ? "en_US" : "zh_CN",
            "-pm-ui-test-store", storeID.uuidString
        ]
        if failFirstSave { app.launchArguments.append("-pm-ui-test-fail-save-once") }
        return app
    }

    private func recoverFailedSave(language: String = "en", captureScenes: Bool = false, app: XCUIApplication) {
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertTrue(alert.staticTexts[language == "en" ? "Not saved" : "尚未保存"].exists)
        let edit = alert.buttons[language == "en" ? "Edit" : "继续编辑"]
        let reloadAction = alert.buttons[language == "en" ? "Reload" : "重新读取"]
        for action in [edit, reloadAction] {
            XCTAssertTrue(action.isHittable, "Recovery actions must be visible before scrolling the alert.")
            XCTAssertGreaterThanOrEqual(action.frame.minY, app.windows.firstMatch.frame.minY)
            XCTAssertLessThanOrEqual(action.frame.maxY, app.windows.firstMatch.frame.maxY)
        }
        if captureScenes { capture("Save-error-\(language)", app) }
        tap(edit, in: app)
        let reload = app.buttons["recap.reloadToolbar"]
        XCTAssertTrue(reload.waitForExistence(timeout: 5))
        XCTAssertTrue(reload.isHittable)
        XCTAssertTrue(reload.isEnabled)
        XCTAssertEqual(reload.label, language == "en" ? "Reload journal" : "重新读取记录")
        assertToolbarTarget(reload)
        XCTAssertFalse(app.buttons["recap.save"].isEnabled)
        if captureScenes { capture("Save-recovery-\(language)", app) }
        tap(reload, in: app)
        let save = app.buttons["recap.saveToolbar"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(save.isEnabled, "Reload must preserve a valid draft and require an explicit save.")
    }

    private func selectTab(_ english: String, _ chinese: String, language: String = "en", app: XCUIApplication) {
        let label = language == "en" ? english : chinese
        let tab = app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "Missing tab: \(label)")
        tab.tap()
    }

    private func assertToolbarTarget(_ control: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        // Snapshot coordinates can differ from 44 by one floating-point ULP.
        // A millionth of a point is below a display pixel; 36pt still fails.
        let tolerance: CGFloat = 0.000001
        XCTAssertGreaterThanOrEqual(control.frame.width + tolerance, 44, file: file, line: line)
        XCTAssertGreaterThanOrEqual(control.frame.height + tolerance, 44, file: file, line: line)
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        // A returned screen retains its scroll position. Existing controls can
        // be above it; lazy controls not yet created are searched below it.
        for _ in 0..<16 {
            let exists = element.waitForExistence(timeout: 0.5)
            let window = app.windows.firstMatch
            let viewport = window.frame
            guard !viewport.isEmpty, !viewport.isInfinite, !viewport.isNull else { continue }
            let keyboard = app.keyboards.firstMatch
            let frame = exists ? element.frame : .zero
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let keyboardCoversCenter = keyboard.exists && keyboard.frame.contains(center)
            let footerTop = fixedFooterTop(ignoring: element, in: app)
            let footerCoversCenter = footerTop.map { center.y >= $0 } ?? false
            if exists, element.isHittable, viewport.contains(center), !keyboardCoversCenter, !footerCoversCenter { return }
            let scroll = scrollSurface(containing: element, in: app)
            if exists, !frame.isEmpty, scroll.exists {
                let top = max(scroll.frame.minY, app.navigationBars.firstMatch.frame.maxY) + 12
                var bottom = min(scroll.frame.maxY, viewport.maxY) - 12
                if keyboard.exists { bottom = min(bottom, keyboard.frame.minY - 12) }
                if app.tabBars.firstMatch.exists { bottom = min(bottom, app.tabBars.firstMatch.frame.minY - 12) }
                if let footerTop { bottom = min(bottom, footerTop - 12) }
                guard bottom > top + 44 else { return XCTFail("No usable scroll viewport for \(element)") }
                let middle = (top + bottom) / 2
                let limit = (bottom - top) * 0.4
                let delta = max(-limit, min(limit, middle - frame.midY))
                let start = window.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: min(scroll.frame.maxX - 12, viewport.maxX - 12) - viewport.minX,
                        dy: middle - viewport.minY))
                start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: delta)))
            } else {
                window.swipeUp()
            }
        }
        XCTFail("Control is unreachable after scrolling: \(element)")
    }

    private func scrollSurface(containing element: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        if element.exists, !element.identifier.isEmpty {
            let owners = app.scrollViews.containing(.any, identifier: element.identifier)
            if let visible = owners.allElementsBoundByIndex.first(where: { $0.isHittable }) { return visible }
            if owners.firstMatch.exists { return owners.firstMatch }
        }
        return app.scrollViews.firstMatch
    }

    private func fixedFooterTop(ignoring element: XCUIElement, in app: XCUIApplication) -> CGFloat? {
        guard !app.alerts.firstMatch.exists else { return nil }
        if element.exists, element.identifier == "backup.merge" { return nil }
        let footers = app.buttons.matching(identifier: "backup.merge").allElementsBoundByIndex
        // Reserve the visible button and its 12pt top safe-area padding.
        return footers.first(where: { $0.isHittable }).map { $0.frame.minY - 12 }
    }

    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        reveal(element, in: app)
        element.tap()
    }

    private func waitForTimelineRows(_ count: Int, in app: XCUIApplication) {
        // Keyboard events can complete before SwiftUI publishes the next
        // accessibility snapshot. Wait for actual results, never a fixed delay.
        let updated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.buttons.matching(identifier: "moment.row").count == count
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [updated], timeout: 5), .completed,
            "Timeline did not publish the expected record count after search changed.")
    }

    private func cancelConfirmation(_ label: String, destructiveAction: String, in app: XCUIApplication) {
        let action = app.buttons[destructiveAction].firstMatch
        XCTAssertTrue(action.waitForExistence(timeout: 10), "Confirmation must appear before cancellation.")
        let cancel = app.buttons[label].firstMatch
        if cancel.exists && cancel.isHittable {
            cancel.tap()
        } else {
            // SDK 26 presents a popover without the role-cancel button. Dismiss
            // outside its actual frame, rather than scrolling the modal away.
            let popover = app.popovers.firstMatch
            XCTAssertTrue(popover.waitForExistence(timeout: 5), "Missing cancel action and popover.")
            let outside = [CGVector(dx: 0.05, dy: 0.5), CGVector(dx: 0.95, dy: 0.5),
                           CGVector(dx: 0.5, dy: 0.9), CGVector(dx: 0.5, dy: 0.1)]
                .map { app.windows.firstMatch.coordinate(withNormalizedOffset: $0) }
                .first { !popover.frame.insetBy(dx: -8, dy: -8).contains($0.screenPoint) }
            guard let outside else {
                XCTFail("No point outside the confirmation popover.")
                return
            }
            outside.tap()
        }
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: action)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed, "Confirmation did not dismiss.")
    }

    private func revealFully(from first: XCUIElement, through last: XCUIElement, in app: XCUIApplication) {
        reveal(last, in: app)
        let scroll = scrollSurface(containing: last, in: app)
        // A hittable element may be only partly visible. Fit the complete range
        // of controls or text below the navigation bar before taking a capture.
        for _ in 0..<6 {
            XCTAssertTrue(first.exists)
            let top = max(scroll.frame.minY, app.navigationBars.firstMatch.frame.maxY) + 12
            var bottom = min(scroll.frame.maxY, app.windows.firstMatch.frame.maxY) - 12
            if let footerTop = fixedFooterTop(ignoring: last, in: app) { bottom = min(bottom, footerTop - 12) }
            let section = first.frame.union(last.frame)
            let delta: CGFloat
            if section.minY < top {
                delta = top - section.minY
            } else if section.maxY > bottom {
                delta = bottom - section.maxY
            } else {
                return
            }
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let distance = max(24, min(200, abs(delta))) * (delta < 0 ? -1 : 1)
            let end = start.withOffset(CGVector(dx: 0, dy: distance))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTFail("Content is not fully visible: \(first), \(last)")
    }

    private func goBack(_ app: XCUIApplication) {
        let back = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        back.tap()
    }

    private func capture(_ name: String, _ app: XCUIApplication, stableSurface: XCUIElement? = nil) {
        // A screenshot can be taken while a SwiftUI push or scroll is still
        // animating. Require a stable scroll-surface frame across polling ticks.
        let surface = stableSurface ?? (app.alerts.firstMatch.exists ? app.alerts.firstMatch : app.scrollViews.firstMatch)
        waitForStableFrame(surface, message: "Screen never settled: \(name)")
        // Capture the physical display, including native system surfaces,
        // without depending on the application root's optional frame.
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func waitForStableFrame(_ surface: XCUIElement, requireHittable: Bool = false, message: String) {
        var lastFrame = CGRect.null
        var stableSince = Date()
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard surface.exists, !requireHittable || surface.isHittable else { return false }
            let frame = surface.frame
            if frame != lastFrame {
                lastFrame = frame
                stableSince = Date()
                return false
            }
            return Date().timeIntervalSince(stableSince) >= 0.75
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 10), .completed, message)
    }
}
