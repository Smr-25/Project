import SwiftUI
import UniformTypeIdentifiers

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }
    var Text: String

    init(Text: String) { self.Text = Text }

    init(configuration: ReadConfiguration) throws {
        Text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(Text.utf8))
    }
}

struct LibraryView: View {
    @EnvironmentObject private var Store: WordRepository
    @State private var Search = ""
    @State private var ShowingAdd = false
    @State private var ShowingImport = false
    @State private var ShowingExport = false
    @State private var EditingEntry: WordEntry?
    @State private var Notice: String?
    @State private var Selecting = false
    @State private var Selected: Set<UUID> = []
    @State private var DeleteIds: Set<UUID> = []
    @State private var ConfirmDelete = false
    @State private var ShowingPaste = false
    @State private var ImportText: String?
    @State private var Filter = "All"
    @FocusState private var SearchFocused: Bool

    private var FilteredEntries: [WordEntry] {
        Store.Entries.filter {
            (Search.isEmpty || $0.Group.localizedCaseInsensitiveContains(Search) || $0.Term.localizedCaseInsensitiveContains(Search) ||
            $0.Translation.localizedCaseInsensitiveContains(Search))
            && (Filter == "All" || Filter == "New" && $0.Learning.IntroducedAt == nil
                || Filter == "Learning" && $0.Learning.Stage < 3 && $0.Learning.IntroducedAt != nil
                || Filter == "Review" && $0.Learning.Stage >= 3
                || Filter == "Difficult" && $0.Learning.Lapses >= Store.Learning.Settings.LeechThreshold
                || Filter == "Paused" && !$0.Learning.IsAvailable(at: .now)
                || Filter == "Synonyms" && !$0.Group.isEmpty)
        }
        .sorted { $0.Term.localizedStandardCompare($1.Term) == .orderedAscending }
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Header
                    SearchField
                    Picker("Filter words", selection: $Filter) {
                        ForEach(["All", "New", "Learning", "Review", "Difficult", "Paused", "Synonyms"], id: \.self) { Text($0).tag($0) }
                    }.pickerStyle(.menu)
                    if Selecting {
                        HStack {
                            Button("Select visible") { Selected.formUnion(FilteredEntries.map(\.Id)) }
                            Spacer()
                            Button("Delete (\(Selected.count))", role: .destructive) { DeleteIds = Selected; ConfirmDelete = true }.disabled(Selected.isEmpty)
                        }.frame(minHeight: 44)
                    }
                    HStack {
                        SectionEyebrow(Title: "Your collection")
                        Spacer()
                        Text("\(FilteredEntries.count) \(FilteredEntries.count == 1 ? "word" : "words")")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.Muted)
                    }
                    if FilteredEntries.isEmpty {
                        EmptyState
                    } else {
                        LazyVStack(spacing: 11) {
                            ForEach(FilteredEntries) { Entry in
                                Button {
                                    SearchFocused = false
                                    if Selecting {
                                        if Selected.contains(Entry.Id) { Selected.remove(Entry.Id) } else { Selected.insert(Entry.Id) }
                                    } else { EditingEntry = Entry }
                                } label: {
                                    HStack {
                                        if Selecting { Image(systemName: Selected.contains(Entry.Id) ? "checkmark.circle.fill" : "circle").foregroundStyle(Palette.Accent) }
                                        WordRow(Entry: Entry)
                                    }.contentShape(Rectangle())
                                }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 35)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $ShowingPaste) { ImportWordsView() }
        .sheet(isPresented: Binding(get: { ImportText != nil }, set: { if !$0 { ImportText = nil } })) { ImportWordsView(CSV: ImportText) }
        .confirmationDialog("Delete \(DeleteIds.count) words?", isPresented: $ConfirmDelete, titleVisibility: .visible) {
            Button("Delete \(DeleteIds.count) words", role: .destructive) {
                Store.Delete(Ids: DeleteIds); Selected.subtract(DeleteIds); Selecting = false
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("The selected words and their schedules will be removed. Past answer history stays. Export a backup first if you may want them back.") }
        .sheet(isPresented: $ShowingAdd) { WordEditorView() }
        .sheet(item: $EditingEntry) { Entry in WordEditorView(Entry: Entry) }
        .fileImporter(isPresented: $ShowingImport, allowedContentTypes: [.commaSeparatedText, .plainText]) { Result in
            do {
                let URL = try Result.get()
                let Accessed = URL.startAccessingSecurityScopedResource()
                defer { if Accessed { URL.stopAccessingSecurityScopedResource() } }
                let Text = try String(contentsOf: URL, encoding: .utf8)
                ImportText = Text
            } catch {
                Notice = "Import failed: \(error.localizedDescription)"
            }
        }
        .fileExporter(isPresented: $ShowingExport,
                      document: CSVDocument(Text: WordCSV.Encode(Store.Entries)),
                      contentType: .commaSeparatedText,
                      defaultFilename: "WordRevisit-Words") { Result in
            if case let .failure(Error) = Result { Notice = "Export failed: \(Error.localizedDescription)" }
        }
        .alert("WordRevisit", isPresented: Binding(
            get: { Notice != nil }, set: { if !$0 { Notice = nil } }
        )) { Button("OK") { Notice = nil } } message: { Text(Notice ?? "") }
    }

    private var Header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    SectionEyebrow(Title: "Build your vocabulary")
                    Text("My words")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                }
                Spacer()
                Button { ShowingAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Palette.Background)
                        .frame(width: 46, height: 46)
                        .background(Palette.White, in: RoundedRectangle(cornerRadius: 15))
                }
                .accessibilityLabel("Add word")
            }
            HStack(spacing: 10) {
                Menu {
                    Button(Selecting ? "Done selecting" : "Select words") { Selecting.toggle(); Selected = [] }
                    Button("Paste words") { ShowingPaste = true }
                    Button("Delete all words", role: .destructive) { DeleteIds = Set(Store.Entries.map(\.Id)); ConfirmDelete = true }.disabled(Store.Entries.isEmpty)
                } label: { Image(systemName: "ellipsis.circle").frame(width: 44, height: 44) }.accessibilityLabel("Manage words")
                Button { ShowingImport = true } label: {
                    Label("Import CSV", systemImage: "square.and.arrow.down")
                }
                Button { ShowingExport = true } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .buttonStyle(.plain)
            .foregroundStyle(Palette.Accent)
        }
    }

    private var SearchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass").foregroundStyle(Palette.Muted)
            TextField("Search your words", text: $Search)
                .focused($SearchFocused)
                .onSubmit { SearchFocused = false }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .font(.system(size: 15))
        .padding(17)
        .FrostedCard(CornerRadius: 19)
    }

    private var EmptyState: some View {
        VStack(spacing: 15) {
            Image(systemName: "text.book.closed").font(.system(size: 42)).foregroundStyle(Palette.Accent)
            Text(Search.isEmpty ? "A fresh page" : "No matching words")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(Search.isEmpty ? "Add a word or import a CSV to begin." : "Try a different search.")
                .foregroundStyle(Palette.Muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 75)
    }
}

private struct WordRow: View {
    let Entry: WordEntry

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Entry.IncorrectCount > Entry.CorrectCount ? Palette.Accent : Palette.White)
                .frame(width: 3, height: 47)
            VStack(alignment: .leading, spacing: 5) {
                Text(Entry.Term).font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(Entry.Translation).font(.system(size: 14)).foregroundStyle(Palette.Muted)
                    .lineLimit(2)
                if !Entry.Group.isEmpty { Text(Entry.Group).font(.caption).foregroundStyle(Palette.Accent) }
                if Entry.Learning.Suspended { Text("Paused").font(.caption) }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                .foregroundStyle(Palette.Muted)
        }
        .padding(17)
        .FrostedCard(CornerRadius: 20)
        .contentShape(Rectangle())
    }
}
