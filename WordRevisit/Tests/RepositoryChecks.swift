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
        print("Repository migration and persistence checks passed")
    }
}
