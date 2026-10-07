import SwiftUI
import UniformTypeIdentifiers

private struct CSVDocument: FileDocument {
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

    private var FilteredEntries: [WordEntry] {
        Store.Entries.filter {
            Search.isEmpty || $0.Term.localizedCaseInsensitiveContains(Search) ||
            $0.Translation.localizedCaseInsensitiveContains(Search)
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
                    HStack {
                        SectionEyebrow(Title: "Your collection")
                        Spacer()
                        Text("\(FilteredEntries.count) words")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.Muted)
                    }
                    if FilteredEntries.isEmpty {
                        EmptyState
                    } else {
                        LazyVStack(spacing: 11) {
                            ForEach(FilteredEntries) { Entry in
                                Button { EditingEntry = Entry } label: { WordRow(Entry: Entry) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 35)
            }
        }
        .sheet(isPresented: $ShowingAdd) { WordEditorView() }
        .sheet(item: $EditingEntry) { Entry in WordEditorView(Entry: Entry) }
        .fileImporter(isPresented: $ShowingImport, allowedContentTypes: [.commaSeparatedText, .plainText]) { Result in
            do {
                let URL = try Result.get()
                let Accessed = URL.startAccessingSecurityScopedResource()
                defer { if Accessed { URL.stopAccessingSecurityScopedResource() } }
                let Text = try String(contentsOf: URL, encoding: .utf8)
                let Added = Store.Import(try WordCSV.Decode(Text))
                Notice = "Imported \(Added) new words."
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
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                .foregroundStyle(Palette.Muted)
        }
        .padding(17)
        .FrostedCard(CornerRadius: 20)
    }
}
