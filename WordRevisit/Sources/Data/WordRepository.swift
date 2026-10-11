import Foundation
import SwiftUI

struct SavedData: Codable {
    var SchemaVersion: Int? = 2
    var Learning: LearningData?
    var Entries: [WordEntry]
    var History: [QuizRecord]
    var Morning: ReminderTime
    var Evening: ReminderTime
    var RemindersEnabled: Bool
    var XcodeInstalledAt: Date?
    var RenewalReminderEnabled: Bool?
}

@MainActor
final class WordRepository: ObservableObject {
    @Published var PresentStudy = false
    @Published private(set) var Learning = LearningData()
    @Published private(set) var Entries: [WordEntry] = []
    @Published private(set) var History: [QuizRecord] = []
    @Published var Morning = ReminderTime(Hour: 9, Minute: 0)
    @Published var Evening = ReminderTime(Hour: 20, Minute: 30)
    @Published var RemindersEnabled = false
    @Published var XcodeInstalledAt: Date?
    @Published var RenewalReminderEnabled = false
    @Published var ErrorMessage: String?

    private var CanSave = true
    private let FileURL: URL

    init(FileURL: URL? = nil) {
        self.FileURL = FileURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WordRevisit.json")
        Load()
    }

    var TotalReviewed: Int { History.reduce(0) { $0 + $1.Total } }
    var Accuracy: Int {
        guard TotalReviewed > 0 else { return 0 }
        return Int(Double(History.reduce(0) { $0 + $1.Correct }) / Double(TotalReviewed) * 100)
    }

    @discardableResult
    func Add(Term: String, Translation: String, Definition: String, ExampleSentences: String = "") -> Bool {
        guard CanSave else { return false }
        let CleanTerm = Term.trimmingCharacters(in: .whitespacesAndNewlines)
        let CleanTranslation = Translation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !CleanTerm.isEmpty, !CleanTranslation.isEmpty else { return false }
        guard !Entries.contains(where: {
            $0.Term.localizedCaseInsensitiveCompare(CleanTerm) == .orderedSame &&
            $0.Translation.localizedCaseInsensitiveCompare(CleanTranslation) == .orderedSame
        }) else { return false }
        Entries.append(WordEntry(Term: CleanTerm, Translation: CleanTranslation,
                                 Definition: Definition.trimmingCharacters(in: .whitespacesAndNewlines),
                                 ExampleSentences: ExampleSentences.trimmingCharacters(in: .whitespacesAndNewlines)))
        Save()
        return true
    }

    func Update(_ Entry: WordEntry) {
        guard CanSave, let Index = Entries.firstIndex(where: { $0.Id == Entry.Id }) else { return }
        Entries[Index] = Entry
        Save()
    }

    func Delete(_ Entry: WordEntry) {
        guard CanSave else { return }
        Delete(Ids: [Entry.Id])
    }

    func Import(_ Imported: [WordEntry]) -> Int {
        guard CanSave else { return 0 }
        var Added = 0
        for Entry in Imported {
            let Duplicate = Entries.contains {
                $0.Term.localizedCaseInsensitiveCompare(Entry.Term) == .orderedSame &&
                $0.Translation.localizedCaseInsensitiveCompare(Entry.Translation) == .orderedSame
            }
            if !Duplicate {
                Entries.append(Entry)
                Added += 1
            }
        }
        if Added > 0 { Save() }
        return Added
    }

    func RecordAnswer(For Id: UUID, IsCorrect: Bool, UpdatesSchedule: Bool = true) {
        guard CanSave, let Index = Entries.firstIndex(where: { $0.Id == Id }) else { return }
        ReviewSchedule.Record(&Entries[Index], IsCorrect: IsCorrect, UpdatesSchedule: UpdatesSchedule)
        Save()
    }

