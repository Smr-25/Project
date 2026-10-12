import Foundation

enum QuizPlanner {
    static func MakeQuestions(From Entries: [WordEntry], Mode: QuizMode, Limit: Int = 20,
                              Now: Date = .now, IncludeUpcoming: Bool = false, Choices: Bool = false) -> [QuizQuestion] {
        Entries.shuffled().filter { $0.Learning.IsAvailable(at: Now) && (IncludeUpcoming || ReviewSchedule.IsDue($0, Now: Now)) }.sorted {
            if $0.IncorrectCount != $1.IncorrectCount {
                return $0.IncorrectCount > $1.IncorrectCount
            }
            if $0.LastReviewedAt != $1.LastReviewedAt {
                return ($0.LastReviewedAt ?? .distantPast) < ($1.LastReviewedAt ?? .distantPast)
            }
            return false
        }
        .lazy.compactMap { Entry -> QuizQuestion? in
            var Question = QuizQuestion(Entry: Entry, Mode: Mode)
            if Choices && Mode != .Hard {
                guard let Options = ChoiceOptions(For: Entry, From: Entries, EnglishPrompt: Mode == .Easy, Now: Now) else { return nil }
                Question.Options = Options
            }
            return Question
        }
        .prefix(max(0, Limit)).map { $0 }
    }

    static func ChoiceOptions(For Entry: WordEntry, From Entries: [WordEntry], EnglishPrompt: Bool, Now: Date) -> [String]? {
        let Correct = EnglishPrompt ? String(Entry.Translation.split(whereSeparator: { $0 == ";" || $0 == "," }).first ?? "") : Entry.Term
        let Candidates = Entries.filter {
            $0.Id != Entry.Id && $0.Learning.IsAvailable(at: Now) && !LearningEngine.Similar(Entry, $0)
            && (Entry.PartOfSpeech.isEmpty || $0.PartOfSpeech.localizedCaseInsensitiveCompare(Entry.PartOfSpeech) == .orderedSame)
            && Normalize($0.Term) != Normalize(Entry.Term)
        }.shuffled().sorted { abs($0.Term.count - Entry.Term.count) < abs($1.Term.count - Entry.Term.count) }
        var Options = [Correct]
        for Other in Candidates {
            let Option = EnglishPrompt ? String(Other.Translation.split(whereSeparator: { $0 == ";" || $0 == "," }).first ?? "") : Other.Term
            if !Options.contains(where: { Normalize($0) == Normalize(Option) }) { Options.append(Option) }
            if Options.count == 4 { break }
        }
        return Options.count == 4 ? Options.shuffled() : nil
    }

    static func Matches(_ Input: String, Answer: String) -> Bool {
        let NormalizedInput = Normalize(Input)
        guard !NormalizedInput.isEmpty else { return false }
        return Answer.split(whereSeparator: { $0 == ";" || $0 == "," })
            .map { Normalize(String($0)) }
            .contains(NormalizedInput)
    }

    static func Normalize(_ Value: String) -> String {
        Value.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: Locale(identifier: "az_AZ"))
            .replacingOccurrences(of: "ə", with: "e")
            .replacingOccurrences(of: "ı", with: "i")
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "az_AZ"))
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
