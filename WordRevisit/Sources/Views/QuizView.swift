import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    @FocusState private var AnswerFocused: Bool

    @State private var Run: QuizRun
    @State private var Input = ""
    @State private var ShowingReview = false

    init(Session: QuizSession) {
        _Run = State(initialValue: QuizRun(Session: Session))
    }

    private var Mode: QuizMode { Run.Session.Mode }
    private var Questions: [QuizQuestion] { Run.Questions }
    private var Index: Int { Run.Index }
    private var Submitted: Bool { Run.SubmittedAnswer != nil }
    private var WasCorrect: Bool { Run.SubmittedAnswer?.IsCorrect == true }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Header
                    if Questions.isEmpty {
                        EmptyState
                    } else if Run.IsFinished {
                        FinishedState
                    } else {
                        QuestionState
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .id(Run.CurrentQuestion?.id)
        }
        .sheet(isPresented: $ShowingReview) {
            QuizReviewView(Answers: Run.OriginalAnswers, Title: "Your first answers")
        }
    }

    private var Header: some View {
        HStack {
            Button { Dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 44, height: 44)
                    .FrostedCard(CornerRadius: 15)
            }
            .accessibilityLabel("Close quiz")
            Spacer()
            Text(Run.IsRetry ? "TRY AGAIN" : Mode.Title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(Palette.Muted)
            Spacer()
            Text(Questions.isEmpty ? "0/0" : "\(min(Index + 1, Questions.count))/\(Questions.count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .frame(width: 44)
        }
        .foregroundStyle(.white)
    }

    private var QuestionState: some View {
        let Question = Questions[Index]
        return VStack(alignment: .leading, spacing: 28) {
            if Run.IsRetry || Run.Session.IsPractice {
                Text(Run.IsRetry ? "A second look. Your original score stays the same."
                     : "Extra practice · your review dates stay the same.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.Muted)
            }
            GeometryReader { Geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule().fill(Mode == .Easy ? Palette.White : Palette.Accent)
                        .frame(width: Geometry.size.width * CGFloat(Index + 1) / CGFloat(Questions.count))
                }
            }
            .frame(height: 5)
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 12) {
                SectionEyebrow(Title: Mode == .Easy ? "Translate this word" : "Find the English word")
                Text(Question.Prompt)
                    .accessibilityIdentifier("QuizPrompt")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Mode == .Easy ? "What does it mean in Azerbaijani?" : "What is this word in English?")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.Muted)
            }
            .frame(maxWidth: .infinity, minHeight: 155, alignment: .leading)
            .padding(28)
            .FrostedCard(CornerRadius: 30)

            if !Question.Entry.ExampleSentences.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("YOUR EXAMPLES", systemImage: "quote.opening")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.Accent)
                    Text(Question.Entry.ExampleSentences)
                        .font(.system(size: 16))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(21)
                .FrostedCard(CornerRadius: 22)
            }

            VStack(alignment: .leading, spacing: 13) {
                SectionEyebrow(Title: "Your answer")
                TextField("Type what you remember...", text: $Input)
                    .id(Question.id)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($AnswerFocused)
                    .onSubmit { CheckAnswer(For: Question) }
                    .font(.system(size: 18, weight: .medium))
                    .padding(18)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.14)))
                    .disabled(Submitted)
                    .accessibilityLabel("Your answer")
                    .accessibilityIdentifier("QuizAnswer")
            }

            if Submitted {
                VStack(alignment: .leading, spacing: 8) {
                    Label(WasCorrect ? "You got it" : "Keep this one close", systemImage: WasCorrect ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(WasCorrect ? Palette.White : Palette.Accent)
                    Text(Question.Answer)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if !Question.Entry.Definition.isEmpty {
                        Text(Question.Entry.Definition)
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.Muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(21)
                .FrostedCard(CornerRadius: 22)
            }

            if Submitted {
                Button(Index == Questions.count - 1 ? "See results" : "Next word") {
                    Advance(From: Question)
                }
                .buttonStyle(PrimaryActionStyle(Tint: Mode == .Easy ? Palette.White : Palette.Accent))
            } else {
                Button("Check answer") { CheckAnswer(For: Question) }
                    .buttonStyle(PrimaryActionStyle(Tint: Mode == .Easy ? Palette.White : Palette.Accent))
                    .disabled(Input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(Input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            }
        }
    }

    private var EmptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 50))
                .foregroundStyle(Palette.Accent)
            Text("Your words come first")
                .font(.system(size: 27, weight: .bold, design: .rounded))
            Text("Add a few words in My words, then come back for your first quiz.")
                .foregroundStyle(Palette.Muted)
                .multilineTextAlignment(.center)
            Button("Back to today") { Dismiss() }
                .buttonStyle(PrimaryActionStyle(Tint: Palette.Accent))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 90)
    }

    private var FinishedState: some View {
        VStack(spacing: 22) {
            Image(systemName: "sparkles")
                .font(.system(size: 54))
                .foregroundStyle(Palette.White)
                .padding(.top, 55)
            Text(Run.IsRetry ? "Another step." : "Nicely done.")
                .font(.system(size: 42, weight: .bold, design: .rounded))
            Text("Every answer makes the next one easier.")
                .foregroundStyle(Palette.Muted)
            VStack(spacing: 5) {
                Text("\(Run.CorrectCount) / \(Questions.count)")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.White)
                Text(Run.IsRetry ? "REMEMBERED THIS TIME" : "WORDS REMEMBERED")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Palette.Muted)
            }
            .frame(maxWidth: .infinity)
            .padding(30)
            .FrostedCard(CornerRadius: 28)
            if Run.IsRetry {
                Text("Original score: \(Run.OriginalAnswers.filter(\.IsCorrect).count) / \(Run.OriginalAnswers.count)")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.Muted)
            }
            if !Run.MissedQuestions.isEmpty {
                Button("Retry \(Run.MissedQuestions.count) missed \(Run.MissedQuestions.count == 1 ? "word" : "words")") {
                    Run.RetryMissed()
                    Input = ""
                }
                .buttonStyle(PrimaryActionStyle(Tint: Palette.Accent))
            }
            Button("Review my answers") { ShowingReview = true }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.White)
                .padding(.vertical, 8)
            Button("Back to today") { Dismiss() }
                .buttonStyle(PrimaryActionStyle(Tint: Palette.White))
        }
        .frame(maxWidth: .infinity)
    }

    private func CheckAnswer(For Question: QuizQuestion) {
        guard let Answer = Run.Submit(Input, For: Question.id) else { return }
        if !Run.IsRetry {
            Store.RecordAnswer(For: Question.Entry.Id, IsCorrect: Answer.IsCorrect,
                               UpdatesSchedule: !Run.Session.IsPractice)
        }
        AnswerFocused = false
    }

    private func Advance(From Question: QuizQuestion) {
        guard Run.CurrentQuestion?.id == Question.id, Run.SubmittedAnswer != nil else { return }
        if Run.Advance(From: Question.id), !Run.IsRetry {
            Store.FinishQuiz(Mode: Mode, Answers: Run.OriginalAnswers, IsPractice: Run.Session.IsPractice)
        }
        Input = ""
    }
}