    func FinishQuiz(Mode: QuizMode, Answers: [QuizAnswer], IsPractice: Bool) {
        guard CanSave else { return }
        History.insert(QuizRecord(Mode: Mode.rawValue, Correct: Answers.filter(\.IsCorrect).count,
                                 Total: Answers.count, Answers: Answers, IsPractice: IsPractice), at: 0)
        Save()
    }

    func SaveSettings() { if CanSave { Save() } }

    private func Load() {
        guard FileManager.default.fileExists(atPath: FileURL.path) else {
            Entries = StarterVocabulary.Entries
            Save()
            return
        }
        do {
            let Data = try Data(contentsOf: FileURL)
            let Saved = try JSONDecoder().decode(SavedData.self, from: Data)
            try Validate(Saved)
            Learning = Saved.Learning ?? LearningData()
            if Saved.Learning == nil {
                let OldDays = Set(Saved.History.filter { $0.Total > 0 }.map { StudyCalendar.Key($0.Date, Hour: Learning.Settings.DayStartHour) })
                Learning.Days = OldDays.sorted().map { LearningDay(id: $0, NewLimit: 20, ReviewLimit: 200, Target: 0, Comeback: false, MinimumMet: true) }
            }
            Entries = Saved.Entries
            History = Saved.History
            Morning = Saved.Morning
            Evening = Saved.Evening
            RemindersEnabled = Saved.RemindersEnabled
            XcodeInstalledAt = Saved.XcodeInstalledAt
            RenewalReminderEnabled = Saved.RenewalReminderEnabled ?? false
            if StarterVocabulary.UpgradeLegacyFellTranslation(&Entries) { Save() }
        } catch {
            CanSave = false
            ErrorMessage = "Your saved words could not be opened. The file was left untouched: \(error.localizedDescription)"
        }
    }

    @discardableResult
    private func Save() -> Bool {
        do {
            let Snapshot = SavedData(Learning: Learning, Entries: Entries, History: History, Morning: Morning,
                                     Evening: Evening, RemindersEnabled: RemindersEnabled,
                                     XcodeInstalledAt: XcodeInstalledAt,
                                     RenewalReminderEnabled: RenewalReminderEnabled)
            let Data = try JSONEncoder().encode(Snapshot)
            try Data.write(to: FileURL, options: .atomic)
            return true
        } catch {
            ErrorMessage = "Could not save your words: \(error.localizedDescription)"
            return false
        }
    }

}

extension WordRepository {
    var TodayKey: String { StudyCalendar.Key(.now, Hour: Learning.Settings.DayStartHour) }
    var Today: LearningDay? { Learning.Days.first { $0.id == TodayKey } }
    var Streak: StreakSummary { StudyCalendar.Streak(Learning.Days, Today: TodayKey, Settings: Learning.Settings) }

    private func Commit(Entries NewEntries: [WordEntry], Learning NewLearning: LearningData) -> Bool {
        guard CanSave else { return false }
        let OldEntries = Entries, OldLearning = Learning
        var Adjusted = NewLearning
        if let Index = Adjusted.Days.firstIndex(where: { $0.id == StudyCalendar.Key(.now, Hour: Adjusted.Settings.DayStartHour) }) {
            let Day = Adjusted.Days[Index]
            let NewRemaining = LearningEngine.NewEntries(NewEntries, Excluding: Day.Introduced, Limit: max(0, Day.NewLimit - Day.Introduced.count), Now: .now).count
            let InProgress = NewEntries.filter { Day.Introduced.contains($0.Id) && !Day.Completed.contains($0.Id) && $0.Learning.IsAvailable(at: .now) }.count
            let Due = NewEntries.filter { $0.Learning.IntroducedAt != nil && !Day.Introduced.contains($0.Id) && !Day.Completed.contains($0.Id) && $0.Learning.IsAvailable(at: .now) && ReviewSchedule.IsDue($0) }.count
            let PendingReviewed = Day.Reviewed.filter { Id in !Day.Completed.contains(Id) && NewEntries.contains { $0.Id == Id && $0.Learning.IsAvailable(at: .now) } }.count
            Adjusted.Days[Index].Target = Day.Completed.count + NewRemaining + InProgress + min(Due, max(0, Day.ReviewLimit - Day.Reviewed.count) + PendingReviewed)
            UpdateCompletion(&Adjusted.Days[Index], Settings: Adjusted.Settings)
        }
        Entries = NewEntries; Learning = Adjusted
        if Save() { return true }
        Entries = OldEntries; Learning = OldLearning
        return false
    }

