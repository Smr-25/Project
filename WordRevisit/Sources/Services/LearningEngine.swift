import Foundation

enum LearningEngine {
    static func Meanings(_ Text: String) -> Set<String> {
        Set(Text.split(whereSeparator: { $0 == ";" || $0 == "," }).map { QuizPlanner.Normalize(String($0)) }.filter { !$0.isEmpty })
    }

    static func Similar(_ A: WordEntry, _ B: WordEntry) -> Bool {
        (!A.Group.isEmpty && A.Group.localizedCaseInsensitiveCompare(B.Group) == .orderedSame)
        || !Meanings(A.Translation).isDisjoint(with: Meanings(B.Translation))
    }

    static func Day(Entries: [WordEntry], Data: inout LearningData, Now: Date) -> Int {
        let Settings = Data.Settings
        let Key = StudyCalendar.Key(Now, Hour: Settings.DayStartHour)
        if let Index = Data.Days.firstIndex(where: { $0.id == Key }) { return Index }
        let Due = Entries.filter { $0.Learning.IsAvailable(at: Now) && $0.Learning.IntroducedAt != nil && ReviewSchedule.IsDue($0, Now: Now) }.count
        if Due > Settings.PauseAbove { Data.IntakePaused = true }
        if Due < Settings.ResumeBelow { Data.IntakePaused = false }
        let LastActive = Data.Days.filter { !$0.Introduced.isEmpty || !$0.Reviewed.isEmpty || $0.MinimumMet }.map(\.id).filter { $0 < Key }.max()
        let Comeback = LastActive.map { StudyCalendar.Gap($0, Key) > Settings.ComebackDays } ?? false
        let Limit = Comeback ? min(Settings.ComebackLimit, Settings.ReviewLimit) : Settings.ReviewLimit
        let New = Comeback || Data.IntakePaused ? 0 : (Due > Settings.HalfAbove ? Settings.NewPerDay / 2 : Settings.NewPerDay)
        let NewCount = NewEntries(Entries, Excluding: [], Limit: New, Now: Now).count
        Data.Days.append(LearningDay(id: Key, NewLimit: New, ReviewLimit: Limit,
                                     Target: min(Due, Limit) + NewCount, Comeback: Comeback))
        return Data.Days.count - 1
    }

    static func NewEntries(_ Entries: [WordEntry], Excluding: [UUID], Limit: Int, Now: Date) -> [WordEntry] {
        var Chosen = Entries.filter { Excluding.contains($0.Id) }
        var Added: [WordEntry] = []
        for Entry in Entries where Entry.Learning.IntroducedAt == nil && Entry.Learning.IsAvailable(at: Now) {
            guard Added.count < Limit else { break }
            if Chosen.contains(where: { Similar(Entry, $0) }) { continue }
            Chosen.append(Entry)
            Added.append(Entry)
        }
        return Added
    }

    static func MakeSession(Entries: [WordEntry], Data: inout LearningData, Now: Date) -> StudySession? {
        let Index = Day(Entries: Entries, Data: &Data, Now: Now)
        let Day = Data.Days[Index]
        let Due = Entries.shuffled().filter {
            $0.Learning.IsAvailable(at: Now) && $0.Learning.IntroducedAt != nil
            && ReviewSchedule.IsDue($0, Now: Now) && !Day.Completed.contains($0.Id)
        }.sorted {
            if $0.NextReviewAt != $1.NextReviewAt { return ($0.NextReviewAt ?? .distantPast) < ($1.NextReviewAt ?? .distantPast) }
            return $0.Learning.Stage < $1.Learning.Stage
        }
        let Remaining = max(0, Day.ReviewLimit - Day.Reviewed.count)
        let Reviews = Due.filter { Day.Reviewed.contains($0.Id) || Remaining > 0 }
        let Batch = max(1, Int(ceil(Double(Day.NewLimit) / Double(Data.Settings.Batches))))
        let New = NewEntries(Entries, Excluding: Day.Introduced, Limit: min(Batch, max(0, Day.NewLimit - Day.Introduced.count)), Now: Now)
        var Cards = New.map { StudyCard(WordId: $0.Id, Kind: .Introduction, Prompt: $0.Term, Expected: $0.Translation, ReadyAt: Now) }
        var NewReviewCount = 0
        for Entry in Reviews {
            if !Day.Reviewed.contains(Entry.Id) { if NewReviewCount >= Remaining { continue }; NewReviewCount += 1 }
            Cards.append(Card(Entry, Entries: Entries, Previous: Data.Logs.last(where: { $0.WordId == Entry.Id })?.Kind, Now: Now))
            if Cards.count >= max(Batch, 20) { break }
        }
        return Cards.isEmpty ? nil : StudySession(Cards: Cards)
    }

