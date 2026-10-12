import SwiftUI
import UserNotifications

@main
struct WordRevisitApp: App {
    @UIApplicationDelegateAdaptor(NotificationDelegate.self) private var Delegate
    @Environment(\.scenePhase) private var Phase
    @StateObject private var Store: WordRepository

    init() {
        #if DEBUG
        if let Value = ProcessInfo.processInfo.environment["WORDREVISIT_TEST_STORE"],
           let Id = UUID(uuidString: Value) {
            let URL = FileManager.default.temporaryDirectory.appendingPathComponent("UITest-\(Id).json")
            let Existing = FileManager.default.fileExists(atPath: URL.path)
            let TestStore = WordRepository(FileURL: URL)
            if !Existing && ProcessInfo.processInfo.environment["WORDREVISIT_UI_FIXTURE"] == "Study" {
                TestStore.Delete(Ids: Set(TestStore.Entries.map(\.Id)))
                for (Term, Translation) in [("forest", "meşə"), ("water", "su"), ("bird", "quş"), ("large", "böyük"), ("huge", "iri"), ("tree", "ağac")] {
                    var Word = WordEntry(Term: Term, Translation: Translation)
                    Word.Learning.IntroducedAt = Date.now.addingTimeInterval(-86400)
                    Word.Learning.Stage = 4; Word.Learning.LearningStep = 3
                    Word.NextReviewAt = Date.now.addingTimeInterval(-3600)
                    if ["large", "huge"].contains(Term) { Word.Group = "size" }
                    _ = TestStore.SaveEntry(Word)
                }
            }
            _Store = StateObject(wrappedValue: TestStore)
            return
        }
        #endif
        _Store = StateObject(wrappedValue: WordRepository())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(Store)
                .preferredColorScheme(Store.Appearance.ColorScheme)
                .task { Store.RefreshDay(); await Store.RefreshNotifications() }
                .onChange(of: Phase) { _, New in
                    if New == .active { Store.RefreshDay(); Task { await Store.RefreshNotifications() } }
                }
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
    @EnvironmentObject private var Store: WordRepository

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
        .fullScreenCover(isPresented: $Store.PresentStudy) { StudySessionView() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenStudy"))) { _ in OpenPendingStudy() }
        .task { OpenPendingStudy() }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-PreviewLibrary") { SelectedTab = 1 }
            if ProcessInfo.processInfo.arguments.contains("-PreviewSettings") { SelectedTab = 2 }
            if ProcessInfo.processInfo.arguments.contains("-PreviewProgress") { SelectedTab = 3 }
            #endif
        }
    }
    private func OpenPendingStudy() {
        if UserDefaults.standard.bool(forKey: "OpenStudyFromNotification") {
            UserDefaults.standard.removeObject(forKey: "OpenStudyFromNotification")
            SelectedTab = 0
            if Store.StartStudy() { Store.PresentStudy = true }
        }
    }
}

final class NotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if response.notification.request.content.userInfo["OpenStudy"] as? Bool == true {
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: "OpenStudyFromNotification")
                NotificationCenter.default.post(name: Notification.Name("OpenStudy"), object: nil)
            }
        }
    }
}