    func RefreshDay(Now: Date = .now) {
        var Data = Learning
        _ = LearningEngine.Day(Entries: Entries, Data: &Data, Now: Now)
        if Data.Days.count != Learning.Days.count { _ = Commit(Entries: Entries, Learning: Data) }
    }

    @discardableResult
    func UpdateLearningSettings(_ Settings: LearningSettings) -> Bool {
        guard Settings.IsValid else { ErrorMessage = "Check the study settings and try again."; return false }
        var Data = Learning
        Data.Settings = Settings
        return Commit(Entries: Entries, Learning: Data)
    }

    @discardableResult
    func StartStudy(Synonyms: Bool = false, Now: Date = .now) -> Bool {
        if Learning.Session != nil { return true }
        var Data = Learning
        Data.Session = Synonyms ? LearningEngine.Synonyms(Entries, Now: Now) : LearningEngine.MakeSession(Entries: Entries, Data: &Data, Now: Now)
        guard Data.Session != nil else { return false }
        return Commit(Entries: Entries, Learning: Data)
    }

    func ReorderReady(Now: Date = .now) {
        guard var Session = Learning.Session, let First = Session.Current, First.Result == nil, First.ReadyAt > Now,
              let Index = Session.Cards.firstIndex(where: { $0.ReadyAt <= Now }) else { return }
        Session.Cards.insert(Session.Cards.remove(at: Index), at: 0)
        var Data = Learning; Data.Session = Session
        _ = Commit(Entries: Entries, Learning: Data)
    }

    func Introduce(CardId: UUID, Known: Bool, Skip: Bool, Mnemonic: String, Now: Date = .now) {
        guard var Session = Learning.Session, let Card = Session.Current, Card.id == CardId, Card.Kind == .Introduction,
              let Index = Entries.firstIndex(where: { $0.Id == Card.WordId }) else { return }
        var Words = Entries, Data = Learning
        let DayIndex = LearningEngine.Day(Entries: Words, Data: &Data, Now: Now)
        Session.Cards.removeFirst()
        if !Skip {
            Words[Index].Mnemonic = Mnemonic
            Words[Index].Learning.IntroducedAt = Now
            if !Data.Days[DayIndex].Introduced.contains(Card.WordId) { Data.Days[DayIndex].Introduced.append(Card.WordId) }
            if Known {
                Words[Index].Learning.Stage = 5
                Words[Index].Learning.LearningStep = 3
                Words[Index].Learning.IntervalDays = Data.Settings.Intervals[4]
                Words[Index].NextReviewAt = Calendar.current.date(byAdding: .day, value: Data.Settings.Intervals[4], to: Now)
                Data.Days[DayIndex].Completed.append(Card.WordId)
            } else {
                let Due = Now.addingTimeInterval(Double(Data.Settings.LearningMinutes[0]) * 60)
                Words[Index].NextReviewAt = Due
                Session.Cards.append(LearningEngine.Card(Words[Index], Entries: Words, Previous: nil, Now: Now, ReadyAt: Due))
            }
        } else {
            // Skipping a new word defers it for one study day without claiming it was learned.
            Words[Index].Learning.SuspendedUntil = Calendar.current.date(byAdding: .day, value: 1, to: Now)
            Data.Days[DayIndex].Target = max(Data.Days[DayIndex].Completed.count, Data.Days[DayIndex].Target - 1)
        }
        UpdateCompletion(&Data.Days[DayIndex], Settings: Data.Settings)
        Data.Session = Session
        _ = Commit(Entries: Words, Learning: Data)
    }

