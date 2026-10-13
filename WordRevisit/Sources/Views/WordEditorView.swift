import SwiftUI

struct WordEditorView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    private let Id: UUID
    private let IsNew: Bool
    @State private var English: String
    @State private var Azerbaijani: String
    @State private var Group: String

    init(Entry: WordEntry? = nil) {
        Id = Entry?.Id ?? UUID(); IsNew = Entry == nil
        _English = State(initialValue: Entry?.Term ?? "")
        _Azerbaijani = State(initialValue: Entry?.Translation ?? "")
        _Group = State(initialValue: Entry?.Group ?? "")
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("English · required") {
                    TextField("English word or phrase", text: $English).accessibilityIdentifier("EditEnglish")
                }
                Section("Azerbaijani · required") {
                    TextField("Translation; another meaning", text: $Azerbaijani, axis: .vertical).accessibilityIdentifier("EditTranslation")
                }
                Section("Group · optional") {
                    TextField("For example: size", text: $Group)
                    Text("Words with the same group appear together in Synonyms.").font(.caption).foregroundStyle(Palette.Muted)
                }
            }.textInputAutocapitalization(.never).autocorrectionDisabled()
                .navigationTitle(IsNew ? "Add word" : "Edit word")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { Dismiss() } } }
                .safeAreaInset(edge: .bottom) {
                    Button("Save word") {
                        let Entry = WordEntry(Id: Id, Term: English.trimmingCharacters(in: .whitespacesAndNewlines),
                            Translation: Azerbaijani.trimmingCharacters(in: .whitespacesAndNewlines), Group: Group.trimmingCharacters(in: .whitespacesAndNewlines))
                        if Store.SaveEntry(Entry) { Dismiss() }
                    }.buttonStyle(PrimaryActionStyle())
                        .disabled(QuizPlanner.Normalize(English).isEmpty || QuizPlanner.Meanings(Azerbaijani).isEmpty)
                        .padding(20).background(.regularMaterial)
                }
        }.tint(Palette.Accent)
    }
}
