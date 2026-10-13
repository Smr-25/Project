import Foundation

@main enum LogicChecks {
    static func main() throws {
        CheckBag()
        CheckAnswers()
        try CheckCSV()
        CheckGroups()
        print("Practice bag, exact grading, alternatives, CSV and synonym checks passed")
    }

    static func Words(_ Count: Int) -> [WordEntry] {
        (0..<Count).map { WordEntry(Term: "word\($0)", Translation: "məna\($0)") }
    }
    static func Finish(_ Bag: inout PracticeBag, Wrong: Bool = false) {
        var SeenRetry: Set<UUID> = []
        while let Question = Bag.Session?.Current {
            let Retry = Bag.Session!.IsRetry
            if Retry { assert(SeenRetry.insert(Question.id).inserted) }
            let Input = Wrong ? "wrong" : Question.Entry.Term
            assert(Bag.Session!.Submit(Input, For: Question.id))
            assert(!Bag.Session!.Submit(Input, For: Question.id))
            assert(Bag.Session!.Current?.id == Question.id)
            assert(Bag.Session!.Advance(From: Question.id))
        }
        assert(Bag.Session!.IsFinished)
    }
    static func CheckBag() {
        var Entries = Words(57)
        var Bag = PracticeBag(Entries: Entries)
        var Seen: Set<UUID> = []
        for Count in [20, 20, 17] {
            Bag.Start(.Hard, Entries: Entries)
            assert(Bag.Session!.Questions.count == Count)
            for Question in Bag.Session!.Questions { assert(Seen.insert(Question.id).inserted) }
            Finish(&Bag, Wrong: true)
            assert(Bag.Session!.RetryAnswers.count == Count)
        }
        assert(Bag.CycleComplete && Seen == Set(Entries.map(\.Id)))
        let Added = WordEntry(Term: "newcomer", Translation: "yeni")
        Entries.append(Added); Bag.Reconcile(Entries)
        assert(!Bag.CycleComplete && Bag.Remaining == [Added.Id])
        Bag.Start(.Hard, Entries: Entries)
        assert(Bag.Cycle == 1 && Bag.Session!.Questions.count == 1)
        Finish(&Bag)
        Bag.Start(.Easy, Entries: Entries)
        assert(Bag.Cycle == 2 && Bag.Session!.Questions.count == 20)
        assert(Bag.Session!.Questions.filter(\.IsEnglishPrompt).count == 10)
        let Current = Bag.Session!.Current!.id
        let Before = Bag.Remaining
        Bag.Start(.Hard, Entries: Entries)
        assert(Bag.Session!.Current!.id == Current && Bag.Session!.Mode == .Easy && Bag.Remaining == Before)
        Entries.removeAll { $0.Id == Current }
        Bag.Reconcile(Entries)
        assert(Bag.Session!.Current?.id != Current && !Bag.Known.contains(Current))
        Bag.Reconcile([])
        assert(Bag.Remaining.isEmpty && Bag.Session!.IsFinished)
        var Small = PracticeBag(Entries: Words(3))
        let Three = Words(3)
        Small = PracticeBag(Entries: Three); Small.Start(.Easy, Entries: Three)
        assert(Small.Session!.Questions.allSatisfy { $0.Options?.count == 3 })
        assert((1...2).contains(Small.Session!.Questions.filter(\.IsEnglishPrompt).count))
        let Alone = [WordEntry(Term: "alone", Translation: "tək")]
        let One = QuizPlanner.MakeQuestions(Alone, From: Alone, Mode: .Easy)[0]
        assert(One.Options == nil && !One.IsEnglishPrompt)
        var Orders = Set<String>()
        for _ in 0..<12 {
            var Random = PracticeBag(Entries: Three); Random.Start(.Hard, Entries: Three)
            Orders.insert(Random.Session!.Questions.map(\.Entry.Term).joined(separator: ","))
        }
        assert(Orders.count > 1)
    }
    static func CheckAnswers() {
        let Large = WordEntry(Term: "large", Translation: "böyük; iri", Group: "size")
        let Huge = WordEntry(Term: "huge", Translation: "böyük", Group: "size")
        let Entries = [Large, Huge] + Words(4)
        let Question = QuizPlanner.MakeQuestions([Large], From: Entries, Mode: .Hard)[0]
        var Session = PracticeSession(Mode: .Hard, Questions: [Question])
        assert(Session.Submit("  HUGE  ", For: Large.id))
        assert(Session.Submitted?.IsCorrect == true && Session.Submitted?.Alternative == true)
        assert(Session.Advance(From: Large.id) && Session.IsFinished)
        for Bad in ["larg", "lárge", "la rge"] {
            var Trial = PracticeSession(Mode: .Hard, Questions: [Question])
            assert(Trial.Submit(Bad, For: Large.id) && Trial.Submitted?.IsCorrect == false)
        }
        assert(QuizPlanner.Normalize("  Take   OFF ") == "take off")
        assert(QuizPlanner.Normalize("şey") != QuizPlanner.Normalize("sey"))
        for _ in 0..<10 {
            let Easy = QuizPlanner.MakeQuestions(Entries, From: Entries, Mode: .Easy)
            let Target = Easy.first { $0.id == Large.id }!
            let Options = Target.Options!
            assert(Options.count == 4 && Set(Options).count == 4)
            if !Target.IsEnglishPrompt { assert(!Options.contains("huge")) }
            var Run = PracticeSession(Mode: .Easy, Questions: [Target])
            assert(!Run.Submit("not listed", For: Large.id))
            let Correct = Target.IsEnglishPrompt ? "böyük" : "large"
            assert(Run.Submit(Correct, For: Large.id) && Run.Submitted?.IsCorrect == true)
        }
    }
    static func CheckCSV() throws {
        let URL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Data/Vocabulary.csv")
        let Original = try String(contentsOf: URL, encoding: .utf8)
        let Preview = try ImportPreview(Text: Original, Existing: [])
        assert(Preview.Added == 287 && Preview.Duplicates == 11 && Preview.Errors.isEmpty)
        assert(Preview.AddedEntries.map(\.Term) == StarterVocabulary.Entries.map(\.Term))
        let Text = "Definition,Group,Azerbaijani,English,Examples\nignored,size,iri,large,ignored\nignored,,su,water,ignored\nignored,,another,WATER,ignored\nignored,,,missing,ignored\n"
        let Existing = [WordEntry(Term: "large", Translation: "böyük", Group: "original")]
        let Result = try ImportPreview(Text: Text, Existing: Existing)
        assert(Result.Added == 1 && Result.Duplicates == 2 && Result.Errors.count == 1)
        assert(Existing[0].Translation == "böyük" && Existing[0].Group == "original")
        let Quoted = [WordEntry(Term: "take, off", Translation: "a\"b\nc", Group: "phrases")]
        let RoundTrip = try ImportPreview(Text: WordCSV.Encode(Quoted), Existing: [])
        assert(RoundTrip.AddedEntries[0].Translation == Quoted[0].Translation)
        assert(WordCSV.Encode(Quoted).hasPrefix("English,Azerbaijani,Group\n"))
        let TwoColumns = try ImportPreview(Text: "English,Azerbaijani\nword,söz\n", Existing: [])
        assert(TwoColumns.Added == 1 && TwoColumns.AddedEntries[0].Group.isEmpty)
        do { _ = try ImportPreview(Text: "word,söz\n", Existing: []); assertionFailure("Missing header accepted") } catch {}
        do { _ = try ImportPreview(Text: "English,Azerbaijani\nword,\"broken", Existing: []); assertionFailure("Broken CSV accepted") } catch {}
    }
    static func CheckGroups() {
        let Entries = [WordEntry(Term: "large", Translation: "böyük", Group: "Size"), WordEntry(Term: "alone", Translation: "tək"), WordEntry(Term: "huge", Translation: "iri", Group: "size")]
        let Groups = VocabularyGroup.Make(Entries, Search: "huge")
        assert(Groups.count == 1 && Groups[0].Words.map(\.Term) == ["large", "huge"])
        assert(VocabularyGroup.Make(Entries).count == 1)
        assert(VocabularyGroup.Make(Entries, Search: "alone").isEmpty)
    }
}
