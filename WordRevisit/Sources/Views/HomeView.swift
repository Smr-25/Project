import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.scenePhase) private var ScenePhase
    @State private var ActiveQuiz: QuizSession?
    @State private var ShowingPlan = false
    @State private var Notice: String?
    @State private var Now = Date.now

    private var DueCount: Int { Store.Entries.filter { $0.Learning.IsAvailable(at: Now) && $0.Learning.IntroducedAt != nil && ReviewSchedule.IsDue($0, Now: Now) }.count }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    Header
                    DailyPlan
                    SectionEyebrow(Title: "Free practice · no schedule changes")
                    ModeCard(Mode: .Easy, Tint: Palette.White) { StartQuiz(.Easy) }
                    ModeCard(Mode: .Hard, Tint: Palette.Accent) { StartQuiz(.Hard) }
                    if Store.Entries.contains(where: { !$0.Group.isEmpty }) {
                        Button("Practise synonyms") {
                            if Store.Learning.Session != nil { Notice = "Finish your saved session first, then start synonym practice." }
                            else if Store.StartStudy(Synonyms: true) { Store.PresentStudy = true }
                            else { Notice = "Add words to the same synonym group and bring at least two to stage 3. Four distinct answer options are needed." }
                        }.buttonStyle(PrimaryActionStyle(Tint: Palette.Accent))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(item: $ActiveQuiz) { Quiz in
            QuizView(Session: Quiz)
                .environmentObject(Store)
        }
        .sheet(isPresented: $ShowingPlan) { StudySettingsView() }
        .alert("Your learning", isPresented: Binding(get: { Notice != nil }, set: { if !$0 { Notice = nil } })) {
            Button("OK") { Notice = nil }
        } message: { Text(Notice ?? "") }
        .onAppear {
            Store.RefreshDay()
            Now = .now
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-PreviewQuiz") { StartQuiz(.Easy) }
            #endif
        }
        .onChange(of: ScenePhase) { _, Phase in
            if Phase == .active { Now = .now; Store.RefreshDay() }
        }
    }

    private func StartQuiz(_ Mode: QuizMode) {
        Now = .now
        let IsPractice = true
        ActiveQuiz = QuizSession(Mode: Mode,
                                 Questions: QuizPlanner.MakeQuestions(From: Store.Entries, Mode: Mode,
                                                                      Now: Now, IncludeUpcoming: IsPractice),
                                 IsPractice: IsPractice)
    }

    private var DailyPlan: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionEyebrow(Title: Store.Today?.Comeback == true ? "Welcome back · a gentle start" : "Your daily plan")
            Text(Store.Today?.FullMet == true ? "Today, well spent." : "A few words.\nA little progress.")
                .font(.largeTitle.bold())
            let Completed = Store.Today?.Completed.count ?? 0
            let Target = Store.Today?.Target ?? 0
            ProgressView(value: Double(min(Completed, Target)), total: Double(max(1, Target))).tint(Palette.Accent)
                .accessibilityLabel("Today's progress").accessibilityValue("\(Completed) of \(Target)")
            HStack {
                Text("\(Completed) / \(Target) words")
                Spacer()
                Label("\(Store.Streak.Current) day streak", systemImage: "flame")
            }.font(.subheadline).foregroundStyle(Palette.Muted)
            if let Day = Store.Today {
                Text("New: \(LearningEngine.NewEntries(Store.Entries, Excluding: Day.Introduced, Limit: max(0, Day.NewLimit - Day.Introduced.count), Now: Now).count) left · Reviews: \(min(DueCount, max(0, Day.ReviewLimit - Day.Reviewed.count))) due")
                    .font(.subheadline)
                Text(Day.MinimumMet ? "Daily minimum complete. Reminders are quiet for today." : "Daily minimum: \(Store.Today?.Attempted.count ?? 0) / \(min(Store.Learning.Settings.MinimumCards, Target)) words practised")
                    .font(.caption).foregroundStyle(Palette.Muted)
            }
            Button(Store.Learning.Session == nil ? "Start today's plan" : "Continue saved session") {
                if Store.StartStudy() { Store.PresentStudy = true }
                else { Notice = "You're caught up for now. Your next words will appear when due. You can still use free practice below." }
            }.buttonStyle(PrimaryActionStyle(Tint: Palette.White))
            Button("Adjust my plan") { ShowingPlan = true }.frame(minHeight: 44)
        }.padding(24).FrostedCard(CornerRadius: 30)
    }

    private var Header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.Muted)
                Text("WordRevisit")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            Spacer()
                Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Palette.Accent)
                .frame(width: 48, height: 48)
                .FrostedCard(CornerRadius: 16)
        }
    }


}

private struct ModeCard: View {
    let Mode: QuizMode
    let Tint: Color
    let Action: () -> Void

    var body: some View {
        Button(action: Action) {
            HStack(spacing: 16) {
                Image(systemName: Mode.Symbol)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Tint)
                    .frame(width: 54, height: 54)
                    .background(Tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 17))
                VStack(alignment: .leading, spacing: 5) {
                    Text(Mode.Title).font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(Mode.Subtitle).font(.system(size: 13)).foregroundStyle(Palette.Muted)
                }
                Spacer(minLength: 2)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Tint)
            }
            .padding(18)
            .FrostedCard(CornerRadius: 25)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
