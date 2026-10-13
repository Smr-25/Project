import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var Store: WordRepository
    @State private var ShowingHistory = false
    @State private var Updating = false
    @State private var Notice = false
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SectionEyebrow(Title: "Make it yours")
                    Text("Settings").font(.largeTitle.bold())
                    VStack(alignment: .leading, spacing: 14) {
                        SectionEyebrow(Title: "Appearance")
                        Picker("Appearance", selection: Binding(get: { Store.Appearance }, set: { Store.SetAppearance($0) })) {
                            ForEach(AppAppearance.allCases) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented).accessibilityIdentifier("AppearancePicker")
                        Text("System follows your iPhone's appearance.").font(.caption).foregroundStyle(Palette.Muted)
                    }.padding(22).FrostedCard()
                    Button { ShowingHistory = true } label: {
                        HStack {
                            Label("Practice history", systemImage: "clock.arrow.circlepath")
                            Spacer()
                            Text("\(Store.History.count)").monospacedDigit()
                            Image(systemName: "chevron.right")
                        }.padding(22).FrostedCard().contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Xcode renewal", isOn: Binding(get: { Store.Data.RenewalReminderEnabled }, set: {
                            Store.SetRenewal(Enabled: $0); UpdateRenewal()
                        })).disabled(Updating)
                        Text("A reminder six days after your last Xcode install.").font(.subheadline).foregroundStyle(Palette.Muted)
                        if Store.Data.RenewalReminderEnabled {
                            if let Installed = Store.Data.XcodeInstalledAt, let Date = ReminderScheduler.RenewalDate(From: Installed) {
                                Text(Date > .now ? "Next reminder: \(Date.formatted(date: .abbreviated, time: .shortened))" : "Time to reinstall from Xcode.")
                                    .font(.subheadline)
                            }
                            Button("I reinstalled from Xcode") {
                                Store.SetRenewal(Enabled: true, Reinstalled: true); UpdateRenewal()
                            }.frame(minHeight: 44).disabled(Updating)
                            Text("Tap after reinstalling to restart the reminder. The app cannot renew the install itself.").font(.caption).foregroundStyle(Palette.Muted)
                        }
                    }.padding(22).FrostedCard()
                    Text("Your words and practice stay on this device. Export CSV from My words to keep a copy of your vocabulary.")
                        .font(.subheadline).foregroundStyle(Palette.Muted)
                    Text("WordRevisit · Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")")
                        .font(.caption).foregroundStyle(Palette.Muted).frame(maxWidth: .infinity)
                }.padding(24)
            }
        }.sheet(isPresented: $ShowingHistory) { HistoryView() }
            .alert("Notifications unavailable", isPresented: $Notice) { Button("OK") {} } message: {
                Text("Allow notifications in iPhone Settings, then enable Xcode renewal again.")
            }
    }
    private func UpdateRenewal() {
        Updating = true
        Task {
            if !(await ReminderScheduler.SetRenewal(Enabled: Store.Data.RenewalReminderEnabled, InstalledAt: Store.Data.XcodeInstalledAt)) {
                Store.SetRenewal(Enabled: false); Notice = true
            }
            Updating = false
        }
    }
}
