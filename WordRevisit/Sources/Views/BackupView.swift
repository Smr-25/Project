import SwiftUI
import UniformTypeIdentifiers

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var Data: Data
    init(Data: Data) { self.Data = Data }
    init(configuration: ReadConfiguration) throws { Data = configuration.file.regularFileContents ?? Foundation.Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: Data) }
}

struct BackupView: View {
    @EnvironmentObject private var Store: WordRepository
    @Environment(\.dismiss) private var Dismiss
    @State private var Export = false
    @State private var Import = false
    @State private var Document: BackupDocument?
    @State private var Pending: Data?
    @State private var Summary = ""
    @State private var Confirm = false
    @State private var Notice: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Everything, together") {
                    Text("A JSON backup includes words, sentences, review dates, answer history, your saved session, and settings. Keep it in Files or your own iCloud Drive.")
                    Button("Export full backup") {
                        do { Document = BackupDocument(Data: try Store.ExportBackup()); Export = true }
                        catch { Notice = error.localizedDescription }
                    }
                    Button("Restore a backup") { Import = true }
                    if let Date = Store.Learning.LastBackupAt { LabeledContent("Last export", value: Date.formatted(date: .abbreviated, time: .shortened)) }
                }
                Section("Backup reminder") {
                    Toggle("Remind me to back up", isOn: Binding(get: { Store.Learning.Settings.BackupReminder }, set: {
                        var Settings = Store.Learning.Settings; Settings.BackupReminder = $0
                        _ = Store.UpdateLearningSettings(Settings); Task { await Store.RefreshNotifications(RequestPermission: true) }
                    }))
                    Stepper("Every \(Store.Learning.Settings.BackupDays) days", value: Binding(get: { Store.Learning.Settings.BackupDays }, set: {
                        var Settings = Store.Learning.Settings; Settings.BackupDays = $0
                        _ = Store.UpdateLearningSettings(Settings); Task { await Store.RefreshNotifications() }
                    }), in: 1...30)
                }
            }
            .navigationTitle("Backup & restore")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { Dismiss() } } }
            .fileExporter(isPresented: $Export, document: Document, contentType: .json, defaultFilename: "WordRevisit-Backup") { Result in
                switch Result {
                case .success: Store.MarkBackup(); Task { await Store.RefreshNotifications() }
                case .failure(let Error): Notice = Error.localizedDescription
                }
            }
            .fileImporter(isPresented: $Import, allowedContentTypes: [.json]) { Result in
                do {
                    let URL = try Result.get(), Access = URL.startAccessingSecurityScopedResource()
                    defer { if Access { URL.stopAccessingSecurityScopedResource() } }
                    let Data = try Data(contentsOf: URL)
                    let Snapshot = try Store.InspectBackup(Data)
                    Pending = Data; Summary = "\(Snapshot.Entries.count) words and \(Snapshot.History.count) legacy quizzes, plus \(Snapshot.Learning?.Logs.count ?? 0) study answers. This replaces current data and settings."; Confirm = true
                } catch { Notice = error.localizedDescription }
            }
            .confirmationDialog("Restore this backup?", isPresented: $Confirm, titleVisibility: .visible) {
                Button("Replace with backup", role: .destructive) {
                    do { if let Pending { try Store.RestoreBackup(Pending); Task { await Store.RefreshNotifications() }; Notice = "Backup restored." } }
                    catch { Notice = error.localizedDescription }
                    Pending = nil
                }
                Button("Cancel", role: .cancel) { Pending = nil }
            } message: { Text(Summary) }
            .alert("Backup", isPresented: Binding(get: { Notice != nil }, set: { if !$0 { Notice = nil } })) {
                Button("OK") { Notice = nil }
            } message: { Text(Notice ?? "") }
        }.tint(Palette.Accent)
    }
}
