import SwiftUI

struct WordEditorView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss

    let Entry: WordEntry?
    @State private var Term: String
    @State private var Translation: String
    @State private var Definition: String
    @State private var ExampleSentences: String
    @State private var Group: String
    @State private var PartOfSpeech: String
    @State private var Mnemonic: String
    @State private var MySentence: String
    @State private var Suspended: Bool
    @State private var ShowingDelete = false
    @State private var ErrorText: String?

    init(Entry: WordEntry? = nil) {
        self.Entry = Entry
        _Group = State(initialValue: Entry?.Group ?? "")
        _PartOfSpeech = State(initialValue: Entry?.PartOfSpeech ?? "")
        _Mnemonic = State(initialValue: Entry?.Mnemonic ?? "")
        _MySentence = State(initialValue: Entry?.MySentence ?? "")
        _Suspended = State(initialValue: Entry?.Learning.Suspended ?? false)
        _Term = State(initialValue: Entry?.Term ?? "")
        _Translation = State(initialValue: Entry?.Translation ?? "")
        _Definition = State(initialValue: Entry?.Definition ?? "")
        _ExampleSentences = State(initialValue: Entry?.ExampleSentences ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        SectionEyebrow(Title: "Make it memorable")
                        Text(Entry == nil ? "Add a word" : "Edit your word")
                            .font(.system(size: 35, weight: .bold, design: .rounded))
                        InputGroup(Title: "ENGLISH WORD", Placeholder: "Enter an English word", Value: $Term)
                        InputGroup(Title: "AZERBAIJANI TRANSLATION", Placeholder: "Enter its translation", Value: $Translation)
                        InputGroup(Title: "DEFINITION · OPTIONAL", Placeholder: "A short meaning", Value: $Definition)
                        InputGroup(Title: "EXAMPLE SENTENCES · OPTIONAL", Placeholder: "Write a sentence using this word", Value: $ExampleSentences)
                        Text("Your examples appear as hints in both quiz modes. You only answer with the word or its translation.")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.Muted)
                        Text("For multiple accepted translations, separate them with a semicolon.")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.Muted)
                        InputGroup(Title: "SYNONYM GROUP · OPTIONAL", Placeholder: "For example: increase", Value: $Group)
                        InputGroup(Title: "PART OF SPEECH · OPTIONAL", Placeholder: "noun, verb, adjective…", Value: $PartOfSpeech)
                        InputGroup(Title: "MEMORY HOOK · OPTIONAL", Placeholder: "A story or association that helps you remember", Value: $Mnemonic)
                        InputGroup(Title: "MY SENTENCE · OPTIONAL", Placeholder: "Write your own sentence", Value: $MySentence)
                        if !MySentence.isEmpty { ShareLink("Share my sentence", item: MySentence).padding(.vertical, 10) }
                        Toggle("Pause this word", isOn: $Suspended).tint(Palette.Accent)
                        Button("Save word") { SaveWord() }
                            .buttonStyle(PrimaryActionStyle(Tint: Palette.Primary))
                            .disabled(Term.trimmingCharacters(in: .whitespaces).isEmpty ||
                                      Translation.trimmingCharacters(in: .whitespaces).isEmpty)
                        if Entry != nil {
                            Button("Delete word", role: .destructive) { ShowingDelete = true }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 10)
                        }
                    }
                    .padding(24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { Dismiss() }.foregroundStyle(Palette.Accent)
                }
            }
            .toolbarBackground(.hidden)
            .confirmationDialog("Delete this word?", isPresented: $ShowingDelete) {
                Button("Delete word", role: .destructive) {
                    if let Entry { Store.Delete(Entry) }
                    Dismiss()
                }
            }
            .alert("Could not save", isPresented: Binding(
                get: { ErrorText != nil }, set: { if !$0 { ErrorText = nil } }
            )) { Button("OK") { ErrorText = nil } } message: { Text(ErrorText ?? "") }
        }

    }

    private func SaveWord() {
        var Updated = Entry ?? WordEntry(Term: Term, Translation: Translation)
        Updated.Term = Term.trimmingCharacters(in: .whitespacesAndNewlines)
        Updated.Translation = Translation.trimmingCharacters(in: .whitespacesAndNewlines)
        Updated.Definition = Definition.trimmingCharacters(in: .whitespacesAndNewlines)
        Updated.ExampleSentences = ExampleSentences.trimmingCharacters(in: .whitespacesAndNewlines)
        Updated.Group = Group.trimmingCharacters(in: .whitespacesAndNewlines)
        Updated.PartOfSpeech = PartOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        Updated.Mnemonic = Mnemonic.trimmingCharacters(in: .whitespacesAndNewlines)
        Updated.MySentence = MySentence.trimmingCharacters(in: .whitespacesAndNewlines)
        Updated.Learning.Suspended = Suspended
        guard Store.SaveEntry(Updated) else { ErrorText = "Check the word and translation. This pair may already exist."; return }
        Dismiss()
    }
}

private struct InputGroup: View {
    let Title: String
    let Placeholder: String
    @Binding var Value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionEyebrow(Title: Title)
            TextField(Placeholder, text: $Value, axis: .vertical)
                .lineLimit(1...3)
                .font(.system(size: 17))
                .padding(17)
                .FrostedCard(CornerRadius: 18)
        }
    }
}
