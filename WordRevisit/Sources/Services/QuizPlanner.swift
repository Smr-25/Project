import Foundation

enum QuizPlanner {
    static func MakeQuestions(From Entries: [WordEntry], Mode: QuizMode, Limit: Int = 20) -> [QuizQuestion] {
        Entries.sorted {
            if $0.IncorrectCount != $1.IncorrectCount {
                return $0.IncorrectCount > $1.IncorrectCount
            }
            if $0.LastReviewedAt != $1.LastReviewedAt {
                return ($0.LastReviewedAt ?? .distantPast) < ($1.LastReviewedAt ?? .distantPast)
            }
            return $0.Term.localizedStandardCompare($1.Term) == .orderedAscending
        }
        .prefix(max(0, Limit))
        .map { QuizQuestion(Entry: $0, Mode: Mode) }
    }

    static func Matches(_ Input: String, Answer: String) -> Bool {
        let NormalizedInput = Normalize(Input)
        return Answer.split(whereSeparator: { $0 == ";" || $0 == "," })
            .map { Normalize(String($0)) }
            .contains(NormalizedInput)
    }

    private static func Normalize(_ Value: String) -> String {
        Value.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: Locale(identifier: "az_AZ"))
            .replacingOccurrences(of: "ə", with: "e")
            .replacingOccurrences(of: "ı", with: "i")
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "az_AZ"))
    }
}
