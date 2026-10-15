import XCTest

final class QuizUITests: XCTestCase {
    private let Words = ["select": "seçmək", "choose": "seçmək", "previous": "əvvəlki", "prior": "əvvəlki", "obtain": "əldə etmək", "acquire": "əldə etmək"]
    @MainActor private func Launch() -> XCUIApplication {
        let App = XCUIApplication()
        App.launchEnvironment["WORDREVISIT_TEST_STORE"] = UUID().uuidString
        App.launch()
        return App
    }
    @MainActor private func OpenTab(_ Name: String, In App: XCUIApplication) {
        let PhoneTab = App.tabBars.buttons[Name]
        if PhoneTab.exists { PhoneTab.tap() }
        else if App.buttons[Name].firstMatch.exists { App.buttons[Name].firstMatch.tap() }
        else { App.cells[Name].firstMatch.tap() }
    }
    @MainActor private func Capture(_ App: XCUIApplication, _ Name: String) {
        let Attachment = XCTAttachment(screenshot: App.screenshot())
        Attachment.name = Name; Attachment.lifetime = .keepAlways; add(Attachment)
    }

    @MainActor func testHardDraftResumePinnedNextAndOneRetry() throws {
        let App = Launch()
        App.segmentedControls["PracticeMode"].buttons["Hard"].tap()
        App.buttons["Start practice"].tap()
        let Prompt = App.staticTexts["QuizPrompt"]
        XCTAssertTrue(Prompt.waitForExistence(timeout: 5))
        let FirstPrompt = Prompt.label
        let Field = App.textFields["QuizAnswer"]
        Field.tap(); Field.typeText("draft")
        App.terminate(); App.launch()
        App.buttons["Continue group"].tap()
        XCTAssertTrue(Field.waitForExistence(timeout: 5))
        XCTAssertEqual(Field.value as? String, "draft")
        XCTAssertEqual(Prompt.label, FirstPrompt)
        // Complete all primary questions incorrectly, then all six retries incorrectly.
        for Index in 0..<12 {
            if Index != 0 { Field.tap(); Field.typeText("wrong") }
            let Before = Prompt.label
            XCTAssertTrue(App.buttons["Check answer"].isHittable)
            App.buttons["Check answer"].tap()
            let Next = App.buttons["NextQuestion"]
            XCTAssertTrue(Next.waitForExistence(timeout: 5))
            XCTAssertTrue(Next.isHittable, "Next must be reachable without scrolling")
            XCTAssertEqual(Prompt.label, Before)
            if Index == 0 {
                Capture(App, "hard-feedback-14")
                App.terminate(); App.launch(); App.buttons["Continue group"].tap()
                XCTAssertTrue(Next.waitForExistence(timeout: 5)); XCTAssertEqual(Prompt.label, Before)
            }
            Next.tap()
        }
        XCTAssertTrue(App.staticTexts["Cycle complete"].waitForExistence(timeout: 5))
        XCTAssertTrue(App.buttons["NextGroup"].isHittable)
        App.buttons["Back to home"].tap()
        OpenTab("Settings", In: App)
        App.buttons.containing(.staticText, identifier: "Practice history").firstMatch.tap()
        XCTAssertTrue(App.staticTexts["0/6"].waitForExistence(timeout: 5))
        App.buttons.containing(.staticText, identifier: "0/6").firstMatch.tap()
        XCTAssertTrue(App.staticTexts["Answer review"].waitForExistence(timeout: 5))
        Capture(App, "history-14")
    }

