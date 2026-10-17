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

    var IsCatalogued: Bool { SynonymCatalog.Families.contains { $0.Code == Code } }

    static func Make(_ Entries: [WordEntry], Search: String = "", Meanings: [String: String] = [:], CatalogOnly: Bool = false) -> [VocabularyGroup] {
        var Members: [String: [WordEntry]] = [:]
        var Codes: [String] = []
        for Word in Entries {
            for Code in Set(SynonymCatalog.Parts(SynonymCatalog.CanonicalGroups(Word.Group, Term: Word.Term)).map(QuizPlanner.Normalize)).sorted() {
                if Members[Code] == nil { Codes.append(Code) }
                Members[Code, default: []].append(Word)
            }
        }
        let Catalogue = Dictionary(uniqueKeysWithValues: SynonymCatalog.Families.map { ($0.Code, $0) })
        let OrderedCodes = SynonymCatalog.Families.map(\.Code) + Codes.filter { Catalogue[$0] == nil }
        let Query = QuizPlanner.Normalize(Search)
        return OrderedCodes.compactMap { Code in
            var Words = Members[Code] ?? []
            let Name: String
            if let Family = Catalogue[Code] {
                let ByTerm = Dictionary(Words.map { (QuizPlanner.Normalize($0.Term), $0) }, uniquingKeysWith: { First, _ in First })
                let Reviewed = Family.Terms.compactMap { ByTerm[$0] }
                // Old saved synonym pools must be validated against their original catalogue rules.
                Words = Reviewed + (CatalogOnly ? [] : Words.filter { !Family.Terms.contains(QuizPlanner.Normalize($0.Term)) })
                Name = Family.Sense
            } else {
                guard !CatalogOnly else { return nil }
                if let Head = Words.firstIndex(where: { QuizPlanner.Normalize($0.Term).hasPrefix(String(Code.prefix(3))) }) {
                    Words.insert(Words.remove(at: Head), at: 0)
                }
                Name = Meanings[Code] ?? ""
            }
            guard Words.count >= 2 else { return nil }
            guard Query.isEmpty || Code.contains(Query) || QuizPlanner.Normalize(Name).contains(Query) || Words.contains(where: {
                QuizPlanner.Normalize($0.Term).contains(Query) || QuizPlanner.Normalize($0.Translation).contains(Query)
            }) else { return nil }
            return VocabularyGroup(Code: Code, Name: Name, Words: Words)
        }
    }
}
