import Foundation

struct WordEntry: Codable, Identifiable, Equatable {
    var Id: UUID
    var Term: String
    var Translation: String
    var Definition: String
    var CorrectCount: Int
    var IncorrectCount: Int
    var LastReviewedAt: Date?

    var id: UUID { Id }

    init(
        Id: UUID = UUID(),
        Term: String,
        Translation: String,
        Definition: String = "",
        CorrectCount: Int = 0,
        IncorrectCount: Int = 0,
        LastReviewedAt: Date? = nil
    ) {
        self.Id = Id
        self.Term = Term
        self.Translation = Translation
        self.Definition = Definition
        self.CorrectCount = CorrectCount
        self.IncorrectCount = IncorrectCount
        self.LastReviewedAt = LastReviewedAt
    }
}

enum QuizMode: String, CaseIterable, Identifiable {
    case Easy
    case Hard

    var id: String { rawValue }

    var Title: String { self == .Easy ? "Easy recall" : "Hard recall" }
    var Subtitle: String { self == .Easy ? "English → Azerbaijani" : "Azerbaijani → English" }
    var Symbol: String { self == .Easy ? "character.bubble.fill" : "bolt.fill" }
}

struct QuizQuestion: Identifiable {
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
}

struct QuizRecord: Codable, Identifiable {
    var Id: UUID = UUID()
    var Date: Date = .now
    var Mode: String
    var Correct: Int
    var Total: Int

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