    @MainActor func testEasyMixedDirectionsPinnedNextAndModeSwitch() throws {
        let App = Launch()
        App.buttons["Start practice"].tap()
        let Prompt = App.staticTexts["QuizPrompt"]
        var Seen: Set<String> = []
        var EnglishPrompts = 0
        for Index in 0..<6 {
            XCTAssertTrue(Prompt.waitForExistence(timeout: 5))
            let Value = Prompt.label
            Seen.insert(Value)
            let Options = App.buttons.matching(identifier: "QuizOption")
            XCTAssertEqual(Options.count, Words[Value] == nil ? 4 : 3)
            let Correct: String
            if let Translation = Words[Value] { Correct = Translation; EnglishPrompts += 1 }
            else {
                Correct = try XCTUnwrap(Options.allElementsBoundByIndex.first { Words[$0.label] == Value }?.label)
            }
            let Choice = try XCTUnwrap(Options.allElementsBoundByIndex.first { $0.label == Correct })
            if !Choice.isHittable { App.swipeUp() }
            Choice.tap()
            let Next = App.buttons["NextQuestion"]
            XCTAssertTrue(Next.isHittable)
            if Index == 0 { Capture(App, "easy-feedback-14") }
            Next.tap()
        }
        XCTAssertEqual(EnglishPrompts, 3)
        XCTAssertTrue(App.staticTexts["Cycle complete"].waitForExistence(timeout: 5))
        let Mode = App.segmentedControls["NextMode"]
        Mode.buttons["Hard"].tap()
        App.buttons["NextGroup"].tap()
        XCTAssertTrue(App.textFields["QuizAnswer"].waitForExistence(timeout: 5))
        XCTAssertEqual(App.buttons.matching(identifier: "QuizOption").count, 0)
    }

    @MainActor func testSynonymsAppearanceAndSimpleEditor() throws {
        let App = Launch()
        OpenTab("Settings", In: App)
        let Appearance = App.segmentedControls["AppearancePicker"]
        Appearance.buttons["Dark"].tap()
        OpenTab("Practice", In: App)
        Capture(App, "home-dark-14")
        OpenTab("Settings", In: App); Appearance.buttons["Light"].tap()
        App.terminate(); App.launch()
        OpenTab("Settings", In: App)
        XCTAssertTrue(Appearance.buttons["Light"].isSelected)
        Capture(App, "settings-light-14")
        OpenTab("Synonyms", In: App)
        XCTAssertTrue(App.staticTexts["select"].waitForExistence(timeout: 5))
        Capture(App, "synonyms-light-14")
        App.textFields["SearchGroups"].tap(); App.textFields["SearchGroups"].typeText("choose")
        XCTAssertTrue(App.staticTexts["select"].exists && App.staticTexts["choose"].exists)
        XCTAssertFalse(App.staticTexts["obtain"].exists)
        OpenTab("My words", In: App)
        App.buttons["Add word"].tap()
        let English = App.textFields["EditEnglish"]
        XCTAssertTrue(English.waitForExistence(timeout: 5))
        XCTAssertFalse(App.staticTexts["Pause this word"].exists)
        XCTAssertFalse(App.staticTexts["Definition"].exists)
        Capture(App, "editor-light-14")
        App.buttons["Cancel"].tap()
    }