    static func Cloze(_ Entry: WordEntry) -> String? {
        let Text = Entry.ExampleSentences.split(separator: "\n").first.map(String.init) ?? ""
        guard !Entry.Term.isEmpty else { return nil }
        let Pattern = "(?i)(?<![\\p{L}])" + NSRegularExpression.escapedPattern(for: Entry.Term) + "(?![\\p{L}])"
        guard let Regex = try? NSRegularExpression(pattern: Pattern), Regex.firstMatch(in: Text, range: NSRange(Text.startIndex..., in: Text)) != nil else { return nil }
        return Regex.stringByReplacingMatches(in: Text, range: NSRange(Text.startIndex..., in: Text), withTemplate: "____")
    }

    static func Card(_ Entry: WordEntry, Entries: [WordEntry], Previous: StudyKind?, Now: Date, ReadyAt: Date? = nil) -> StudyCard {
        var Stage = Entry.Learning.Stage
        if Entry.Learning.IntervalDays > 0, let Due = Entry.NextReviewAt,
           Now.timeIntervalSince(Due) > Double(Entry.Learning.IntervalDays) * 86400 { Stage = max(0, Stage - 1) }
        var Kinds: [StudyKind]
        switch Stage {
        case 0...1: Kinds = [.EnglishChoice, .TranslationChoice]
        case 2...3: Kinds = [.DefinitionChoice, .ClozeChoice, .TranslationChoice]
        case 4...5: Kinds = [.TranslationWriting, .ClozeWriting]
        default: Kinds = [.DefinitionWriting, .ClozeWriting, .TranslationWriting]
        }
        Kinds = Kinds.filter {
            ($0 != .DefinitionChoice && $0 != .DefinitionWriting || !Entry.Definition.isEmpty)
            && ($0 != .ClozeChoice && $0 != .ClozeWriting || Cloze(Entry) != nil)
        }
        let Kind = Kinds.filter { $0 != Previous }.randomElement() ?? Kinds.first ?? .TranslationWriting
        let Prompt: String
        switch Kind {
        case .EnglishChoice: Prompt = Entry.Term
        case .DefinitionChoice, .DefinitionWriting: Prompt = Entry.Definition
        case .ClozeChoice, .ClozeWriting: Prompt = Cloze(Entry) ?? Entry.Translation
        default: Prompt = Entry.Translation
        }
        let Expected = Kind == .EnglishChoice ? Entry.Translation : Entry.Term
        var Card = StudyCard(WordId: Entry.Id, Kind: Kind, Prompt: Prompt, Expected: Expected, ReadyAt: ReadyAt ?? Now)
        if Kind.IsChoice {
            let Correct = Kind == .EnglishChoice ? String(Entry.Translation.split(separator: ";").first ?? "") : Entry.Term
            let Candidates = Entries.filter {
                $0.Id != Entry.Id && $0.Learning.IsAvailable(at: Now) && !Similar(Entry, $0)
                && (Entry.PartOfSpeech.isEmpty || $0.PartOfSpeech.localizedCaseInsensitiveCompare(Entry.PartOfSpeech) == .orderedSame)
                && QuizPlanner.Normalize($0.Term) != QuizPlanner.Normalize(Entry.Term)
            }.shuffled().sorted { abs($0.Term.count - Entry.Term.count) < abs($1.Term.count - Entry.Term.count) }
            var Options = [Correct]
            for Other in Candidates {
                let Option = Kind == .EnglishChoice ? String(Other.Translation.split(separator: ";").first ?? "") : Other.Term
                if !Options.contains(where: { QuizPlanner.Normalize($0) == QuizPlanner.Normalize(Option) }) { Options.append(Option) }
                if Options.count == 4 { break }
            }
            if Options.count == 4 { Card.Options = Options.shuffled() }
            else { Card.Kind = .TranslationWriting; Card.Prompt = Entry.Translation; Card.Expected = Entry.Term }
        }
        return Card
    }

    static func Grade(_ Input: String, Card: StudyCard, Milliseconds: Int, Settings: LearningSettings, DontKnow: Bool) -> RecallResult {
        if DontKnow { return .DontKnow }
        if QuizPlanner.Matches(Input, Answer: Card.Expected) {
            return Card.HintUsed || Milliseconds > (Card.Kind.IsChoice ? Settings.ChoiceSeconds : Settings.TypingSeconds) * 1000 ? .Hard : .Correct
        }
        let Value = QuizPlanner.Normalize(Input)
        if Settings.AllowTypos && !Card.Kind.IsChoice && !Value.isEmpty && Card.Expected.split(separator: ";").contains(where: {
            let Expected = QuizPlanner.Normalize(String($0))
            return Expected.count >= 5 && OneEdit(Value, Expected)
        }) { return .Hard }
        return .Wrong
    }

