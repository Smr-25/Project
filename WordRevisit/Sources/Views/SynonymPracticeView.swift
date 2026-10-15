import SwiftUI

struct SynonymPracticeView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    @State private var ShowingRound = false
    @State private var Selected: UUID?
    private var Round: SynonymRound? { ShowingRound ? Store.Synonyms.Round : nil }
    private var Groups: [VocabularyGroup] { VocabularyGroup.Make(Store.Entries) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let Round {
                            if Round.IsFinished { Results(Round) }
                            else {
                                HStack {
                                    SectionEyebrow(Title: Round.IsRetry ? "Missed synonyms · one retry" : "Cycle \(Store.Synonyms.Cycle)")
                                    Spacer()
                                    Text(Round.Mode.rawValue).font(.subheadline).foregroundStyle(Palette.Muted)
                                }
                                if Round.Mode == .Grouping { Grouping(Round) }
                                else { Easy(Round) }
                            }
                        } else { Introduction }
                    }.padding(24)
                }
            }
            .safeAreaInset(edge: .bottom) { Actions }
            .navigationTitle("Synonym practice").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { Dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                        .accessibilityLabel("Save and close synonyms")
                }
            }
        }.onAppear { ShowingRound = Store.Synonyms.Round?.IsFinished == false }
    }

    private var Introduction: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "rectangle.3.group.fill").font(.system(size: 40)).foregroundStyle(Palette.Accent)
            Text("Same meaning.\nMore possibilities.").font(.largeTitle.bold())
            Text("\(Groups.count) synonym families in your vocabulary").font(.headline)
            Text("Practise related meanings in a separate shuffled cycle. Every family gets a turn, and missed words return once.")
                .foregroundStyle(Palette.Muted)
            ModePicker
            Text("Grouping draws up to three families with no shared words. A single remaining family uses Easy. Every synonym in each selected family is included.")
                .font(.subheadline).foregroundStyle(Palette.Muted)
            if Groups.isEmpty {
                Text("Import the supplied vocabulary to add reviewed synonym families. A family needs at least two of its words in My words.")
                    .font(.subheadline)
            }
        }
    }

    private var ModePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionEyebrow(Title: "Synonym mode")
            Picker("Synonym mode", selection: Binding(get: { Store.Synonyms.PreferredMode }, set: { Store.SetSynonymMode($0) })) {
                ForEach(SynonymMode.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).accessibilityIdentifier("SynonymMode")
            Text(Store.Synonyms.PreferredMode == .Grouping ? "Tap a word, then choose its family." : "Choose a synonym for the displayed meaning.")
                .font(.subheadline).foregroundStyle(Palette.Muted)
        }.padding(20).FrostedCard()
    }

    private func Grouping(_ Round: SynonymRound) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(Round.Revealed ? "Your families" : "Find each word’s family.").font(.title.bold())
            let Waiting = Round.ActiveChips.filter { Round.Inputs[$0.id.uuidString] == nil }
            if !Waiting.isEmpty {
                SectionEyebrow(Title: "\(Waiting.count) words to place")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 12) {
                    ForEach(Waiting) { Item in Chip(Item, Round) }
                }
            }
            ForEach(Round.Families) { Family in
                VStack(alignment: .leading, spacing: 10) {
                    Text(Family.Words.first?.Term ?? "").font(.title2.bold()).foregroundStyle(Palette.Accent)
                    Text(Family.Name).font(.caption).foregroundStyle(Palette.Muted)
                    let Placed = Round.ActiveChips.filter { Round.Inputs[$0.id.uuidString] == Family.Code }
                    if Placed.isEmpty { Text("Choose a word below to place it here.").font(.caption).foregroundStyle(Palette.Muted) }
                    ForEach(Placed) { Item in Chip(Item, Round) }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(16).FrostedCard()
            }

        }
    }

    private func Chip(_ Item: SynonymChip, _ Round: SynonymRound) -> some View {
        Button { Selected = Item.id } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(Item.Word.Term).font(.headline)
                    Spacer(minLength: 4)
                    if Round.Revealed {
                        Image(systemName: Round.Correct(Item, Retry: Round.IsRetry) ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(Round.Correct(Item, Retry: Round.IsRetry) ? Palette.Success : Palette.Danger)
                    } else if Selected == Item.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.Accent) }
                }
                if Round.Revealed {
                    Text(Item.Word.Translation).font(.caption).foregroundStyle(Palette.Muted)
                    if !Round.Correct(Item, Retry: Round.IsRetry) {
                        Text("Family: \(Round.Families.first { $0.Code == Item.Family }?.Words.first?.Term ?? "")")
                            .font(.caption.weight(.semibold)).foregroundStyle(Palette.Danger)
                    }
                }
            }.padding(12).frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .background(Selected == Item.id && !Round.Revealed ? Palette.Accent.opacity(0.14) : Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        }.buttonStyle(.plain).disabled(Round.Revealed).accessibilityIdentifier("SynonymChip-\(Item.Word.Term)")
    }

    private func Easy(_ Round: SynonymRound) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            if let Item = Round.Current, let Family = Round.Families.first(where: { $0.Code == Item.Family }) {
                Text("\(Round.Index + 1) / \(Round.ActiveChips.count)").font(.subheadline).foregroundStyle(Palette.Muted)
                VStack(alignment: .leading, spacing: 12) {
                    SectionEyebrow(Title: "Choose a synonym")
                    Text(Family.Words.first?.Term ?? "").font(.largeTitle.bold()).accessibilityIdentifier("SynonymPrompt")
                    Text(Family.Name).foregroundStyle(Palette.Muted)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(24).FrostedCard()
                if Item.IsReview {
                    Text("No distinct alternatives are available. Review this synonym; it will not count towards your score.").font(.subheadline).foregroundStyle(Palette.Muted)
                }
                ForEach(Item.Options, id: \.self) { Option in
                    Button {
                        Store.AssignSynonym(Option, Chip: Item.id, Round: Round.id, Retry: Round.IsRetry)
                    } label: {
                        HStack {
                            Text(Option).font(.headline)
                            Spacer()
                            if Round.Revealed && Option == Item.Word.Term { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.Success) }
                            else if Round.Revealed && Round.Inputs[Item.id.uuidString] == Option { Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.Danger) }
                        }.padding(18).frame(maxWidth: .infinity, minHeight: 54).FrostedCard(CornerRadius: 18)
                    }.buttonStyle(.plain).disabled(Round.Revealed).accessibilityIdentifier("SynonymOption")
                }
            }
        }
    }

    private var Actions: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let Round, !Round.IsFinished {
                if Round.Revealed {
                    if Round.Mode == .Easy, let Item = Round.Current {
                        Label(Item.IsReview ? "Reviewed" : Round.Correct(Item, Retry: Round.IsRetry) ? "Correct" : "Incorrect",
                              systemImage: Round.Correct(Item, Retry: Round.IsRetry) ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.headline).foregroundStyle(Round.Correct(Item, Retry: Round.IsRetry) ? Palette.Success : Palette.Danger)
                        Text("\(Item.Word.Term) · \(Item.Word.Translation)").font(.subheadline)
                    } else { Text("\(Round.ActiveChips.filter { Round.Correct($0, Retry: Round.IsRetry) }.count) / \(Round.ActiveChips.count) placed correctly").font(.headline) }
                    Button("Next") {
                        Selected = nil
                        Store.AdvanceSynonyms(Round: Round.id, Chip: Round.Current?.id, Retry: Round.IsRetry)
                    }.buttonStyle(PrimaryActionStyle()).accessibilityIdentifier("NextSynonym")
                } else if Round.Mode == .Grouping {
                    if let Item = Round.ActiveChips.first(where: { $0.id == Selected }) {
                        Text("Place: \(Item.Word.Term)").font(.headline)
                        ViewThatFits(in: .horizontal) {
                            HStack { FamilyButtons(Round, Item) }
                            VStack { FamilyButtons(Round, Item) }
                        }
                    } else { Text("Tap a word to choose its family.").font(.subheadline).foregroundStyle(Palette.Muted) }
                    Button("Check families") { Selected = nil; Store.CheckSynonyms(Round: Round.id) }
                        .buttonStyle(PrimaryActionStyle()).disabled(!Round.CanCheck).accessibilityIdentifier("CheckSynonyms")
                }
            } else {
                Button(Round == nil ? "Start synonyms" : Store.Synonyms.CycleComplete ? "Start next synonym cycle" : "Next synonym round") {
                    if Store.StartSynonyms() { ShowingRound = true; Selected = nil }
                }.buttonStyle(PrimaryActionStyle()).disabled(Groups.isEmpty).accessibilityIdentifier("StartSynonyms")
                if Round != nil { Button("Back to home") { Dismiss() }.frame(maxWidth: .infinity, minHeight: 44) }
            }
        }.padding(.horizontal, 20).padding(.vertical, 14).frame(maxWidth: .infinity).background(.regularMaterial)
    }

    private func FamilyButtons(_ Round: SynonymRound, _ Item: SynonymChip) -> some View {
        ForEach(Round.Families) { Family in
            Button(Family.Words.first?.Term ?? "") {
                Store.AssignSynonym(Family.Code, Chip: Item.id, Round: Round.id, Retry: Round.IsRetry); Selected = nil
            }.buttonStyle(.bordered).frame(minHeight: 44).accessibilityIdentifier("PlaceIn-\(Family.Code)")
        }
    }

    private func Results(_ Round: SynonymRound) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 44)).foregroundStyle(Palette.Success)
            Text(Store.Synonyms.CycleComplete ? "Synonym cycle complete" : "Round complete").font(.largeTitle.bold())
                .accessibilityIdentifier("SynonymResults")
            Text("\(Round.Score) / \(Round.ScoredChips.count) correct on the first try").font(.title3)
            if Round.IsRetry { Text("Missed synonyms revisited once.").foregroundStyle(Palette.Muted) }
            Text("\(Store.Synonyms.Remaining.count) families waiting in this cycle.").foregroundStyle(Palette.Muted)
            ModePicker
        }
    }
}
