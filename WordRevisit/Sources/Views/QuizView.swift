import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    @FocusState private var AnswerFocused: Bool
    @State private var Input = ""
    private var Session: PracticeSession? { Store.Session }
    private var Question: QuizQuestion? { Session?.Current }
    private var Answer: QuizAnswer? { Session?.Submitted }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let Question { QuestionContent(Question) }
                        else { Results }
                    }.padding(24)
                }.scrollDismissesKeyboard(.interactively)
                    .id(Question?.id)
            }
            .safeAreaInset(edge: .bottom) { ActionPanel }
            .navigationTitle(Session?.IsRetry == true ? "Missed words · one retry" : "\(Session?.Mode.rawValue ?? "") practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { Dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                        .accessibilityLabel("Save and close practice")
                }
            }
        }
        .onAppear { LoadDraft() }
        .onChange(of: Question?.id) { _, _ in LoadDraft() }
        .onChange(of: Session?.IsRetry) { _, _ in LoadDraft() }
        .onChange(of: Input) { _, Value in if let Question { Store.SaveDraft(Value, For: Question.id) } }
    }

    private func QuestionContent(_ Question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                SectionEyebrow(Title: Question.IsEnglishPrompt ? "English → Azerbaijani" : "Azerbaijani → English")
                Spacer()
                Text("\((Session?.Index ?? 0) + 1)/\(Session?.CurrentQuestions.count ?? 0)").monospacedDigit()
            }
            Text(Question.Prompt).font(.largeTitle.bold()).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("QuizPrompt")
                .frame(maxWidth: .infinity, alignment: .leading).padding(24).FrostedCard()
            if let Options = Question.Options {
                if Options.count < 4 { Text("\(Options.count) distinct choices are available for this word.").font(.caption).foregroundStyle(Palette.Muted) }
                ForEach(Options, id: \.self) { Option in
                    Button { Submit(Option, For: Question) } label: {
                        HStack {
                            Text(Option).font(.body.weight(.medium)).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 10)
                            if Answer != nil && IsCorrectOption(Option, Question) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.Success)
                            } else if Answer?.Input == Option {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.Danger)
                            }
                        }.padding(18).frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                            .FrostedCard(CornerRadius: 18).contentShape(Rectangle())
                    }.buttonStyle(.plain).disabled(Answer != nil).accessibilityIdentifier("QuizOption")
                }
            } else {
                if Question.Mode == .Easy {
                    Text("No distinct alternatives for this word. Write the English answer to keep it in your cycle.")
                        .font(.caption).foregroundStyle(Palette.Muted)
                }
                TextField("Write the English word", text: $Input)
                    .font(.title3).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .focused($AnswerFocused).submitLabel(.done)
                    .onSubmit { Submit(Input, For: Question) }
                    .padding(18).FrostedCard(CornerRadius: 18)
                    .disabled(Answer != nil).accessibilityIdentifier("QuizAnswer")
            }
        }
    }

    private var ActionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let Question {
                if let Answer {
                    VStack(alignment: .leading, spacing: 5) {
                        Label(Answer.IsCorrect ? "Correct" : "Incorrect", systemImage: Answer.IsCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.headline).foregroundStyle(Answer.IsCorrect ? Palette.Success : Palette.Danger)
                        if Answer.Alternative == true {
                            Text("This is also correct: \(Answer.Input). Vocabulary answer: \(Question.Answer).")
                                .font(.subheadline).accessibilityIdentifier("AlternativeAnswer")
                        } else { Text(Question.Answer).font(.body.weight(.semibold)) }
                    }.accessibilityElement(children: .combine)
                    Button("Next") { AnswerFocused = false; Store.Advance(From: Question.id) }
                        .buttonStyle(PrimaryActionStyle()).accessibilityIdentifier("NextQuestion")
                } else if Question.Options == nil {
                    Button("Check answer") { Submit(Input, For: Question) }
                        .buttonStyle(PrimaryActionStyle())
                        .disabled(QuizPlanner.Normalize(Input).isEmpty)
                }
            } else {
                Button(Store.Data.Bag.CycleComplete ? "Start next cycle" : "Next group") { _ = Store.StartPractice() }
                    .buttonStyle(PrimaryActionStyle()).disabled(Store.Entries.isEmpty)
                    .accessibilityIdentifier("NextGroup")
                Button("Back to home") { Dismiss() }.frame(maxWidth: .infinity, minHeight: 44)
            }
        }.padding(.horizontal, 20).padding(.vertical, 14).frame(maxWidth: .infinity)
            .background(.regularMaterial)
    }

    private var Results: some View {
        VStack(alignment: .leading, spacing: 22) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 46)).foregroundStyle(Palette.Success)
            Text(Store.Data.Bag.CycleComplete ? "Cycle complete" : "Group complete").font(.largeTitle.bold())
            if let Session {
                Text("\(Session.Answers.filter(\.IsCorrect).count) / \(Session.Answers.count) correct on the first try").font(.title3)
                if !Session.RetryAnswers.isEmpty {
                    Text("\(Session.RetryAnswers.count) missed words revisited once.").foregroundStyle(Palette.Muted)
                }
            }
            Text(Store.Data.Bag.CycleComplete ? "Every word has had its turn. The next cycle will be shuffled again." : "\(Store.Data.Bag.Remaining.count) words are waiting in this cycle.")
                .foregroundStyle(Palette.Muted)
            ModePicker(Identifier: "NextMode")
        }
    }

    private func IsCorrectOption(_ Option: String, _ Question: QuizQuestion) -> Bool {
        Question.IsEnglishPrompt ? QuizPlanner.Meanings(Question.Answer).contains(QuizPlanner.Normalize(Option)) : QuizPlanner.Normalize(Option) == QuizPlanner.Normalize(Question.Answer)
    }
    private func LoadDraft() { Input = Session?.Submitted?.Input ?? Session?.Draft ?? ""; AnswerFocused = false }
    private func Submit(_ Value: String, For Question: QuizQuestion) {
        guard Answer == nil else { return }
        Store.Submit(Value, For: Question.id)
        guard let Answer else { return }
        AnswerFocused = false
        UINotificationFeedbackGenerator().notificationOccurred(Answer.IsCorrect ? .success : .warning)
    }
}
