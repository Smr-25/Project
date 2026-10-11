import XCTest

final class QuizUITests: XCTestCase {
    private let Words = ["forest": "meşə", "water": "su", "bird": "quş", "large": "böyük", "huge": "iri", "tree": "ağac"]
    @MainActor
    private func Launch() -> XCUIApplication {
        let App = XCUIApplication()
        App.launchEnvironment["WORDREVISIT_TEST_STORE"] = UUID().uuidString
        App.launchEnvironment["WORDREVISIT_UI_FIXTURE"] = "Study"
        App.launch()
        if App.staticTexts["Quickly Change Keyboards"].exists { App.buttons["Continue"].tap() }
        return App
    }

    @MainActor
    func testDailyAnswerIsStableAndRestoresAfterRelaunch() throws {
        let App = Launch()
        Capture(App, Name: "today-2")
        App.buttons["Start today's plan"].tap()
        let Prompt = App.staticTexts["StudyPrompt"]
        XCTAssertTrue(Prompt.waitForExistence(timeout: 10))
        let Original = Prompt.label
        let Expected = try XCTUnwrap(Words.first { $0.value == Original }?.key)
        let Answer = App.textFields["StudyAnswer"]
        Answer.tap(); Answer.typeText(Expected + "\n")
        XCTAssertTrue(App.buttons["Continue"].waitForExistence(timeout: 5))
        XCTAssertEqual(Prompt.label, Original)
        Capture(App, Name: "study-feedback")
        App.terminate(); App.launch()
        App.buttons["Continue saved session"].tap()
        XCTAssertTrue(Prompt.waitForExistence(timeout: 5))
        XCTAssertEqual(Prompt.label, Original)
        XCTAssertTrue(App.buttons["Continue"].exists)
        App.swipeUp(); App.buttons["Continue"].tap()
        XCTAssertNotEqual(Prompt.label, Original)
        let Next = Prompt.label
        App.buttons["I don't know"].tap()
        XCTAssertEqual(Prompt.label, Next)
        App.swipeUp(); App.buttons["Continue"].tap()
        App.buttons["Save and close session"].tap()
        App.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(App.staticTexts["Your progress"].waitForExistence(timeout: 5))
        Capture(App, Name: "progress-2")
        App.swipeUp(); App.buttons["Review study answers"].tap()
        XCTAssertTrue(App.staticTexts["Study answers"].waitForExistence(timeout: 5))
        XCTAssertTrue(App.staticTexts["You: " + Expected].exists)
    }

    @MainActor
    func testFreeQuizRandomOrderReviewAndRetry() throws {
        let App = Launch()
        App.swipeUp()
        App.buttons.containing(.staticText, identifier: "Easy recall").firstMatch.tap()
        let Prompt = App.staticTexts["QuizPrompt"]
        XCTAssertTrue(Prompt.waitForExistence(timeout: 5))
        let First = Prompt.label
        let Correct = try XCTUnwrap(Words[First])
        for Index in 0..<6 {
            let Current = Prompt.label
            let Answer = App.textFields["QuizAnswer"]
            if !Answer.isHittable { App.swipeUp() }
            Answer.tap(); Answer.typeText((Index == 0 ? Correct : "incorrect answer") + "\n")
            XCTAssertEqual(Prompt.label, Current)
            App.swipeUp()
            App.buttons[Index == 5 ? "See results" : "Next word"].tap()
        }
        XCTAssertTrue(App.staticTexts["1 / 6"].waitForExistence(timeout: 5))
        App.swipeUp(); App.buttons["Review my answers"].tap()
        XCTAssertTrue(App.staticTexts["Your first answers"].waitForExistence(timeout: 5))
        App.buttons["Done"].tap()
        App.buttons["Retry 5 missed words"].tap()
        XCTAssertTrue(Prompt.waitForExistence(timeout: 5))
        XCTAssertNotEqual(Prompt.label, First)
    }

    @MainActor
    func testBulkDeletePastePreviewAndSettings() throws {
        let App = Launch()
        App.tabBars.buttons["My words"].tap()
        App.buttons["Manage words"].tap(); App.buttons["Select words"].tap()
        App.buttons["Select visible"].tap()
        Capture(App, Name: "bulk-delete")
        App.buttons["Delete (6)"].tap(); App.buttons["Delete 6 words"].tap()
        XCTAssertTrue(App.staticTexts["A fresh page"].waitForExistence(timeout: 5))
        App.buttons["Manage words"].tap(); App.buttons["Paste words"].tap()
        let Editor = App.textViews["PasteWords"]
        XCTAssertTrue(Editor.waitForExistence(timeout: 5))
        Editor.tap(); Editor.typeText("calm - sakit\nquiet - sessiz\nbad row")
        App.swipeUp(); App.buttons["Preview import"].tap()
        App.swipeUp()
        XCTAssertTrue(App.buttons["Import 2 words"].waitForExistence(timeout: 5))
        Capture(App, Name: "import-preview")
        App.buttons["Import 2 words"].tap()
        XCTAssertTrue(App.buttons.containing(.staticText, identifier: "calm").firstMatch.waitForExistence(timeout: 5))
        App.tabBars.buttons["Settings"].tap()
        App.buttons["My learning plan"].tap()
        XCTAssertTrue(App.staticTexts["My learning plan"].waitForExistence(timeout: 5))
        Capture(App, Name: "learning-plan")
        App.buttons["Save"].tap()
        App.buttons["Backup & restore"].tap()
        XCTAssertTrue(App.buttons["Export full backup"].waitForExistence(timeout: 5))
        Capture(App, Name: "backup")
        App.buttons["Done"].tap()
        App.tabBars.buttons["Today"].tap(); App.buttons["Start today's plan"].tap()
        XCTAssertTrue(App.staticTexts["StudyIntroduction"].waitForExistence(timeout: 5))
        Capture(App, Name: "learn")
        App.swipeUp(); App.buttons["Learn this word"].tap()
        if App.buttons["Learn this word"].waitForExistence(timeout: 2) { App.buttons["Learn this word"].tap() }
        XCTAssertTrue(App.buttons["Save and return home"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSynonymsUseEligibleGroups() throws {
        let App = Launch()
        App.swipeUp()
        App.buttons["Practise synonyms"].tap()
        let Prompt = App.staticTexts["StudyPrompt"]
        XCTAssertTrue(Prompt.waitForExistence(timeout: 5))
        let Original = Prompt.label
        XCTAssertTrue(["large", "huge"].contains(Original))
        App.buttons[Original == "large" ? "huge" : "large"].tap()
        XCTAssertEqual(Prompt.label, Original)
        Capture(App, Name: "synonyms")
        App.swipeUp(); App.buttons["Continue"].tap()
        XCTAssertNotEqual(Prompt.label, Original)
    }

    @MainActor
    private func Capture(_ App: XCUIApplication, Name: String) {
        let Attachment = XCTAttachment(screenshot: App.screenshot())
        Attachment.name = Name; Attachment.lifetime = .keepAlways; add(Attachment)
    }
}
