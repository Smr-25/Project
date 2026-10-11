import Foundation

@main
struct LearningChecks {
    @MainActor
    static func main() throws {
        var Calendar = Calendar(identifier: .gregorian)
        Calendar.timeZone = TimeZone(identifier: "Asia/Baku")!
        let Now = Calendar.date(from: DateComponents(year: 2026, month: 10, day: 11, hour: 12))!
        let Settings = LearningSettings()
        assert(Settings.IsValid)
        let Night = Calendar.date(from: DateComponents(year: 2026, month: 10, day: 11, hour: 1))!
        assert(StudyCalendar.Key(Night, Hour: 4, Calendar: Calendar) == "2026-10-10")
        var New = WordEntry(Term: "forest", Translation: "meşə")
        New.Learning.IntroducedAt = Now; New.Learning.LearningStep = 3
        for Expected in [1, 2, 4] {
            LearningEngine.Record(&New, Result: .Correct, Milliseconds: 1000, Settings: Settings, Now: Now, Calendar: Calendar, Fuzz: 0)
            assert(New.Learning.IntervalDays == Expected)
            assert(Calendar.dateComponents([.day], from: Now, to: New.NextReviewAt!).day == Expected)
        }
        New.Learning.Stage = 2
        LearningEngine.Record(&New, Result: .Wrong, Milliseconds: 1000, Settings: Settings, Now: Now)
        assert(New.Learning.Stage == 1 && New.Learning.RecoveryRemaining == 2)
        for Remaining in [1, 0] {
            LearningEngine.Record(&New, Result: .Correct, Milliseconds: 1000, Settings: Settings, Now: Now)
            assert(New.Learning.RecoveryRemaining == Remaining)
        }
        assert(New.NextReviewAt! > Now)
        var Card = StudyCard(WordId: New.Id, Kind: .TranslationWriting, Prompt: "meşə", Expected: "forest", ReadyAt: Now)
        assert(LearningEngine.Grade("fores", Card: Card, Milliseconds: 100, Settings: Settings, DontKnow: false) == .Hard)
        assert(LearningEngine.Grade("foxxst", Card: Card, Milliseconds: 100, Settings: Settings, DontKnow: false) == .Wrong)
        assert(LearningEngine.Grade("forest", Card: Card, Milliseconds: 13000, Settings: Settings, DontKnow: false) == .Hard)
        Card.HintUsed = true
        assert(LearningEngine.Grade("forest", Card: Card, Milliseconds: 100, Settings: Settings, DontKnow: false) == .Hard)
        assert(LearningEngine.Grade("", Card: Card, Milliseconds: 100, Settings: Settings, DontKnow: true) == .DontKnow)
        var Entries = (0..<180).map { WordEntry(Term: "word\($0)", Translation: "meaning\($0)") }
        for Index in 0..<160 { Entries[Index].Learning.IntroducedAt = Now; Entries[Index].NextReviewAt = Now }
        var Data = LearningData()
        var Day = LearningEngine.Day(Entries: Array(Entries[0..<130]) + Array(Entries[160..<180]), Data: &Data, Now: Now)
        assert(Data.Days[Day].NewLimit == 10)
        Data.Days = []
        Day = LearningEngine.Day(Entries: Entries, Data: &Data, Now: Now)
        assert(Data.Days[Day].NewLimit == 0 && Data.IntakePaused)
        Data.Days = []
        Day = LearningEngine.Day(Entries: Array(Entries[0..<90]) + Array(Entries[160..<180]), Data: &Data, Now: Now)
        assert(Data.Days[Day].NewLimit == 20 && !Data.IntakePaused)
        Data.Days = [LearningDay(id: "2026-10-07", Reviewed: [UUID()], NewLimit: 20, ReviewLimit: 200, Target: 20, Comeback: false)]
        Day = LearningEngine.Day(Entries: Entries, Data: &Data, Now: Now)
        assert(Data.Days[Day].Comeback && Data.Days[Day].NewLimit == 0 && Data.Days[Day].ReviewLimit == 40)
        var A = WordEntry(Term: "large", Translation: "böyük"), B = WordEntry(Term: "huge", Translation: "iri; böyük")
        A.Group = "size"; B.Group = "size"
        assert(LearningEngine.NewEntries([A, B], Excluding: [], Limit: 20, Now: Now).count == 1)
        A.Learning.Stage = 3; B.Learning.Stage = 3
        let Others = [WordEntry(Term: "tree", Translation: "ağac"), WordEntry(Term: "water", Translation: "su"), WordEntry(Term: "bird", Translation: "quş")]
        let Synonyms = LearningEngine.Synonyms([A, B] + Others, Now: Now)!
        assert(Synonyms.Cards.count == 2 && Synonyms.IsPractice)
        for _ in 0..<30 {
            let Q = LearningEngine.Card(A, Entries: [A, B] + Others, Previous: nil, Now: Now)
            assert(!Q.Options.contains("huge"))
        }
        A.ExampleSentences = "A large forest has large trees."
        assert(LearningEngine.Cloze(A) == "A ____ forest has ____ trees.")
        let CSV = "English,Azerbaijani,Definition\n" + (0..<298).map { "word\($0),məna\($0),\($0 == 0 ? "\"An explanation, with comma\"" : "")" }.joined(separator: "\n")
        let Imported = try WordCSV.Decode(CSV)
        assert(Imported.count == 298 && Imported[0].Definition == "An explanation, with comma" && Imported[1].Definition.isEmpty)
        let Preview = try ImportPreview(Text: "English,Azerbaijani\nlarge,böyük\nlarge,iri\ninvalid\n", Existing: [A], Policy: .Merge)
        assert(Preview.Duplicates == 1 && Preview.Merged == 1 && Preview.Errors.count == 1 && Preview.Entries.count == 1)
        let Paste = try ImportPreview(Text: "tree - ağac\nwater - su", Existing: [], Policy: .Merge, Paste: true)
        assert(Paste.Added == 2)
        var Days: [LearningDay] = (1...7).map { LearningDay(id: String(format: "2026-10-%02d", $0), NewLimit: 20, ReviewLimit: 200, Target: 20, Comeback: false, MinimumMet: true) }
        var Streak = StudyCalendar.Streak(Days, Today: "2026-10-09", Settings: Settings)
        assert(Streak.Current == 8 && Streak.Freezes == 0)
        Days.append(LearningDay(id: "2026-10-09", NewLimit: 20, ReviewLimit: 200, Target: 20, Comeback: false, MinimumMet: true))
        Streak = StudyCalendar.Streak(Days, Today: "2026-10-10", Settings: Settings)
        assert(Streak.Current == 9 && Streak.Best == 9)
        Data = LearningData(); Data.Days = [LearningDay(id: StudyCalendar.Key(Now, Hour: 4, Calendar: Calendar), NewLimit: 20, ReviewLimit: 200, Target: 20, Comeback: false, MinimumMet: true)]
        let Reminders = NotificationPlan.Make(Data: Data, Enabled: true, Morning: .init(Hour: 9, Minute: 0), Evening: .init(Hour: 20, Minute: 30), Now: Now, Calendar: Calendar)
        assert(Reminders.allSatisfy { !Calendar.isDate($0.Date, inSameDayAs: Now) })
        assert(Reminders.allSatisfy { (7..<23).contains(Calendar.component(.hour, from: $0.Date)) })
        Data.Session = StudySession(Cards: [StudyCard(WordId: UUID(), Kind: .TranslationWriting, Prompt: "x", Expected: "y", ReadyAt: Now.addingTimeInterval(60))])
        assert(!NotificationPlan.Make(Data: Data, Enabled: true, Morning: .init(Hour: 9, Minute: 0), Evening: .init(Hour: 20, Minute: 30), Now: Now, Calendar: Calendar).contains { $0.Id == "WordRevisit.Plan.Session" })
        Data.Settings.BackupReminder = true; Data.Settings.QuietStart = 11; Data.Settings.QuietEnd = 13
        Data.CreatedAt = Now.addingTimeInterval(-8 * 86400)
        let BackupReminder = NotificationPlan.Make(Data: Data, Enabled: false, Morning: .init(Hour: 9, Minute: 0), Evening: .init(Hour: 20, Minute: 30), Now: Now, Calendar: Calendar)
        assert(BackupReminder.count == 1 && Calendar.component(.hour, from: BackupReminder[0].Date) == 13)
        var LearningWord = WordEntry(Term: "new", Translation: "yeni")
        LearningWord.Learning.IntroducedAt = Now
        LearningEngine.Record(&LearningWord, Result: .Correct, Milliseconds: 100, Settings: Settings, Now: Now)
        assert(LearningWord.Learning.LearningStep == 1 && LearningWord.NextReviewAt == Now.addingTimeInterval(600))
        LearningEngine.Record(&LearningWord, Result: .Correct, Milliseconds: 100, Settings: Settings, Now: Now.addingTimeInterval(600))
        assert(LearningWord.Learning.LearningStep == 2 && LearningWord.Learning.Stage == 0)
        LearningEngine.Record(&LearningWord, Result: .Correct, Milliseconds: 100, Settings: Settings, Now: Now.addingTimeInterval(601))
        assert(LearningWord.Learning.LearningStep == 3 && LearningWord.Learning.Stage == 1)
        let Orders = (0..<10).map { _ in QuizPlanner.MakeQuestions(From: Others, Mode: .Easy).map(\.id) }
        assert(Set(Orders).count > 1, "Equal-priority questions should be shuffled")
        try Repository(Now: Now)
        try Performance()
        print("2.0 learning, import, scheduling, notification and recovery checks passed")
    }

