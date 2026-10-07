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
        assert(QuizPlanner.Matches(" DÖZÜMLÜ ", Answer: Difficult.Translation))
        assert(!QuizPlanner.Matches("curious", Answer: Difficult.Translation))

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
