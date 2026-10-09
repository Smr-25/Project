import Foundation

struct QuizRun {
    let Session: QuizSession
    private(set) var Questions: [QuizQuestion]
    private(set) var Index = 0
    private(set) var Answers: [QuizAnswer] = []
    private(set) var OriginalAnswers: [QuizAnswer] = []
    private(set) var IsRetry = false
    private(set) var IsFinished = false

    init(Session: QuizSession) {
        self.Session = Session
        Questions = Session.Questions
    }

    var CurrentQuestion: QuizQuestion? {
        guard !IsFinished, Questions.indices.contains(Index) else { return nil }
        return Questions[Index]
    }

    var SubmittedAnswer: QuizAnswer? {
        guard let Question = CurrentQuestion else { return nil }
        return Answers.last.flatMap { $0.id == Question.id ? $0 : nil }
    }

    var CorrectCount: Int { Answers.filter(\.IsCorrect).count }
    var MissedQuestions: [QuizQuestion] { Answers.filter { !$0.IsCorrect }.map(\.Question) }

    mutating func Submit(_ Input: String, For QuestionId: UUID) -> QuizAnswer? {
        guard let Question = CurrentQuestion, Question.id == QuestionId, SubmittedAnswer == nil,
              !Input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let Answer = QuizAnswer(Question: Question, Input: Input,
                                IsCorrect: QuizPlanner.Matches(Input, Answer: Question.Answer))
        Answers.append(Answer)
        return Answer
    }

    @discardableResult
    mutating func Advance(From QuestionId: UUID) -> Bool {
        guard CurrentQuestion?.id == QuestionId, SubmittedAnswer != nil else { return false }
        if Index + 1 == Questions.count {
            IsFinished = true
            if !IsRetry { OriginalAnswers = Answers }
        } else {
            Index += 1
        }
        return IsFinished
    }

    mutating func RetryMissed() {
        guard IsFinished, !MissedQuestions.isEmpty else { return }
        Questions = MissedQuestions
        Index = 0
        Answers = []
        IsRetry = true
        IsFinished = false
    }
}
