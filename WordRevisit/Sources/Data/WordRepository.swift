import Foundation
import SwiftUI

struct PracticeData: Codable {
    var Format = "WordRevisitPractice"
    var SchemaVersion = 1
    var Entries: [WordEntry]
    var Bag: PracticeBag
    var History: [QuizRecord] = []
    var Appearance = AppAppearance.System
    var PreferredMode = QuizMode.Easy
    var RenewalReminderEnabled = false
    var XcodeInstalledAt: Date?
}

private struct Legacy12Data: Decodable {
    var Entries: [WordEntry]
    var History: [QuizRecord]
    var RenewalReminderEnabled: Bool?
    var XcodeInstalledAt: Date?
}

enum StorageIssue: LocalizedError {
    case Unsupported, Invalid
    var errorDescription: String? {
        switch self {
        case .Unsupported: "This installation contains 2.x or newer data. Version 1.3 does not migrate it. Export your vocabulary as CSV from that version before switching. The existing file has not been changed."
        case .Invalid: "The saved file could not be read safely. It has not been changed."
        }
    }
}

@MainActor
final class WordRepository: ObservableObject {
    @Published private(set) var Data = PracticeData(Entries: [], Bag: PracticeBag())
    @Published private(set) var StorageBlocked = false
    @Published var ErrorMessage: String?
    private let FileURL: URL
    var Entries: [WordEntry] { Data.Entries }
    var History: [QuizRecord] { Data.History }
    var Appearance: AppAppearance { Data.Appearance }
    var Session: PracticeSession? { Data.Bag.Session }

    init(FileURL: URL? = nil) {
        self.FileURL = FileURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("WordRevisit.json")
        Load()
    }

    private func Load() {
        do {
            guard FileManager.default.fileExists(atPath: FileURL.path) else {
                let Entries = StarterVocabulary.Entries
                _ = Commit(PracticeData(Entries: Entries, Bag: PracticeBag(Entries: Entries)))
                return
            }
            let Bytes = try Foundation.Data(contentsOf: FileURL)
            let Header = try JSONSerialization.jsonObject(with: Bytes) as? [String: Any]
            if Header?["Format"] as? String == "WordRevisitPractice" {
                let Saved = try JSONDecoder().decode(PracticeData.self, from: Bytes)
                try Validate(Saved)
                Data = Saved
            } else {
                guard Header?["Format"] == nil, Header?["SchemaVersion"] == nil, Header?["Learning"] == nil else { throw StorageIssue.Unsupported }
                let Old = try JSONDecoder().decode(Legacy12Data.self, from: Bytes)
                var Seen: Set<String> = []
                let Entries = Old.Entries.filter { Seen.insert(QuizPlanner.Normalize($0.Term)).inserted }
                var Saved = PracticeData(Entries: Entries, Bag: PracticeBag(Entries: Entries), History: Old.History)
                Saved.RenewalReminderEnabled = Old.RenewalReminderEnabled ?? false
                Saved.XcodeInstalledAt = Old.XcodeInstalledAt
                try Validate(Saved)
                let Recovery = FileURL.appendingPathExtension("before-1-3")
                if !FileManager.default.fileExists(atPath: Recovery.path) { try Bytes.write(to: Recovery, options: .atomic) }
                if !Commit(Saved) { StorageBlocked = true }
            }
        } catch {
            StorageBlocked = true
            ErrorMessage = error.localizedDescription
        }
    }

    @discardableResult
    private func Commit(_ Next: PracticeData) -> Bool {
        guard !StorageBlocked else { return false }
        do {
            try JSONEncoder().encode(Next).write(to: FileURL, options: .atomic)
            Data = Next
            return true
        } catch { ErrorMessage = "Could not save your changes: \(error.localizedDescription)"; return false }
    }

    // Called only after the user confirms a fresh start. Unsupported data is retained in full on disk.
    func StartFresh() {
        do {
            let Previous = FileURL.appendingPathExtension("archived-\(UUID().uuidString)")
            try FileManager.default.copyItem(at: FileURL, to: Previous)
            let Entries = StarterVocabulary.Entries
            StorageBlocked = false
            if Commit(PracticeData(Entries: Entries, Bag: PracticeBag(Entries: Entries))) { ErrorMessage = nil }
            else { StorageBlocked = true }
        } catch { ErrorMessage = "Could not preserve the old file: \(error.localizedDescription)" }
    }

    func SetAppearance(_ Value: AppAppearance) { var Next = Data; Next.Appearance = Value; _ = Commit(Next) }
    func SetMode(_ Mode: QuizMode) { var Next = Data; Next.PreferredMode = Mode; _ = Commit(Next) }
    func SetRenewal(Enabled: Bool, Reinstalled: Bool = false) {
        var Next = Data
        Next.RenewalReminderEnabled = Enabled
        if Reinstalled || Enabled && Next.XcodeInstalledAt == nil { Next.XcodeInstalledAt = .now }
        _ = Commit(Next)
    }

