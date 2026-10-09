import XCTest

final class QuizUITests: XCTestCase {
    @MainActor
    func testExamplesQuizReviewRetryAndProgress() throws {
        let App = XCUIApplication()
        App.launchEnvironment["WORDREVISIT_TEST_STORE"] = UUID().uuidString
        App.launch()
        if App.staticTexts["Quickly Change Keyboards"].exists { App.buttons["Continue"].tap() }
        App.tabBars.buttons["My words"].tap()
        let Search = App.textFields["Search your words"]
        XCTAssertTrue(Search.waitForExistence(timeout: 10))
        Search.tap()
        Search.typeText("accumulate")
        App.buttons.containing(.staticText, identifier: "accumulate").firstMatch.tap()
        let Example = App.textFields["Write a sentence using this word"]
        XCTAssertTrue(Example.waitForExistence(timeout: 5))
        if !Example.isHittable { App.swipeUp() }
        Example.tap()
        Example.typeText("Small efforts accumulate over time.")
        App.swipeUp()
        App.buttons["Save word"].tap()
        App.tabBars.buttons["Today"].tap()
        App.swipeUp()
        App.buttons.containing(.staticText, identifier: "Hard recall").firstMatch.tap()
        let HardPrompt = App.staticTexts["QuizPrompt"]
        XCTAssertTrue(HardPrompt.waitForExistence(timeout: 5))
        XCTAssertEqual(HardPrompt.label, "yığılmaq; toplamaq")
        XCTAssertTrue(App.staticTexts["Small efforts accumulate over time."].exists)
        Capture(App, Name: "quiz-examples-hard")
        App.buttons["Close quiz"].tap()
        App.buttons.containing(.staticText, identifier: "Easy recall").firstMatch.tap()

        let Prompt = App.staticTexts["QuizPrompt"]
        XCTAssertTrue(Prompt.waitForExistence(timeout: 10))
        XCTAssertEqual(Prompt.label, "accumulate")
        XCTAssertTrue(App.staticTexts["Small efforts accumulate over time."].exists)
        Capture(App, Name: "quiz-examples")
        let Answer = App.textFields["QuizAnswer"]
        if !Answer.isHittable { App.swipeUp() }
        Answer.tap()
        Answer.typeText("toplamaq\n")
        XCTAssertTrue(App.staticTexts["You got it"].waitForExistence(timeout: 5))
        XCTAssertEqual(Prompt.label, "accumulate", "Recording a correct answer must not replace the question.")
        App.swipeUp()
        App.buttons["Next word"].tap()
        XCTAssertEqual(Prompt.label, "adapt")

        for Index in 1..<20 {
            let Current = Prompt.label
            if !Answer.isHittable { App.swipeUp() }
            Answer.tap()
            Answer.typeText("incorrect answer")
            App.swipeUp()
            App.buttons["Check answer"].tap()
            XCTAssertEqual(Prompt.label, Current)
            App.swipeUp()
            App.buttons[Index == 19 ? "See results" : "Next word"].tap()
        }
        XCTAssertTrue(App.staticTexts["1 / 20"].waitForExistence(timeout: 5))
        Capture(App, Name: "quiz-results")
        App.swipeUp()
        App.buttons["Review my answers"].tap()
        XCTAssertTrue(App.staticTexts["Your first answers"].waitForExistence(timeout: 5))
        XCTAssertTrue(App.staticTexts["toplamaq"].exists)
        Capture(App, Name: "answer-review")
        App.buttons["Done"].tap()
        App.buttons["Retry 19 missed words"].tap()
        XCTAssertTrue(App.staticTexts["TRY AGAIN"].waitForExistence(timeout: 5))
        XCTAssertEqual(Prompt.label, "adapt")
        if !Answer.isHittable { App.swipeUp() }
        Answer.tap()
        Answer.typeText("uygunlasmaq\n")
        XCTAssertTrue(App.staticTexts["You got it"].waitForExistence(timeout: 5))
        App.swipeDown()
        App.buttons["Close quiz"].tap()
        App.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(App.staticTexts["Your progress"].waitForExistence(timeout: 5))
        XCTAssertTrue(App.staticTexts["20"].exists)
        Capture(App, Name: "progress")

        App.terminate()
        App.launch()
        App.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(App.staticTexts["20"].waitForExistence(timeout: 5), "Results must persist across launches.")
        App.swipeUp()
        App.buttons.containing(.staticText, identifier: "1/20").firstMatch.tap()
        XCTAssertTrue(App.staticTexts["Answer review"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func Capture(_ App: XCUIApplication, Name: String) {
        let Attachment = XCTAttachment(screenshot: App.screenshot())
        Attachment.name = Name
        Attachment.lifetime = .keepAlways
        add(Attachment)
    }
}
