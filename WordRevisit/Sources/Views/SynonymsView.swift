import SwiftUI

struct SynonymsView: View {
    @EnvironmentObject private var Store: WordRepository
    @State private var Search = ""
    @State private var EditingGroup: VocabularyGroup?
    @FocusState private var SearchFocused: Bool

    var body: some View {
        ZStack {
            AppBackground()
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    SectionEyebrow(Title: "Shared meanings")
                    Text("Synonyms").font(.largeTitle.bold())
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Palette.Accent)
                        TextField("Word, translation or group", text: $Search)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .focused($SearchFocused).onSubmit { SearchFocused = false }
                            .submitLabel(.search).accessibilityIdentifier("SearchGroups")
                        if !Search.isEmpty {
                            Button { Search = "" } label: { Image(systemName: "xmark.circle.fill") }
                                .accessibilityLabel("Clear search")
                        }
                    }.padding(16).FrostedCard(CornerRadius: 18)
                }.padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 8)
                ScrollView {
                    let Groups = VocabularyGroup.Make(Store.Entries, Search: Search, Meanings: Store.Data.FamilyMeanings ?? [:])
                    if Groups.isEmpty {
                        ContentUnavailableView(Search.isEmpty ? "Your word families" : "No matching groups",
                            systemImage: "rectangle.3.group", description: Text(Search.isEmpty ? "Give at least two words the same Group code to create a synonym family." : "Search an English word, translation, family code or shared meaning."))
                    } else {
                        LazyVStack(alignment: .leading, spacing: 18) {
                            ForEach(Groups) { Group in
                                VStack(alignment: .leading, spacing: 16) {
                                    if !Group.Name.isEmpty { SectionEyebrow(Title: Group.Name) }
                                    if let First = Group.Words.first {
                                        HStack(alignment: .top) {
                                            Text(First.Term).font(.title2.bold())
                                            Spacer()
                                            if !Group.IsCatalogued {
                                                Button { SearchFocused = false; EditingGroup = Group } label: {
                                                    Image(systemName: "square.and.pencil").frame(width: 44, height: 44)
                                                }.accessibilityLabel("Edit shared meaning for \(First.Term)")
                                                    .accessibilityIdentifier("EditMeaning-\(Group.Code)")
                                            }
                                        }
                                        Text(First.Translation).foregroundStyle(Palette.Muted)
                                    }
                                    Divider()
                                    ForEach(Group.Words.dropFirst()) { Word in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(Word.Term).font(.headline)
                                            Text(Word.Translation).foregroundStyle(Palette.Muted)
                                        }
                                    }
                                }.frame(maxWidth: .infinity, alignment: .leading).padding(22).FrostedCard(CornerRadius: 24)
                            }
                        }.padding(24)
                    }
                }.scrollDismissesKeyboard(.interactively)
            }
        }.sheet(item: $EditingGroup) { Group in FamilyMeaningEditor(Group: Group) }
    }
}

private struct FamilyMeaningEditor: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    let Group: VocabularyGroup
    @State private var Meaning: String

    init(Group: VocabularyGroup) {
        self.Group = Group
        _Meaning = State(initialValue: Group.Name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(Group.Words.first?.Term ?? Group.Code) {
                    TextField("Shared meaning · optional", text: $Meaning, axis: .vertical)
                        .accessibilityIdentifier("FamilyMeaning")
                    Text("Describe the sense these words share. This note is saved on this device; CSV exports contain words, translations and group codes.")
                        .font(.caption).foregroundStyle(Palette.Muted)
                }
            }.navigationTitle("Shared meaning")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { Dismiss() } } }
                .safeAreaInset(edge: .bottom) {
                    Button("Save meaning") {
                        if Store.SetFamilyMeaning(Code: Group.Code, Meaning: Meaning) { Dismiss() }
                    }.buttonStyle(PrimaryActionStyle()).padding(20).background(.regularMaterial)
                }
        }.tint(Palette.Accent)
    }
}
