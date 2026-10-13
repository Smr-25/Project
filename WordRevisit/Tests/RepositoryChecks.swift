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
        try CheckLegacy(Directory)
        try CheckUnsupported(Directory)
        print("Session persistence, shared cycles, history, 1.2 migration and 2.x rejection checks passed")
    }
    @MainActor static func CheckLegacy(_ Directory: URL) throws {
        let URL = Directory.appendingPathComponent("Legacy.json")
        let WordId = UUID()
        let Text = """
        {"Entries":[{"Id":"\(WordId)","Term":"forest","Translation":"meşə","Definition":"old definition","CorrectCount":4,"IncorrectCount":1,"ExampleSentences":"An old sentence."}],"History":[{"Id":"\(UUID())","Date":0,"Mode":"Easy","Correct":12,"Total":20}],"Morning":{"Hour":9,"Minute":0},"Evening":{"Hour":20,"Minute":30},"RemindersEnabled":true,"RenewalReminderEnabled":true,"XcodeInstalledAt":0}
        """
        let Bytes = Data(Text.utf8); try Bytes.write(to: URL)
        let Store = WordRepository(FileURL: URL)
        assert(!Store.StorageBlocked && Store.Entries.count == 1 && Store.Entries[0].Id == WordId)
        assert(Store.History[0].Correct == 12 && Store.Data.RenewalReminderEnabled)
        let Old = try Data(contentsOf: URL.appendingPathExtension("before-1-3")); assert(Old == Bytes)
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
            assert(!Store.StorageBlocked && Store.Entries.count == 287)
            let Files = try FileManager.default.contentsOfDirectory(at: Directory, includingPropertiesForKeys: nil)
            let Archive = Files.first { $0.lastPathComponent.hasPrefix("Blocked\(Version).json.archived-") }!
            let Archived = try Data(contentsOf: Archive); assert(Archived == Bytes)
        }
        let BadURL = Directory.appendingPathComponent("Broken.json")
        let Broken = Data("{bad".utf8); try Broken.write(to: BadURL)
        let Bad = WordRepository(FileURL: BadURL)
        assert(Bad.StorageBlocked)
        let Untouched = try Data(contentsOf: BadURL); assert(Untouched == Broken)
    }
}
