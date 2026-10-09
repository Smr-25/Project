import SwiftUI

struct LearningProgressView: View {
    @EnvironmentObject private var Store: WordRepository
    @State private var SelectedQuiz: QuizRecord?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { Context in
            let Progress = StudyProgress(History: Store.History, Now: Context.date)
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        SectionEyebrow(Title: "See how far you've come")
                        Text("Your progress")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                        WeekCard(Progress: Progress, Now: Context.date)
                        HStack(spacing: 12) {
                            Metric(Value: "\(Progress.Streak)", Title: "Day quiz streak", Symbol: "flame.fill", Tint: Palette.Accent)
                            Metric(Value: "\(Progress.Accuracy)%", Title: "Recall accuracy", Symbol: "scope", Tint: Palette.White)
                        }
                        AttentionCard(Now: Context.date)
                        SectionEyebrow(Title: "Recent quizzes")
                        if Store.History.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Your first step starts today.")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                Text("Finish a quiz to see your activity here. Every completed quiz counts, even on a difficult day.")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Palette.Muted)
                            }
                            .padding(22)
                            .FrostedCard(CornerRadius: 24)
                        } else {
                            ForEach(Store.History.prefix(20)) { Quiz in
                                Button { SelectedQuiz = Quiz } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: Quiz.Mode == QuizMode.Hard.rawValue ? "bolt.fill" : "character.bubble.fill")
                                            .foregroundStyle(Palette.Accent)
                                            .frame(width: 40)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(QuizMode(rawValue: Quiz.Mode)?.Title ?? Quiz.Mode)
                                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            Text(Quiz.Date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.system(size: 12))
                                                .foregroundStyle(Palette.Muted)
                                            if Quiz.IsPractice == true {
                                                Text("Extra practice").font(.system(size: 11)).foregroundStyle(Palette.Muted)
                                            }
                                            if Quiz.Answers == nil {
                                                Text("Saved before answer reviews").font(.system(size: 11)).foregroundStyle(Palette.Muted)
                                            }
                                        }
                                        Spacer()
                                        Text("\(Quiz.Correct)/\(Quiz.Total)")
                                            .font(.system(size: 21, weight: .bold, design: .rounded))
                                        if Quiz.Answers != nil {
                                            Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
                                        }
                                    }
                                    .foregroundStyle(Palette.White)
                                    .padding(19)
                                    .FrostedCard(CornerRadius: 23)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .disabled(Quiz.Answers == nil)
                            }
                        }
                        Text("Activity and accuracy count completed quizzes. Retry rounds don't change your original results.")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.Muted)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 35)
                }
            }
        }
        .sheet(item: $SelectedQuiz) { Quiz in
            QuizReviewView(Answers: Quiz.Answers ?? [])
        }
    }

    private func WeekCard(Progress: StudyProgress, Now: Date) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Progress.WeeklyAnswers)")
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                    SectionEyebrow(Title: "Answers this week")
                }
                Spacer()
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 26))
                    .foregroundStyle(Palette.Accent)
                    .padding(13)
                    .background(Palette.Accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 18))
            }
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Progress.Week) { Day in
                    let Today = Calendar.current.isDate(Day.Date, inSameDayAs: Now)
                    let Maximum = max(Progress.Week.map(\.Answers).max() ?? 1, 1)
                    VStack(spacing: 9) {
                        Text("\(Day.Answers)").font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Palette.Muted)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Day.Answers == 0 ? Palette.White.opacity(0.12) : (Today ? Palette.Accent : Palette.White))
                            .frame(height: max(4, 100 * CGFloat(Day.Answers) / CGFloat(Maximum)))
                        Text(Day.Date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 12, weight: Today ? .bold : .regular))
                            .foregroundStyle(Today ? Palette.Accent : Palette.Muted)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(Day.Date.formatted(date: .complete, time: .omitted)), \(Day.Answers) answers")
                }
            }
            .frame(height: 146, alignment: .bottom)
            HStack(spacing: 7) {
                Circle().fill(Palette.Accent).frame(width: 6, height: 6)
                Text("Active on \(Progress.ActiveDays) of the last 7 days")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.Muted)
            }
        }
        .padding(25)
        .FrostedCard(CornerRadius: 30)
    }

    private func Metric(Value: String, Title: String, Symbol: String, Tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: Symbol).foregroundStyle(Tint)
            Text(Value).font(.system(size: 32, weight: .bold, design: .rounded))
            Text(Title).font(.system(size: 12)).foregroundStyle(Palette.Muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .FrostedCard(CornerRadius: 24)
    }

    private func AttentionCard(Now: Date) -> some View {
        let Words = Store.Entries.filter { $0.IncorrectCount > 0 && ReviewSchedule.IsDue($0, Now: Now) }
            .sorted { $0.IncorrectCount == $1.IncorrectCount
                ? $0.Term.localizedStandardCompare($1.Term) == .orderedAscending
                : $0.IncorrectCount > $1.IncorrectCount
            }.prefix(5)
        return VStack(alignment: .leading, spacing: 18) {
            SectionEyebrow(Title: "A little more attention")
            if Words.isEmpty {
                Label("No difficult words due right now", systemImage: "checkmark.seal")
                    .font(.system(size: 15, weight: .medium))
            } else {
                ForEach(Array(Words)) { Word in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Word.Term).font(.system(size: 18, weight: .bold, design: .rounded))
                            Text(Word.Translation).font(.system(size: 13)).foregroundStyle(Palette.Muted)
                        }
                        Spacer()
                        Text("Due").font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.Accent)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Palette.Accent.opacity(0.12), in: Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .FrostedCard(CornerRadius: 25)
    }
}
