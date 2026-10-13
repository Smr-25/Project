import Foundation

enum QuizPlanner {
    static func Normalize(_ Value: String) -> String {
        Value.lowercased(with: Locale(identifier: "en_US_POSIX"))
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    static func Meanings(_ Value: String) -> Set<String> {
        Set(Value.split(separator: ";").map { Normalize(String($0)) }.filter { !$0.isEmpty })
    }

    static func SharesMeaning(_ A: WordEntry, _ B: WordEntry) -> Bool {
        !Meanings(A.Translation).isDisjoint(with: Meanings(B.Translation))
    }

    static func MakeQuestions(_ Selected: [WordEntry], From All: [WordEntry], Mode: QuizMode) -> [QuizQuestion] {
        let EnglishCount = Mode == .Easy ? Selected.count / 2 + (Selected.count % 2 == 1 && Bool.random() ? 1 : 0) : 0
        let Directions = (Array(repeating: QuizDirection.EnglishToAzerbaijani, count: EnglishCount)
            + Array(repeating: .AzerbaijaniToEnglish, count: Selected.count - EnglishCount)).shuffled()
        return zip(Selected.shuffled(), Directions).map { Entry, Direction in
            var Question = QuizQuestion(Entry: Entry, Mode: Mode, Direction: Direction,
                Alternatives: All.filter { SharesMeaning(Entry, $0) && $0.Id != Entry.Id }.map(\.Term))
            if Mode == .Easy {
                let EnglishPrompt = Direction == .EnglishToAzerbaijani
                func Label(_ Word: WordEntry) -> String {
                    EnglishPrompt ? String(Word.Translation.split(separator: ";").first ?? "").trimmingCharacters(in: .whitespacesAndNewlines) : Word.Term
                }
                var Options = [Label(Entry)]
                for Other in All.shuffled() where Other.Id != Entry.Id && Normalize(Other.Term) != Normalize(Entry.Term) && !SharesMeaning(Entry, Other) {
                    let Option = Label(Other)
                    if !Options.contains(where: { Normalize($0) == Normalize(Option) }) { Options.append(Option) }
                    if Options.count == 4 { break }
                }
                if Options.count >= 2 { Question.Options = Options.shuffled() }
                else {
                    // A single distinct meaning cannot form a choice question; keep the word in this cycle with written recall.
                    Question.Direction = .AzerbaijaniToEnglish
                }
            }
            return Question
        }
    }
}
