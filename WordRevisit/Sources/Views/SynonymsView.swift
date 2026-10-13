import SwiftUI

struct SynonymsView: View {
    @EnvironmentObject private var Store: WordRepository
    @State private var Search = ""
    @FocusState private var SearchFocused: Bool

    var body: some View {
        GeometryReader { Geometry in
            ZStack {
                AppBackground()
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionEyebrow(Title: "Words that belong together")
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
                        let Groups = VocabularyGroup.Make(Store.Entries, Search: Search)
                        if Groups.isEmpty {
                            ContentUnavailableView(Search.isEmpty ? "Your word families" : "No matching groups",
                                systemImage: "rectangle.3.group", description: Text(Search.isEmpty ? "Add a Group to words in My words or CSV to see them together here." : "Search an English word, translation or group name."))
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .top), count: Geometry.size.width >= 1000 ? 3 : Geometry.size.width >= 700 ? 2 : 1), alignment: .leading, spacing: 18) {
                                ForEach(Groups) { Group in
                                    VStack(alignment: .leading, spacing: 16) {
                                        SectionEyebrow(Title: Group.Name)
                                        if let First = Group.Words.first {
                                            Text(First.Term).font(.title2.bold())
                                            Text(First.Translation).foregroundStyle(Palette.Muted)
                                        }
                                        if Group.Words.count > 1 {
                                            Divider()
                                            ForEach(Group.Words.dropFirst()) { Word in
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(Word.Term).font(.headline)
                                                    Text(Word.Translation).foregroundStyle(Palette.Muted)
                                                }
                                            }
                                        }
                                    }.frame(maxWidth: .infinity, alignment: .leading).padding(22).FrostedCard(CornerRadius: 24)
                                }
                            }.padding(24)
                        }
                    }.scrollDismissesKeyboard(.interactively)
                }
            }
        }
    }
}