    @discardableResult
    func StartPractice() -> Bool {
        guard !Entries.isEmpty else { return false }
        var Next = Data
        Next.Bag.Start(Next.PreferredMode, Entries: Next.Entries)
        return Commit(Next)
    }

    func SaveDraft(_ Input: String, For Id: UUID) {
        guard Session?.Current?.id == Id, Session?.Submitted == nil, Session?.Draft != Input else { return }
        var Next = Data; Next.Bag.Session?.Draft = Input; _ = Commit(Next)
    }

    func Submit(_ Input: String, For Id: UUID) {
        var Next = Data
        guard Next.Bag.Session?.Submit(Input, For: Id) == true else { return }
        _ = Commit(Next)
    }

    func Advance(From Id: UUID) {
        var Next = Data
        guard Next.Bag.Session?.Advance(From: Id) == true else { return }
        RecordFinished(&Next)
        _ = Commit(Next)
    }

    private func RecordFinished(_ Next: inout PracticeData) {
        guard let Session = Next.Bag.Session, Session.IsFinished,
              !Next.History.contains(where: { $0.Id == Session.id }), !Session.Answers.isEmpty else { return }
        Next.History.insert(QuizRecord(Id: Session.id, Mode: Session.Mode.rawValue,
            Correct: Session.Answers.filter(\.IsCorrect).count, Total: Session.Answers.count,
            Answers: Session.Answers, RetryAnswers: Session.RetryAnswers), at: 0)
    }

    @discardableResult
    func SaveEntry(_ Entry: WordEntry) -> Bool {
        guard !QuizPlanner.Normalize(Entry.Term).isEmpty, !QuizPlanner.Meanings(Entry.Translation).isEmpty else { return false }
        guard !Entries.contains(where: { $0.Id != Entry.Id && QuizPlanner.Normalize($0.Term) == QuizPlanner.Normalize(Entry.Term) }) else {
            ErrorMessage = "This English word is already in your vocabulary."; return false
        }
        var Next = Data
        if let Index = Next.Entries.firstIndex(where: { $0.Id == Entry.Id }) { Next.Entries[Index] = Entry }
        else { Next.Entries.append(Entry) }
        Next.Bag.Reconcile(Next.Entries)
        return Commit(Next)
    }

    func Delete(Ids: Set<UUID>) {
        var Next = Data
        Next.Entries.removeAll { Ids.contains($0.Id) }
        Next.Bag.Reconcile(Next.Entries)
        RecordFinished(&Next)
        _ = Commit(Next)
    }

    @discardableResult
    func ApplyImport(Text: String, Paste: Bool) -> Bool {
        do {
            let Preview = try ImportPreview(Text: Text, Existing: Entries, Paste: Paste)
            var Next = Data; Next.Entries.append(contentsOf: Preview.AddedEntries)
            Next.Bag.Reconcile(Next.Entries)
            return Commit(Next)
        } catch { ErrorMessage = error.localizedDescription; return false }
    }

    private func Validate(_ Saved: PracticeData) throws {
        let Ids = Set(Saved.Entries.map(\.Id))
        guard Saved.SchemaVersion == 1, Saved.Bag.Cycle > 0,
              Ids.count == Saved.Entries.count,
              Set(Saved.Entries.map { QuizPlanner.Normalize($0.Term) }).count == Saved.Entries.count,
              Saved.Entries.allSatisfy({ !QuizPlanner.Normalize($0.Term).isEmpty && !QuizPlanner.Meanings($0.Translation).isEmpty }),
              Set(Saved.Bag.Known) == Ids, Saved.Bag.Known.count == Ids.count, Set(Saved.Bag.Remaining).isSubset(of: Ids),
              Set(Saved.Bag.Remaining).count == Saved.Bag.Remaining.count else { throw StorageIssue.Invalid }
        if let Session = Saved.Bag.Session {
            let Questions = Set(Session.Questions.map(\.id))
            guard Questions.count == Session.Questions.count, Questions.isSubset(of: Ids),
                  Questions.isDisjoint(with: Saved.Bag.Remaining), Session.Index >= 0,
                  Session.Index <= Session.CurrentQuestions.count,
                  Session.IsFinished || Session.Current != nil,
                  Set(Session.RetryQuestions.map(\.id)).isSubset(of: Questions),
                  Set(Session.RetryQuestions.map(\.id)).count == Session.RetryQuestions.count,
                  Set(Session.Answers.map(\.id)).isSubset(of: Questions),
                  Set(Session.Answers.map(\.id)).count == Session.Answers.count,
                  Set(Session.RetryAnswers.map(\.id)).isSubset(of: Set(Session.RetryQuestions.map(\.id))),
                  Set(Session.RetryAnswers.map(\.id)).count == Session.RetryAnswers.count else { throw StorageIssue.Invalid }
        }
    }
}
