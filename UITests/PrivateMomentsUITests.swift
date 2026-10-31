import XCTest

final class PrivateMomentsUITests: XCTestCase {
    func testEnglishPrimaryRecordFlow() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let startButton = app.buttons["today.startMoment"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10), "The Today screen should expose the primary action.")
        XCTAssertTrue(startButton.isEnabled, "The journal should be ready before a session starts.")
        attachScreenshot(named: "Today — English", from: app)
        startButton.tap()

        let finishButton = app.buttons["session.finish"]
        XCTAssertTrue(finishButton.waitForExistence(timeout: 10), "Starting a moment should open the live session.")
        XCTAssertTrue(app.buttons["session.pauseResume"].exists, "The live session should expose pause and resume.")
        finishButton.tap()

        let saveButton = app.buttons["recap.save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 10), "Finishing a session should open its recap.")
        XCTAssertTrue(saveButton.isEnabled, "A valid recap should be saveable.")
        saveButton.tap()

        XCTAssertTrue(startButton.waitForExistence(timeout: 10), "Saving should return to Today.")
        let timelineTab = app.tabBars.buttons["Timeline"]
        XCTAssertTrue(timelineTab.waitForExistence(timeout: 10), "The primary navigation should expose Timeline.")
        timelineTab.tap()

        let momentRow = app.buttons.matching(identifier: "moment.row").firstMatch
        XCTAssertTrue(momentRow.waitForExistence(timeout: 10), "The saved moment should appear in Timeline.")
        momentRow.tap()
        XCTAssertTrue(app.navigationBars["Moment details"].waitForExistence(timeout: 10), "Opening the row should show its detail screen.")
        XCTAssertTrue(app.staticTexts["No note added."].exists, "A note-free record should have a clear empty note state.")
        attachScreenshot(named: "Moment details — English", from: app)
    }

    func testSimplifiedChineseHomeLocalization() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()

        let startButton = app.buttons["today.startMoment"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10), "The primary action should remain accessible in Simplified Chinese.")
        XCTAssertEqual(startButton.label, "开始记录")
        attachScreenshot(named: "Today — Simplified Chinese", from: app)
    }

    private func attachScreenshot(named name: String, from app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
