import Foundation

@main
enum LogicChecks {
    static func main() throws {
        let Difficult = WordEntry(Term: "resilient", Translation: "dözümlü; davamlı", IncorrectCount: 3)
        let Recent = WordEntry(Term: "curious", Translation: "maraqlı", LastReviewedAt: .now)
        let Questions = QuizPlanner.MakeQuestions(From: [Recent, Difficult], Mode: .Hard)
        assert(Questions.count == 2)
        assert(Questions[0].Prompt == "dözümlü; davamlı")
        assert(Questions[0].Answer == "resilient")
        var First = WordEntry(Term: "array", Translation: "sıra")
        let Second = WordEntry(Term: "breed", Translation: "çoxalmaq")
        let Session = QuizSession(Mode: .Easy, Questions: QuizPlanner.MakeQuestions(From: [First, Second], Mode: .Easy))
        First.LastReviewedAt = .now // Recording an answer changes the planner order.
        assert(QuizPlanner.MakeQuestions(From: [First, Second], Mode: .Easy)[0].id == Second.id)
        assert(Session.Questions[0].id == First.id)
        assert(QuizPlanner.Matches(" DÖZÜMLÜ ", Answer: Difficult.Translation))
        assert(!QuizPlanner.Matches("curious", Answer: Difficult.Translation))
        var LegacyWords = [WordEntry(Term: "fell", Translation: "ağacı kəsmək"),
                           WordEntry(Term: "fell", Translation: "my custom answer")]
        assert(StarterVocabulary.UpgradeLegacyFellTranslation(&LegacyWords))
        assert(QuizPlanner.Matches("agac kesmek", Answer: LegacyWords[0].Translation))
        assert(QuizPlanner.Matches("yasayis muhiti", Answer: "yaşayış mühiti"))
        assert(LegacyWords[1].Translation == "my custom answer")

        var Calendar = Calendar(identifier: .gregorian)
        Calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let InstalledAt = Calendar.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 9))!
        let ReminderAt = ReminderScheduler.RenewalDate(From: InstalledAt, Calendar: Calendar)!
        let ReminderDay = Calendar.dateComponents([.year, .month, .day, .hour], from: ReminderAt)
        assert(ReminderDay.year == 2026 && ReminderDay.month == 10 && ReminderDay.day == 29 && ReminderDay.hour == 9)

        let CSV = WordCSV.Encode([WordEntry(Term: "a,b", Translation: "söz", Definition: "A \"quoted\" meaning")])
        let Parsed = try WordCSV.Decode(CSV)
        assert(Parsed.count == 1)
        assert(Parsed[0].Term == "a,b")
        assert(Parsed[0].Definition == "A \"quoted\" meaning")
        assert(StarterVocabulary.Entries.count == 59)
        assert(Set(StarterVocabulary.Entries.map(\.Term)).count == 59)
        let RoundTrip = try WordCSV.Decode(WordCSV.Encode(StarterVocabulary.Entries))
        assert(RoundTrip.count == 59)
        try CheckMigrationAndExamples()
        CheckQuizFlow()
        CheckReviewSchedule()
        CheckProgress()
        print("Logic checks passed")
    }

    private static func CheckQuizFlow() {
        let First = WordEntry(Term: "fell", Translation: "ağacı kəsmək; ağac kəsmək", ExampleSentences: "They fell old trees.")
        let Second = WordEntry(Term: "breed", Translation: "çoxalmaq")
        let Questions = [First, Second].map { QuizQuestion(Entry: $0, Mode: .Easy) }
        var Run = QuizRun(Session: QuizSession(Mode: .Easy, Questions: Questions))
        assert(Run.Submit(" ", For: First.id) == nil)
        assert(!Run.Advance(From: First.id))
        assert(Run.Submit("agac   kesmek", For: First.id)?.IsCorrect == true)
        assert(Run.CurrentQuestion?.id == First.id)
        assert(Run.Submit("agac kesmek", For: First.id) == nil)
        assert(Run.Answers.count == 1)
        assert(!Run.Advance(From: First.id))
        assert(Run.CurrentQuestion?.id == Second.id)
        assert(Run.Submit("agac kesmek", For: First.id) == nil)
        assert(Run.Submit("wrong", For: Second.id)?.IsCorrect == false)
        assert(Run.Advance(From: Second.id))
        assert(!Run.Advance(From: Second.id))
        assert(Run.OriginalAnswers.count == 2 && Run.CorrectCount == 1)
        Run.RetryMissed()
        assert(Run.IsRetry && Run.Questions.count == 1 && Run.CurrentQuestion?.id == Second.id)
        assert(Run.Submit("coxalmaq", For: Second.id)?.IsCorrect == true)
        assert(Run.Advance(From: Second.id))
        assert(Run.MissedQuestions.isEmpty && Run.CorrectCount == 1)
        assert(Run.OriginalAnswers.filter(\.IsCorrect).count == 1)
        Run.RetryMissed()
        assert(Run.IsFinished)
        let Hard = QuizQuestion(Entry: First, Mode: .Hard)
        assert(Hard.Prompt == First.Translation && Hard.Answer == "fell")
        assert(Hard.Entry.ExampleSentences == Questions[0].Entry.ExampleSentences)
        let Empty = QuizRun(Session: QuizSession(Mode: .Easy, Questions: []))
        assert(Empty.CurrentQuestion == nil && Empty.SubmittedAnswer == nil)
    }

    private static func CheckReviewSchedule() {
        var Calendar = Calendar(identifier: .gregorian)
        Calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let Now = Calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 10))!
        var Word = WordEntry(Term: "fell", Translation: "ağac kəsmək")
        assert(ReviewSchedule.IsDue(Word, Now: Now))
        for Interval in [1, 3, 7, 14, 30, 30] {
            ReviewSchedule.Record(&Word, IsCorrect: true, Now: Now, Calendar: Calendar)
            assert(Word.NextReviewAt == Calendar.date(byAdding: .day, value: Interval, to: Now))
            assert(!ReviewSchedule.IsDue(Word, Now: Now))
        }
        assert(Word.CorrectCount == 6)
        let Scheduled = Word.NextReviewAt
        ReviewSchedule.Record(&Word, IsCorrect: false, Now: Now, UpdatesSchedule: false)
        assert(Word.NextReviewAt == Scheduled && Word.ReviewStreak == 5)
        assert(QuizPlanner.MakeQuestions(From: [Word], Mode: .Easy, Now: Now).isEmpty)
        assert(QuizPlanner.MakeQuestions(From: [Word], Mode: .Easy, Now: Now, IncludeUpcoming: true).count == 1)
        ReviewSchedule.Record(&Word, IsCorrect: false, Now: Now)
        assert(Word.ReviewStreak == 0 && ReviewSchedule.IsDue(Word, Now: Now))
        assert(Word.IncorrectCount == 2)
    }

    private static func CheckMigrationAndExamples() throws {
        let Id = UUID()
        let Legacy = """
        {"Id":"\(Id)","Term":"fell","Translation":"ağacı kəsmək","Definition":"","CorrectCount":3,"IncorrectCount":1}
        """
        let Word = try JSONDecoder().decode(WordEntry.self, from: Data(Legacy.utf8))
        assert(Word.Id == Id && Word.CorrectCount == 3)
        assert(Word.ExampleSentences.isEmpty && Word.ReviewStreak == 0 && Word.NextReviewAt == nil)
        let OldRecord = """
        {"Id":"\(UUID())","Date":0,"Mode":"Easy","Correct":12,"Total":20}
        """
        let Record = try JSONDecoder().decode(QuizRecord.self, from: Data(OldRecord.utf8))
        assert(Record.Answers == nil && Record.Correct == 12)
        let Example = "They said, \"Try again.\"\nSmall efforts accumulate."
        let WithExample = WordEntry(Term: "accumulate", Translation: "toplamaq", ExampleSentences: Example)
        let Imported = try WordCSV.Decode(WordCSV.Encode([WithExample]))
        assert(Imported[0].ExampleSentences == Example)
        let OldCSV = try WordCSV.Decode("English,Azerbaijani,Definition\nfell,ağac kəsmək,To cut down a tree\n")
        assert(OldCSV[0].ExampleSentences.isEmpty)
        let SavedWord = try JSONDecoder().decode(WordEntry.self, from: JSONEncoder().encode(WithExample))
        assert(SavedWord == WithExample)
    }

    private static func CheckProgress() {
        var Calendar = Calendar(identifier: .gregorian)
        Calendar.timeZone = TimeZone(identifier: "Asia/Baku")!
        let Now = Calendar.date(from: DateComponents(year: 2026, month: 10, day: 9, hour: 0, minute: 30))!
        func Record(_ Days: Int, _ Correct: Int, _ Total: Int) -> QuizRecord {
            QuizRecord(Date: Calendar.date(byAdding: .day, value: Days, to: Now)!, Mode: "Easy", Correct: Correct, Total: Total)
        }
        let History = [Record(0, 10, 20), Record(0, 5, 5), Record(-1, 7, 10), Record(-2, 2, 5), Record(-6, 1, 2), Record(-7, 1, 2)]
        let Progress = StudyProgress(History: History, Now: Now, Calendar: Calendar)
        assert(Progress.Week.count == 7 && Progress.WeeklyAnswers == 42)
        assert(Progress.ActiveDays == 4 && Progress.Streak == 3)
        assert(Progress.Accuracy == 59)
        let Yesterday = StudyProgress(History: [Record(-1, 1, 2)], Now: Now, Calendar: Calendar)
        assert(Yesterday.Streak == 1)
        assert(StudyProgress(History: [Record(-2, 1, 2)], Now: Now, Calendar: Calendar).Streak == 0)
        assert(StudyProgress(History: [], Now: Now, Calendar: Calendar).WeeklyAnswers == 0)
    }
}
