import SwiftUI
import Charts

struct LearningProgressView: View {
    @EnvironmentObject private var Store: WordRepository
    @State private var SelectedQuiz: QuizRecord?
    @State private var ShowingAnswers = false
    @State private var Editing: WordEntry?
    private var Logs: [StudyLog] { Store.Learning.Logs.filter { !$0.IsPractice && StudyCalendar.Gap($0.Day, Store.TodayKey) >= 0 && StudyCalendar.Gap($0.Day, Store.TodayKey) < 30 } }
    private var ChartEnd: Date { (StudyCalendar.Day(Store.TodayKey) ?? .now).addingTimeInterval(86400) }
    private var ChartStart: Date { ChartEnd.addingTimeInterval(-30 * 86400) }
    private var Accuracy: Int { Logs.isEmpty ? 0 : Int(Double(Logs.filter { $0.Result.IsCorrect }.count) / Double(Logs.count) * 100) }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SectionEyebrow(Title: "See how far you've come")
                    Text("Your progress").font(.largeTitle.bold())
                    HStack {
                        Metric("\(Store.Streak.Current)", "Day streak")
                        Metric("\(Store.Streak.Best)", "Best streak")
                        Metric("\(Store.Streak.Freezes)", "Freezes left")
                    }
                    ActivityCard
                    VocabularyCard
                    DifficultWords
                    if !Store.History.isEmpty {
                        SectionEyebrow(Title: "Free practice & previous quizzes")
                        ForEach(Store.History.prefix(20)) { Quiz in
                            Button { SelectedQuiz = Quiz } label: {
                                HStack { Text(Quiz.Date.formatted(date: .abbreviated, time: .shortened)); Spacer(); Text("\(Quiz.Correct)/\(Quiz.Total)") }
                                    .padding(18).FrostedCard(CornerRadius: 20).contentShape(Rectangle())
                            }.buttonStyle(.plain).disabled(Quiz.Answers == nil)
                        }
                    }
                    Text("Study-day totals include saved answers from unfinished sessions. Free practice is separate. A daily minimum counts distinct words practised, so repeating one card cannot fill the target.")
                        .font(.caption).foregroundStyle(Palette.Muted)
                }.padding(24)
            }
        }
        .sheet(item: $SelectedQuiz) { Quiz in QuizReviewView(Answers: Quiz.Answers ?? []) }
        .sheet(item: $Editing) { Word in WordEditorView(Entry: Word) }
        .sheet(isPresented: $ShowingAnswers) {
            NavigationStack {
                List(Store.Learning.Logs.suffix(200).reversed()) { Log in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Log.Prompt).font(.headline)
                        Text("You: \(Log.Input)").foregroundStyle(.secondary)
                        Text(Log.Expected).foregroundStyle(Log.Result.IsCorrect ? Palette.White : Palette.Accent)
                        Text("\(Log.Result.rawValue) · \(Log.Date.formatted(date: .abbreviated, time: .shortened))").font(.caption)
                    }
                }.navigationTitle("Study answers")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { ShowingAnswers = false } } }
            }
        }
    }
    private var ActivityCard: some View {
VStack(alignment: .leading, spacing: 16) {
                        SectionEyebrow(Title: "Last 30 study days")
                        HStack { Metric("\(Accuracy)%", "Recall · target 85%") ; Metric("\(Logs.reduce(0) { $0 + $1.ResponseMs } / 60000)", "Answering minutes") }
                        let Groups = Dictionary(grouping: Logs, by: \.Day)
                        if !Groups.isEmpty { Chart {
                            ForEach(Groups.keys.sorted(), id: \.self) { Key in
                                if let Day = StudyCalendar.Day(Key) {
                                    BarMark(x: .value("Day", Day, unit: .day), y: .value("Answers", Groups[Key]?.count ?? 0)).foregroundStyle(Palette.Accent)
                                }
                            }
                        }
                        .chartXScale(domain: ChartStart...ChartEnd)
                        .chartXAxis { AxisMarks(values: .stride(by: .day, count: 7)) { AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
                        .frame(height: 150).accessibilityLabel("Daily review answers over the last 30 study days") }
                        if Logs.isEmpty { Text("Your first study answers will appear here.").foregroundStyle(Palette.Muted) }
                        if !Store.Learning.Logs.isEmpty { Button("Review study answers") { ShowingAnswers = true }.frame(minHeight: 44) }
                    }.padding(22).FrostedCard()
    }
    private var VocabularyCard: some View {
VStack(alignment: .leading, spacing: 14) {
                        SectionEyebrow(Title: "Your vocabulary")
                        LabeledContent("New", value: "\(Store.Entries.filter { $0.Learning.IntroducedAt == nil }.count)")
                        LabeledContent("Learning · stages 0–2", value: "\(Store.Entries.filter { $0.Learning.IntroducedAt != nil && $0.Learning.Stage < 3 }.count)")
                        LabeledContent("Growing · stages 3–5", value: "\(Store.Entries.filter { (3...5).contains($0.Learning.Stage) }.count)")
                        LabeledContent("Mature · stages 6–9", value: "\(Store.Entries.filter { $0.Learning.Stage >= 6 }.count)")
                        LabeledContent("New today", value: "\(Store.Today?.Introduced.count ?? 0)")
                        LabeledContent("Reviewed today", value: "\(Store.Today?.Reviewed.count ?? 0)")
                    }.padding(22).FrostedCard()
    }
    @ViewBuilder private var DifficultWords: some View {
let Difficult = Store.Entries.filter { $0.Learning.Lapses > 0 }.sorted { $0.Learning.Lapses > $1.Learning.Lapses }.prefix(20)
                    if !Difficult.isEmpty {
                        SectionEyebrow(Title: "Words to give some care")
                        ForEach(Array(Difficult)) { Word in
                            Button { Editing = Word } label: {
                                HStack { VStack(alignment: .leading) { Text(Word.Term).font(.headline); Text(Word.Translation).font(.subheadline).foregroundStyle(Palette.Muted) }; Spacer(); Text("\(Word.Learning.Lapses) misses").font(.caption) }
                                    .padding(18).FrostedCard(CornerRadius: 20).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                    }
    }
    private func Metric(_ Value: String, _ Title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) { Text(Value).font(.title.bold()); Text(Title).font(.caption).foregroundStyle(Palette.Muted) }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
