import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    var body: some View {
        NavigationStack {
            List {
                if Store.History.isEmpty {
                    ContentUnavailableView("Your practice history", systemImage: "clock", description: Text("Finished groups appear here, including your first answers and the one-time retry."))
                }
                ForEach(Store.History) { Record in
                    NavigationLink {
                        QuizReviewView(Record: Record)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text(Record.Mode).font(.headline); Spacer(); Text("\(Record.Correct)/\(Record.Total)").monospacedDigit() }
                            Text(Record.Date.formatted(date: .abbreviated, time: .shortened)).font(.subheadline).foregroundStyle(Palette.Muted)
                        }.padding(.vertical, 5)
                    }
                }
            }.navigationTitle("Practice history")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { Dismiss() } } }
        }.tint(Palette.Accent)
    }
}

struct QuizReviewView: View {
    let Record: QuizRecord
    var body: some View {
        List {
            Section("First answers · \(Record.Correct) / \(Record.Total)") {
                if let Answers = Record.Answers { ForEach(Answers) { Row($0) } }
                else { Text("Individual answers were not recorded in this older session.").foregroundStyle(Palette.Muted) }
            }
            if let Retry = Record.RetryAnswers, !Retry.isEmpty {
                Section("Missed words · one retry") { ForEach(Retry) { Row($0) } }
            }
        }.navigationTitle("Answer review")
    }
    private func Row(_ Answer: QuizAnswer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Answer.Question.Prompt).font(.headline)
            Label(Answer.Input, systemImage: Answer.IsCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(Answer.IsCorrect ? Palette.Success : Palette.Danger)
            Text("Vocabulary answer: \(Answer.Question.Answer)").font(.subheadline)
            if Answer.Alternative == true { Text("Another word with the same meaning was accepted.").font(.caption).foregroundStyle(Palette.Muted) }
        }.padding(.vertical, 8)
    }
}
