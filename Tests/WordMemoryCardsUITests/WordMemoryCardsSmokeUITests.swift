import XCTest

final class WordMemoryCardsSmokeUITests: XCTestCase {
    func testAddWordAndEnterReview() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.staticTexts["单词卡片"].waitForExistence(timeout: 8))
        app.buttons["home.addWords"].tap()

        XCTAssertTrue(app.navigationBars["添加单词"].waitForExistence(timeout: 5))
        app.buttons["单个添加"].tap()

        let english = app.textFields["addWords.english"]
        XCTAssertTrue(english.waitForExistence(timeout: 3))
        english.tap()
        english.typeText("apple")

        let chinese = app.textFields["addWords.chinese"]
        chinese.tap()
        chinese.typeText("苹果")
        app.buttons["addWords.add"].tap()

        XCTAssertTrue(app.alerts["导入完成"].waitForExistence(timeout: 5))
        app.alerts["导入完成"].buttons["好"].tap()
        app.navigationBars["添加单词"].buttons.firstMatch.tap()

        XCTAssertTrue(app.staticTexts["2 张"].waitForExistence(timeout: 5))
        app.buttons["home.startReview"].tap()
        XCTAssertTrue(app.staticTexts["review.card"].waitForExistence(timeout: 8))
    }

    func testResetProgressRequiresExplicitConfirmation() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.staticTexts["单词卡片"].waitForExistence(timeout: 8))
        app.buttons["设置"].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 5))

        let resetButton = app.buttons["settings.resetProgress"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 5))
        resetButton.tap()

        let alert = app.alerts["清除全部学习记录？"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.buttons["确认清除"].exists)
        XCTAssertTrue(alert.buttons["取消"].exists)
        alert.buttons["取消"].tap()
    }
}
