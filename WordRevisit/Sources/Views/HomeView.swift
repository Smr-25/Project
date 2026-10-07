import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var Store: WordRepository
    @State private var ActiveMode: QuizMode?

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    Header
                    Hero
                    Stats
                    SectionEyebrow(Title: "Choose your challenge")
                    ModeCard(Mode: .Easy, Tint: Palette.White) { ActiveMode = .Easy }
                    ModeCard(Mode: .Hard, Tint: Palette.Accent) { ActiveMode = .Hard }
                    Footer
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(item: $ActiveMode) { Mode in
            QuizView(Mode: Mode, Questions: QuizPlanner.MakeQuestions(From: Store.Entries, Mode: Mode))
                .environmentObject(Store)
        }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-PreviewQuiz") { ActiveMode = .Easy }
            #endif
        }
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

    private var Hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 7) {
                Circle().fill(Palette.Accent).frame(width: 7, height: 7)
                Text("YOUR DAILY PRACTICE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Palette.Accent)
            }
            Text("Make every\nword count.")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .tracking(-1.5)
                .fixedSize(horizontal: false, vertical: true)
            Text("A few minutes of recall today, a stronger vocabulary tomorrow.")
                .font(.system(size: 15))
                .foregroundStyle(Palette.Muted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(28)
        .background {
            RoundedRectangle(cornerRadius: 32)
                .fill(LinearGradient(colors: [Color(red: 0.24, green: 0.055, blue: 0.075),
                                              Color(red: 0.08, green: 0.08, blue: 0.09)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(alignment: .topTrailing) {
                    Circle().stroke(.white.opacity(0.10), lineWidth: 30)
                        .frame(width: 190, height: 190).offset(x: 76, y: -65)
                        .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 32))
        }
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(.white.opacity(0.15)))
    }

    private var Stats: some View {
        HStack(spacing: 12) {
            StatTile(Value: "\(Store.Entries.count)", Label: "Words saved", Symbol: "text.book.closed", Tint: Palette.Accent)
            StatTile(Value: "\(Store.Accuracy)%", Label: "Recall rate", Symbol: "chart.line.uptrend.xyaxis", Tint: Palette.White)
        }
    }

    private var Footer: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge")
                .foregroundStyle(Palette.Accent)
            Text(Store.RemindersEnabled ? "Morning and evening reminders are on" : "Set reminders to build a daily rhythm")
                .font(.system(size: 13))
                .foregroundStyle(Palette.Muted)
        }
        .padding(.top, 4)
    }
}

private struct StatTile: View {
    let Value: String
    let Label: String
    let Symbol: String
    let Tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: Symbol).foregroundStyle(Tint).font(.system(size: 18))
            Text(Value).font(.system(size: 28, weight: .bold, design: .rounded))
            Text(Label).font(.system(size: 12)).foregroundStyle(Palette.Muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .FrostedCard(CornerRadius: 24)
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
        }
        .buttonStyle(.plain)
    }
}