    func SaveDraft(CardId: UUID, Input: String, Hint: Bool) {
        guard var Session = Learning.Session, Session.Current?.id == CardId, Session.Current?.Result == nil else { return }
        Session.Cards[0].Input = Input; Session.Cards[0].HintUsed = Hint
        var Data = Learning; Data.Session = Session
        _ = Commit(Entries: Entries, Learning: Data)
    }

    func SubmitStudy(CardId: UUID, Input: String, Hint: Bool, Milliseconds: Int, DontKnow: Bool = false, Now: Date = .now) {
        guard var Session = Learning.Session, var Card = Session.Current, Card.id == CardId, Card.Result == nil,
              Card.Kind != .Introduction, Card.ReadyAt <= Now,
              DontKnow || !Input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let Index = Entries.firstIndex(where: { $0.Id == Card.WordId }) else { return }
        var Data = Learning, Words = Entries
        Card.Input = DontKnow ? "I don’t know" : Input
        Card.HintUsed = Hint
        let Ms = min(3_600_000, max(0, Milliseconds))
        let Result = LearningEngine.Grade(Input, Card: Card, Milliseconds: Ms, Settings: Data.Settings, DontKnow: DontKnow)
        Card.Result = Result
        let Before = Words[Index].Learning.Stage
        let DayIndex = LearningEngine.Day(Entries: Words, Data: &Data, Now: Now)
        if !Session.IsPractice {
            if !Data.Days[DayIndex].Attempted.contains(Card.WordId) { Data.Days[DayIndex].Attempted.append(Card.WordId) }
            LearningEngine.Record(&Words[Index], Result: Result, Milliseconds: Ms, Settings: Data.Settings, Now: Now)
            if !Data.Days[DayIndex].Introduced.contains(Card.WordId) && !Data.Days[DayIndex].Reviewed.contains(Card.WordId) {
                Data.Days[DayIndex].Reviewed.append(Card.WordId)
            }
            if Words[Index].Learning.RecoveryRemaining == 0 && Words[Index].Learning.LearningStep >= 3 && Result.IsCorrect {
                if !Data.Days[DayIndex].Completed.contains(Card.WordId) { Data.Days[DayIndex].Completed.append(Card.WordId) }
            } else if !Data.Days[DayIndex].Completed.contains(Card.WordId) {
                let Repeat = LearningEngine.Card(Words[Index], Entries: Words, Previous: Card.Kind, Now: Now, ReadyAt: Words[Index].NextReviewAt)
                let Position = Result.IsCorrect ? Session.Cards.count : min(Session.Cards.count, Data.Settings.RepeatGap + 1)
                Session.Cards.insert(Repeat, at: Position)
            }
            let Leeches = Words.indices.filter { Words[$0].Learning.Lapses >= Data.Settings.LeechThreshold && Words[$0].Learning.IsAvailable(at: Now) }
            if Leeches.count > Data.Settings.ActiveLeeches {
                for Leech in Leeches.sorted(by: { Words[$0].Learning.Lapses > Words[$1].Learning.Lapses }).prefix(Leeches.count - Data.Settings.ActiveLeeches) {
                    Words[Leech].Learning.SuspendedUntil = Calendar.current.date(byAdding: .day, value: Data.Settings.LeechPauseDays, to: Now)
                    Session.Cards.removeAll { $0.WordId == Words[Leech].Id && $0.id != Card.id }
                    Data.Days[DayIndex].Target = max(Data.Days[DayIndex].Completed.count, Data.Days[DayIndex].Target - 1)
                }
            }
            UpdateCompletion(&Data.Days[DayIndex], Settings: Data.Settings)
        }
        let Log = StudyLog(WordId: Card.WordId, Date: Now, Day: Data.Days[DayIndex].id, Kind: Card.Kind, Result: Result,
                           ResponseMs: Ms, StageBefore: Before, StageAfter: Words[Index].Learning.Stage,
                           Prompt: Card.Prompt, Input: Card.Input, Expected: Card.Expected, IsPractice: Session.IsPractice)
        Data.Logs.append(Log); Session.Finished.append(Log); Session.Cards[0] = Card; Data.Session = Session
        _ = Commit(Entries: Words, Learning: Data)
    }

