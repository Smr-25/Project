import SwiftUI

struct ImportWordsView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    var CSV: String?
    @State private var SourceText = ""
    @State private var Policy = DuplicatePolicy.Merge
    @State private var Preview: ImportPreview?
    @State private var ErrorText: String?
    var body: some View {
        NavigationStack {
            Form {
                if CSV == nil {
                    Section("One pair per line: word - tərcümə") {
                        TextEditor(text: $SourceText).frame(minHeight: 160).autocorrectionDisabled().textInputAutocapitalization(.never)
                            .accessibilityIdentifier("PasteWords")
                    }
                }
                Section("Same word, different translation") {
                    Picker("Action", selection: $Policy) { ForEach(DuplicatePolicy.allCases) { Text($0.rawValue).tag($0) } }
                    Text("Identical word and translation pairs are always skipped. Existing learning progress is kept when merging.").font(.caption)
                }
                Button("Preview import") { BuildPreview() }.disabled(SourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if let Preview {
                    Section("Review before importing") {
                        LabeledContent("New words", value: "\(Preview.Added)")
                        LabeledContent("Merged words", value: "\(Preview.Merged)")
                        LabeledContent("Duplicates skipped", value: "\(Preview.Duplicates)")
                        LabeledContent("Invalid rows skipped", value: "\(Preview.Errors.count)")
                        ForEach(Preview.Errors.prefix(20), id: \.self) { Text($0).font(.caption).foregroundStyle(Palette.Danger) }
                        Button("Import \(Preview.Added + Preview.Merged) words") {
                            if Store.ApplyImport(Text: SourceText, Policy: Policy, Paste: CSV == nil) { Dismiss() }
                        }.disabled(Preview.Added + Preview.Merged == 0)
                    }
                }
                if let ErrorText { Text(ErrorText).foregroundStyle(Palette.Danger) }
            }
            .navigationTitle(CSV == nil ? "Paste words" : "Import CSV")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { Dismiss() } } }
            .onAppear { SourceText = CSV ?? ""; if CSV != nil { BuildPreview() } }
            .onChange(of: Policy) { _, _ in Preview = nil }
            .onChange(of: SourceText) { _, _ in if CSV == nil { Preview = nil } }
        }.tint(Palette.Accent)
    }
    private func BuildPreview() {
        do { Preview = try ImportPreview(Text: SourceText, Existing: Store.Entries, Policy: Policy, Paste: CSV == nil); ErrorText = nil }
        catch { ErrorText = error.localizedDescription; Preview = nil }
    }
}
