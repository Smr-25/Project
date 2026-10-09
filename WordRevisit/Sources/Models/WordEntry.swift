import Foundation

struct WordEntry: Codable, Identifiable, Equatable {
    var Id: UUID
    var Term: String
    var Translation: String
    var Definition: String
    var CorrectCount: Int
    var IncorrectCount: Int
    var LastReviewedAt: Date?
    var ExampleSentences: String
    var ReviewStreak: Int
    var NextReviewAt: Date?

    var id: UUID { Id }

    init(
        Id: UUID = UUID(),
        Term: String,
        Translation: String,
        Definition: String = "",
        CorrectCount: Int = 0,
        IncorrectCount: Int = 0,
        LastReviewedAt: Date? = nil,
        ExampleSentences: String = "",
        ReviewStreak: Int = 0,
        NextReviewAt: Date? = nil
    ) {
        self.Id = Id
        self.Term = Term
        self.Translation = Translation
        self.Definition = Definition
        self.CorrectCount = CorrectCount
        self.IncorrectCount = IncorrectCount
        self.LastReviewedAt = LastReviewedAt
        self.ExampleSentences = ExampleSentences
        self.ReviewStreak = ReviewStreak
        self.NextReviewAt = NextReviewAt
    }

    private enum CodingKeys: String, CodingKey {
        case Id, Term, Translation, Definition, CorrectCount, IncorrectCount, LastReviewedAt
        case ExampleSentences, ReviewStreak, NextReviewAt
    }

    init(from Decoder: Decoder) throws {
        let Values = try Decoder.container(keyedBy: CodingKeys.self)
        Id = try Values.decode(UUID.self, forKey: .Id)
        Term = try Values.decode(String.self, forKey: .Term)
        Translation = try Values.decode(String.self, forKey: .Translation)
        Definition = try Values.decode(String.self, forKey: .Definition)
        CorrectCount = try Values.decode(Int.self, forKey: .CorrectCount)
        IncorrectCount = try Values.decode(Int.self, forKey: .IncorrectCount)
        LastReviewedAt = try Values.decodeIfPresent(Date.self, forKey: .LastReviewedAt)
        ExampleSentences = try Values.decodeIfPresent(String.self, forKey: .ExampleSentences) ?? ""
        ReviewStreak = try Values.decodeIfPresent(Int.self, forKey: .ReviewStreak) ?? 0
        NextReviewAt = try Values.decodeIfPresent(Date.self, forKey: .NextReviewAt)
    }
}

enum QuizMode: String, Codable, CaseIterable, Identifiable {
    case Easy
    case Hard

    var id: String { rawValue }

    var Title: String { self == .Easy ? "Easy recall" : "Hard recall" }
    var Subtitle: String { self == .Easy ? "English → Azerbaijani" : "Azerbaijani → English" }
    var Symbol: String { self == .Easy ? "character.bubble.fill" : "bolt.fill" }
}

struct QuizQuestion: Codable, Identifiable {
    let Entry: WordEntry
    let Mode: QuizMode

    var id: UUID { Entry.Id }
    var Prompt: String { Mode == .Easy ? Entry.Term : Entry.Translation }
    var Answer: String { Mode == .Easy ? Entry.Translation : Entry.Term }
}

struct QuizSession: Identifiable {
    let id = UUID()
    let Mode: QuizMode
    let Questions: [QuizQuestion]
    var IsPractice = false
}

struct QuizAnswer: Codable, Identifiable {
    let Question: QuizQuestion
    let Input: String
    let IsCorrect: Bool

    var id: UUID { Question.id }
}

struct QuizRecord: Codable, Identifiable {
    var Id: UUID = UUID()
    var Date: Date = .now
    var Mode: String
    var Correct: Int
    var Total: Int
    var Answers: [QuizAnswer]?
    var IsPractice: Bool?

    var id: UUID { Id }
}

struct ReminderTime: Codable, Equatable {
    var Hour: Int
    var Minute: Int

    var DateValue: Date {
        Calendar.current.date(from: DateComponents(hour: Hour, minute: Minute)) ?? .now
    }

    init(Hour: Int, Minute: Int) {
        self.Hour = Hour
        self.Minute = Minute
    }

    init(DateValue: Date) {
        let Components = Calendar.current.dateComponents([.hour, .minute], from: DateValue)
        Hour = Components.hour ?? 9
        Minute = Components.minute ?? 0
    }
}
