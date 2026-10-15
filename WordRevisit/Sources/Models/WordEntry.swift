import Foundation

struct WordEntry: Codable, Identifiable, Equatable {
    var Id = UUID()
    var Term: String
    var Translation: String
    var Group = ""
    var id: UUID { Id }

    init(Id: UUID = UUID(), Term: String, Translation: String, Group: String = "") {
        self.Id = Id; self.Term = Term; self.Translation = Translation; self.Group = Group
    }

    private enum CodingKeys: String, CodingKey { case Id, Term, Translation, Group }
    init(from Decoder: Decoder) throws {
        let Values = try Decoder.container(keyedBy: CodingKeys.self)
        Id = try Values.decode(UUID.self, forKey: .Id)
        Term = try Values.decode(String.self, forKey: .Term)
        Translation = try Values.decode(String.self, forKey: .Translation)
        Group = try Values.decodeIfPresent(String.self, forKey: .Group) ?? ""
    }
}

enum QuizMode: String, Codable, CaseIterable, Identifiable {
    case Easy, Hard
    var id: String { rawValue }
    var Title: String { self == .Easy ? "Easy practice" : "Hard practice" }
    var Subtitle: String { self == .Easy ? "Mixed directions · choose an answer" : "Azerbaijani → English · write" }
}

enum QuizDirection: String, Codable { case EnglishToAzerbaijani, AzerbaijaniToEnglish }

struct QuizQuestion: Codable, Identifiable {
    var Entry: WordEntry
    var Mode: QuizMode
    // Optional fields allow the original 1.2 answer history to remain readable.
    var Direction: QuizDirection?
    var Options: [String]?
    var Alternatives: [String]?
    var id: UUID { Entry.Id }
    var IsEnglishPrompt: Bool { (Direction ?? (Mode == .Easy ? .EnglishToAzerbaijani : .AzerbaijaniToEnglish)) == .EnglishToAzerbaijani }
    var Prompt: String { IsEnglishPrompt ? Entry.Term : Entry.Translation }
    var Answer: String { IsEnglishPrompt ? Entry.Translation : Entry.Term }
}

struct QuizAnswer: Codable, Identifiable {
    var Question: QuizQuestion
    var Input: String
    var IsCorrect: Bool
    var Alternative: Bool? = nil
    var id: UUID { Question.id }
}

struct QuizRecord: Codable, Identifiable {
    var Id = UUID()
    var Date = Foundation.Date.now
    var Mode: String
    var Correct: Int
    var Total: Int
    var Answers: [QuizAnswer]?
    var RetryAnswers: [QuizAnswer]?
    var id: UUID { Id }
}

enum AppAppearance: String, Codable, CaseIterable, Identifiable {
    case System, Light, Dark
    var id: String { rawValue }
}

struct VocabularyGroup: Identifiable, Codable {
    let Code: String
    let Name: String
    let Words: [WordEntry]
    var id: String { Code }

    static func Make(_ Entries: [WordEntry], Search: String = "") -> [VocabularyGroup] {
        let ByTerm = Dictionary(Entries.map { (QuizPlanner.Normalize($0.Term), $0) }, uniquingKeysWith: { First, _ in First })
        let Query = QuizPlanner.Normalize(Search)
        return SynonymCatalog.Families.compactMap { Family in
            let Words = Family.Terms.compactMap { Term -> WordEntry? in
                guard let Word = ByTerm[Term], SynonymCatalog.Parts(SynonymCatalog.CanonicalGroups(Word.Group, Term: Word.Term))
                    .map(QuizPlanner.Normalize).contains(Family.Code) else { return nil }
                return Word
            }
            guard Words.count >= 2 else { return nil }
            guard Query.isEmpty || Family.Code.contains(Query) || QuizPlanner.Normalize(Family.Sense).contains(Query) || Words.contains(where: {
                QuizPlanner.Normalize($0.Term).contains(Query) || QuizPlanner.Normalize($0.Translation).contains(Query)
            }) else { return nil }
            return VocabularyGroup(Code: Family.Code, Name: Family.Sense, Words: Words)
        }
    }
}
