import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    @FocusState private var AnswerFocused: Bool

    let Mode: QuizMode
    let Questions: [QuizQuestion]

    @State private var Index = 0
    @State private var Input = ""
    @State private var Submitted = false
    @State private var WasCorrect = false
    @State private var CorrectCount = 0
    @State private var IsFinished = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Header
                    if Questions.isEmpty {
                        EmptyState
                    } else if IsFinished {
                        FinishedState
                    } else {
                        QuestionState
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
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
            Text(Mode.Title.uppercased())
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
        VStack(alignment: .leading, spacing: 28) {
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
                Text(Questions[Index].Prompt)
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

            VStack(alignment: .leading, spacing: 13) {
                SectionEyebrow(Title: "Your answer")
                TextField("Type what you remember...", text: $Input)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($AnswerFocused)
                    .onSubmit { if !Submitted { CheckAnswer() } }
                    .font(.system(size: 18, weight: .medium))
                    .padding(18)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.14)))
                    .disabled(Submitted)
                    .accessibilityLabel("Your answer")
            }

            if Submitted {
                VStack(alignment: .leading, spacing: 8) {
                    Label(WasCorrect ? "You got it" : "Keep this one close", systemImage: WasCorrect ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(WasCorrect ? Palette.White : Palette.Accent)
                    Text(Questions[Index].Answer)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if !Questions[Index].Entry.Definition.isEmpty {
                        Text(Questions[Index].Entry.Definition)
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.Muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(21)
                .FrostedCard(CornerRadius: 22)
            }

            Button(Submitted ? (Index == Questions.count - 1 ? "See results" : "Next word") : "Check answer") {
                if Submitted { Advance() } else { CheckAnswer() }
            }
            .buttonStyle(PrimaryActionStyle(Tint: Mode == .Easy ? Palette.White : Palette.Accent))
            .disabled(!Submitted && Input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(!Submitted && Input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
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
            Text("Nicely done.")
                .font(.system(size: 42, weight: .bold, design: .rounded))
            Text("Every answer makes the next one easier.")
                .foregroundStyle(Palette.Muted)
            VStack(spacing: 5) {
                Text("\(CorrectCount) / \(Questions.count)")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.White)
                Text("WORDS REMEMBERED")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Palette.Muted)
            }
            .frame(maxWidth: .infinity)
            .padding(30)
            .FrostedCard(CornerRadius: 28)
            Button("Back to today") { Dismiss() }
                .buttonStyle(PrimaryActionStyle(Tint: Palette.White))
        }
        .frame(maxWidth: .infinity)
    }

    private func CheckAnswer() {
        guard !Submitted, !Input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        WasCorrect = QuizPlanner.Matches(Input, Answer: Questions[Index].Answer)
        if WasCorrect { CorrectCount += 1 }
        Store.RecordAnswer(For: Questions[Index].Entry.Id, IsCorrect: WasCorrect)
        AnswerFocused = false
        Submitted = true
    }

    private func Advance() {
        if Index + 1 == Questions.count {
            Store.FinishQuiz(Mode: Mode, Correct: CorrectCount, Total: Questions.count)
            IsFinished = true
        } else {
            Index += 1
            Input = ""
            Submitted = false
        }
    }
}
