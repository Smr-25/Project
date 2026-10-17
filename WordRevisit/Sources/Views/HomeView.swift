import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var Store: WordRepository
    @State private var ShowingPractice = false
    @State private var ShowingSynonyms = false
    private var Resuming: Bool { Store.Session != nil && Store.Session?.IsFinished == false }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            SectionEyebrow(Title: "A little practice, anytime")
                            Text("WordRevisit").font(.title.bold())
                        }
                        Spacer()
                        Image("BrandLogo").resizable().scaledToFit().frame(width: 44, height: 44)
                            .clipShape(Circle()).accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 20) {
                        SectionEyebrow(Title: "Cycle \(Store.Data.Bag.Cycle)")
                        Text(Store.Entries.isEmpty ? "Your words come first." : Store.Data.Bag.CycleComplete ? "Cycle complete." : "Every word.\nIts turn.")
                            .font(.largeTitle.bold())
                        HStack(alignment: .top) {
                            Metric("\(Store.Entries.count)", "Words")
                            Metric("\(Store.Data.Bag.Remaining.count)", "Waiting in this cycle")
                        }
                        if let Session = Store.Session, !Session.IsFinished {
                            Label(Session.IsRetry ? "One more look at missed words" : "Group in progress", systemImage: "bookmark.fill")
                                .foregroundStyle(Palette.Accent)
                            Text("\(Session.Mode.rawValue) · \(Session.Index + 1) of \(Session.CurrentQuestions.count)")
                                .foregroundStyle(Palette.Muted)
                        } else {
                            Text(Store.Data.Bag.CycleComplete ? "You have practised every word. Start a fresh shuffled cycle whenever you like." : "Up to 20 words per group. Keep going for as long as you like.")
                                .foregroundStyle(Palette.Muted)
                        }
                    }.padding(24).FrostedCard(CornerRadius: 30)
                    Button { ShowingSynonyms = true } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "rectangle.3.group.fill").font(.title).foregroundStyle(Palette.Accent)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(Store.Synonyms.Round?.IsFinished == false ? "Continue synonyms" : "Synonym practice").font(.headline)
                                Text("\(Store.Groups.count) families · a separate cycle")
                                    .font(.subheadline).foregroundStyle(Palette.Muted)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right").foregroundStyle(Palette.Accent)
                        }.padding(22).FrostedCard(CornerRadius: 24)
                    }.buttonStyle(.plain).accessibilityIdentifier("OpenSynonyms")
                    if let Notice = Store.Synonyms.Notice { Text(Notice).font(.subheadline).foregroundStyle(Palette.Muted) }
                    if !Resuming {
                        ModePicker()
                    } else {
                        Text("Your saved group keeps its mode. Choose a different mode for the next group.")
                            .font(.subheadline).foregroundStyle(Palette.Muted)
                    }
                }.padding(24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(Resuming ? "Continue group" : Store.Data.Bag.CycleComplete ? "Start next cycle" : "Start practice") {
                if Store.StartPractice() { ShowingPractice = true }
            }
            .buttonStyle(PrimaryActionStyle())
            .disabled(Store.Entries.isEmpty)
            .padding(20).background(.regularMaterial)
        }
        .fullScreenCover(isPresented: $ShowingPractice) { QuizView() }
        .fullScreenCover(isPresented: $ShowingSynonyms) { SynonymPracticeView() }
    }

    private func Metric(_ Value: String, _ Label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Value).font(.title.bold())
            Text(Label).font(.caption).foregroundStyle(Palette.Muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ModePicker: View {
    var Identifier = "PracticeMode"
    @EnvironmentObject private var Store: WordRepository
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionEyebrow(Title: "Practice mode")
            Picker("Practice mode", selection: Binding(get: { Store.Data.PreferredMode }, set: { Store.SetMode($0) })) {
                ForEach(QuizMode.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).accessibilityIdentifier(Identifier)
            Text(Store.Data.PreferredMode.Subtitle).font(.subheadline).foregroundStyle(Palette.Muted)
        }
    }
}