    @MainActor
    static func Performance() throws {
        let URL = FileManager.default.temporaryDirectory.appendingPathComponent("WordRevisit5000-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: URL) }
        let Entries = (0..<5000).map { WordEntry(Term: "word\($0)", Translation: "məna\($0)") }
        let Snapshot = SavedData(Learning: LearningData(), Entries: Entries, History: [], Morning: .init(Hour: 9, Minute: 0), Evening: .init(Hour: 20, Minute: 30), RemindersEnabled: false)
        try JSONEncoder().encode(Snapshot).write(to: URL)
        let Start = Date.now
        let Store = WordRepository(FileURL: URL)
        Store.RefreshDay()
        assert(Store.Entries.count == 5000 && Store.Today?.Target == 20)
        print("5000-word load and day plan: \(String(format: "%.3f", Date.now.timeIntervalSince(Start)))s")
    }

    @MainActor
    static func Repository(Now: Date) throws {
        let URL = FileManager.default.temporaryDirectory.appendingPathComponent("WordRevisit20-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: URL); try? FileManager.default.removeItem(at: URL.appendingPathExtension("before-restore")) }
        let Store = WordRepository(FileURL: URL)
        Store.Delete(Ids: Set(Store.Entries.map(\.Id)))
        for Index in 0..<20 {
            var Word = WordEntry(Term: "word\(Index)", Translation: "məna\(Index)")
            Word.Learning.Stage = 4; Word.Learning.IntroducedAt = Now.addingTimeInterval(-86400)
            Word.Learning.LearningStep = 3; Word.NextReviewAt = Now
            assert(Store.SaveEntry(Word))
        }
        assert(Store.StartStudy(Now: Now))
        let First = Store.Learning.Session!.Current!
        Store.SubmitStudy(CardId: First.id, Input: First.Expected, Hint: false, Milliseconds: 100, Now: Now)
        Store.SubmitStudy(CardId: First.id, Input: "wrong", Hint: false, Milliseconds: 100, Now: Now)
        assert(Store.Learning.Logs.count == 1 && Store.Learning.Session?.Current?.id == First.id)
        var Reopened = WordRepository(FileURL: URL)
        assert(Reopened.Learning.Session?.Current?.Result == .Correct)
        Reopened.AdvanceStudy(CardId: First.id, Now: Now)
        let NextId = Reopened.Learning.Session!.Current!.id
        Reopened.AdvanceStudy(CardId: First.id, Now: Now)
        assert(Reopened.Learning.Session?.Current?.id == NextId)
        while Reopened.Learning.Logs.count < 15 {
            let Card = Reopened.Learning.Session!.Current!
            Reopened.SubmitStudy(CardId: Card.id, Input: Card.Expected, Hint: false, Milliseconds: 100, Now: Now)
            if Reopened.Learning.Logs.count == 14 { assert(Reopened.Learning.Days.last?.MinimumMet == false) }
            Reopened.AdvanceStudy(CardId: Card.id, Now: Now)
        }
        assert(Reopened.Learning.Days.last?.MinimumMet == true)
        let Backup = try Reopened.ExportBackup()
        let Expected = Reopened.Entries
        Reopened.Delete(Ids: Set(Reopened.Entries.map(\.Id)))
        assert(Reopened.Entries.isEmpty)
        try Reopened.RestoreBackup(Backup)
        assert(Reopened.Entries == Expected && Reopened.Learning.Logs.count == 15 && Reopened.Learning.Session != nil)
        do { try Reopened.RestoreBackup(Data("{}".utf8)); assertionFailure("Invalid backup accepted") } catch {}
        assert(Reopened.Entries == Expected)
        Reopened = WordRepository(FileURL: URL)
        assert(Reopened.Entries == Expected)
        let Current = Reopened.Learning.Session!.Current!
        Reopened.SubmitStudy(CardId: Current.id, Input: "bad", Hint: false, Milliseconds: 100, Now: Now)
        assert(Reopened.Learning.Session!.Cards.filter { $0.WordId == Current.WordId }.count == 2)
        assert(Reopened.Learning.Session!.Cards[min(4, Reopened.Learning.Session!.Cards.count - 1)].WordId == Current.WordId)
        Reopened.Delete(Ids: [Current.WordId])
        assert(!Reopened.Learning.Session!.Cards.contains { $0.WordId == Current.WordId })
    }
}
