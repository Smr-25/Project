import Foundation

struct PracticeSession: Codable, Identifiable {
    var id = UUID()
    var Mode: QuizMode
    var Questions: [QuizQuestion]
    var Index = 0
    var Answers: [QuizAnswer] = []
    var RetryQuestions: [QuizQuestion] = []
    var RetryAnswers: [QuizAnswer] = []
    var IsRetry = false
    var IsFinished = false
    var Draft = ""
    var CurrentQuestions: [QuizQuestion] { IsRetry ? RetryQuestions : Questions }
    var Current: QuizQuestion? { !IsFinished && CurrentQuestions.indices.contains(Index) ? CurrentQuestions[Index] : nil }
    var Submitted: QuizAnswer? {
        guard let Current else { return nil }
        return (IsRetry ? RetryAnswers : Answers).last.flatMap { $0.id == Current.id ? $0 : nil }
    }

    mutating func Submit(_ Input: String, For Id: UUID) -> Bool {
        guard let Question = Current, Question.id == Id, Submitted == nil,
              !QuizPlanner.Normalize(Input).isEmpty else { return false }
        if let Options = Question.Options, !Options.contains(Input) { return false }
        let Exact = Question.IsEnglishPrompt
            ? QuizPlanner.Meanings(Question.Answer).contains(QuizPlanner.Normalize(Input))
            : QuizPlanner.Normalize(Input) == QuizPlanner.Normalize(Question.Answer)
        let Alternative = !Question.IsEnglishPrompt && !Exact && (Question.Alternatives ?? []).contains { QuizPlanner.Normalize($0) == QuizPlanner.Normalize(Input) }
        let Answer = QuizAnswer(Question: Question, Input: Input, IsCorrect: Exact || Alternative, Alternative: Alternative)
        if IsRetry { RetryAnswers.append(Answer) } else { Answers.append(Answer) }
        Draft = ""
        return true
    }

    mutating func Advance(From Id: UUID) -> Bool {
        guard Current?.id == Id, Submitted != nil else { return false }
        Index += 1; Draft = ""
        CompleteIfNeeded()
        return true
    }

    mutating func Remove(_ Ids: Set<UUID>) {
        let RemovedBefore = CurrentQuestions.prefix(Index).filter { Ids.contains($0.id) }.count
        let RemovedCurrent = Current.map { Ids.contains($0.id) } ?? false
        Questions.removeAll { Ids.contains($0.id) }
        RetryQuestions.removeAll { Ids.contains($0.id) }
        Answers.removeAll { Ids.contains($0.id) }
        RetryAnswers.removeAll { Ids.contains($0.id) }
        Index = max(0, Index - RemovedBefore)
        if RemovedCurrent { Draft = "" }
        CompleteIfNeeded()
    }

    private mutating func CompleteIfNeeded() {
        guard !IsFinished, Index >= CurrentQuestions.count else { return }
        if !IsRetry {
            RetryQuestions = Answers.filter { !$0.IsCorrect }.map(\.Question).shuffled()
            if !RetryQuestions.isEmpty { IsRetry = true; Index = 0; return }
        }
        IsFinished = true
    }
}

struct PracticeBag: Codable {
    var Cycle = 1
    var Known: [UUID] = []
    var Remaining: [UUID] = []
    var Session: PracticeSession?

    init(Entries: [WordEntry] = []) {
        Known = Entries.map(\.Id)
        Remaining = Known.shuffled()
    }

    var CycleComplete: Bool { !Known.isEmpty && Remaining.isEmpty && Session?.IsFinished == true }

    mutating func Reconcile(_ Entries: [WordEntry]) {
        let Existing = Set(Entries.map(\.Id)), Previous = Set(Known)
        let Deleted = Previous.subtracting(Existing)
        Remaining.removeAll { !Existing.contains($0) }
        Remaining.append(contentsOf: Entries.filter { !Previous.contains($0.Id) }.map(\.Id))
        Known = Entries.map(\.Id)
        if !Deleted.isEmpty { Session?.Remove(Deleted) }
    }

    mutating func Start(_ Mode: QuizMode, Entries: [WordEntry]) {
        Reconcile(Entries)
        guard !Entries.isEmpty, Session == nil || Session!.IsFinished else { return }
        if Remaining.isEmpty { Cycle += 1; Remaining = Known.shuffled() }
        let Chosen = Array(Remaining.shuffled().prefix(20))
        let Selected = Set(Chosen)
        let ById = Dictionary(uniqueKeysWithValues: Entries.map { ($0.Id, $0) })
        Remaining.removeAll { Selected.contains($0) }
        Session = PracticeSession(Mode: Mode, Questions: QuizPlanner.MakeQuestions(Chosen.compactMap { ById[$0] }, From: Entries, Mode: Mode))
    }
}
