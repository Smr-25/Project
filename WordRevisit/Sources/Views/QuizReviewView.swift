import SwiftUI

struct QuizReviewView: View {
    @Environment(\.dismiss) private var Dismiss
    let Answers: [QuizAnswer]
    var Title = "Answer review"

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionEyebrow(Title: "A little reflection")
                        Text(Title)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("\(Answers.filter(\.IsCorrect).count) correct · \(Answers.count) answers")
                            .foregroundStyle(Palette.Muted)
                        ForEach(Answers) { Answer in
                            VStack(alignment: .leading, spacing: 15) {
                                HStack(alignment: .top) {
                                    Text(Answer.Question.Prompt)
                                        .font(.system(size: 23, weight: .bold, design: .rounded))
                                    Spacer()
                                    Image(systemName: Answer.IsCorrect ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                                        .foregroundStyle(Answer.IsCorrect ? Palette.White : Palette.Accent)
                                        .accessibilityLabel(Answer.IsCorrect ? "Correct" : "Incorrect")
                                }
                                VStack(alignment: .leading, spacing: 5) {
                                    SectionEyebrow(Title: "You wrote")
                                    Text(Answer.Input).foregroundStyle(Answer.IsCorrect ? Palette.White : Palette.Accent)
                                }
                                VStack(alignment: .leading, spacing: 5) {
                                    SectionEyebrow(Title: "Accepted answer")
                                    Text(Answer.Question.Answer)
                                }
                                if !Answer.Question.Entry.ExampleSentences.isEmpty {
                                    Divider()
                                    Text(Answer.Question.Entry.ExampleSentences)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Palette.Muted)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(22)
                            .FrostedCard(CornerRadius: 25)
                        }
                    }
                    .padding(24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { Dismiss() }.tint(Palette.Accent)
                }
            }
            .toolbarBackground(.hidden)
        }
        .preferredColorScheme(.dark)
    }
}
