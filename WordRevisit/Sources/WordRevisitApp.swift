import SwiftUI

@main
struct WordRevisitApp: App {
    @StateObject private var Store: WordRepository
    init() {
        #if DEBUG
        if let Value = ProcessInfo.processInfo.environment["WORDREVISIT_TEST_STORE"], let Id = UUID(uuidString: Value) {
            let URL = FileManager.default.temporaryDirectory.appendingPathComponent("UITest-\(Id).json")
            if !FileManager.default.fileExists(atPath: URL.path) {
                let Pairs = [("select", "seçmək"), ("choose", "seçmək"), ("previous", "əvvəlki"), ("prior", "əvvəlki"), ("obtain", "əldə etmək"), ("acquire", "əldə etmək")]
                let Words = Pairs.map { Pair in
                    WordEntry(Term: Pair.0, Translation: Pair.1, Group: SynonymCatalog.Families.filter { $0.Terms.contains(Pair.0) }.map(\.Code).joined(separator: "; "))
                }
                let Data = PracticeData(Entries: Words, Bag: PracticeBag(Entries: Words))
                try? JSONEncoder().encode(Data).write(to: URL, options: .atomic)
            }
            _Store = StateObject(wrappedValue: WordRepository(FileURL: URL)); return
        }
        #endif
        _Store = StateObject(wrappedValue: WordRepository())
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if Store.StorageBlocked { StorageRecoveryView() }
                else { RootView() }
            }.environmentObject(Store).preferredColorScheme(Store.Appearance.ColorScheme).tint(Palette.Accent)
                .alert("WordRevisit", isPresented: Binding(get: { Store.ErrorMessage != nil && !Store.StorageBlocked }, set: { if !$0 { Store.ErrorMessage = nil } })) {
                    Button("OK") { Store.ErrorMessage = nil }
                } message: { Text(Store.ErrorMessage ?? "") }
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var Store: WordRepository
    var body: some View {
        TabView {
            HomeView().tabItem { Label("Practice", systemImage: "house.fill") }
            LibraryView().tabItem { Label("My words", systemImage: "text.book.closed.fill") }
            SynonymsView().tabItem { Label("Synonyms", systemImage: "rectangle.3.group.fill") }
            SettingsView().tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }.task {
            await ReminderScheduler.RemoveStudyReminders()
            _ = await ReminderScheduler.SetRenewal(Enabled: Store.Data.RenewalReminderEnabled, InstalledAt: Store.Data.XcodeInstalledAt)
        }
    }
}

private struct StorageRecoveryView: View {
    @EnvironmentObject private var Store: WordRepository
    @State private var Confirm = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Existing file preserved").font(.largeTitle.bold())
                    Text(Store.ErrorMessage ?? "This file cannot be opened by version 1.4.")
                    Text("To bring words from 2.x, export CSV in that version first. You can then start 1.4 and import that CSV. Practice history and schedules from 2.x are not migrated.")
                    Button("Start with the new vocabulary") { Confirm = true }
                        .buttonStyle(PrimaryActionStyle())
                }.padding(24)
            }.confirmationDialog("Start a fresh 1.4 vocabulary?", isPresented: $Confirm, titleVisibility: .visible) {
                Button("Keep old file and start fresh", role: .destructive) { Store.StartFresh() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("The old file will be retained separately on this device. Version 1.4 starts with 513 words and an empty practice history. Export CSV from your previous version first if you need its vocabulary.") }
        }
    }
}