    static func OneEdit(_ A: String, _ B: String) -> Bool {
        let A = Array(A), B = Array(B)
        guard abs(A.count - B.count) <= 1 else { return false }
        var I = 0, J = 0, Edits = 0
        while I < A.count && J < B.count {
            if A[I] == B[J] { I += 1; J += 1; continue }
            Edits += 1
            if Edits > 1 { return false }
            if A.count <= B.count { J += 1 }
            if A.count >= B.count { I += 1 }
        }
        return Edits + A.count - I + B.count - J == 1
    }

    static func Record(_ Entry: inout WordEntry, Result: RecallResult, Milliseconds: Int, Settings: LearningSettings, Now: Date, Calendar: Calendar = .current, Fuzz: Double = Double.random(in: -1...1)) {
        Entry.Learning.Reps += 1
        Entry.Learning.ResponseMs += Milliseconds
        Entry.LastReviewedAt = Now
        if Result.IsCorrect { Entry.CorrectCount += 1 } else { Entry.IncorrectCount += 1 }
        if !Result.IsCorrect {
            Entry.Learning.Lapses += 1
            Entry.Learning.Stage = max(1, Entry.Learning.Stage - Settings.WrongDrop)
            Entry.Learning.LearningStep = 3
            Entry.Learning.RecoveryRemaining = Settings.CorrectAfterWrong
            Entry.NextReviewAt = Now
            return
        }
        if Entry.Learning.RecoveryRemaining > 0 {
            Entry.Learning.RecoveryRemaining -= 1
            Entry.NextReviewAt = Entry.Learning.RecoveryRemaining == 0 ? Calendar.date(byAdding: .day, value: 1, to: Now) : Now
            Entry.Learning.IntervalDays = 1
            return
        }
        if Entry.Learning.LearningStep < 3 {
            Entry.Learning.LearningStep += 1
            if Entry.Learning.LearningStep < 2 {
                Entry.NextReviewAt = Now.addingTimeInterval(Double(Settings.LearningMinutes[1]) * 60)
                return
            }
            if Entry.Learning.LearningStep == 2 {
                Entry.NextReviewAt = Now
                return
            }
            Entry.Learning.Stage = 1
        } else if Result == .Correct { Entry.Learning.Stage = min(9, Entry.Learning.Stage + 1) }
        let Base = Settings.Intervals[max(0, Entry.Learning.Stage - 1)]
        let Interval = Base > 8 ? max(1, Int((Double(Base) * (1 + min(1, max(-1, Fuzz)) * Double(Settings.FuzzPercent) / 100)).rounded())) : Base
        Entry.Learning.IntervalDays = Interval
        Entry.ReviewStreak = Entry.Learning.Stage
        Entry.NextReviewAt = Calendar.date(byAdding: .day, value: Interval, to: Now)
    }

    static func Synonyms(_ Entries: [WordEntry], Now: Date) -> StudySession? {
        var Cards: [StudyCard] = []
        let Eligible = Entries.filter { !$0.Group.isEmpty && $0.Learning.Stage >= 3 && $0.Learning.IsAvailable(at: Now) }
        for Entry in Eligible.shuffled() {
            guard let Answer = Eligible.filter({ $0.Id != Entry.Id && $0.Group.localizedCaseInsensitiveCompare(Entry.Group) == .orderedSame && $0.Term.lowercased() != Entry.Term.lowercased() }).randomElement() else { continue }
            var Options = [Answer.Term]
            for Other in Entries.shuffled() where Other.Id != Entry.Id && !Similar(Entry, Other) && !Similar(Answer, Other) && Other.Learning.IsAvailable(at: Now) {
                if !Options.contains(where: { $0.lowercased() == Other.Term.lowercased() }) { Options.append(Other.Term) }
                if Options.count == 4 { break }
            }
            guard Options.count == 4 else { continue }
            Cards.append(StudyCard(WordId: Entry.Id, Kind: .Synonym, Prompt: Entry.Term, Expected: Answer.Term, Options: Options.shuffled(), ReadyAt: Now))
            if Cards.count == 10 { break }
        }
        return Cards.isEmpty ? nil : StudySession(Cards: Cards, IsPractice: true)
    }
}
