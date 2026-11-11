import XCTest

final class PrivateMomentsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
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
            XCTAssertGreaterThanOrEqual(brand.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(brand.frame.maxX, app.frame.maxX)
            if !app.buttons["today.weekMenu"].exists {
                XCTAssertGreaterThanOrEqual(brand.frame.width, language == "en" ? 115 : 60,
                    "The brand must not collapse into an icon-sized toolbar item.")
            }
            XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0, "Each locale must use an isolated empty store.")
            for action in [start, app.buttons["today.addRecord"]] {
                XCTAssertGreaterThanOrEqual(action.frame.minX, app.frame.minX, "Home action is clipped on the left.")
                XCTAssertLessThanOrEqual(action.frame.maxX, app.frame.maxX, "Home action is clipped on the right.")
                XCTAssertGreaterThanOrEqual(action.frame.height, 44, "Home action needs an accessible target height.")
            }
            capture("Today-\(language)", app)
            let weekMenu = app.buttons["today.weekMenu"]
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
                XCTAssertGreaterThanOrEqual(field.frame.minX, app.frame.minX, "Timing input is clipped on the left.")
                XCTAssertLessThanOrEqual(field.frame.maxX, app.frame.maxX, "Timing input is clipped on the right.")
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
            app.swipeUp()
            app.swipeUp()
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
            revealFully(from: app.staticTexts["settings.footer"], through: app.staticTexts["settings.footer"], in: app)
            capture("Settings-bottom-\(language)", app)
            tap(app.buttons["settings.export"], in: app)
            let warning = app.alerts.firstMatch
            XCTAssertTrue(warning.waitForExistence(timeout: 5))
            XCTAssertTrue(warning.buttons[language == "en" ? "Export" : "导出"].isHittable)
            capture("Backup-warning-\(language)", app)
            tap(warning.buttons[language == "en" ? "Cancel" : "取消"], in: app)
            tap(app.buttons["settings.lock"], in: app)
            // Simulator policy evaluation may remain pending rather than fail
            // immediately. Exercise real background cancellation, without an
            // authentication-success fixture or an assumed Simulator policy.
            XCUIDevice.shared.press(.home)
            XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10))
            app.activate()
            let lock = app.buttons["settings.lock"]
            reveal(lock, in: app)
            let recovered = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: lock)
            XCTAssertEqual(XCTWaiter.wait(for: [recovered], timeout: 10), .completed)
            XCTAssertEqual(lock.label, language == "en" ? "Lock journal, Off" : "锁定日记, 关闭")
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
        XCTAssertNotNil(nativeControl(["Save"], app: app, timeout: 30))
        captureSystem("Export-files-en", app)
        // Each hosted Simulator is fresh; this test exports exactly one file.
        // iOS may hide Save As on first presentation; use the real default name.
        let filename = "Private-Moments-Backup"
        saveToLocalFiles(app)
        let saved = app.staticTexts["Backup saved."]
        XCTAssertTrue(saved.waitForExistence(timeout: 15), "Only the real exporter completion may report success.")

        tap(app.buttons["settings.restore"], in: app)
        let cancel = try XCTUnwrap(nativeControl(["Cancel"], app: app, timeout: 10))
        captureSystem("Import-files-en", app)
        cancel.tap()
        assertSavedCount("1", app: app)
        tap(app.buttons["settings.deleteAll"], in: app)
        tap(app.buttons["Delete all moments"], in: app)
        assertSavedCount("0", app: app)

        openBackup(filename, app: app)
        capture("Backup-review-en", app)
        assertMetric("backup.newCount", value: "1", app: app)
        assertMetric("backup.updatedCount", value: "0", app: app)
        assertMetric("backup.noteCount", value: "1", app: app)
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
        assertSavedCount("1", app: app)
        capture("Backup-restored-en", app)
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

    private func assertMetric(_ identifier: String, value: String, app: XCUIApplication) {
        let metric = app.staticTexts[identifier]
        reveal(metric, in: app)
        XCTAssertEqual(metric.label, value)
    }

    private func nativeControl(_ labels: [String], app: XCUIApplication, timeout: TimeInterval = 2) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for label in labels {
                for item in [app.buttons[label].firstMatch, app.staticTexts[label].firstMatch] {
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
        tap(app.buttons["settings.restore"], in: app)
        let predicate = NSPredicate(format: "label CONTAINS[cd] %@", filename)
        func selectedFile() -> XCUIElement? {
            for query in [app.cells.matching(predicate), app.buttons.matching(predicate), app.staticTexts.matching(predicate)] {
                let item = query.firstMatch
                if item.exists && item.isHittable { return item }
            }
            return nil
        }
        let deadline = Date().addingTimeInterval(10)
        var file = selectedFile()
        while file == nil && Date() < deadline { file = selectedFile() }
        if file == nil {
            if let browse = nativeControl(["Browse"], app: app) { browse.tap() }
            if let local = nativeControl(["On My iPhone", "On My iPad"], app: app) { local.tap() }
            let localDeadline = Date().addingTimeInterval(10)
            repeat { file = selectedFile() } while file == nil && Date() < localDeadline
        }
        guard let file else {
            captureSystem("Import-file-unavailable", app)
            return XCTFail("Exported file is not available in the real document picker.")
        }
        file.tap()
        if !app.buttons["backup.merge"].waitForExistence(timeout: 5), let open = nativeControl(["Open"], app: app) { open.tap() }
        XCTAssertTrue(app.buttons["backup.merge"].waitForExistence(timeout: 10), "Selecting the file must lead to a validated review.")
    }

    private func captureSystem(_ name: String, _ app: XCUIApplication) {
        capture(name, app, stableSurface: app.windows.firstMatch)
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
        app.swipeDown()
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
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 1)
        search.typeText("Calm")
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
            XCTAssertGreaterThanOrEqual(action.frame.minY, app.frame.minY)
            XCTAssertLessThanOrEqual(action.frame.maxY, app.frame.maxY)
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
            let scroll = app.scrollViews.firstMatch
            let keyboard = app.keyboards.firstMatch
            let frame = exists ? element.frame : .zero
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let keyboardCoversCenter = keyboard.exists && keyboard.frame.contains(center)
            if exists, element.isHittable, app.frame.contains(center), !keyboardCoversCenter { return }
            if exists, !frame.isEmpty, scroll.exists {
                let top = max(scroll.frame.minY, app.navigationBars.firstMatch.frame.maxY) + 12
                var bottom = min(scroll.frame.maxY, app.frame.maxY) - 12
                if keyboard.exists { bottom = min(bottom, keyboard.frame.minY - 12) }
                if app.tabBars.firstMatch.exists { bottom = min(bottom, app.tabBars.firstMatch.frame.minY - 12) }
                guard bottom > top + 44 else { return XCTFail("No usable scroll viewport for \(element)") }
                let middle = (top + bottom) / 2
                let limit = (bottom - top) * 0.4
                let delta = max(-limit, min(limit, middle - frame.midY))
                let start = app.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: min(scroll.frame.maxX - 12, app.frame.maxX - 12), dy: middle))
                start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: delta)))
            } else {
                app.swipeUp()
            }
        }
        XCTFail("Control is unreachable after scrolling: \(element)")
    }

    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        reveal(element, in: app)
        element.tap()
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
                .map { app.coordinate(withNormalizedOffset: $0) }
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
        let scroll = app.scrollViews.firstMatch
        // A hittable element may be only partly visible. Fit the complete range
        // of controls or text below the navigation bar before taking a capture.
        for _ in 0..<6 {
            XCTAssertTrue(first.exists)
            let top = max(scroll.frame.minY, app.navigationBars.firstMatch.frame.maxY) + 12
            let bottom = min(scroll.frame.maxY, app.frame.maxY) - 12
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
        var lastFrame = CGRect.null
        var stableSince = Date()
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard surface.exists else { return false }
            let frame = surface.frame
            if frame != lastFrame {
                lastFrame = frame
                stableSince = Date()
                return false
            }
            return Date().timeIntervalSince(stableSince) >= 0.75
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 10), .completed, "Screen never settled: \(name)")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