    private func UpdateCompletion(_ Day: inout LearningDay, Settings: LearningSettings) {
        Day.MinimumMet = Day.MinimumMet || (Day.Target > 0 && (Day.Attempted.count >= min(Settings.MinimumCards, Day.Target) || Day.Completed.count >= Day.Target))
        Day.FullMet = Day.Target > 0 && Day.Completed.count >= Day.Target
    }

    func AdvanceStudy(CardId: UUID, Now: Date = .now) {
        guard var Session = Learning.Session, Session.Current?.id == CardId, Session.Current?.Result != nil else { return }
        Session.Cards.removeFirst()
        let RecentIds = Set(Session.Finished.suffix(Learning.Settings.SimilarGap).map(\.WordId))
        let Recent = Entries.filter { RecentIds.contains($0.Id) }
        if let Better = Session.Cards.firstIndex(where: { Card in
            Card.ReadyAt <= Now && Entries.contains { Word in Word.Id == Card.WordId && !Recent.contains { LearningEngine.Similar(Word, $0) } }
        }) { Session.Cards.insert(Session.Cards.remove(at: Better), at: 0) }
        var Data = Learning; Data.Session = Session
        _ = Commit(Entries: Entries, Learning: Data)
        ReorderReady(Now: Now)
    }

    func FinishStudy() {
        guard Learning.Session?.Cards.isEmpty == true else { return }
        var Data = Learning; Data.Session = nil
        _ = Commit(Entries: Entries, Learning: Data)
    }

    func SetMnemonic(_ Text: String, WordId: UUID) {
        guard let Index = Entries.firstIndex(where: { $0.Id == WordId }) else { return }
        var Words = Entries; Words[Index].Mnemonic = Text.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = Commit(Entries: Words, Learning: Learning)
    }

    func Delete(Ids: Set<UUID>) {
        var Data = Learning
        Data.Session?.Cards.removeAll { Ids.contains($0.WordId) }
        if let Index = Data.Days.firstIndex(where: { $0.id == TodayKey }) {
            let PendingDeleted = Entries.filter { Ids.contains($0.Id) && !Data.Days[Index].Completed.contains($0.Id) && ($0.Learning.IntroducedAt == nil || ReviewSchedule.IsDue($0)) }.count
            Data.Days[Index].Target = max(Data.Days[Index].Completed.count, Data.Days[Index].Target - PendingDeleted)
            UpdateCompletion(&Data.Days[Index], Settings: Data.Settings)
        }
        _ = Commit(Entries: Entries.filter { !Ids.contains($0.Id) }, Learning: Data)
    }

    func ExportBackup() throws -> Data {
        guard CanSave else { throw BackupError.Invalid("Saved data is unavailable. The original file has been preserved.") }
        return try JSONEncoder().encode(SavedData(Learning: Learning, Entries: Entries, History: History, Morning: Morning,
            Evening: Evening, RemindersEnabled: RemindersEnabled, XcodeInstalledAt: XcodeInstalledAt, RenewalReminderEnabled: RenewalReminderEnabled))
    }

    func MarkBackup() {
        var Data = Learning; Data.LastBackupAt = .now
        _ = Commit(Entries: Entries, Learning: Data)
    }

    func InspectBackup(_ Data: Data) throws -> SavedData {
        guard Data.count <= 64 * 1024 * 1024 else { throw BackupError.Invalid("This backup is too large (maximum 64 MB).") }
        let Snapshot = try JSONDecoder().decode(SavedData.self, from: Data)
        try Validate(Snapshot)
        return Snapshot
    }

