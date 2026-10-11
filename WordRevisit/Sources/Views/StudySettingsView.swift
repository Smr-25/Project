import SwiftUI

struct StudySettingsView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    @State private var Settings = LearningSettings()
    @State private var Notice = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Your daily rhythm") {
                    Stepper("New words: \(Settings.NewPerDay)", value: $Settings.NewPerDay, in: 0...100)
                    Picker("Batches", selection: $Settings.Batches) { ForEach([1, 2, 4], id: \.self) { Text("\($0)").tag($0) } }
                    Stepper("Daily minimum: \(Settings.MinimumCards)", value: $Settings.MinimumCards, in: 1...200)
                    Stepper("Day starts at \(Settings.DayStartHour):00", value: $Settings.DayStartHour, in: 0...23)
                    Text("Changes to limits apply to the next study day. Today's plan stays consistent. A smaller available queue also completes your minimum.").font(.caption)
                }
                Section("Load protection") {
                    Stepper("Halve new words above \(Settings.HalfAbove) due", value: $Settings.HalfAbove, in: 10...400, step: 10)
                    Stepper("Pause new words above \(Settings.PauseAbove) due", value: $Settings.PauseAbove, in: 20...500, step: 10)
                    Stepper("Resume below \(Settings.ResumeBelow) due", value: $Settings.ResumeBelow, in: 10...400, step: 10)
                    Stepper("Review limit: \(Settings.ReviewLimit)", value: $Settings.ReviewLimit, in: 10...500, step: 10)
                    Stepper("Come back gently after \(Settings.ComebackDays) missed days", value: $Settings.ComebackDays, in: 1...30)
                    Stepper("Comeback reviews: \(Settings.ComebackLimit)", value: $Settings.ComebackLimit, in: 10...200, step: 10)
                }
                Section("Recall") {
                    Toggle("Allow one spelling error in words of 5+ letters", isOn: $Settings.AllowTypos)
                    Stepper("Choice response: \(Settings.ChoiceSeconds)s", value: $Settings.ChoiceSeconds, in: 1...120)
                    Stepper("Written response: \(Settings.TypingSeconds)s", value: $Settings.TypingSeconds, in: 1...300)
                    Text("Correct answers with a hint, a spelling error, or a longer response are marked Hard and keep the same stage.").font(.caption)
                }
                Section("Memory and consistency") {
                    Stepper("Difficult after \(Settings.LeechThreshold) mistakes", value: $Settings.LeechThreshold, in: 1...20)
                    Stepper("Active difficult words: \(Settings.ActiveLeeches)", value: $Settings.ActiveLeeches, in: 1...100)
                    Stepper("Pause excess difficult words: \(Settings.LeechPauseDays) days", value: $Settings.LeechPauseDays, in: 1...30)
                    Stepper("Earn a freeze every \(Settings.FreezeEvery) days", value: $Settings.FreezeEvery, in: 1...30)
                    Stepper("Maximum freezes: \(Settings.MaxFreezes)", value: $Settings.MaxFreezes, in: 0...10)
                }
                Section {
                    DisclosureGroup("Review intervals and advanced rules") {
                        ForEach(0..<2, id: \.self) { Index in Stepper("Learning step \(Index + 1): \(Settings.LearningMinutes[Index]) min", value: $Settings.LearningMinutes[Index], in: 1...120) }
                        ForEach(0..<9, id: \.self) { Index in Stepper("Stage \(Index + 1): \(Settings.Intervals[Index]) days", value: $Settings.Intervals[Index], in: 1...365) }
                        Stepper("Spread longer intervals: ±\(Settings.FuzzPercent)%", value: $Settings.FuzzPercent, in: 0...25)
                        Stepper("Wrong answer: drop \(Settings.WrongDrop) stages", value: $Settings.WrongDrop, in: 1...9)
                        Stepper("Repeat after \(Settings.RepeatGap) other cards", value: $Settings.RepeatGap, in: 3...5)
                        Stepper("Recovery: \(Settings.CorrectAfterWrong) correct answers", value: $Settings.CorrectAfterWrong, in: 1...5)
                        Stepper("Similar-word gap: \(Settings.SimilarGap) cards", value: $Settings.SimilarGap, in: 0...20)
                    }
                }
            }
            .navigationTitle("My learning plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { Dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") {
                    if Store.UpdateLearningSettings(Settings) { Task { await Store.RefreshNotifications() }; Dismiss() } else { Notice = true }
                } }
            }
            .onAppear { Settings = Store.Learning.Settings }
            .alert("Check these settings", isPresented: $Notice) { Button("OK") {} } message: {
                Text("Pause must be above halve; resume must not exceed halve. Comeback reviews must not exceed the review limit, and intervals must increase.")
            }
        }.tint(Palette.Accent)
    }
}
