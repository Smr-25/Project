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

struct VocabularyGroup: Identifiable {
    let Name: String
    let Words: [WordEntry]
    var id: String { QuizPlanner.Normalize(Name) }

    static func Make(_ Entries: [WordEntry], Search: String = "") -> [VocabularyGroup] {
        var Names: [String] = []
        var Groups: [String: [WordEntry]] = [:]
        for Word in Entries where !Word.Group.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let Key = QuizPlanner.Normalize(Word.Group)
            if Groups[Key] == nil { Names.append(Key) }
            Groups[Key, default: []].append(Word)
        }
        return Names.compactMap { Key in
            guard let Words = Groups[Key], let First = Words.first else { return nil }
            let Query = QuizPlanner.Normalize(Search)
            guard Query.isEmpty || QuizPlanner.Normalize(First.Group).contains(Query) || Words.contains(where: {
                QuizPlanner.Normalize($0.Term).contains(Query) || QuizPlanner.Normalize($0.Translation).contains(Query)
            }) else { return nil }
            return VocabularyGroup(Name: First.Group, Words: Words)
        }
    }
}
