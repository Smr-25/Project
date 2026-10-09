import SwiftUI

@main
struct WordRevisitApp: App {
    @StateObject private var Store: WordRepository

    init() {
        #if DEBUG
        if let Value = ProcessInfo.processInfo.environment["WORDREVISIT_TEST_STORE"],
           let Id = UUID(uuidString: Value) {
            let URL = FileManager.default.temporaryDirectory.appendingPathComponent("UITest-\(Id).json")
            _Store = StateObject(wrappedValue: WordRepository(FileURL: URL))
            return
        }
        #endif
        _Store = StateObject(wrappedValue: WordRepository())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(Store)
                .preferredColorScheme(.dark)
                .alert("Storage issue", isPresented: Binding(
                    get: { Store.ErrorMessage != nil },
                    set: { if !$0 { Store.ErrorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) { Store.ErrorMessage = nil }
                } message: {
                    Text(Store.ErrorMessage ?? "")
                }
        }
    }
}

private struct RootView: View {
    @State private var SelectedTab = 0

    var body: some View {
        TabView(selection: $SelectedTab) {
            HomeView()
                .tabItem { Label("Today", systemImage: "house.fill") }
                .tag(0)
            LibraryView()
                .tabItem { Label("My words", systemImage: "text.book.closed.fill") }
                .tag(1)
            LearningProgressView()
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                .tag(3)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                .tag(2)
        }
        .tint(Palette.Accent)
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-PreviewLibrary") { SelectedTab = 1 }
            if ProcessInfo.processInfo.arguments.contains("-PreviewSettings") { SelectedTab = 2 }
            if ProcessInfo.processInfo.arguments.contains("-PreviewProgress") { SelectedTab = 3 }
            #endif
        }
    }
}
