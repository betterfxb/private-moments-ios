import XCTest
import UIKit

final class PrivateMomentsUITests: XCTestCase {
    private var importRecoveryCount = 0
    private let rotationNote = "Rotation draft\nKeep every line"
    private enum BackupSelectionResult {
        case delivered
        case pendingDelivery
        case unavailablePicker(XCUICoordinate)
        case failed
    }

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
               let cancel = nativeControl(["Cancel", "取消"], app: app) { cancel.tap() }
            app.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
    }

    func testLargeJournalInteractionBaseline() throws {
        let app = makeApp()
        let arguments = app.launchArguments
        app.launchArguments.append("-pm-ui-test-performance-fixture")
        app.launch()
        XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 30))
        selectTab("Timeline", "时间线", language: "en", app: app)
        let count = app.staticTexts["timeline.resultCount"]
        let fullCountLabels = ["1,000 moments", "1000 moments"]
        XCTAssertTrue(fullCountLabels.contains(count.label), "Unexpected fixture count: \(count.label)")
        app.terminate()
        app.launchArguments = arguments + ["-pm-ui-test-performance-trace"]

        // Seed setup and termination stay outside the recorded launch time.
        // UI measurements include XCTest events and accessibility polling.
        for sample in 1...3 {
            let launchStarted = ProcessInfo.processInfo.systemUptime
            app.launch()
            XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 30))
            print("Performance UI count=1000 sample=\(sample) launchReadySeconds=\(ProcessInfo.processInfo.systemUptime - launchStarted)")

            selectTab("Timeline", "时间线", language: "en", app: app)
            XCTAssertTrue(fullCountLabels.contains(count.label), "Unexpected fixture count: \(count.label)")
            let rows = app.buttons.matching(identifier: "moment.row")
            let firstRow = rows.firstMatch
            XCTAssertTrue(firstRow.isHittable)
            let firstFrame = firstRow.frame
            let firstLabel = firstRow.label
            let scroll = app.scrollViews.firstMatch
            let scrollStarted = ProcessInfo.processInfo.systemUptime
            scroll.swipeUp()
            let visibleRow = try XCTUnwrap(rows.allElementsBoundByIndex.first(where: \.isHittable))
            XCTAssertTrue(visibleRow.label != firstLabel || visibleRow.frame != firstFrame,
                          "A scroll sample must move a result or expose another result.")
            print("Performance UI count=1000 sample=\(sample) scrollGestureSeconds=\(ProcessInfo.processInfo.systemUptime - scrollStarted)")
            let search = revealTimelineSearch(in: app)
            search.tap()
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
            let searchStarted = ProcessInfo.processInfo.systemUptime
            search.typeText("baseline-target")
            let matching = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in count.label == "1 moment" },
                                                       object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [matching], timeout: 15), .completed)
            XCTAssertEqual(search.value as? String, "baseline-target")
            print("Performance UI count=1000 sample=\(sample) searchTypingToMatchSeconds=\(ProcessInfo.processInfo.systemUptime - searchStarted)")
            let submitStarted = ProcessInfo.processInfo.systemUptime
            guard submitTimelineSearch(language: "en", app: app) else { return }
            let rowRevealed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                !app.keyboards.firstMatch.exists && rows.firstMatch.isHittable
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [rowRevealed], timeout: 15), .completed)
            XCTAssertEqual(count.label, "1 moment")
            XCTAssertEqual(search.value as? String, "baseline-target")
            print("Performance UI count=1000 sample=\(sample) searchSubmitToRowSeconds=\(ProcessInfo.processInfo.systemUptime - submitStarted)")
            app.terminate()
        }
    }

    func testTimelineSearchReflectsEditAndDeletion() {
        let app = makeApp()
        app.launch()
        tap(app.buttons["today.addRecord"], in: app)
        tap(app.buttons["recap.saveToolbar"], in: app)
        XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
        selectTab("Timeline", "时间线", language: "en", app: app)

        let result = app.buttons.matching(identifier: "moment.row").firstMatch
        let total = app.staticTexts["timeline.resultCount"]
        func assertCount(_ count: String, for query: String) {
            let updated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                !app.keyboards.firstMatch.exists && total.exists && total.label == count
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [updated], timeout: 10), .completed, "Search result for \(query)")
        }

        func searchFor(_ query: String, count: String) {
            let clear = app.buttons["timeline.clearFilters"]
            if clear.exists { tap(clear, in: app) }
            let field = revealTimelineSearch(in: app)
            tap(field, in: app)
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
            field.typeText(query)
            XCTAssertEqual(field.value as? String, query)
            guard submitTimelineSearch(language: "en", app: app) else { return }
            assertCount(count, for: query)
        }

        func assertAfterReturning(query: String, count: String) {
            XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
            let field = app.searchFields.firstMatch
            if field.exists, field.value as? String == query {
                assertCount(count, for: query)
            } else {
                searchFor(query, count: count)
            }
        }

        searchFor("Calm", count: "1 moment")
        tap(result, in: app)
        tap(app.buttons["detail.edit"], in: app)
        tap(app.buttons["recap.mood.Happy"], in: app)
        tap(app.buttons["recap.saveToolbar"], in: app)
        XCTAssertTrue(app.staticTexts["Happy"].waitForExistence(timeout: 10))
        goBack(app)
        assertAfterReturning(query: "Calm", count: "0 moments")
        XCTAssertFalse(result.exists)
        searchFor("Happy", count: "1 moment")
        tap(result, in: app)
        tap(app.buttons["detail.delete"], in: app)
        tap(app.buttons["Delete moment"], in: app)
        assertAfterReturning(query: "Happy", count: "0 moments")
        XCTAssertFalse(result.exists)
    }

    func testReviewTabBrowsesPeriodsAndOpensFilteredRecord() {
        for language in ["en", "zh-Hans"] {
            let english = language == "en"
            let app = makeApp(language: language)
            app.launch()
            XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 15))
            let tab = app.buttons.matching(NSPredicate(format: "label == %@", english ? "Review" : "回顾")).firstMatch
            guard tab.waitForExistence(timeout: 5) else {
                captureFailure("Review-tab-unavailable-\(language)", app)
                return XCTFail("Review must have its own native tab.")
            }
            tab.tap()

            let count = app.staticTexts["weekReview.count"]
            let range = app.staticTexts["weekReview.range"]
            let empty = app.staticTexts["weekReview.empty"]
            let month = app.buttons["review.month"]
            let week = app.buttons["review.week"]
            let previous = app.buttons["review.previous"]
            let next = app.buttons["review.next"]
            let zero = english ? "0 moments" : "0 条记录"
            let two = english ? "2 moments" : "2 条记录"

            XCTAssertTrue(count.waitForExistence(timeout: 10))
            XCTAssertEqual(count.label, zero)
            XCTAssertEqual(week.label, english ? "Week" : "周")
            XCTAssertEqual(month.label, english ? "Month" : "月")
            XCTAssertTrue(week.isSelected)
            XCTAssertFalse(next.isEnabled)
            XCTAssertEqual(empty.label, english ? "No moments in this period" : "这段时间还没有记录")
            capture("Review-tab-empty-\(language)", app, stableSurface: range)

            selectTab("Today", "今天", language: language, app: app)
            tap(app.buttons["today.addRecord"], in: app)
            tap(app.buttons["recap.saveToolbar"], in: app)
            XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
            tap(app.buttons["today.addRecord"], in: app)
            let happyChoice = app.buttons["recap.mood.Happy"]
            revealFully(from: happyChoice, through: happyChoice, in: app)
            happyChoice.tap()
            XCTAssertTrue(happyChoice.isSelected)
            tap(app.buttons["recap.saveToolbar"], in: app)
            XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
            tab.tap()

            XCTAssertTrue(count.waitForExistence(timeout: 10))
            XCTAssertEqual(count.label, two)
            let currentWeek = range.label
            tap(previous, in: app)
            XCTAssertNotEqual(range.label, currentWeek)
            XCTAssertEqual(count.label, zero)
            XCTAssertTrue(empty.exists)
            tap(next, in: app)
            XCTAssertEqual(range.label, currentWeek)
            XCTAssertEqual(count.label, two)

            tap(month, in: app)
            XCTAssertTrue(month.isSelected)
            XCTAssertEqual(count.label, two)
            let currentMonth = range.label
            XCTAssertNotEqual(currentMonth, currentWeek)
            capture("Review-tab-month-\(language)", app, stableSurface: range)
            tap(previous, in: app)
            XCTAssertNotEqual(range.label, currentMonth)
            XCTAssertEqual(count.label, zero)
            tap(app.buttons["review.jumpDate"], in: app)
            tap(app.buttons["review.selectToday"], in: app)
            tap(app.buttons["review.applyDate"], in: app)
            XCTAssertTrue(range.waitForExistence(timeout: 10))
            XCTAssertEqual(range.label, currentMonth)
            XCTAssertEqual(count.label, two)

            let happy = app.buttons["weekReview.mood.Happy"]
            revealFully(from: happy, through: happy, in: app)
            XCTAssertGreaterThanOrEqual(happy.frame.height, 44)
            assertAboveBottomTabBar(happy, message: "Mood filter must clear the tab bar.", app: app)
            happy.tap()
            XCTAssertTrue(happy.isSelected)
            let records = app.buttons.matching(identifier: "weekReview.moment")
            XCTAssertEqual(records.count, 1)
            let record = records.firstMatch
            revealFully(from: record, through: record, in: app)
            XCTAssertTrue(app.staticTexts.matching(identifier: "review.recordDay").firstMatch.exists)
            capture("Review-tab-filtered-\(language)", app, stableSurface: record)
            record.tap()
            XCTAssertTrue(app.buttons["detail.edit"].waitForExistence(timeout: 10))
            XCTAssertTrue(app.staticTexts[english ? "Happy" : "愉悦"].exists)
            goBack(app)
            XCTAssertTrue(range.waitForExistence(timeout: 10))
            XCTAssertEqual(range.label, currentMonth)
            XCTAssertTrue(happy.isSelected)
            tap(app.buttons["review.clearMood"], in: app)
            XCTAssertEqual(records.count, 2)
            app.terminate()
        }
    }

    func testWeekReviewShowsLocalRecords() {
        for language in ["en", "zh-Hans"] {
            let english = language == "en"
            let app = makeApp(language: language)
            app.launch()
            XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 15))

            let weekMenu = app.buttons["today.weekMenu"]
            let weekContext = weekMenu.exists ? weekMenu : app.staticTexts[english ? "This week" : "本周"]
            reveal(weekContext, in: app)
            capture("Today-week-context-\(language)", app, stableSurface: weekContext)
            let entry = app.buttons["today.weekReview"]
            guard entry.waitForExistence(timeout: 5) else {
                captureFailure("Week-review-entry-unavailable-\(language)", app)
                return XCTFail("Today must provide a native Week in review entry.")
            }
            XCTAssertEqual(entry.label, english ? "Week in review" : "本周回顾")
            revealFully(from: entry, through: entry, in: app)
            waitForStableFrame(entry, requireHittable: true, message: "The full review entry must settle before tapping.")
            XCTAssertGreaterThanOrEqual(entry.frame.height, 44)
            assertAboveBottomTabBar(entry, message: "Review entry must clear the tab bar.", app: app)
            capture("Week-review-entry-\(language)", app, stableSurface: entry)
            entry.tap()

            let count = app.staticTexts["weekReview.count"]
            let range = app.staticTexts["weekReview.range"]
            let empty = app.staticTexts["weekReview.empty"]
            let records = app.buttons.matching(identifier: "weekReview.moment")
            XCTAssertTrue(count.waitForExistence(timeout: 10))
            XCTAssertEqual(count.label, english ? "0 moments" : "0 条记录")
            XCTAssertTrue(range.exists)
            XCTAssertFalse(range.label.isEmpty)
            XCTAssertTrue(app.windows.firstMatch.frame.contains(range.frame))
            XCTAssertEqual(empty.label, english ? "No moments this week" : "本周还没有记录")
            XCTAssertEqual(records.count, 0)
            capture("Week-review-empty-\(language)", app, stableSurface: count)
            goBack(app)

            tap(app.buttons["today.addRecord"], in: app)
            tap(app.buttons["recap.saveToolbar"], in: app)
            XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
            tap(entry, in: app)
            XCTAssertTrue(count.waitForExistence(timeout: 10))
            let one = english ? "1 moment" : "1 条记录"
            XCTAssertEqual(count.label, one)
            XCTAssertFalse(empty.exists)
            let mood = app.descendants(matching: .any).matching(identifier: "weekReview.mood.Calm").firstMatch
            XCTAssertTrue(mood.waitForExistence(timeout: 10))
            XCTAssertEqual(mood.label, english ? "Calm" : "平静")
            XCTAssertEqual(mood.value as? String, one)
            XCTAssertEqual(records.count, 1)
            let record = records.firstMatch
            XCTAssertEqual(record.frame.minX, range.frame.minX, accuracy: 1)
            XCTAssertGreaterThanOrEqual(app.windows.firstMatch.frame.intersection(record.frame).height, 44,
                "A one-record review must show at least one touch target on its first screen.")
            capture("Week-review-single-\(language)", app, stableSurface: count)

            revealFully(from: record, through: record, in: app)
            XCTAssertGreaterThanOrEqual(record.frame.height, 44)
            capture("Week-review-record-\(language)", app, stableSurface: record)
            record.tap()
            XCTAssertTrue(app.buttons["detail.edit"].waitForExistence(timeout: 10))
            XCTAssertTrue(app.navigationBars[english ? "Moment details" : "记录详情"].exists)
            XCTAssertTrue(app.staticTexts[english ? "Calm" : "平静"].exists)
            goBack(app)
            XCTAssertTrue(count.waitForExistence(timeout: 10))
            XCTAssertEqual(count.label, one)
            app.terminate()
        }
    }

    // The CI profile sets device, appearance and text size.
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
            XCTAssertTrue(start.isHittable, "The primary action must be usable on the first screen.")
            XCTAssertLessThan(start.frame.maxY, app.buttons["today.addRecord"].frame.minY,
                "The cover should present the primary action before the secondary action.")
            let weekMenu = app.buttons["today.weekMenu"]
            let usesAccessibilityLayout = weekMenu.exists
            if usesAccessibilityLayout {
                let add = app.buttons["today.addRecord"]
                XCTAssertTrue(add.isHittable)
                assertAboveBottomTabBar(add, message: "The full add-past action must fit on the first screen.", app: app)
            }
            capture("Today-\(language)", app)
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
            checkManualNoteDraft(language: language, expanded: usesAccessibilityLayout, app: app)
            tap(start, in: app)
            capture("Session-\(language)", app)
            reveal(app.buttons["session.finish"], in: app)
            capture("Session-controls-\(language)", app)
            tap(app.buttons["session.cancel"], in: app)
            let discard = language == "en" ? "Discard" : "放弃"
            let keep = language == "en" ? "Keep going" : "继续记录"
            captureVisibleConfirmation("Session-discard-confirm-\(language)", keep: keep, discard: discard, app: app)
            cancelConfirmation(keep, destructiveAction: discard, in: app)
            XCTAssertEqual(app.buttons["session.pauseResume"].label, language == "en" ? "Pause" : "暂停",
                "Keeping the timer must leave it running.")
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
            let savedRow = app.buttons.matching(identifier: "moment.row").firstMatch
            reveal(savedRow, in: app)
            XCTAssertTrue(savedRow.isHittable, "A saved record must be reachable below the cover.")
            capture("Today-record-\(language)", app, stableSurface: savedRow)
            tap(app.buttons["today.chooseDate"], in: app)
            capture("Calendar-\(language)", app)
            tap(app.buttons["today.applyDate"], in: app)
            capture("Today-filtered-\(language)", app)
            tap(app.buttons["today.clearDateFilter"], in: app)
            app.windows.firstMatch.swipeUp()
            app.windows.firstMatch.swipeUp()
            capture("Today-summary-\(language)", app)
            selectTab("Timeline", "时间线", language: language, app: app)
            checkTimelineSearch(language: language, app: app)
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
            if usesAccessibilityLayout {
                assertAboveBottomTabBar(countTitle, message: "Settings should initially show the saved-record label.", app: app)
                assertAboveBottomTabBar(countValue, message: "Settings should initially show the saved-record count.", app: app)
            }
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
            // immediately. Exercise a real background handoff after the request,
            // without an authentication-success fixture or assumed prompt state.
            // Activate a real second app: Home events may leave this app in the
            // foreground on hosted iPad Simulators. No system setting is changed.
            let systemSettings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
            systemSettings.activate()
            guard systemSettings.wait(for: .runningForeground, timeout: 10) else {
                captureFailure("System-settings-foreground-unavailable-\(language)", app)
                return XCTFail("System Settings must actually receive the foreground.")
            }
            let backgrounded = app.state == .runningBackgroundSuspended ||
                app.wait(for: .runningBackground, timeout: 30) ||
                app.wait(for: .runningBackgroundSuspended, timeout: 2)
            guard backgrounded else {
                print("Authentication exit state raw value: \(app.state.rawValue); locale: \(language).")
                captureFailure("Lock-background-unavailable-\(language)", app)
                return XCTFail("Authentication exit must reach a real running background state.")
            }
            print("Verified system Settings foreground handoff. Locale: \(language).")
            app.activate()
            let lock = app.buttons["settings.lock"]
            reveal(lock, in: app)
            let recovered = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: lock)
            XCTAssertEqual(XCTWaiter.wait(for: [recovered], timeout: 10), .completed)
            XCTAssertTrue(lock.staticTexts[language == "en" ? "Off" : "关闭"].exists)
            XCTAssertFalse(lock.staticTexts[language == "en" ? "On" : "开启"].exists)
            let lockTitle = lock.staticTexts["settings.lockTitle"]
            let lockValue = lock.staticTexts[language == "en" ? "Off" : "关闭"]
            revealFully(from: lockTitle, through: lockValue, in: app)
            XCTAssertEqual(lockTitle.label, language == "en" ? "Lock journal" : "锁定日记")
            assertValueLayout(title: lockTitle, value: lockValue, stacked: usesAccessibilityLayout)
            print("Verified fully visible lock title and value. Locale: \(language).")
            captureSystem("Lock-recovery-\(language)", app)
            app.terminate()
        }
    }

    func testIPadRotationContinuity() throws {
        runRotationContinuity(languages: ["en", "zh-Hans"], usingSystemReference: true)
    }

    func testIPadColdEnglishRotationContinuity() throws {
        runRotationContinuity(languages: ["en"], usingSystemReference: false)
    }

    func testIPadColdChineseRotationContinuity() throws {
        runRotationContinuity(languages: ["zh-Hans"], usingSystemReference: false)
    }

    private func runRotationContinuity(languages: [String], usingSystemReference: Bool) {
        XCTAssertEqual(UIDevice.current.userInterfaceIdiom, .pad, "This method requires the explicit iPad profile.")
        if !usingSystemReference {
            // Each cold method must be selected alone in a fresh CI job. A
            // second locale in the same process cannot establish cold rotation.
            XCTAssertEqual(languages.count, 1)
            XCTAssertEqual(XCUIApplication().state, .notRunning)
            print("Cold rotation entry: app not running; no system reference activation; locale: \(languages[0]).")
        }
        for language in languages {
            let app = makeApp(language: language)
            app.launch()
            if usingSystemReference {
                prepareRotationReference(language: language, app: app)
            }
            rotateInterface(.portrait, stage: "initial", language: language, app: app)
            createRotatingDraft(language: language, app: app)
            inspectRotatingNavigation(language: language, app: app)
            inspectRotatingPausedTimer(language: language, app: app)
            assertRotationRecordAfterRelaunch(language: language, app: app)
            print("Verified iPad rotation continuity. Locale: \(language).")
            app.terminate()
        }
    }

    private func prepareRotationReference(language: String, app: XCUIApplication) {
        // Compare a real independent system app before creating any draft. An
        // empty Simulator Control Center cannot establish rotation-lock state.
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.activate()
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 10))
        let window = settings.windows.firstMatch
        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait] {
            XCUIDevice.shared.orientation = orientation
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                guard window.exists else { return false }
                let frame = window.frame
                return frame.width > 0 && frame.height > 0 &&
                    (orientation.isLandscape ? frame.width > frame.height : frame.height > frame.width)
            }, object: nil)
            guard XCTWaiter.wait(for: [changed], timeout: 20) == .completed else {
                print("System reference rotation unavailable. Locale: \(language); requested: \(orientation.rawValue); observed device: \(XCUIDevice.shared.orientation.rawValue); frame: \(window.frame).")
                captureFailure("Rotation-reference-unavailable-\(orientation.rawValue)-\(language)", settings)
                return XCTFail("The independent system reference must rotate before app continuity can be assessed.")
            }
            waitForStableFrame(window, message: "The system reference window must settle.")
            print("Verified system reference geometry. Locale: \(language); device: \(orientation.rawValue); frame: \(window.frame).")
            if orientation.isLandscape {
                captureSystem("Rotation-reference-landscape-\(language)", settings)
            }
        }
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.buttons["today.addRecord"].waitForExistence(timeout: 10))
    }

    func testIPadWindowResizeContinuity() throws {
        guard enableIPadWindowedApps() else { return }

        let app = makeApp()
        app.launch()
        let window = app.windows.firstMatch
        waitForStableFrame(window, message: "The real app window must settle before resizing.")
        let wide = window.frame
        XCTAssertGreaterThanOrEqual(wide.width, 700, "A wide starting window is required.")
        tap(app.buttons["today.addRecord"], in: app)
        replaceNumber(app.textFields["recap.minutes"], with: "3", in: app)
        dismissRecapKeyboard(language: "en", app: app)
        replaceNumber(app.textFields["recap.seconds"], with: "8", in: app)
        dismissRecapKeyboard(language: "en", app: app)
        let note = app.textViews["recap.note"]
        tap(note, in: app)
        note.typeText(rotationNote)
        dismissRecapKeyboard(language: "en", app: app)
        captureSystem("Window-resize-wide", app)

        let firstWindow = try resizeIPadWindow(app, targetWidth: wide.width * 0.76, name: "first-drag")
        // Leaving maximized mode can land on the system's default floating size.
        // Measure that step, then use the floating grabber to reach medium width.
        let medium = firstWindow.width > wide.width * 0.86
            ? try resizeIPadWindow(app, targetWidth: wide.width * 0.76, name: "medium")
            : firstWindow
        assertRotationDraft(app)
        let narrow = try resizeIPadWindow(app, targetWidth: wide.width * 0.50, name: "narrow")
        assertRotationDraft(app)
        XCTAssertTrue((wide.width * 0.65...wide.width * 0.86).contains(medium.width))
        XCTAssertLessThanOrEqual(narrow.width, wide.width * 0.60)
        XCTAssertGreaterThanOrEqual(medium.width - narrow.width, 48)

        tap(app.buttons["recap.saveToolbar"], in: app)
        selectTab("Timeline", "时间线", language: "en", app: app)
        tap(app.buttons.matching(identifier: "moment.row").firstMatch, in: app)
        let detailWide = try resizeIPadWindow(app, targetWidth: wide.width, name: "detail-wide")
        XCTAssertGreaterThanOrEqual(detailWide.width, wide.width * 0.85)
        XCTAssertEqual(app.staticTexts["detail.note"].label, rotationNote)
        returnFromRotatingDetail(app)
        XCTAssertEqual(app.staticTexts["timeline.resultCount"].label, "1 moment")

        selectTab("Today", "今天", language: "en", app: app)
        tap(app.buttons["today.startMoment"], in: app)
        let pause = app.buttons["session.pauseResume"]
        tap(pause, in: app)
        XCTAssertEqual(pause.label, "Resume")
        let duration = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Session duration ")
        ).firstMatch
        XCTAssertTrue(duration.exists)
        let pausedDuration = duration.label
        let pausedNarrow = try resizeIPadWindow(app, targetWidth: narrow.width, name: "paused-narrow")
        XCTAssertLessThanOrEqual(pausedNarrow.width, wide.width * 0.60)
        XCTAssertEqual(duration.label, pausedDuration)
        XCTAssertEqual(pause.label, "Resume")
        reveal(pause, in: app)
        XCTAssertTrue(pause.isHittable)
    }

    func testIPadWindowResizeWithKeyboard() throws {
        guard enableIPadWindowedApps(scrollSidebar: true) else { return }
        let app = makeApp()
        app.launch()
        let window = app.windows.firstMatch
        waitForStableFrame(window, message: "The real app window must settle before resizing.")
        let wide = window.frame
        XCTAssertGreaterThanOrEqual(wide.width, 700)
        tap(app.buttons["today.addRecord"], in: app)
        XCTAssertTrue(app.buttons["recap.date.open"].exists, "The form must use its accessibility text layout.")

        let start = try resizeIPadWindow(app, targetWidth: wide.width * 0.61, name: "keyboard-entry",
                                         targetHeight: wide.height * 0.66)
        XCTAssertLessThanOrEqual(start.width, wide.width * 0.68)
        let note = app.textViews["recap.note"]
        tap(note, in: app)
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10) && keyboard.isHittable)
        note.typeText(rotationNote)
        XCTAssertEqual(note.value as? String, rotationNote)
        XCTAssertTrue(keyboard.isHittable)
        captureSystem("Window-keyboard-before-drag", app)

        let narrowed = try resizeIPadWindow(app, targetWidth: wide.width * 0.49, name: "keyboard-narrow",
                                            keyboard: keyboard)
        XCTAssertLessThanOrEqual(narrowed.width, wide.width * 0.58)
        XCTAssertEqual(note.value as? String, rotationNote)
        if !keyboard.isHittable {
            print("The system dismissed the software keyboard during the window drag.")
            tap(note, in: app)
        }
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10) && keyboard.isHittable)
        XCTAssertEqual(note.value as? String, rotationNote)
        let save = app.buttons["recap.saveToolbar"]
        XCTAssertTrue(save.isEnabled && save.isHittable && window.frame.contains(save.frame))
        XCTAssertFalse(save.frame.intersects(keyboard.frame), "The keyboard must leave Save unobstructed.")
        assertToolbarTarget(save)
        captureSystem("Window-keyboard-save-reachable", app)
        save.tap()

        selectTab("Timeline", "时间线", language: "en", app: app)
        XCTAssertEqual(app.staticTexts["timeline.resultCount"].label, "1 moment")
        tap(app.buttons.matching(identifier: "moment.row").firstMatch, in: app)
        let savedNote = app.staticTexts["detail.note"]
        reveal(savedNote, in: app)
        XCTAssertEqual(savedNote.label, rotationNote)
        captureSystem("Window-keyboard-saved-note", app)
    }

    private func enableIPadWindowedApps(scrollSidebar: Bool = false) -> Bool {
        XCTAssertEqual(UIDevice.current.userInterfaceIdiom, .pad)
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()
        let multitasking = settings.staticTexts["Multitasking & Gestures"].firstMatch
        if scrollSidebar {
            let sidebar = settings.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.16, dy: 0.69))
            for _ in 0..<6 where !multitasking.isHittable {
                sidebar.press(forDuration: 0.05, thenDragTo: sidebar.withOffset(CGVector(dx: 0, dy: -242)),
                              withVelocity: .slow, thenHoldForDuration: 0.15)
            }
        }
        if !multitasking.isHittable {
            let sidebar = settings.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.16, dy: 0.33))
            sidebar.press(forDuration: 0.05, thenDragTo: sidebar.withOffset(CGVector(dx: 0, dy: 260)))
            let search = settings.searchFields.firstMatch
            guard search.waitForExistence(timeout: 8), search.isHittable else {
                captureFailure("Window-resize-settings-unavailable", settings)
                XCTFail("Could not reach system Settings search for Multitasking & Gestures.")
                return false
            }
            search.tap()
            search.typeText("Multitasking")
        }
        guard multitasking.waitForExistence(timeout: 8), multitasking.isHittable else {
            captureFailure("Window-resize-multitasking-unavailable", settings)
            XCTFail("System multitasking settings are unavailable.")
            return false
        }
        multitasking.tap()
        let windowed = settings.staticTexts["Windowed Apps"].firstMatch
        guard windowed.waitForExistence(timeout: 8), windowed.isHittable else {
            captureFailure("Windowed-apps-unavailable", settings)
            XCTFail("Could not turn on the public system Windowed Apps mode.")
            return false
        }
        windowed.tap()
        return true
    }

    private func resizeIPadWindow(_ app: XCUIApplication, targetWidth: CGFloat, name: String,
                                  targetHeight: CGFloat? = nil, keyboard: XCUIElement? = nil) throws -> CGRect {
        let window = app.windows.firstMatch
        let before = window.frame
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let handle = springboard.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Resize Private Moments")
        ).firstMatch
        let source: XCUICoordinate
        if let keyboard, keyboard.isHittable,
           !handle.exists || !handle.isHittable || handle.frame.intersects(keyboard.frame) {
            // iPadOS also supports resizing from the top-right corner when
            // the software keyboard covers the usual bottom-right handle.
            source = window.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0))
                .withOffset(CGVector(dx: -3, dy: 3))
            print("Resizing \(name) from the uncovered top-right corner.")
        } else {
            guard handle.waitForExistence(timeout: 8), handle.isHittable else {
                captureFailure("Window-resize-handle-unavailable-\(name)", springboard)
                throw NSError(domain: "PrivateMoments.WindowVerification", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "System window handle could not receive a drag."])
            }
            source = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        }
        let delta = targetWidth - before.width
        let verticalDelta = (targetHeight ?? before.height) - before.height
        // In this simulator's Windowed Apps mode the window resizes about its
        // center: the right edge moves the drag distance, and the left mirrors it.
        source.press(forDuration: 0.10, thenDragTo: source.withOffset(CGVector(dx: delta / 2, dy: verticalDelta / 2)),
                     withVelocity: .slow, thenHoldForDuration: 0.10)
        let resized = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            window.exists && (window.frame.width - before.width) * (delta > 0 ? 1 : -1) >= 48
        }, object: nil)
        guard XCTWaiter.wait(for: [resized], timeout: 10) == .completed else {
            captureFailure("Window-resize-no-geometry-change-\(name)", app)
            throw NSError(domain: "PrivateMoments.WindowVerification", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Window width did not change from \(before) toward \(targetWidth)."])
        }
        waitForStableFrame(window, message: "The resized system window must settle.")
        print("System window resize \(name): \(before) → \(window.frame).")
        captureSystem("Window-resize-\(name)", app)
        return window.frame
    }

    private func createRotatingDraft(language: String, app: XCUIApplication) {
        tap(app.buttons["today.addRecord"], in: app)
        replaceNumber(app.textFields["recap.minutes"], with: "3", in: app)
        dismissRecapKeyboard(language: language, app: app)
        replaceNumber(app.textFields["recap.seconds"], with: "8", in: app)
        dismissRecapKeyboard(language: language, app: app)
        let note = app.textViews["recap.note"]
        tap(note, in: app)
        note.typeText(rotationNote)
        dismissRecapKeyboard(language: language, app: app)
        rotateInterface(.landscapeLeft, stage: "draft", language: language, app: app)
        assertRotationDraft(app)
        revealFully(from: note, through: note, in: app)
        capture("Rotation-draft-landscape-\(language)", app)
        tap(app.buttons["recap.cancel"], in: app)
        let keep = language == "en" ? "Edit" : "继续编辑"
        let discard = language == "en" ? "Discard" : "放弃"
        captureVisibleConfirmation("Rotation-discard-confirm-\(language)", keep: keep, discard: discard, app: app)
        cancelConfirmation(keep, destructiveAction: discard, in: app)
        rotateInterface(.portrait, stage: "retained-draft", language: language, app: app)
        assertRotationDraft(app)
        revealFully(from: note, through: note, in: app)
        capture("Rotation-draft-portrait-\(language)", app)
        tap(app.buttons["recap.saveToolbar"], in: app)
        XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
    }

    private func assertRotationDraft(_ app: XCUIApplication) {
        XCTAssertEqual(app.textFields["recap.minutes"].value as? String, "3")
        XCTAssertEqual(app.textFields["recap.seconds"].value as? String, "8")
        XCTAssertEqual(app.textViews["recap.note"].value as? String, rotationNote)
        let save = app.buttons["recap.saveToolbar"]
        XCTAssertTrue(save.isEnabled && save.isHittable)
        print("Draft save target: \(save.frame.size) in window \(app.windows.firstMatch.frame.size).")
        assertToolbarTarget(save)
    }

    private func inspectRotatingNavigation(language: String, app: XCUIApplication) {
        rotateInterface(.landscapeLeft, stage: "today", language: language, app: app)
        for action in [app.buttons["today.startMoment"], app.buttons["today.addRecord"]] {
            XCTAssertTrue(action.isHittable && app.windows.firstMatch.frame.contains(action.frame))
        }
        capture("Rotation-today-landscape-\(language)", app)
        selectTab("Timeline", "时间线", language: language, app: app)
        let row = app.buttons.matching(identifier: "moment.row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["timeline.resultCount"].label, language == "en" ? "1 moment" : "1 条记录")
        capture("Rotation-timeline-landscape-\(language)", app)
        tap(row, in: app)
        rotateInterface(.landscapeRight, stage: "detail", language: language, app: app)
        revealFully(from: app.staticTexts["detail.note"], through: app.staticTexts["detail.note"], in: app)
        XCTAssertEqual(app.staticTexts["detail.note"].label, rotationNote)
        capture("Rotation-detail-landscape-\(language)", app)
        tap(app.buttons["detail.editToolbar"], in: app)
        assertRotationDraft(app)
        tap(app.buttons["recap.cancel"], in: app)
        XCTAssertTrue(app.buttons["detail.editToolbar"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts.firstMatch.exists, "Unchanged editing should return directly to the same detail.")
        rotateInterface(.portrait, stage: "detail-return", language: language, app: app)
        revealFully(from: app.staticTexts["detail.note"], through: app.staticTexts["detail.note"], in: app)
        XCTAssertEqual(app.staticTexts["detail.note"].label, rotationNote)
        capture("Rotation-detail-portrait-\(language)", app)
        returnFromRotatingDetail(app)
        selectTab("Settings", "设置", language: language, app: app)
        rotateInterface(.landscapeLeft, stage: "settings", language: language, app: app)
        revealFully(from: app.staticTexts["settings.savedCountTitle"], through: app.staticTexts["settings.savedCount"], in: app)
        XCTAssertEqual(app.staticTexts["settings.savedCount"].label, "1")
        capture("Rotation-settings-landscape-\(language)", app)
        selectTab("Today", "今天", language: language, app: app)
    }

    private func returnFromRotatingDetail(_ app: XCUIApplication) {
        // The first navigation button may belong to a transitioning stack.
        // Resolve the native back control and prove the destination after one tap.
        let back = app.navigationBars.buttons.matching(identifier: "BackButton").firstMatch
        guard back.waitForExistence(timeout: 10) else {
            captureFailure("Rotation-back-unavailable", app)
            return XCTFail("The rotated detail must expose its native Back control.")
        }
        waitForStableFrame(back, requireHittable: true, message: "Rotated Back control must settle.")
        print("Rotated native Back before tap: \(back.debugDescription)")
        back.tap()
        let returned = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.staticTexts["timeline.resultCount"].exists &&
                !app.buttons["detail.editToolbar"].exists
        }, object: nil)
        guard XCTWaiter.wait(for: [returned], timeout: 15) == .completed else {
            captureFailure("Rotation-back-destination-unavailable", app)
            return XCTFail("One native Back tap must return to Timeline after rotation.")
        }
    }

    private func inspectRotatingPausedTimer(language: String, app: XCUIApplication) {
        tap(app.buttons["today.startMoment"], in: app)
        let pause = app.buttons["session.pauseResume"]
        tap(pause, in: app)
        XCTAssertEqual(pause.label, language == "en" ? "Resume" : "继续")
        rotateInterface(.portrait, stage: "paused-timer", language: language, app: app)
        XCTAssertEqual(pause.label, language == "en" ? "Resume" : "继续")
        reveal(app.buttons["session.finish"], in: app)
        capture("Rotation-timer-portrait-\(language)", app)
        tap(app.buttons["session.cancel"], in: app)
        tap(app.buttons[language == "en" ? "Discard" : "放弃"], in: app)
        XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
    }

    private func assertRotationRecordAfterRelaunch(language: String, app: XCUIApplication) {
        app.terminate()
        app.launch()
        rotateInterface(.portrait, stage: "relaunch", language: language, app: app)
        selectTab("Timeline", "时间线", language: language, app: app)
        let row = app.buttons.matching(identifier: "moment.row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["timeline.resultCount"].label, language == "en" ? "1 moment" : "1 条记录")
        tap(row, in: app)
        revealFully(from: app.staticTexts["detail.note"], through: app.staticTexts["detail.note"], in: app)
        XCTAssertEqual(app.staticTexts["detail.note"].label, rotationNote)
        capture("Rotation-relaunched-portrait-\(language)", app)
        tap(app.buttons["detail.editToolbar"], in: app)
        assertRotationDraft(app)
    }

    private func rotateInterface(_ orientation: UIDeviceOrientation, stage: String, language: String, app: XCUIApplication) {
        XCUIDevice.shared.orientation = orientation
        let window = app.windows.firstMatch
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard window.exists else { return false }
            let frame = window.frame
            return frame.width > 0 && frame.height > 0 &&
                (orientation.isLandscape ? frame.width > frame.height : frame.height > frame.width)
        }, object: nil)
        guard XCTWaiter.wait(for: [changed], timeout: 20) == .completed else {
            print("Rotation failure state. Locale: \(language); stage: \(stage); requested: \(orientation.rawValue); observed device: \(XCUIDevice.shared.orientation.rawValue); app state: \(app.state.rawValue); window: \(window.frame).")
            captureFailure("Rotation-interface-unavailable-\(stage)-\(language)", app)
            captureFailure("Rotation-system-after-unavailable-\(stage)-\(language)", XCUIApplication(bundleIdentifier: "com.apple.springboard"))
            return XCTFail("The actual app interface must rotate, not only the device orientation value.")
        }
        waitForStableFrame(window, message: "The rotated application window must settle.")
        print("Verified rotated app geometry. Locale: \(language); stage: \(stage); device: \(orientation.rawValue); frame: \(window.frame).")
    }

    func testBackupFileRoundTrip() throws {
        runBackupFileRoundTrip(language: "en")
    }

    func testChineseBackupFileRoundTrip() throws {
        runBackupFileRoundTrip(language: "zh-Hans")
    }

    private func runBackupFileRoundTrip(language: String) {
        let english = language == "en"
        let app = makeApp(language: language)
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
        selectTab("Settings", "设置", language: language, app: app)
        tap(app.buttons["settings.export"], in: app)
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        assertExportWarning(app.alerts.firstMatch, language: language, app: app)
        tap(app.alerts.firstMatch.buttons[english ? "Export" : "导出"], in: app)
        // The fresh hosted Simulator can take over 45 seconds to launch the
        // DocumentManager extension. Wait for actual controls, not a fixed nap
        // or a blank sheet that merely finished its presentation animation.
        let browserDeadline = Date().addingTimeInterval(90)
        let browserReady = waitForLocalExportBrowser(app, timeout: max(0, browserDeadline.timeIntervalSinceNow))
        guard browserReady else {
            captureFailure("Exporter-browser-unavailable-\(language)", app)
            return XCTFail("The system exporter must show the local browser or a real location control.")
        }
        // Each locale exports one distinct default filename on the fresh host.
        // iOS may hide Save As on first presentation; use the real default name.
        let filename = english ? "Private-Moments-Backup" : "私密时刻-备份"
        saveToLocalFiles(app, language: language, browserDeadline: browserDeadline)
        let saved = app.staticTexts[english ? "Backup saved." : "备份已保存。"]
        XCTAssertTrue(saved.waitForExistence(timeout: 15), "Only the real exporter completion may report success.")
        assertBackupResultVisible(saved, in: app)
        capture("Backup-exported-\(language)", app)
        let dismissFeedback = app.buttons["settings.dismissBackupStatus"]
        XCTAssertEqual(dismissFeedback.label, english ? "Dismiss message" : "关闭提示")
        assertToolbarTarget(dismissFeedback)
        waitForStableFrame(dismissFeedback, requireHittable: true,
            message: "Backup feedback dismissal must settle before one tap.")
        dismissFeedback.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !app.staticTexts["settings.backupStatus"].exists
        }, object: nil)
        guard XCTWaiter.wait(for: [dismissed], timeout: 15) == .completed else {
            captureFailure("Backup-dismiss-unavailable-\(language)", app)
            return XCTFail("One feedback dismissal must remove the status without changing journal records.")
        }
        XCTAssertEqual(app.staticTexts["settings.savedCount"].label, "1")

        tap(app.buttons["settings.restore"], in: app)
        let cancel = nativeControl(["Cancel", "取消"], app: app, timeout: 10)
        let outside = pickerDismissalPoint(in: app, requireBlank: false)
        captureSystem("Import-files-\(language)", app)
        if let outside {
            // Exercise the real adaptive presentation's escape path on iPad.
            print("Explicit native picker backdrop cancellation; journal checked unchanged afterward.")
            outside.tap()
        } else if let cancel {
            cancel.tap()
        } else {
            return XCTFail("The system picker has no native cancel action or safe outside dismissal.")
        }
        assertImportCancelled(language: language, in: app)
        capture("Import-cancelled-\(language)", app)
        assertBackupFeedbackScrollsAway(language: language, app: app)
        // Keep this notice open to verify that Delete all clears it. The
        // Settings gallery separately checks the visible count's geometry.
        XCTAssertEqual(app.staticTexts["settings.savedCount"].label, "1")
        let delete = app.buttons["settings.deleteAll"]
        revealFully(from: delete, through: delete, in: app)
        XCTAssertGreaterThanOrEqual(delete.frame.height, 44, "Delete needs a full-height touch target.")
        // Tap within the padded row, above the label. Only the confirmation
        // should open; the separate confirmation below still performs deletion.
        delete.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            .withOffset(CGVector(dx: 0, dy: 8)).tap()
        let confirmDelete = app.buttons[english ? "Delete all moments" : "删除所有记录"]
        guard confirmDelete.waitForExistence(timeout: 10), confirmDelete.isHittable else {
            captureFailure("Delete-confirmation-unavailable", app)
            return XCTFail("The actual deletion confirmation must appear before confirming.")
        }
        confirmDelete.tap()
        assertDeletedJournal(language: language, in: app)
        assertSavedCount("0", app: app)

        openBackup(filename, language: language, app: app)
        XCTAssertTrue(app.navigationBars[english ? "Review backup" : "确认备份内容"].exists)
        XCTAssertEqual(app.buttons["backup.merge"].label, english ? "Merge backup" : "合并备份")
        capture("Backup-review-\(language)", app)
        assertMetric("backup.newCount", value: "1", app: app)
        assertMetric("backup.updatedCount", value: "0", app: app)
        assertMetric("backup.noteCount", value: "1", app: app)
        revealFully(from: app.buttons["backup.replace"], through: app.buttons["backup.replace"], in: app)
        capture("Backup-review-controls-\(language)", app)
        XCTAssertTrue(app.buttons["backup.merge"].isHittable)
        tap(app.buttons["backup.cancel"], in: app)
        assertSavedCount("0", app: app)
        openBackup(filename, language: language, app: app)
        tap(app.buttons["backup.merge"], in: app)
        assertSavedCount("1", app: app)

        selectTab("Today", "今天", language: language, app: app)
        tap(app.buttons["today.addRecord"], in: app)
        tap(app.buttons["recap.saveToolbar"], in: app)
        selectTab("Settings", "设置", language: language, app: app)
        assertSavedCount("2", app: app)
        openBackup(filename, language: language, app: app)
        assertMetric("backup.updatedCount", value: "1", app: app)
        assertMetric("backup.otherCount", value: "1", app: app)
        capture("Replace-review-\(language)", app)
        tap(app.buttons["backup.replace"], in: app)
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        capture("Backup-replace-\(language)", app)
        tap(app.alerts.firstMatch.buttons[english ? "Cancel" : "取消"], in: app)
        tap(app.buttons["backup.cancel"], in: app)
        assertSavedCount("2", app: app)
        openBackup(filename, language: language, app: app)
        tap(app.buttons["backup.replace"], in: app)
        tap(app.alerts.firstMatch.buttons[english ? "Replace" : "替换"], in: app)
        let restored = app.staticTexts[english ? "Local journal replaced from backup." : "已从备份替换本地记录。"]
        XCTAssertTrue(restored.waitForExistence(timeout: 15))
        assertBackupResultVisible(restored, in: app)
        capture("Backup-restored-\(language)", app)
        assertSavedCount("1", app: app)
        app.terminate()
        app.launch()
        selectTab("Timeline", "时间线", language: language, app: app)
        tap(app.buttons.matching(identifier: "moment.row").firstMatch, in: app)
        reveal(app.staticTexts["detail.note"], in: app)
        XCTAssertEqual(app.staticTexts["detail.note"].label, "Synthetic backup note")
        tap(app.buttons["detail.editToolbar"], in: app)
        XCTAssertEqual(app.textFields["recap.minutes"].value as? String, "4")
        XCTAssertEqual(app.textFields["recap.seconds"].value as? String, "7")
        print("Verified real backup file roundtrip and relaunch. Locale: \(language); filename: \(filename); explicit recoveries: \(importRecoveryCount).")
    }

    private func assertDeletedJournal(language: String = "en", in app: XCUIApplication) {
        // Observe the real operation's published outcome before a helper is
        // allowed to dismiss any feedback. No further UI action is performed.
        let published = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.staticTexts[language == "en" ? "Local entries deleted." : "本地记录已删除。"].exists
                && app.staticTexts["settings.savedCount"].label == "0"
                && !app.staticTexts[language == "en" ? "Import cancelled. Records unchanged." : "已取消导入，记录未改动。"].exists
        }, object: nil)
        let result = XCTWaiter.wait(for: [published], timeout: 15)
        if result != .completed { captureFailure("Delete-all-outcome-unavailable", app) }
        XCTAssertEqual(result, .completed,
            "Deletion must publish success, zero records and clear the previous cancellation notice.")
    }

    private func assertSavedCount(_ value: String, app: XCUIApplication) {
        let dismiss = app.buttons["settings.dismissBackupStatus"]
        if dismiss.exists {
            // Read the captured result, then explicitly close it before
            // inspecting the journal. This is a user action, not a store reset.
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                dismiss.exists && dismiss.isHittable
            }, object: nil)
            guard XCTWaiter.wait(for: [ready], timeout: 15) == .completed else {
                captureFailure("Backup-feedback-dismiss-unavailable", app)
                return XCTFail("Backup feedback did not become actionable after review dismissal.")
            }
            dismiss.tap()
            let closed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                !app.staticTexts["settings.backupStatus"].exists
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 5), .completed)
        }
        let count = app.staticTexts["settings.savedCount"]
        reveal(count, in: app)
        XCTAssertEqual(count.label, value)
    }

    private func assertImportCancelled(language: String = "en", in app: XCUIApplication) {
        let notice = app.staticTexts[language == "en" ? "Import cancelled. Records unchanged." : "已取消导入，记录未改动。"]
        let exists = notice.waitForExistence(timeout: 15)
        if !exists { captureFailure("Import-cancelled-unavailable-\(language)", app) }
        XCTAssertTrue(exists)
        assertBackupResultVisible(notice, in: app)
    }

    private func assertBackupFeedbackScrollsAway(language: String, app: XCUIApplication) {
        let scroll = app.scrollViews["settings.scroll"]
        let notice = app.staticTexts["settings.backupStatus"]
        XCTAssertTrue(scroll.exists)
        XCTAssertTrue(scroll.descendants(matching: .staticText).matching(identifier: "settings.backupStatus").firstMatch.exists,
            "The complete result must belong to scroll content, not a fixed block outside it.")
        let viewport = scroll.frame.intersection(app.windows.firstMatch.frame)
        XCTAssertGreaterThan(viewport.height, app.windows.firstMatch.frame.height * 0.65,
            "A long result must not reserve almost half the screen above the scroll viewport.")
        if backupActionsFitWithFeedback(language: language, app: app) { return }
        var drags = 0
        while drags < 3 && notice.frame.maxY > viewport.minY {
            scroll.swipeUp()
            drags += 1
        }
        XCTAssertLessThanOrEqual(notice.frame.maxY, viewport.minY,
            "Normal scrolling must move the retained result out of the content viewport.")
        XCTAssertTrue(notice.exists, "Scrolling must not dismiss or truncate the feedback.")
        XCTAssertEqual(app.staticTexts["settings.savedCount"].label, "1")
        capture("Import-feedback-scrolled-\(language)", app)
        print("Verified scrollable backup feedback. Locale: \(language); viewport: \(viewport); drags: \(drags); notice: \(notice.frame).")
    }

    private func backupActionsFitWithFeedback(language: String, app: XCUIApplication) -> Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
        let window = app.windows.firstMatch.frame
        let navigation = app.navigationBars.firstMatch
        let tab = app.tabBars.firstMatch
        let top = navigation.exists ? navigation.frame.maxY : window.minY
        let bottom = tab.exists && tab.frame.midY > window.midY ? tab.frame.minY : window.maxY
        let bounds = CGRect(x: window.minX, y: top, width: window.width, height: bottom - top)
        let actions = [app.buttons["settings.export"], app.buttons["settings.restore"], app.buttons["settings.deleteAll"]]
        let frames = actions.map(\.frame)
        guard zip(actions, frames).allSatisfy({ action, frame in
            action.exists && action.isHittable && !frame.isEmpty && bounds.contains(frame)
        }) else { return false }
        let notice = app.staticTexts["settings.backupStatus"]
        XCTAssertTrue(bounds.contains(notice.frame), "The complete retained message must also fit.")
        XCTAssertTrue(frames.allSatisfy { $0.minY >= notice.frame.maxY },
            "All backup and deletion actions must remain below the complete message.")
        XCTAssertEqual(app.staticTexts["settings.savedCount"].label, "1")
        capture("Import-feedback-all-actions-\(language)", app)
        print("Verified backup actions fit with retained feedback. Locale: \(language); viewport: \(bounds); export: \(frames[0]); restore: \(frames[1]); delete: \(frames[2]); notice: \(notice.frame).")
        return true
    }

    private func assertAboveBottomTabBar(_ element: XCUIElement, message: String, app: XCUIApplication,
                                         file: StaticString = #filePath, line: UInt = #line) {
        let window = app.windows.firstMatch.frame
        let tabBar = app.tabBars.firstMatch
        let bottom = tabBar.exists && tabBar.frame.midY > window.midY ? tabBar.frame.minY : window.maxY
        let frame = element.frame
        XCTAssertTrue(element.exists && !frame.isEmpty && window.contains(frame) && frame.maxY <= bottom,
                      "\(message) Element: \(frame); unobstructed bottom: \(bottom).", file: file, line: line)
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
        // Callers already wait up to 15 seconds for the actual result message.
        // Read geometry once, not inside a timed predicate: synchronous remote
        // attribute reads can exhaust its clock even when every condition is true.
        // Their duration is not a measurement of the app's response time.
        let window = app.windows.containing(.staticText, identifier: "settings.backupStatus").firstMatch
        guard window.exists else {
            captureFailure("Backup-result-unavailable", app)
            return XCTFail("No application window contains the feedback.")
        }
        let viewport = window.frame
        let frame = window.staticTexts["settings.backupStatus"].frame
        // Native navigation/tab surfaces can be separate from the content window.
        let navigation = app.navigationBars.firstMatch
        let navigationFrame = navigation.exists ? navigation.frame : nil
        let tabBar = app.tabBars.firstMatch
        let tabFrame = tabBar.exists ? tabBar.frame : nil
        let top = navigationFrame?.maxY ?? viewport.minY
        let bottom = tabFrame.map { $0.midY > viewport.midY ? $0.minY : viewport.maxY }
            ?? viewport.maxY
        let validFrames = !frame.isEmpty && !frame.isInfinite && !frame.isNull
            && !viewport.isEmpty && !viewport.isInfinite && !viewport.isNull
        let fullyVisible = validFrames && frame.minY >= top && frame.maxY <= bottom
            && frame.minX >= viewport.minX && frame.maxX <= viewport.maxX
        let unobscured = result.exists && app.state == .runningForeground
            && !app.alerts.firstMatch.exists && !app.sheets.firstMatch.exists
            && !app.collectionViews["File View"].exists
        if !fullyVisible || !unobscured {
            print("Backup feedback visibility: frame=\(frame), viewport=\(viewport), top=\(top), bottom=\(bottom), unobscured=\(unobscured).")
            captureFailure("Backup-result-unavailable", app)
        }
        XCTAssertTrue(fullyVisible && unobscured,
            "Backup completion feedback must be fully visible without a test scroll.")
    }

    private func assertMetric(_ identifier: String, value: String, app: XCUIApplication) {
        let metric = app.staticTexts[identifier]
        reveal(metric, in: app)
        XCTAssertEqual(metric.label, value)
    }

    private func nativeControl(_ labels: [String], app: XCUIApplication, timeout: TimeInterval = 2,
        surface: XCUIElement? = nil, enabledAction: Bool = false) -> XCUIElement? {
        let scope: XCUIElement = surface ?? app
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for label in labels {
                let predicate = NSPredicate(format: "label == %@", label)
                let items = scope.buttons.matching(predicate).allElementsBoundByIndex
                    + (enabledAction ? [] : scope.staticTexts.matching(predicate).allElementsBoundByIndex)
                for item in items {
                    if item.exists && item.isHittable && (!enabledAction || item.isEnabled) { return item }
                }
            }
        } while Date() < deadline
        return nil
    }

    private func waitForLocalExportBrowser(_ app: XCUIApplication, timeout: TimeInterval) -> Bool {
        // Let XCTest schedule accessibility polling while the system File
        // Provider starts. A title can report readiness without being a button.
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.localFileRoots(in: app).firstMatch.exists || !self.nativeLocalLocations(in: app).isEmpty
        }, object: nil)
        return XCTWaiter.wait(for: [ready], timeout: timeout) == .completed
    }

    private func saveToLocalFiles(_ app: XCUIApplication, language: String, browserDeadline: Date) {
        // A visible location title is not a sidebar action: tapping it can open
        // Browse and turn its unrelated More menu into Edit. Stay in a ready
        // local browser, or navigate using the actual location cell/button.
        guard enterLocalExportBrowser(app, timeout: max(0, browserDeadline.timeIntervalSinceNow)) else {
            captureSystem("Exporter-unavailable", app)
            return XCTFail("The native local destination is not available.")
        }
        let root = localFileRoots(in: app).firstMatch
        // Sidebar appearance does not establish completed provider navigation.
        // Share the original 90-second browser budget across both phases;
        // never reset that budget after tapping the native location once.
        let remaining = max(0, browserDeadline.timeIntervalSinceNow)
        print("Waiting for actual local export root within remaining browser budget: \(remaining) seconds.")
        guard root.waitForExistence(timeout: remaining) else {
            captureSystem("Exporter-unavailable", app)
            return XCTFail("The local file browser did not finish navigating.")
        }
        let labels = ["Save", "Export", "Move", "存储", "保存", "导出", "移动"]
        if let action = nativeControl(labels, app: app, timeout: 15, surface: root, enabledAction: true) {
            captureReadyExporter(action: action, language: language, app: app)
            action.tap()
            return
        }
        if let more = nativeControl(["More", "更多"], app: app, timeout: 5, surface: root, enabledAction: true) { more.tap() }
        guard let folder = nativeControl(["New Folder", "新建文件夹"], app: app, timeout: 5, enabledAction: true) else {
            captureSystem("Exporter-unavailable", app)
            return XCTFail("No writable local folder or New Folder action in system exporter.")
        }
        folder.tap()
        let name = app.alerts.firstMatch.exists ? app.alerts.firstMatch.textFields.firstMatch : app.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        replaceNumber(name, with: "PM Tests", in: app)
        guard let create = nativeControl(["Create", "Done", "创建", "完成"], app: app, timeout: 5, enabledAction: true) else { return XCTFail("Missing native folder creation action") }
        create.tap()
        guard let save = nativeControl(labels, app: app, timeout: 15,
            surface: localFileRoots(in: app).firstMatch, enabledAction: true) else { return XCTFail("No enabled system save action") }
        captureReadyExporter(action: save, language: language, app: app)
        save.tap()
    }

    private func enterLocalExportBrowser(_ app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let root = localFileRoots(in: app).firstMatch
        let window = app.windows.firstMatch
        var previousLocationFrame: CGRect?
        repeat {
            if root.exists { return true }
            guard let location = nativeLocalLocations(in: app).first(where: {
                $0.exists && $0.isHittable && $0.isEnabled
            }) else {
                previousLocationFrame = nil
                continue
            }
            let frame = location.frame
            let bounds = window.frame
            // Files can navigate to the local root while this temporary
            // sidebar row is being resolved. Confirm it has settled and let a
            // ready provider win before tapping a live screen coordinate.
            if root.exists { return true }
            if frame == previousLocationFrame, !frame.isEmpty, bounds.contains(frame) {
                window.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: frame.midX - bounds.minX, dy: frame.midY - bounds.minY)).tap()
                return true
            }
            previousLocationFrame = frame
        } while Date() < deadline
        return root.exists
    }

    private func captureReadyExporter(action: XCUIElement, language: String, app: XCUIApplication) {
        waitForStableFrame(action, requireHittable: true, message: "The real system save action must settle before capture.")
        XCTAssertTrue(action.isEnabled && action.isHittable)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(action.frame), "The complete system save action must be on screen.")
        captureSystem("Export-files-\(language)", app)
        print("Verified ready native export action. Locale: \(language); label: \(action.label); frame: \(action.frame).")
    }

    private func openBackup(_ filename: String, language: String = "en", app: XCUIApplication) {
        let originalCount = app.staticTexts["settings.savedCount"].label
        tap(app.buttons["settings.restore"], in: app)
        for attempt in 0..<2 {
            let selection = selectBackupFile(filename, app: app)
            if app.buttons["backup.merge"].exists { return }
            switch selection {
            case .failed: return
            case .pendingDelivery, .unavailablePicker:
                // An actual selection can remain undelivered, or the native
                // browser can fail to load. Both share one explicit escape and
                // reopen budget; never infer a read or retry the whole test.
                guard attempt == 0 else {
                    captureSystem("Import-selection-unresolved", app)
                    return XCTFail("The system picker has no bounded recovery left.")
                }
                let cancel: () -> Void
                let reason: String
                if case .unavailablePicker(let outside) = selection {
                    cancel = { outside.tap() }
                    reason = "picker-unavailable"
                } else {
                    guard app.collectionViews["File View"].exists,
                          let button = nativeControl(["Cancel", "取消"], app: app) else {
                        captureSystem("Import-selection-unresolved", app)
                        return XCTFail("A pending system selection has no native cancel action.")
                    }
                    cancel = { button.tap() }
                    reason = "picker-not-delivered"
                }
                importRecoveryCount += 1
                captureSystem("Import-recovery-\(importRecoveryCount)-\(language)", app)
                cancel()
                assertImportCancelled(language: language, in: app)
                XCTAssertEqual(app.staticTexts["settings.savedCount"].label, originalCount)
                print("Explicit system backup reselection \(importRecoveryCount); local record count unchanged. Reason: \(reason).")
                tap(app.buttons["settings.restore"], in: app)
                continue
            case .delivered: break
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
            captureSystem("Import-recovery-\(importRecoveryCount)-\(language)", app)
            tap(chooseAgain, in: app)
        }
        XCTFail("Backup review did not open after the explicit recovery action.")
    }

    private func localFileRoots(in app: XCUIApplication) -> XCUIElementQuery {
        app.otherElements.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "DOC.browsingRoot Source: com.apple.FileProvider.LocalStorage,"
        ))
    }

    private func selectBackupFile(_ filename: String, app: XCUIApplication) -> BackupSelectionResult {
        // The native Files service is a separate process. Wait for its actual
        // browser, as the exporter already does, before looking for a filename.
        guard app.collectionViews["File View"].waitForExistence(timeout: 90) else {
            if let outside = pickerDismissalPoint(in: app, requireBlank: true) {
                return .unavailablePicker(outside)
            }
            captureSystem("Import-file-unavailable", app)
            XCTFail("The native browser is unavailable and has no safe blank-panel dismissal.")
            return .failed
        }
        let predicate = NSPredicate(format: "label CONTAINS[cd] %@", filename)
        func selectedFile() -> XCUIElement? {
            // Browse can reopen its previous local folder directly. Scope the
            // file to the actual local provider, never a Recents staging copy.
            let localRoots = localFileRoots(in: app)
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
            else if let browse = nativeControl(["Browse", "浏览"], app: app, timeout: 3) { browse.tap() }
        }
        let deadline = Date().addingTimeInterval(10)
        while file == nil && Date() < deadline { file = selectedFile() }
        guard let file else {
            captureSystem("Import-file-unavailable", app)
            XCTFail("Exported file is not available in the real document picker.")
            return .failed
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
           let open = nativeControl(["Open", "打开"], app: app) { open.tap() }
        let resolved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.buttons["backup.merge"].exists || app.buttons["settings.chooseBackupAgain"].exists
        }, object: nil)
        return XCTWaiter.wait(for: [resolved], timeout: 30) == .completed ? .delivered : .pendingDelivery
    }

    private func pickerDismissalPoint(in app: XCUIApplication, requireBlank: Bool) -> XCUICoordinate? {
        let window = app.windows.firstMatch
        let viewport = window.frame
        guard !viewport.isEmpty, !viewport.isNull, !viewport.isInfinite else { return nil }
        // Match the actual adaptive presentation backdrop and its sibling panel,
        // not a guessed sheet size or a tap on an underlying journal control.
        for overlay in window.children(matching: .other).allElementsBoundByIndex.reversed() {
            let children = overlay.children(matching: .other)
            let backdrop = children.matching(identifier: "PopoverDismissRegion").firstMatch
            guard backdrop.exists else { continue }
            for panel in children.allElementsBoundByIndex where panel.identifier != "PopoverDismissRegion" {
                let frame = panel.frame
                guard !frame.isEmpty, frame != viewport, viewport.contains(frame) else { continue }
                if requireBlank {
                    guard panel.buttons.count == 0, panel.staticTexts.count == 0,
                          panel.collectionViews.count == 0 else { continue }
                }
                for offset in [CGVector(dx: 0.05, dy: 0.5), CGVector(dx: 0.95, dy: 0.5)] {
                    let point = window.coordinate(withNormalizedOffset: offset)
                    if viewport.contains(point.screenPoint), backdrop.frame.contains(point.screenPoint),
                       !frame.insetBy(dx: -8, dy: -8).contains(point.screenPoint) { return point }
                }
            }
        }
        return nil
    }

    private func nativeLocalLocations(in app: XCUIApplication) -> [XCUIElement] {
        let predicate = NSPredicate(format: "label IN %@", ["On My iPhone", "On My iPad", "我的 iPhone", "我的 iPad"])
        return app.buttons.matching(predicate).allElementsBoundByIndex
            + app.cells.matching(predicate).allElementsBoundByIndex
    }

    private func localFilesLocation(_ app: XCUIApplication, timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for location in nativeLocalLocations(in: app) {
                if location.exists && location.isHittable && location.isEnabled { return location }
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

    func testTerminationPreservesOnlyExplicitlySavedRecords() throws {
        let app = makeApp()
        app.launch()
        let start = app.buttons["today.startMoment"]
        let add = app.buttons["today.addRecord"]
        tap(start, in: app)
        tap(app.buttons["session.finish"], in: app)
        let note = app.textViews["recap.note"]
        tap(note, in: app)
        note.typeText("Explicitly saved synthetic note")
        dismissRecapKeyboard(language: "en", app: app)
        tap(app.buttons["recap.saveToolbar"], in: app)

        tap(add, in: app)
        tap(note, in: app)
        note.typeText("Unsaved synthetic draft")
        XCTAssertEqual(note.value as? String, "Unsaved synthetic draft")
        app.terminate()
        app.launch()
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        XCTAssertFalse(note.exists)
        selectTab("Timeline", "时间线", language: "en", app: app)
        XCTAssertEqual(app.staticTexts["timeline.resultCount"].label, "1 moment")
        tap(app.buttons.matching(identifier: "moment.row").firstMatch, in: app)
        XCTAssertEqual(app.staticTexts["detail.note"].label, "Explicitly saved synthetic note")

        goBack(app)
        selectTab("Today", "今天", language: "en", app: app)
        tap(start, in: app)
        reveal(app.buttons["session.pauseResume"], in: app)
        XCTAssertEqual(app.buttons["session.pauseResume"].label, "Pause")
        app.terminate()
        app.launch()
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["session.pauseResume"].exists)
        selectTab("Timeline", "时间线", language: "en", app: app)
        XCTAssertEqual(app.staticTexts["timeline.resultCount"].label, "1 moment")
    }

    func testSessionAndRecapDiscardConfirmations() throws {
        let app = makeApp()
        app.launch()
        tap(app.buttons["today.startMoment"], in: app)
        tap(app.buttons["session.cancel"], in: app)
        cancelConfirmation("Keep going", destructiveAction: "Discard", in: app)
        XCTAssertTrue(app.buttons["session.finish"].exists)
        XCTAssertEqual(app.buttons["session.pauseResume"].label, "Pause",
            "Keeping a running timer must not silently pause it.")
        tap(app.buttons["session.cancel"], in: app)
        tap(app.buttons["Discard"], in: app)
        XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0)

        tap(app.buttons["today.startMoment"], in: app)
        tap(app.buttons["session.finish"], in: app)
        tap(app.buttons["recap.cancel"], in: app)
        cancelConfirmation("Edit", destructiveAction: "Discard", in: app)
        XCTAssertTrue(app.buttons["recap.save"].exists)
        tap(app.buttons["recap.cancel"], in: app)
        tap(app.buttons["Discard"], in: app)
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
        tap(app.buttons["Discard"], in: app)
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
        let keyboardGone = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !app.keyboards.firstMatch.exists
        }, object: nil)
        let clearResult = XCTWaiter.wait(for: [keyboardGone], timeout: 5)
        if clearResult != .completed { captureFailure("Timeline-clear-keyboard-unavailable", app) }
        XCTAssertEqual(clearResult, .completed)
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

        func selectOption(_ identifier: String, selected: Bool = true) {
            let option = app.buttons[identifier]
            // iOS 17 can report a partially visible option as hittable even
            // when its tap point lands in the bottom system gesture area.
            revealFully(from: option, through: option, in: app)
            option.tap()
            if option.isSelected != selected { captureFailure("Manual-option-not-applied", app) }
            XCTAssertEqual(option.isSelected, selected, "The draft must reflect the chosen option before cancelling.")
        }

        tap(app.buttons["today.addRecord"], in: app)
        tap(app.buttons["recap.cancel"], in: app)
        XCTAssertTrue(app.buttons["today.addRecord"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Discard"].exists)
        XCTAssertEqual(app.buttons.matching(identifier: "moment.row").count, 0)
        tap(app.buttons["today.addRecord"], in: app)
        selectOption("recap.kind.Solo")
        tap(app.buttons["recap.cancel"], in: app)
        cancelConfirmation("Edit", destructiveAction: "Discard", in: app)
        XCTAssertTrue(app.buttons["recap.saveToolbar"].isHittable)
        selectOption("recap.kind.Together")
        tap(app.buttons["recap.cancel"], in: app)
        XCTAssertTrue(app.buttons["today.addRecord"].waitForExistence(timeout: 10), "Reverting all changes should restore a clean draft.")
        tap(app.buttons["today.addRecord"], in: app)
        for (changed, original) in [
            ("recap.mood.Happy", "recap.mood.Calm"),
            ("recap.rating.5", "recap.rating.4"),
            ("recap.tag.Relaxed", "recap.tag.Relaxed")
        ] {
            selectOption(changed)
            tap(app.buttons["recap.cancel"], in: app)
            cancelConfirmation("Edit", destructiveAction: "Discard", in: app)
            XCTAssertTrue(app.buttons[changed].isSelected, "Keeping the draft must preserve the selection.")
            selectOption(original, selected: changed != original)
            tap(app.buttons["recap.cancel"], in: app)
            XCTAssertTrue(app.buttons["today.addRecord"].waitForExistence(timeout: 10))
            tap(app.buttons["today.addRecord"], in: app)
        }
        let shortNote = "Synthetic kept draft"
        tap(app.textViews["recap.note"], in: app)
        app.textViews["recap.note"].typeText(shortNote)
        tap(app.buttons["recap.dismissKeyboard"], in: app)
        tap(app.buttons["recap.cancel"], in: app)
        cancelConfirmation("Edit", destructiveAction: "Discard", in: app)
        XCTAssertEqual(app.textViews["recap.note"].value as? String, shortNote)
        tap(app.buttons["recap.cancel"], in: app)
        tap(app.buttons["Discard"], in: app)
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
        tap(app.buttons["Discard"], in: app)
        tap(app.buttons["detail.editToolbar"], in: app)
        XCTAssertEqual(app.textFields["recap.minutes"].value as? String, "17")
        XCTAssertEqual(app.textFields["recap.seconds"].value as? String, "9")
        tap(app.buttons["recap.cancel"], in: app) // Unchanged edit exits directly.
        XCTAssertTrue(app.buttons["detail.editToolbar"].waitForExistence(timeout: 10))
    }

    private func replaceNumber(_ field: XCUIElement, with value: String, in app: XCUIApplication) {
        reveal(field, in: app)
        waitForStableFrame(field, requireHittable: true, message: "Numeric input must settle before one tap.")
        field.tap()
        let keyboard = app.keyboards.firstMatch
        guard keyboard.waitForExistence(timeout: 10) else {
            captureFailure("Numeric-keyboard-unavailable-\(field.identifier)", app)
            return XCTFail("A single numeric-field tap must present the software keyboard.")
        }
        waitForStableFrame(keyboard, message: "Numeric keyboard must settle before typing.")
        guard let current = field.value as? String else {
            captureFailure("Numeric-value-unavailable-\(field.identifier)", app)
            return XCTFail("Numeric input must expose its current editable value.")
        }
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + value)
        // A remote accessibility value query can itself take several seconds.
        // Inspect its result before the next deadline check; do not lose a
        // matching value because the expectation's timer fired during a query.
        let valueDeadline = Date().addingTimeInterval(15)
        var observed = field.value as? String
        while observed != value && Date() < valueDeadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
            observed = field.value as? String
        }
        guard observed == value else {
            print("Numeric value mismatch: identifier=\(field.identifier), expected=\(value), observed=\(observed ?? "<unavailable>").")
            captureFailure("Numeric-value-mismatch-\(field.identifier)", app)
            return XCTFail("Numeric typing must publish the exact requested value.")
        }
    }

    private func checkManualNoteDraft(language: String, expanded: Bool, app: XCUIApplication) {
        tap(app.buttons["today.addRecord"], in: app)
        let minutes = app.textFields["recap.minutes"]
        replaceNumber(minutes, with: "1", in: app)
        dismissRecapKeyboard(language: language, app: app)

        let note = app.textViews["recap.note"]
        let draft = "Test draft\nKeep this"
        tap(note, in: app)
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        note.typeText(draft)
        let done = app.buttons["recap.dismissKeyboard"]
        XCTAssertTrue(done.isHittable)
        assertToolbarTarget(done)
        let count = app.staticTexts["recap.noteCount"]
        XCTAssertTrue(count.exists)
        let countFrame = count.frame
        let dismissFrame = done.frame
        let clearOfAccessory = !countFrame.isEmpty && countFrame.maxX <= dismissFrame.minX + 0.000001
        if !clearOfAccessory {
            print("Keyboard metadata geometry: count=\(countFrame), dismiss=\(dismissFrame).")
            captureFailure("Keyboard-counter-overlap-\(language)", app)
        }
        XCTAssertTrue(clearOfAccessory, "The note count must stay clear of the floating keyboard action.")
        captureSystem("Manual-note-keyboard-\(language)", app)
        dismissRecapKeyboard(language: language, app: app)
        XCTAssertEqual(note.value as? String, draft)

        tap(app.buttons["recap.cancel"], in: app)
        let discard = language == "en" ? "Discard" : "放弃"
        let keep = language == "en" ? "Edit" : "继续编辑"
        captureVisibleConfirmation("Manual-note-confirm-\(language)", keep: keep, discard: discard, app: app)
        cancelConfirmation(language == "en" ? "Edit" : "继续编辑",
            destructiveAction: discard, in: app)
        XCTAssertEqual(note.value as? String, draft)
        XCTAssertEqual(minutes.value as? String, "1")
        let save = app.buttons["recap.saveToolbar"]
        XCTAssertTrue(save.isEnabled && save.isHittable)
        revealFully(from: note, through: note, in: app)
        XCTAssertGreaterThanOrEqual(note.frame.minX, app.windows.firstMatch.frame.minX)
        XCTAssertLessThanOrEqual(note.frame.maxX, app.windows.firstMatch.frame.maxX)
        XCTAssertGreaterThanOrEqual(note.frame.height, expanded ? 160 : 96)
        capture("Manual-note-retained-\(language)", app)
        tap(app.buttons["recap.cancel"], in: app)
        XCTAssertTrue(app.buttons[discard].waitForExistence(timeout: 10))
        tap(app.buttons[discard], in: app)
        XCTAssertTrue(app.buttons["today.startMoment"].waitForExistence(timeout: 10))
    }

    private func captureVisibleConfirmation(_ name: String, keep: String, discard: String, app: XCUIApplication) {
        let alert = app.alerts.firstMatch
        guard alert.waitForExistence(timeout: 10) else {
            captureFailure("Confirmation-missing-\(name)", app)
            return XCTFail("The confirmation did not appear.")
        }
        waitForStableFrame(alert, message: "Confirmation never settled: \(name)")
        let window = app.windows.containing(.button, identifier: keep).firstMatch
        guard window.exists else {
            captureFailure("Confirmation-window-missing-\(name)", app)
            return XCTFail("No window contains the confirmation action.")
        }
        let viewport = window.frame
        for label in [keep, discard] {
            let action = alert.buttons[label]
            let frame = action.frame
            let tolerance: CGFloat = 0.000001
            let visible = !viewport.isEmpty && !frame.isEmpty
                && frame.minX >= viewport.minX - tolerance && frame.maxX <= viewport.maxX + tolerance
                && frame.minY >= viewport.minY - tolerance && frame.maxY <= viewport.maxY + tolerance
            let hittable = action.isHittable
            if !visible || !hittable || frame.width < 44 - tolerance || frame.height < 44 - tolerance {
                print("Confirmation geometry: name=\(name), action=\(label), frame=\(frame), viewport=\(viewport), alert=\(alert.frame), hittable=\(hittable).")
                captureFailure("Confirmation-invalid-\(name)", app)
            }
            XCTAssertTrue(visible && hittable, "Both confirmation actions must be fully visible without scrolling.")
            assertToolbarTarget(action)
        }
        captureSystem(name, app)
    }

    private func dismissRecapKeyboard(language: String, app: XCUIApplication) {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists && keyboard.isHittable else {
            captureFailure("Keyboard-not-visible-before-Done-\(language)", app)
            return XCTFail("Actual typing must show an operable software keyboard before Done.")
        }
        let done = app.buttons["recap.dismissKeyboard"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCTAssertEqual(done.label, language == "en" ? "Done" : "完成")
        XCTAssertTrue(done.isEnabled && done.isHittable)
        let target = done.frame
        if target.width < 44 - 0.000001 || target.height < 44 - 0.000001 {
            captureFailure("Keyboard-target-invalid-\(language)", app)
        }
        assertToolbarTarget(done)
        let window = app.windows.firstMatch.frame
        XCTAssertTrue(window.contains(done.frame))
        done.tap()
        let closed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            // iPad can retain a non-hittable Keyboard with all keys below
            // the screen after dismissal. Existence is not visibility.
            let remainingKeyboard = app.keyboards.firstMatch
            // Phone keyboards leave the hierarchy. Observe that single state
            // instead of resolving isHittable after an existence snapshot
            // that may already be stale during the dismissal animation.
            if UIDevice.current.userInterfaceIdiom != .pad { return !remainingKeyboard.exists }
            return !remainingKeyboard.exists || !remainingKeyboard.isHittable
        }, object: nil)
        let result = XCTWaiter.wait(for: [closed], timeout: 5)
        if result != .completed {
            // The keyboard or its Done accessory may already have vanished.
            // Capture the whole current screen/tree without querying them.
            print("Keyboard dismissal diagnostic: locale=\(language), wait result=\(result).")
            captureFailure("Keyboard-dismissal-incomplete-\(language)", app)
        }
        XCTAssertEqual(result, .completed, "Done must hide the operable software keyboard after the actual tap.")
        XCTAssertFalse(app.alerts.firstMatch.exists, "A blocking alert must not substitute for keyboard dismissal.")
        print("Verified software keyboard dismissal after actual typing. Locale: \(language).")
    }

    private func chooseMomentFilter(_ label: String, in app: XCUIApplication) {
        let segment = app.segmentedControls.buttons[label]
        if segment.exists {
            tap(segment, in: app)
        } else {
            tap(app.buttons["timeline.filter"], in: app)
            let option = app.buttons[label].firstMatch
            // A menu is a native presentation, not content to reveal by
            // swiping the underlying timeline while it is still appearing.
            guard option.waitForExistence(timeout: 10) else {
                captureFailure("Timeline-filter-unavailable", app)
                return XCTFail("The requested native filter option did not appear: \(label)")
            }
            XCTAssertTrue(option.isEnabled)
            option.tap()
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
        let destination: XCUIElement
        switch english {
        case "Timeline": destination = app.staticTexts["timeline.resultCount"]
        case "Settings": destination = app.buttons["settings.export"]
        default: destination = app.buttons["today.startMoment"]
        }
        guard destination.waitForExistence(timeout: 15) else {
            captureFailure("Tab-destination-unavailable", app)
            return XCTFail("The selected tab did not present its content: \(english)")
        }
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
        for attempt in 0..<16 {
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
            let tabBar = app.tabBars.firstMatch
            let tabCoversCenter = tabBar.exists && tabBar.isHittable && tabBar.frame.contains(center)
            let canTap = exists && element.isHittable && viewport.contains(center) &&
                !keyboardCoversCenter && !footerCoversCenter && !tabCoversCenter
            // Keep visible controls on the normal fast path. Only a fixed
            // Settings result requires the extra scroll-ownership query.
            if canTap && !app.buttons["settings.dismissBackupStatus"].exists {
                if element.identifier == "settings.deleteAll" {
                    print("Verified Settings delete reachability. Scroll drags: \(attempt).")
                }
                return
            }
            let scroll = scrollSurface(containing: element, in: app)
            // A fixed result banner can cover a control that still reports
            // hittable within the window. Require its center inside its own
            // scroll viewport; toolbar and native dialog actions have no owner.
            let hasScrollOwner = canTap && !element.identifier.isEmpty &&
                app.scrollViews.containing(.any, identifier: element.identifier).firstMatch.exists
            let visibleContent = hasScrollOwner ? scroll.frame.intersection(viewport) : viewport
            if canTap, visibleContent.contains(center) {
                if element.identifier == "settings.deleteAll" {
                    print("Verified Settings delete reachability. Scroll drags: \(attempt).")
                }
                return
            }
            if exists, !frame.isEmpty, scroll.exists {
                let top = max(scroll.frame.minY, app.navigationBars.firstMatch.frame.maxY) + 12
                var bottom = min(scroll.frame.maxY, viewport.maxY) - 12
                if keyboard.exists { bottom = min(bottom, keyboard.frame.minY - 12) }
                if tabBar.exists, tabBar.isHittable, tabBar.frame.midY > viewport.midY {
                    bottom = min(bottom, tabBar.frame.minY - 12)
                }
                if let footerTop { bottom = min(bottom, footerTop - 12) }
                guard bottom > top + 44 else { return XCTFail("No usable scroll viewport for \(element)") }
                let middle = (top + bottom) / 2
                let limit = (bottom - top) * 0.4
                let delta = max(-limit, min(limit, middle - frame.midY))
                let start = window.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: scroll.frame.intersection(viewport).midX - viewport.minX,
                        dy: middle - viewport.minY))
                let end = start.withOffset(CGVector(dx: 0, dy: delta))
                let fixedFeedback = app.buttons["settings.dismissBackupStatus"].exists &&
                    !app.scrollViews.containing(.button, identifier: "settings.dismissBackupStatus").firstMatch.exists
                let nearTarget = abs(middle - frame.midY) <= (bottom - top) * 3
                if fixedFeedback {
                    print("Revealing below fixed feedback. Control: \(element.identifier); frame: \(frame); usable top/bottom: \(top)/\(bottom); delta: \(delta); precise: \(nearTarget).")
                }
                if fixedFeedback && nearTarget {
                    // A large fixed notice leaves a narrow scroll viewport.
                    // End this normal drag at rest instead of releasing a
                    // fast flick that can carry the target past that viewport.
                    start.press(forDuration: 0.05, thenDragTo: end,
                        withVelocity: .slow, thenHoldForDuration: 0.2)
                } else {
                    start.press(forDuration: 0.05, thenDragTo: end)
                }
            } else {
                window.swipeUp()
            }
        }
        captureFailure("Control-unreachable", app)
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
        let homeDestination: String?
        switch element.identifier {
        case "today.startMoment": homeDestination = "session.pauseResume"
        case "today.addRecord": homeDestination = "recap.saveToolbar"
        default: homeDestination = nil
        }
        element.tap()
        if let homeDestination,
           !app.buttons[homeDestination].waitForExistence(timeout: 15) {
            captureFailure("Home-action-destination-unavailable", app)
            XCTFail("A single Home action did not present its destination: \(homeDestination)")
        }
    }

    private func checkTimelineSearch(language: String, app: XCUIApplication) {
        let scope = app.staticTexts["timeline.searchScope"]
        let total = app.staticTexts["timeline.resultCount"]
        let one = language == "en" ? "1 moment" : "1 条记录"
        revealFully(from: scope, through: total, in: app)
        XCTAssertEqual(scope.label, language == "en" ? "Date, type, mood, or tag" : "搜索日期、类型、感受或标签")
        XCTAssertEqual(total.label, one)
        XCTAssertGreaterThan(scope.frame.height, 0)
        XCTAssertGreaterThanOrEqual(scope.frame.minX, app.windows.firstMatch.frame.minX)
        XCTAssertLessThanOrEqual(scope.frame.maxX, app.windows.firstMatch.frame.maxX)
        // A settled scroll container alone does not prove that its body has
        // appeared. Require the actual scope/count before the first snapshot.
        capture("Timeline-\(language)", app, stableSurface: scope)

        let search = app.searchFields.firstMatch
        reveal(search, in: app)
        XCTAssertEqual(search.placeholderValue, language == "en" ? "Search moments" : "搜索记录")
        tap(search, in: app)
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
        assertSearchCountAboveKeyboard(total, app: app)
        capture("Timeline-search-ready-\(language)", app)

        // ASCII queries exercise both localized interfaces without claiming IME
        // composition coverage. The gallery's saved record has the Calm mood.
        let query = "no-matching-mood"
        search.typeText(query)
        let empty = language == "en" ? "0 moments" : "0 条记录"
        let updated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            total.exists && total.label == empty
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [updated], timeout: 10), .completed)
        assertSearchCountAboveKeyboard(total, app: app)
        capture("Timeline-search-empty-\(language)", app)

        submitEmptyTimelineSearch(query: query, expectedCount: empty, language: language, app: app)

        guard let editingSearch = replaceTimelineSearchQuery(query, language: language, app: app) else { return }
        let matched = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            total.exists && total.label == one
        }, object: nil)
        let matchedResult = XCTWaiter.wait(for: [matched], timeout: 10)
        if matchedResult != .completed { captureFailure("Timeline-match-update-unavailable-\(language)", app) }
        XCTAssertEqual(matchedResult, .completed)
        XCTAssertEqual(editingSearch.value as? String, "Calm")
        assertSearchCountAboveKeyboard(total, app: app)
        capture("Timeline-search-matched-\(language)", app)

        submitMatchedTimelineSearch(expectedCount: one, language: language, app: app)

        tap(app.buttons["timeline.clearFilters"], in: app)
        let cleared = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            total.exists && total.label == one && !app.keyboards.firstMatch.exists &&
                !app.buttons["timeline.clearFilters"].exists
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [cleared], timeout: 10), .completed)
        // Native phone search collapses after the body scrolls to Clear filters.
        // Reveal it with the normal scroll gesture before reading its value.
        let clearedSearch = revealTimelineSearch(in: app)
        let placeholder = language == "en" ? "Search moments" : "搜索记录"
        XCTAssertEqual(clearedSearch.placeholderValue, placeholder)
        let clearedValue = clearedSearch.value as? String
        XCTAssertTrue(clearedValue == "" || clearedValue == placeholder,
            "Revealing the inactive search field must show an empty query.")
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        revealFully(from: scope, through: total, in: app)
        capture("Timeline-search-cleared-\(language)", app)
        print("Verified short search prompt, scope, empty/matched queries and clear keyboard dismissal. Locale: \(language).")
        print("Verified visible keyboard result count and query-preserving search submission. Locale: \(language).")
    }

    private func submitEmptyTimelineSearch(query: String, expectedCount: String, language: String, app: XCUIApplication) {
        let total = app.staticTexts["timeline.resultCount"]
        guard submitTimelineSearch(language: language, app: app) else { return }
        let submitted = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !app.keyboards.firstMatch.exists && total.exists && total.label == expectedCount
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [submitted], timeout: 10), .completed,
            "Submitting search must hide the keyboard while preserving the zero-result query.")
        let submittedSearch = app.searchFields.firstMatch
        guard submittedSearch.value as? String == query else {
            captureFailure("Timeline-query-not-retained-\(language)", app)
            return XCTFail("The actual native search field must retain the submitted query.")
        }
        assertSubmittedEmptyStateVisible(language: language, app: app)
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        capture("Timeline-search-submitted-\(language)", app)
    }

    private func replaceTimelineSearchQuery(_ query: String, language: String, app: XCUIApplication) -> XCUIElement? {
        let editingSearch = revealTimelineSearch(in: app)
        tap(editingSearch, in: app)
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(editingSearch.value as? String, query)
        // A new field tap can place the insertion point inside the old query.
        // Use its real Clear action instead of assuming the cursor is at end.
        guard let nativeClear = nativeControl(["Clear text", "清除文本", "清除文字"], app: app,
            timeout: 5, surface: editingSearch, enabledAction: true) else {
            captureFailure("Timeline-native-clear-unavailable-\(language)", app)
            XCTFail("The actual search field must expose its native text-clear action.")
            return nil
        }
        nativeClear.tap()
        let emptyField = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let value = editingSearch.value as? String
            return value == "" || value == editingSearch.placeholderValue
        }, object: nil)
        let clearedField = XCTWaiter.wait(for: [emptyField], timeout: 5)
        if clearedField != .completed { captureFailure("Timeline-native-clear-failed-\(language)", app) }
        XCTAssertEqual(clearedField, .completed)
        // Native iPad search can release focus when its text-clear action
        // collapses the expanded field. Resume editing with a real field tap.
        waitForStableFrame(editingSearch, requireHittable: true,
            message: "The cleared native search field must settle before editing resumes.")
        editingSearch.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
        editingSearch.typeText("Calm")
        guard editingSearch.value as? String == "Calm" else {
            captureFailure("Timeline-replacement-query-incorrect-\(language)", app)
            XCTFail("Native clear followed by actual typing must produce exactly Calm.")
            return nil
        }
        return editingSearch
    }

    private func submitMatchedTimelineSearch(expectedCount: String, language: String, app: XCUIApplication) {
        let total = app.staticTexts["timeline.resultCount"]
        let scope = app.staticTexts["timeline.searchScope"]
        guard submitTimelineSearch(language: language, app: app) else { return }
        let row = app.buttons.matching(identifier: "moment.row").firstMatch
        let recordVisible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !app.keyboards.firstMatch.exists && total.exists && total.label == expectedCount && row.exists && row.isHittable
        }, object: nil)
        let matchSubmitted = XCTWaiter.wait(for: [recordVisible], timeout: 10)
        if matchSubmitted != .completed { captureFailure("Timeline-matched-result-not-revealed-\(language)", app) }
        XCTAssertEqual(matchSubmitted, .completed, "Submitting a matching query must reveal its operable record without test scrolling.")
        XCTAssertEqual(app.searchFields.firstMatch.value as? String, "Calm")
        XCTAssertLessThanOrEqual(app.buttons["timeline.clearFilters"].frame.maxY, row.frame.minY,
            "Reset controls must precede an unbounded result list, not require traversing every record.")
        XCTAssertLessThanOrEqual(scope.frame.maxY, row.frame.minY)
        capture("Timeline-search-match-submitted-\(language)", app)
        print("Verified submitted matching record and controls before result list. Locale: \(language).")
    }

    private func assertSearchCountAboveKeyboard(_ count: XCUIElement, app: XCUIApplication) {
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))
        waitForStableFrame(count, message: "The result count must settle without test scrolling while typing.")
        let frame = count.frame
        let keyboardFrame = keyboard.frame
        let assistant = app.otherElements["SystemInputAssistantView"].firstMatch
        let assistantFrame = assistant.exists ? assistant.frame : .zero
        let viewport = app.windows.firstMatch.frame
        let inputTop = !assistantFrame.isEmpty && assistantFrame.intersects(viewport)
            ? min(keyboardFrame.minY, assistantFrame.minY) : keyboardFrame.minY
        XCTAssertTrue(app.windows.firstMatch.frame.contains(frame))
        XCTAssertLessThanOrEqual(frame.maxY, inputTop,
            "The entire result count must stay above the keyboard, including its prediction/accessory strip.")
        print("Verified search count geometry. Count: \(frame); keyboard: \(keyboardFrame).")
        print("Verified search obstruction geometry. Count: \(frame); input top: \(inputTop); assistant: \(assistantFrame).")
    }

    private func assertSubmittedEmptyStateVisible(language: String, app: XCUIApplication) {
        // No test scrolling: explicit Search submission must reveal the whole
        // explanation in the product, including the line above the tab bar.
        let title = app.staticTexts["timeline.emptyTitle"]
        let message = app.staticTexts["timeline.emptyMessage"]
        XCTAssertEqual(title.label, language == "en" ? "No matching moments" : "没有找到匹配记录")
        XCTAssertEqual(message.label, language == "en"
            ? "Try another word or change the selected filter." : "试试其他关键词，或更改当前筛选条件。")
        // Derive the pixel grid from this actual window capture, rather than
        // a hardcoded device scale or the deprecated UIScreen.main context.
        let windowFrame = app.windows.firstMatch.frame
        let measurement = app.windows.firstMatch.screenshot().image
        guard windowFrame.width > 0, let bitmap = measurement.cgImage else {
            captureFailure("Timeline-pixel-measurement-unavailable-\(language)", app)
            return XCTFail("The actual window must provide native bitmap dimensions.")
        }
        let bitmapWidth: Int
        switch measurement.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored: bitmapWidth = bitmap.height
        default: bitmapWidth = bitmap.width
        }
        let displayScale = CGFloat(bitmapWidth) / windowFrame.width
        XCTAssertTrue(displayScale.isFinite && displayScale > 0)
        func pixel(_ point: CGFloat) -> CGFloat { (point * displayScale).rounded() }
        func geometry() -> (section: CGRect, top: CGFloat, bottom: CGFloat, viewport: CGRect) {
            let viewport = app.windows.firstMatch.frame
            let navigation = app.navigationBars.firstMatch
            let top = navigation.exists ? max(viewport.minY, navigation.frame.maxY) : viewport.minY
            let tab = app.tabBars.firstMatch
            let bottom = tab.exists && tab.frame.midY > viewport.midY ? tab.frame.minY : viewport.maxY
            return (title.frame.union(message.frame), top, bottom, viewport)
        }
        func isVisible(_ value: (section: CGRect, top: CGFloat, bottom: CGFloat, viewport: CGRect)) -> Bool {
            !value.section.isEmpty && !value.section.isInfinite && !value.section.isNull &&
                pixel(value.section.minY) >= pixel(value.top) && pixel(value.section.maxY) <= pixel(value.bottom) &&
                pixel(value.section.minX) >= pixel(value.viewport.minX) && pixel(value.section.maxX) <= pixel(value.viewport.maxX)
        }
        // Keyboard disappearance can precede the product's scroll/layout
        // update. Await the real postcondition, not a delay or a test gesture.
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            title.exists && message.exists && !app.keyboards.firstMatch.exists && isVisible(geometry())
        }, object: nil)
        let ready = XCTWaiter.wait(for: [settled], timeout: 10)
        let actual = geometry()
        if ready != .completed || !isVisible(actual) {
            print("Submitted explanation not ready. Locale: \(language); wait: \(ready.rawValue); actual: \(actual).")
            captureFailure("Timeline-submitted-explanation-obscured-\(language)", app)
        }
        XCTAssertEqual(ready, .completed, "Submission must reveal the complete explanation without test scrolling.")
        XCTAssertTrue(isVisible(actual), "The full empty-result title and explanation must stay above the bottom tabs.")
        print("Verified submitted explanation visibility. Locale: \(language); section: \(actual.section); top: \(actual.top); bottom: \(actual.bottom); scale: \(displayScale); viewport: \(actual.viewport).")
    }

    private func submitTimelineSearch(language: String, app: XCUIApplication) -> Bool {
        guard let submit = nativeControl(["Search", "搜索", "search"], app: app, timeout: 5,
            surface: app.keyboards.firstMatch, enabledAction: true) else {
            captureFailure("Timeline-submit-unavailable-\(language)", app)
            XCTFail("The actual software keyboard must provide its Search submission action.")
            return false
        }
        submit.tap()
        return true
    }

    private func revealTimelineSearch(in app: XCUIApplication) -> XCUIElement {
        let search = app.searchFields.firstMatch
        for attempt in 0...4 {
            if search.exists && search.isHittable && app.windows.firstMatch.frame.contains(search.frame) {
                waitForStableFrame(search, requireHittable: true,
                    message: "The revealed native search field must settle.")
                return search
            }
            if attempt < 4 { app.scrollViews.firstMatch.swipeDown() }
        }
        captureFailure("Timeline-search-not-revealed", app)
        XCTFail("Normal scrolling must reveal the cleared native search field.")
        return search
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
        if label != "Cancel" {
            // Keeping a draft or timer must be an explicit visible choice;
            // the product no longer relies on a hidden popover-cancel role.
            XCTAssertTrue(cancel.waitForExistence(timeout: 10))
            XCTAssertTrue(cancel.isHittable)
            cancel.tap()
        } else if cancel.exists && cancel.isHittable {
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
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !action.exists
        }, object: nil)
        let result = XCTWaiter.wait(for: [dismissed], timeout: 15)
        if result != .completed { captureFailure("Confirmation-dismiss-unavailable", app) }
        XCTAssertEqual(result, .completed, "Confirmation did not dismiss.")
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
            // Bottom tab bars overlay scroll content. A hittable center does
            // not prove the complete text is above that native surface.
            // iPad's top tab bar must not become the bottom boundary.
            let tabBar = app.tabBars.firstMatch
            if tabBar.exists, tabBar.isHittable,
               tabBar.frame.midY > app.windows.firstMatch.frame.midY {
                bottom = min(bottom, tabBar.frame.minY - 12)
            }
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
        captureFailure("Content-not-fully-visible", app)
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
            guard !frame.isEmpty, !frame.isNull, !frame.isInfinite else { return false }
            if frame != lastFrame {
                lastFrame = frame
                stableSince = Date()
                return false
            }
            return Date().timeIntervalSince(stableSince) >= 0.75
        }, object: nil)
        // This is an automation sampling window, not a UI latency claim.
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 30), .completed, message)
    }
}
