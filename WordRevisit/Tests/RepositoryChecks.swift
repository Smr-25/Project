import Foundation

@main enum RepositoryChecks {
    @MainActor static func main() throws {
        let Directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: Directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: Directory) }
        let URL = Directory.appendingPathComponent("Words.json")
        let Entries = (0..<45).map { WordEntry(Term: "word\($0)", Translation: "məna\($0)") }
        let Initial = PracticeData(Entries: Entries, Bag: PracticeBag(Entries: Entries))
        try JSONEncoder().encode(Initial).write(to: URL)
        let Store = WordRepository(FileURL: URL)
        Store.SetMode(.Hard); assert(Store.StartPractice())
        let Question = Store.Session!.Current!
        let Remaining = Store.Data.Bag.Remaining
        Store.SaveDraft("a saved draft", For: Question.id)
        let Reopened = WordRepository(FileURL: URL)
        assert(Reopened.Session!.Draft == "a saved draft" && Reopened.Session!.Current!.id == Question.id)
        assert(Reopened.Data.Bag.Remaining == Remaining)
        Reopened.Submit(Question.Answer, For: Question.id)
        let Answered = WordRepository(FileURL: URL)
        assert(Answered.Session!.Submitted?.IsCorrect == true && Answered.Session!.Current!.id == Question.id)
        Answered.Advance(From: Question.id)
        Answered.Submit("stale", For: Question.id)
        assert(Answered.Session!.Answers.count == 1)
        while let Current = Answered.Session?.Current {
            Answered.Submit("wrong", For: Current.id); Answered.Advance(From: Current.id)
        }
        assert(Answered.History.count == 1 && Answered.History[0].Correct == 1)
        assert(Answered.History[0].RetryAnswers?.count == 19)
        let Finished = WordRepository(FileURL: URL)
        assert(Finished.Session!.IsFinished && Finished.History.count == 1)
        Finished.SetMode(.Easy); assert(Finished.StartPractice())
        assert(Finished.Session!.Mode == .Easy && Finished.Data.Bag.Cycle == 1)
        assert(Set(Finished.Session!.Questions.map(\.id)).isDisjoint(with: Store.Session!.Questions.map(\.id)))
        let New = WordEntry(Term: "new", Translation: "yeni")
        assert(Finished.SaveEntry(New)); assert(Finished.Data.Bag.Remaining.contains(New.Id))
        let Delete = Finished.Session!.Current!.id
        Finished.Delete(Ids: [Delete]); assert(Finished.Session!.Current?.id != Delete)
        Finished.SetAppearance(.Dark); Finished.SetRenewal(Enabled: true)
        let Again = WordRepository(FileURL: URL)
        assert(Again.Appearance == .Dark && Again.Data.RenewalReminderEnabled && Again.Data.XcodeInstalledAt != nil)
        assert(!Again.StorageBlocked && Again.History.count == 1)
        try Check14MigrationAndSynonyms(Directory)
        try CheckLegacy(Directory)
        try CheckUnsupported(Directory)
        print("Session persistence, shared cycles, history, 1.2 migration and 2.x rejection checks passed")
    }
    @MainActor static func Check14MigrationAndSynonyms(_ Directory: URL) throws {
        let URL = Directory.appendingPathComponent("Version13.json")
        let CSVURL = Foundation.URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/Version13Vocabulary.csv")
        let Rows = try WordCSV.Rows(String(contentsOf: CSVURL, encoding: .utf8)).dropFirst()
        var Seen: Set<String> = []
        var Words = Rows.compactMap { Row -> WordEntry? in
            guard Seen.insert(QuizPlanner.Normalize(Row[0])).inserted else { return nil }
            return WordEntry(Term: Row[0], Translation: Row[1], Group: Row[2])
        }
        assert(Words.count == 287)
        Words[0].Translation += "; my personal meaning"
        var Old = PracticeData(Entries: Words, Bag: PracticeBag(Entries: Words))
        Old.SchemaVersion = 1; Old.Appearance = .Dark; Old.PreferredMode = .Hard
        Old.RenewalReminderEnabled = true; Old.XcodeInstalledAt = .now
        Old.Bag.Start(.Hard, Entries: Words); Old.Bag.Session?.Draft = "keep this draft"
        let Bytes = try JSONEncoder().encode(Old); try Bytes.write(to: URL)
        let Store = WordRepository(FileURL: URL)
        assert(!Store.StorageBlocked && Store.Entries.count == 513 && Store.Data.SchemaVersion == 2)
        assert(Store.Entries.prefix(287).map(\.Id) == Words.map(\.Id))
        assert(Store.Entries[0].Translation.contains("my personal meaning"))
        assert(Store.Session?.Current?.id == Old.Bag.Session?.Current?.id && Store.Session?.Draft == "keep this draft")
        assert(Store.Data.Bag.Remaining.count == Old.Bag.Remaining.count + 226)
        assert(Store.Appearance == .Dark && Store.Data.RenewalReminderEnabled)
        let Recovery = try Data(contentsOf: URL.appendingPathExtension("before-1-4")); assert(Recovery == Bytes)
        let Ordinary = try JSONEncoder().encode(Store.Data.Bag)
        assert(Store.StartSynonyms())
        let Round = Store.Synonyms.Round!
        let Chip = Round.Chips[0]
        Store.AssignSynonym(Round.Mode == .Grouping ? Chip.Family : Chip.Word.Term, Chip: Chip.id, Round: Round.id, Retry: Round.IsRetry)
        let Reopened = WordRepository(FileURL: URL)
        assert(!Reopened.StorageBlocked && Reopened.Synonyms.Round?.id == Round.id)
        assert(Reopened.Synonyms.Round?.Inputs[Chip.id.uuidString] != nil)
        assert(Reopened.Session?.Draft == "keep this draft")
        // The ordinary cycle and active question stay intact when synonym practice or CSV updates run.
        assert(Store.ApplyImport(Text: "English,Azerbaijani,Group\nlogging,new translation,\n", Paste: false))
        assert(Store.Session?.Current?.id == Old.Bag.Session?.Current?.id && Store.Session?.Draft == "keep this draft")
        assert(Store.Data.Bag.Remaining == Old.Bag.Remaining + Array(Store.Entries.suffix(226)).map(\.Id))
        let Before = Store.Data.Bag.Session!.Questions.map(\.Entry)
        let After = WordRepository(FileURL: URL).Data.Bag.Session!.Questions.map(\.Entry)
        assert(Before == After && !Ordinary.isEmpty)
        // Removing a member rebuilds only an affected synonym round.
        Store.Delete(Ids: [Chip.id])
        assert(Store.Synonyms.Round == nil && Store.Synonyms.Notice != nil)
        assert(!WordRepository(FileURL: URL).StorageBlocked)
        // One-time upgrade must never resurrect words deleted after upgrading.
        let Count = Store.Entries.count
        assert(WordRepository(FileURL: URL).Entries.count == Count)
        Store.SetSynonymMode(.Easy); assert(Store.StartSynonyms())
        while let Active = Store.Synonyms.Round, !Active.IsFinished, let Current = Active.Current {
            Store.AssignSynonym(Current.Word.Term, Chip: Current.id, Round: Active.id, Retry: Active.IsRetry)
            let Answered = Store.Synonyms.Round!
            Store.AdvanceSynonyms(Round: Answered.id, Chip: Current.id, Retry: Answered.IsRetry)
        }
        assert(Store.History.filter { $0.Mode.hasPrefix("Synonyms") }.count == 1)
        assert(!WordRepository(FileURL: URL).StorageBlocked)
    }
    @MainActor static func CheckLegacy(_ Directory: URL) throws {
        let URL = Directory.appendingPathComponent("Legacy.json")
        let WordId = UUID()
        let Text = """
        {"Entries":[{"Id":"\(WordId)","Term":"forest","Translation":"meşə","Definition":"old definition","CorrectCount":4,"IncorrectCount":1,"ExampleSentences":"An old sentence."}],"History":[{"Id":"\(UUID())","Date":0,"Mode":"Easy","Correct":12,"Total":20}],"Morning":{"Hour":9,"Minute":0},"Evening":{"Hour":20,"Minute":30},"RemindersEnabled":true,"RenewalReminderEnabled":true,"XcodeInstalledAt":0}
        """
        let Bytes = Data(Text.utf8); try Bytes.write(to: URL)
        let Store = WordRepository(FileURL: URL)
        assert(!Store.StorageBlocked && Store.Entries.count >= 513 && Store.Entries[0].Id == WordId)
        assert(Store.History[0].Correct == 12 && Store.Data.RenewalReminderEnabled)
        let Old = try Data(contentsOf: URL.appendingPathExtension("before-1-4")); assert(Old == Bytes)
        assert(WordRepository(FileURL: URL).Entries == Store.Entries)
    }
    @MainActor static func CheckUnsupported(_ Directory: URL) throws {
        let Fixture = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/Version2Backup.json")
        let Original = try Data(contentsOf: Fixture)
        for Version in [2, 3] {
            var Object = try JSONSerialization.jsonObject(with: Original) as! [String: Any]
            Object["SchemaVersion"] = Version
            let Bytes = try JSONSerialization.data(withJSONObject: Object)
            let URL = Directory.appendingPathComponent("Blocked\(Version).json")
            try Bytes.write(to: URL)
            let Store = WordRepository(FileURL: URL)
            assert(Store.StorageBlocked && Store.Entries.isEmpty)
            assert(!Store.SaveEntry(WordEntry(Term: "new", Translation: "yeni")))
            let Unchanged = try Data(contentsOf: URL); assert(Unchanged == Bytes)
            Store.StartFresh()
            assert(!Store.StorageBlocked && Store.Entries.count == 513)
            let Files = try FileManager.default.contentsOfDirectory(at: Directory, includingPropertiesForKeys: nil)
            let Archive = Files.first { $0.lastPathComponent.hasPrefix("Blocked\(Version).json.archived-") }!
            let Archived = try Data(contentsOf: Archive); assert(Archived == Bytes)
        }
        let FutureURL = Directory.appendingPathComponent("Future.json")
        var Future = PracticeData(Entries: [], Bag: PracticeBag())
        Future.SchemaVersion = 99
        let FutureBytes = try JSONEncoder().encode(Future); try FutureBytes.write(to: FutureURL)
        assert(WordRepository(FileURL: FutureURL).StorageBlocked)
        let FutureUntouched = try Data(contentsOf: FutureURL); assert(FutureUntouched == FutureBytes)
        let BadURL = Directory.appendingPathComponent("Broken.json")
        let Broken = Data("{bad".utf8); try Broken.write(to: BadURL)
        let Bad = WordRepository(FileURL: BadURL)
        assert(Bad.StorageBlocked)
        let Untouched = try Data(contentsOf: BadURL); assert(Untouched == Broken)
    }
}
