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
        print("Logic checks passed")
    }
}
