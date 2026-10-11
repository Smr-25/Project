import Foundation

struct LearningSettings: Codable, Equatable {
    var NewPerDay = 20
    var Batches = 2
    var DayStartHour = 4
    var MinimumCards = 15
    var HalfAbove = 100
    var PauseAbove = 150
    var ResumeBelow = 100
    var ReviewLimit = 200
    var ComebackDays = 2
    var ComebackLimit = 40
    var LearningMinutes = [1, 10]
    var Intervals = [1, 2, 4, 8, 16, 30, 60, 120, 180]
    var FuzzPercent = 10
    var ChoiceSeconds = 5
    var TypingSeconds = 12
    var AllowTypos = true
    var WrongDrop = 2
    var RepeatGap = 3
    var CorrectAfterWrong = 2
    var LeechThreshold = 4
    var ActiveLeeches = 15
    var LeechPauseDays = 7
    var SimilarGap = 5
    var FreezeEvery = 7
    var MaxFreezes = 2
    var BackupReminder = false
    var BackupDays = 7
    var QuietStart = 23
    var QuietEnd = 7

    var IsValid: Bool {
        (0...100).contains(NewPerDay) && [1, 2, 4].contains(Batches) && (0...23).contains(DayStartHour)
        && (1...200).contains(MinimumCards) && HalfAbove > 0 && PauseAbove > HalfAbove
        && (1...HalfAbove).contains(ResumeBelow) && (1...500).contains(ReviewLimit)
        && (1...30).contains(ComebackDays) && (1...ReviewLimit).contains(ComebackLimit)
        && LearningMinutes.count == 2 && LearningMinutes.allSatisfy { (1...120).contains($0) }
        && Intervals.count == 9 && Intervals.allSatisfy { (1...365).contains($0) }
        && zip(Intervals, Intervals.dropFirst()).allSatisfy { $0 <= $1 }
        && (0...25).contains(FuzzPercent) && (1...120).contains(ChoiceSeconds) && (1...300).contains(TypingSeconds)
        && (1...9).contains(WrongDrop) && (3...5).contains(RepeatGap) && (1...5).contains(CorrectAfterWrong)
        && (1...20).contains(LeechThreshold) && (1...100).contains(ActiveLeeches) && (1...30).contains(LeechPauseDays)
        && (0...20).contains(SimilarGap) && (1...30).contains(FreezeEvery) && (0...10).contains(MaxFreezes)
        && (1...30).contains(BackupDays) && (0...23).contains(QuietStart) && (0...23).contains(QuietEnd)
    }
}

struct WordLearning: Codable, Equatable {
    var Stage = 0
    var IntervalDays = 0
    var Reps = 0
    var Lapses = 0
    var ResponseMs = 0
    var CreatedAt = Date.now
    var IntroducedAt: Date?
    var LearningStep = 0
    var Suspended = false
    var SuspendedUntil: Date?
    var RecoveryRemaining = 0

    func IsAvailable(at Date: Date) -> Bool {
        !Suspended && (SuspendedUntil == nil || SuspendedUntil! <= Date)
    }
}

enum StudyKind: String, Codable {
    case Introduction, EnglishChoice, TranslationChoice, DefinitionChoice, ClozeChoice
    case TranslationWriting, ClozeWriting, DefinitionWriting, Synonym
    var IsChoice: Bool { [.EnglishChoice, .TranslationChoice, .DefinitionChoice, .ClozeChoice, .Synonym].contains(self) }
}

enum RecallResult: String, Codable {
    case Correct, Hard, Wrong, DontKnow
    var IsCorrect: Bool { self == .Correct || self == .Hard }
}

struct StudyCard: Codable, Identifiable {
    var id = UUID()
    var WordId: UUID
    var Kind: StudyKind
    var Prompt: String
    var Expected: String
    var Options: [String] = []
    var ReadyAt: Date
    var Input = ""
    var Result: RecallResult?
    var HintUsed = false
}

struct StudyLog: Codable, Identifiable {
    var id = UUID()
    var WordId: UUID
    var Date: Date
    var Day: String
    var Kind: StudyKind
    var Result: RecallResult
    var ResponseMs: Int
    var StageBefore: Int
    var StageAfter: Int
    var Prompt: String
    var Input: String
    var Expected: String
    var IsPractice = false
}

struct LearningDay: Codable, Identifiable {
    var id: String
    var Introduced: [UUID] = []
    var Reviewed: [UUID] = []
    var Completed: [UUID] = []
    var Attempted: [UUID] = []
    var NewLimit: Int
    var ReviewLimit: Int
    var Target: Int
    var Comeback: Bool
    var MinimumMet = false
    var FullMet = false
}

struct StudySession: Codable, Identifiable {
    var id = UUID()
    var Cards: [StudyCard]
    var Finished: [StudyLog] = []
    var IsPractice = false
    var Current: StudyCard? { Cards.first }
}

struct LearningData: Codable {
    var CreatedAt = Date.now
    var Settings = LearningSettings()
    var Days: [LearningDay] = []
    var Logs: [StudyLog] = []
    var Session: StudySession?
    var IntakePaused = false
    var LastBackupAt: Date?
}

struct StreakSummary {
    var Current = 0
    var Best = 0
    var Freezes = 0
}
