import SwiftUI
import Combine

struct StudySessionView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    @Environment(\.scenePhase) private var Phase
    @State private var Input = ""
    @State private var Hint = false
    @State private var Mnemonic = ""
    @State private var Started = Date.now
    @State private var Elapsed = 0.0
    @State private var Now = Date.now
    @FocusState private var Focused: Bool
    private let Timer = Foundation.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var Card: StudyCard? { Store.Learning.Session?.Current }
    private var Entry: WordEntry? { Store.Entries.first { $0.Id == Card?.WordId } }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        if let Card, let Entry {
                            if Card.Kind == .Introduction { Introduction(Card, Entry) }
                            else if Card.ReadyAt > Now && Card.Result == nil { Waiting(Card) }
                            else { Question(Card, Entry) }
                        } else { Results }
                    }
                    .padding(24)
                }
                .scrollDismissesKeyboard(.interactively)
                .id(Card?.id)
            }
            .navigationTitle(Store.Learning.Session?.IsPractice == true ? "Synonym practice" : "Today's session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { SaveDraft(); Dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                        .accessibilityLabel("Save and close session")
                }
            }
        }
        .onAppear { LoadCard() }
        .onChange(of: Card?.id) { _, _ in LoadCard() }
        .onReceive(Timer) { Value in Now = Value; Store.ReorderReady(Now: Value) }
        .onChange(of: Phase) { Old, New in
            if New == .active { Started = .now; Now = .now }
            else if Old == .active { Elapsed += Date.now.timeIntervalSince(Started); SaveDraft() }
        }
        .onDisappear { SaveDraft(); Task { await Store.RefreshNotifications() } }
    }

    private func Introduction(_ Card: StudyCard, _ Entry: WordEntry) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionEyebrow(Title: "Meet a new word")
            Text(Entry.Term).font(.largeTitle.bold()).accessibilityIdentifier("StudyIntroduction")
            Text(Entry.Translation).font(.title2)
            if !Entry.Definition.isEmpty { Text(Entry.Definition).foregroundStyle(Palette.Muted) }
            if !Entry.ExampleSentences.isEmpty { Text(Entry.ExampleSentences).font(.body.italic()) }
            TextField("Add a memory hook (optional)", text: $Mnemonic, axis: .vertical)
                .padding(16).FrostedCard(CornerRadius: 18)
            Text("You will recall this word after a short gap. You can leave and continue later.")
                .font(.subheadline).foregroundStyle(Palette.Muted)
            Button("Learn this word") { Store.Introduce(CardId: Card.id, Known: false, Skip: false, Mnemonic: Mnemonic) }
                .buttonStyle(PrimaryActionStyle(Tint: Palette.White))
            Button("I already know this") { Store.Introduce(CardId: Card.id, Known: true, Skip: false, Mnemonic: Mnemonic) }
                .frame(maxWidth: .infinity, minHeight: 44)
            Button("Leave for tomorrow") { Store.Introduce(CardId: Card.id, Known: false, Skip: true, Mnemonic: Mnemonic) }
                .foregroundStyle(Palette.Muted).frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    private func Waiting(_ Card: StudyCard) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            SectionEyebrow(Title: "A little space helps")
            Text("Your next recall is coming up.").font(.largeTitle.bold())
            Text(Card.ReadyAt, style: .relative).font(.title.monospacedDigit()).foregroundStyle(Palette.Accent)
            Text("Your progress is saved. You can close the session and come back when this word is ready.")
                .foregroundStyle(Palette.Muted)
            Button("Save and return home") { Dismiss() }.buttonStyle(PrimaryActionStyle(Tint: Palette.White))
        }
    }

    private func Question(_ Card: StudyCard, _ Entry: WordEntry) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionEyebrow(Title: Entry.Learning.LearningStep == 2 && Entry.Learning.Stage == 0 ? "Your mini-test" : Card.Kind == .Synonym ? "Choose a synonym" : Card.Kind.IsChoice ? "Choose the answer" : "Recall and write")
            Text(Card.Prompt).font(.largeTitle.bold()).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("StudyPrompt")
                .frame(maxWidth: .infinity, alignment: .leading).padding(24).FrostedCard()
            if Card.Kind.IsChoice {
                ForEach(Card.Options, id: \.self) { Option in
                    Button { Input = Option; Submit(Card) } label: {
                        HStack { Text(Option); Spacer(); if Card.Input == Option { Image(systemName: "checkmark.circle") } }
                            .padding(18).frame(maxWidth: .infinity, minHeight: 50).FrostedCard(CornerRadius: 18).contentShape(Rectangle())
                    }.buttonStyle(.plain).disabled(Card.Result != nil)
                }
            } else {
                TextField("Type what you remember...", text: $Input)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.done)
                    .focused($Focused).onSubmit { Submit(Card) }
                    .padding(18).FrostedCard(CornerRadius: 18).disabled(Card.Result != nil)
                    .accessibilityIdentifier("StudyAnswer")
            }
            if Card.Result == nil {
                if !Entry.ExampleSentences.isEmpty || !Entry.MySentence.isEmpty {
                    if Hint { Text([Entry.ExampleSentences, Entry.MySentence].filter { !$0.isEmpty }.joined(separator: "\n")).foregroundStyle(Palette.Muted) }
                    else { Button("Show sentence hint") { Hint = true; SaveDraft() }.frame(minHeight: 44) }
                }
                if !Card.Kind.IsChoice {
                    Button("Check answer") { Submit(Card) }.buttonStyle(PrimaryActionStyle(Tint: Palette.White))
                        .disabled(Input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Button("I don't know") { Submit(Card, DontKnow: true) }
                    .frame(maxWidth: .infinity, minHeight: 44).foregroundStyle(Palette.Muted)
            } else {
                Feedback(Card, Entry)
                Button("Continue") { Store.AdvanceStudy(CardId: Card.id) }
                    .buttonStyle(PrimaryActionStyle(Tint: Palette.Accent))
            }
        }
    }

    private func Feedback(_ Card: StudyCard, _ Entry: WordEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Card.Result == .Correct ? "You got it" : Card.Result == .Hard ? "Correct · keep practising" : "Let's revisit this one",
                  systemImage: Card.Result?.IsCorrect == true ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                .foregroundStyle(Palette.Accent).font(.headline)
            Text(Card.Expected).font(.title2.bold())
            if Card.Result == .Hard { Text("A hint, a longer response, or a small spelling error keeps this interval steady.").font(.caption).foregroundStyle(Palette.Muted) }
            ForEach([Entry.Definition, Entry.ExampleSentences, Entry.MySentence, Entry.Mnemonic].filter { !$0.isEmpty }, id: \.self) { Text($0) }
            if Entry.Learning.Lapses >= Store.Learning.Settings.LeechThreshold && Entry.Mnemonic.isEmpty {
                TextField("Give this difficult word a memory hook", text: $Mnemonic, axis: .vertical).textFieldStyle(.roundedBorder)
                Button("Save memory hook") { Store.SetMnemonic(Mnemonic, WordId: Entry.Id) }.disabled(Mnemonic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(22).FrostedCard()
    }

    private var Results: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("A little further.").font(.largeTitle.bold())
            let Logs = Store.Learning.Session?.Finished ?? []
            Text("\(Logs.filter { $0.Result.IsCorrect }.count) of \(Logs.count) answers recalled")
                .font(.title2).foregroundStyle(Palette.Accent)
            Text("Your progress and next review dates are saved.").foregroundStyle(Palette.Muted)
            ForEach(Logs) { Log in
                VStack(alignment: .leading, spacing: 7) {
                    Text(Log.Prompt).font(.headline)
                    Text("You: \(Log.Input)").foregroundStyle(Palette.Muted)
                    Text(Log.Expected).foregroundStyle(Log.Result.IsCorrect ? Palette.White : Palette.Accent)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(18).FrostedCard(CornerRadius: 20)
            }
            Button("Back to today") { Store.FinishStudy(); Dismiss() }.buttonStyle(PrimaryActionStyle(Tint: Palette.White))
        }
    }

    private func LoadCard() {
        Input = Card?.Input ?? ""; Hint = Card?.HintUsed ?? false; Mnemonic = Entry?.Mnemonic ?? ""
        Started = .now; Elapsed = 0; Focused = false
    }
    private func SaveDraft() {
        if let Card, Card.Kind != .Introduction, Card.Result == nil { Store.SaveDraft(CardId: Card.id, Input: Input, Hint: Hint) }
    }
    private func Submit(_ Card: StudyCard, DontKnow: Bool = false) {
        guard self.Card?.id == Card.id, Card.Result == nil else { return }
        Store.SubmitStudy(CardId: Card.id, Input: Input, Hint: Hint,
                          Milliseconds: Int((Elapsed + Date.now.timeIntervalSince(Started)) * 1000), DontKnow: DontKnow)
        Focused = false
        if self.Card?.Result?.IsCorrect == true { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        else { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        Task { await Store.RefreshNotifications() }
    }
}
