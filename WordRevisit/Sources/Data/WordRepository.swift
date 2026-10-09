import Foundation
import SwiftUI

private struct SavedData: Codable {
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
    @Published private(set) var Entries: [WordEntry] = []
    @Published private(set) var History: [QuizRecord] = []
    @Published var Morning = ReminderTime(Hour: 9, Minute: 0)
    @Published var Evening = ReminderTime(Hour: 19, Minute: 0)
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
        Entries.removeAll { $0.Id == Entry.Id }
        Save()
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

    private func Save() {
        do {
            let Snapshot = SavedData(Entries: Entries, History: History, Morning: Morning,
                                     Evening: Evening, RemindersEnabled: RemindersEnabled,
                                     XcodeInstalledAt: XcodeInstalledAt,
                                     RenewalReminderEnabled: RenewalReminderEnabled)
            let Data = try JSONEncoder().encode(Snapshot)
            try Data.write(to: FileURL, options: .atomic)
        } catch {
            ErrorMessage = "Could not save your words: \(error.localizedDescription)"
        }
    }

}