    func RestoreBackup(_ Data: Data) throws {
        _ = try InspectBackup(Data)
        // Save the previous file before replacing anything, including an unreadable store.
        if FileManager.default.fileExists(atPath: FileURL.path) {
            try Foundation.Data(contentsOf: FileURL).write(to: FileURL.appendingPathExtension("before-restore"), options: .atomic)
        }
        try Data.write(to: FileURL, options: .atomic)
        CanSave = true; ErrorMessage = nil
        Load()
    }

    private func Validate(_ Snapshot: SavedData) throws {
        guard (Snapshot.SchemaVersion ?? 1) <= 2, Snapshot.Entries.count <= 50_000,
              Set(Snapshot.Entries.map(\.Id)).count == Snapshot.Entries.count,
              Snapshot.Entries.allSatisfy({ !$0.Term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !$0.Translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (0...9).contains($0.Learning.Stage) && (0...3).contains($0.Learning.LearningStep) && $0.Learning.Reps >= 0 && $0.Learning.Lapses >= 0 }),
              [Snapshot.Morning, Snapshot.Evening].allSatisfy({ (0...23).contains($0.Hour) && (0...59).contains($0.Minute) }) else {
            throw BackupError.Invalid("Invalid or unsupported backup. Your current data was not changed.")
        }
        if let Data = Snapshot.Learning {
            guard Data.Settings.IsValid, Set(Data.Days.map(\.id)).count == Data.Days.count,
                  Data.Days.allSatisfy({ StudyCalendar.Day($0.id) != nil && $0.Target >= 0 }),
                  Data.Session?.Cards.allSatisfy({ Card in Snapshot.Entries.contains { $0.Id == Card.WordId } }) ?? true,
                  Set(Data.Session?.Cards.map(\.id) ?? []).count == (Data.Session?.Cards.count ?? 0) else {
                throw BackupError.Invalid("The learning data in this backup is invalid.")
            }
        }
    }
}

enum BackupError: LocalizedError {
    case Invalid(String)
    var errorDescription: String? { if case let .Invalid(Message) = self { return Message }; return nil }
}

extension WordRepository {
    @discardableResult
    func ApplyImport(Text: String, Policy: DuplicatePolicy, Paste: Bool) -> Bool {
        do {
            let Preview = try ImportPreview(Text: Text, Existing: Entries, Policy: Policy, Paste: Paste)
            return Commit(Entries: Preview.Entries, Learning: Learning)
        } catch { ErrorMessage = error.localizedDescription; return false }
    }
}

extension WordRepository {
    @discardableResult
    func SaveEntry(_ Entry: WordEntry) -> Bool {
        guard !Entry.Term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !Entry.Translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !Entries.contains(where: { $0.Id != Entry.Id && QuizPlanner.Normalize($0.Term) == QuizPlanner.Normalize(Entry.Term) && LearningEngine.Meanings($0.Translation) == LearningEngine.Meanings(Entry.Translation) }) else { return false }
        var Words = Entries, Data = Learning
        if let Index = Words.firstIndex(where: { $0.Id == Entry.Id }) { Words[Index] = Entry } else { Words.append(Entry) }
        if Entry.Learning.Suspended { Data.Session?.Cards.removeAll { $0.WordId == Entry.Id } }
        return Commit(Entries: Words, Learning: Data)
    }
}

extension WordRepository {
    @discardableResult
    func RefreshNotifications(RequestPermission: Bool = false) async -> Bool {
        let Plan = NotificationPlan.Make(Data: Learning, Enabled: RemindersEnabled, Morning: Morning, Evening: Evening)
        let Success = await ReminderScheduler.SetPlan(Plan, RequestPermission: RequestPermission)
        _ = await ReminderScheduler.SetRenewal(Enabled: RenewalReminderEnabled, InstalledAt: XcodeInstalledAt)
        return Success
    }
}
