import SwiftUI

struct ImportWordsView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    var CSV: String?
    @State private var SourceText = ""
    @State private var Preview: ImportPreview?
    @State private var ErrorText: String?
    var body: some View {
        NavigationStack {
            Form {
                if CSV == nil {
                    Section("One pair per line: word - tərcümə") {
                        TextEditor(text: $SourceText).frame(minHeight: 150).autocorrectionDisabled().textInputAutocapitalization(.never)
                            .accessibilityIdentifier("PasteWords")
                    }
                }
                Section {
                    Text("English and Azerbaijani are required. Group is optional. Other CSV columns are ignored.")
                    Text("Existing English words are updated without resetting your cycle. Repeated rows in this file combine their meanings and groups. A missing Group column keeps current groups; an empty Group clears them.")
                }.font(.subheadline)
                if let Preview {
                    Section("Import preview") {
                        LabeledContent("New words", value: "\(Preview.Added)")
                        LabeledContent("Words to update", value: "\(Preview.Updated)")
                        LabeledContent("Unchanged words", value: "\(Preview.Unchanged)")
                        LabeledContent("Repeated rows combined", value: "\(Preview.Duplicates)")
                        LabeledContent("Invalid rows skipped", value: "\(Preview.Errors.count)")
                        ForEach(Preview.Errors.prefix(20), id: \.self) { Text($0).font(.caption).foregroundStyle(Palette.Danger) }
                    }
                }
                if let ErrorText { Text(ErrorText).foregroundStyle(Palette.Danger) }
            }.navigationTitle(CSV == nil ? "Paste words" : "Import CSV")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { Dismiss() } } }
                .safeAreaInset(edge: .bottom) {
                    Group {
                        if let Preview {
                            Button("Import \(Preview.Added + Preview.Updated) words") {
                                if Store.ApplyImport(Text: SourceText, Paste: CSV == nil) { Dismiss() }
                            }.disabled(Preview.Added + Preview.Updated == 0)
                        } else {
                            Button("Preview import") { BuildPreview() }.disabled(SourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }.buttonStyle(PrimaryActionStyle()).padding(20).background(.regularMaterial)
                }
                .onAppear { SourceText = CSV ?? ""; if CSV != nil { BuildPreview() } }
                .onChange(of: SourceText) { _, _ in if CSV == nil { Preview = nil } }
        }.tint(Palette.Accent)
    }
    private func BuildPreview() {
        do { Preview = try ImportPreview(Text: SourceText, Existing: Store.Entries, Paste: CSV == nil); ErrorText = nil }
        catch { ErrorText = error.localizedDescription; Preview = nil }
    }
}