    @MainActor func testBulkDeleteAndDuplicateImport() throws {
        let App = Launch()
        OpenTab("My words", In: App)
        App.buttons["Manage words"].tap(); App.buttons["Select words"].tap()
        App.buttons["Select visible"].tap(); App.buttons["Delete (6)"].tap(); App.buttons["Delete 6 words"].tap()
        XCTAssertTrue(App.staticTexts["A fresh page"].waitForExistence(timeout: 5))
        App.buttons["Manage words"].tap(); App.buttons["Paste words"].tap()
        let Editor = App.textViews["PasteWords"]
        XCTAssertTrue(Editor.waitForExistence(timeout: 5))
        Editor.tap(); Editor.typeText("calm - sakit\nCALM - different\nquiet - sessiz\nbad row")
        XCTAssertTrue(App.buttons["Preview import"].isHittable)
        App.buttons["Preview import"].tap()
        XCTAssertTrue(App.buttons["Import 2 words"].isHittable)
        Capture(App, "import-14")
        App.buttons["Import 2 words"].tap()
        XCTAssertTrue(App.buttons.containing(.staticText, identifier: "calm").firstMatch.waitForExistence(timeout: 5))
        OpenTab("Practice", In: App); App.buttons["Start practice"].tap()
        XCTAssertTrue(App.staticTexts["QuizPrompt"].waitForExistence(timeout: 5))
        XCTAssertEqual(App.buttons.matching(identifier: "QuizOption").count, 2)
    }
    @MainActor func testSeparateSynonymGroupingAndEasyResume() throws {
        let App = Launch()
        App.buttons["OpenSynonyms"].tap()
        XCTAssertTrue(App.segmentedControls["SynonymMode"].waitForExistence(timeout: 5))
        App.buttons["StartSynonyms"].tap()
        let Answers = ["choose": "select", "prior": "previous", "acquire": "obtain"]
        for (Index, Pair) in Answers.sorted(by: { $0.key < $1.key }).enumerated() {
            let Chip = App.buttons["SynonymChip-\(Pair.key)"]
            for _ in 0..<6 {
                let Footer = App.buttons["CheckSynonyms"].frame.minY - 55
                if Chip.isHittable && Chip.frame.maxY < Footer { break }
                App.scrollViews.allElementsBoundByIndex.last?.swipeUp()
            }
            XCTAssertTrue(Chip.isHittable); Chip.tap()
            let Target = App.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'PlaceIn-' AND label == %@", Pair.value)).firstMatch
            XCTAssertTrue(Target.isHittable); Target.tap()
            if Index == 0 {
                App.terminate(); App.launch(); App.buttons["OpenSynonyms"].tap()
                XCTAssertTrue(App.buttons["CheckSynonyms"].waitForExistence(timeout: 5))
            }
        }
        XCTAssertTrue(App.buttons["CheckSynonyms"].isEnabled && App.buttons["CheckSynonyms"].isHittable)
        Capture(App, "synonym-grouping-14")
        App.buttons["CheckSynonyms"].tap()
        XCTAssertTrue(App.buttons["NextSynonym"].isHittable)
        App.buttons["NextSynonym"].tap()
        XCTAssertTrue(App.staticTexts["SynonymResults"].waitForExistence(timeout: 5))
        App.segmentedControls["SynonymMode"].buttons["Easy"].tap()
        App.buttons["StartSynonyms"].tap()
        let Prompt = App.staticTexts["SynonymPrompt"]
        XCTAssertTrue(Prompt.waitForExistence(timeout: 5))
        let Correct = try XCTUnwrap(Answers.first { $0.value == Prompt.label }?.key)
        let Wrong = try XCTUnwrap(App.buttons.matching(identifier: "SynonymOption").allElementsBoundByIndex.first { $0.label != Correct })
        Wrong.tap()
        App.terminate(); App.launch(); App.buttons["OpenSynonyms"].tap()
        XCTAssertTrue(App.buttons["NextSynonym"].waitForExistence(timeout: 5))
        App.buttons["NextSynonym"].tap()
        let Choice = App.buttons.matching(identifier: "SynonymOption").matching(NSPredicate(format: "label == %@", Correct)).firstMatch
        XCTAssertTrue(Choice.waitForExistence(timeout: 5)); Choice.tap()
        App.buttons["NextSynonym"].tap()
        XCTAssertTrue(App.staticTexts["SynonymResults"].waitForExistence(timeout: 5))
        App.buttons["Back to home"].tap()
        // Synonym rounds never consume the ordinary practice pool.
        XCTAssertTrue(App.buttons["Start practice"].isHittable)
        App.buttons["Start practice"].tap()
        XCTAssertTrue(App.staticTexts["QuizPrompt"].waitForExistence(timeout: 5))
        XCTAssertTrue(App.staticTexts["1/6"].exists)
    }

}
