import Foundation

@main
enum RepositoryChecks {
    @MainActor
    static func main() throws {
        let Directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: Directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: Directory) }
        let URL = Directory.appendingPathComponent("Words.json")
        let Legacy = """
        {"Entries":[{"Id":"\(UUID())","Term":"fell","Translation":"ağacı kəsmək","Definition":"","CorrectCount":3,"IncorrectCount":1}],
        "History":[{"Id":"\(UUID())","Date":0,"Mode":"Easy","Correct":12,"Total":20}],
        "Morning":{"Hour":9,"Minute":0},"Evening":{"Hour":19,"Minute":0},"RemindersEnabled":false}
        """
        try Data(Legacy.utf8).write(to: URL)
        let Store = WordRepository(FileURL: URL)
        assert(Store.ErrorMessage == nil && Store.Entries.count == 1)
        assert(Store.History.count == 1 && Store.History[0].Correct == 12)
        var Word = Store.Entries[0]
        assert(Word.CorrectCount == 3 && Word.Translation.contains("ağac kəsmək"))
        Word.ExampleSentences = "They fell trees."
        Store.Update(Word)
        let Session = QuizSession(Mode: .Easy, Questions: QuizPlanner.MakeQuestions(From: Store.Entries, Mode: .Easy))
        var Run = QuizRun(Session: Session)
        let Answer = Run.Submit("agac kesmek", For: Word.id)!
        Store.RecordAnswer(For: Word.id, IsCorrect: Answer.IsCorrect)
        assert(Run.CurrentQuestion?.id == Word.id)
        assert(QuizPlanner.MakeQuestions(From: Store.Entries, Mode: .Easy).isEmpty)
        assert(Run.Advance(From: Word.id))
        Store.FinishQuiz(Mode: .Easy, Answers: Run.OriginalAnswers, IsPractice: false)
        let Reloaded = WordRepository(FileURL: URL)
        assert(Reloaded.Entries[0].ExampleSentences == "They fell trees.")
        assert(Reloaded.Entries[0].CorrectCount == 4 && Reloaded.Entries[0].NextReviewAt != nil)
        assert(Reloaded.History.count == 2 && Reloaded.History[0].Answers?.first?.Input == "agac kesmek")
        assert(Reloaded.History[1].Answers == nil)
        let BrokenURL = Directory.appendingPathComponent("Broken.json")
        let BrokenData = Data("{broken".utf8)
        try BrokenData.write(to: BrokenURL)
        let Broken = WordRepository(FileURL: BrokenURL)
        assert(Broken.ErrorMessage != nil)
        assert(!Broken.Add(Term: "word", Translation: "söz", Definition: ""))
        let PreservedData = try Data(contentsOf: BrokenURL)
        assert(PreservedData == BrokenData)
        try CheckVersion2Upgrade(Directory: Directory)
        print("Repository migration and persistence checks passed")
    }
    @MainActor
    private static func CheckVersion2Upgrade(Directory: URL) throws {
        // This fixture was encoded by the unchanged 2.0 app with seven study days and a saved session.
        let FixtureURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/Version2Backup.json")
        let Original = try Data(contentsOf: FixtureURL)
        let URL = Directory.appendingPathComponent("Version2.json")
        try Original.write(to: URL)
        let Store = WordRepository(FileURL: URL)
        assert(Store.ErrorMessage == nil && Store.Appearance == .System)
        assert(Store.Learning.Days.count == 7 && Store.Learning.Session?.Current?.Input == "wat")
        assert(Store.History[0].Answers?[0].Question.Options == nil)
        let Recovery = URL.appendingPathExtension("before-schema-3")
        let RecoveryData = try Data(contentsOf: Recovery)
        assert(RecoveryData == Original)
        func Content(_ Data: Data) throws -> NSDictionary {
            var Object = try JSONSerialization.jsonObject(with: Data) as! [String: Any]
            Object.removeValue(forKey: "SchemaVersion"); Object.removeValue(forKey: "Appearance")
            return Object as NSDictionary
        }
        func AssertContent(_ Data: Data, Expected: NSDictionary) throws {
            let Actual = try Content(Data)
            assert(Actual == Expected)
        }
        let Expected = try Content(Original)
        let Upgraded = try Store.ExportBackup()
        let UpgradedContent = try Content(Upgraded)
        assert(UpgradedContent == Expected)
        Store.SetAppearance(.Light)
        let Reopened = WordRepository(FileURL: URL)
        assert(Reopened.Appearance == .Light)
        try AssertContent(Reopened.ExportBackup(), Expected: Expected)
        let CleanURL = Directory.appendingPathComponent("CleanInstall.json")
        let Clean = WordRepository(FileURL: CleanURL)
        try Clean.RestoreBackup(Original)
        assert(Clean.Appearance == .System)
        try AssertContent(Clean.ExportBackup(), Expected: Expected)
        Clean.SetAppearance(.Dark)
        let NewBackup = try Clean.ExportBackup()
        try Reopened.RestoreBackup(NewBackup)
        assert(Reopened.Appearance == .Dark)
        try AssertContent(Reopened.ExportBackup(), Expected: Expected)
        let BeforeInvalid = try Data(contentsOf: URL)
        var Future = try JSONSerialization.jsonObject(with: Original) as! [String: Any]
        Future["SchemaVersion"] = 99
        do {
            try Reopened.RestoreBackup(JSONSerialization.data(withJSONObject: Future))
            assertionFailure("Future schema accepted")
        } catch {}
        let AfterInvalid = try Data(contentsOf: URL)
        assert(AfterInvalid == BeforeInvalid)
        try Reopened.RestoreBackup(Original)
        try AssertContent(Reopened.ExportBackup(), Expected: Expected)
        let StillPreserved = try Data(contentsOf: Recovery)
        assert(StillPreserved == Original)
        print("2.0 upgrade, seven-day history, saved session, appearance and backup restore checks passed")
    }

}
