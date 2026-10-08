import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var Store: WordRepository
    @State private var IsUpdating = false
    @State private var Notice: String?

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    SectionEyebrow(Title: "Shape your routine")
                    Text("Settings")
                        .font(.system(size: 38, weight: .bold, design: .rounded))

                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 14) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Palette.Accent)
                                .frame(width: 48, height: 48)
                                .background(Palette.Accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 15))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily reminders")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Text("Two gentle nudges every day")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Palette.Muted)
                            }
                            Spacer()
                            Toggle("Daily reminders", isOn: Binding(
                                get: { Store.RemindersEnabled },
                                set: { Enabled in
                                    Store.RemindersEnabled = Enabled
                                    UpdateReminders()
                                }
                            ))
                            .labelsHidden()
                            .tint(Palette.Accent)
                            .disabled(IsUpdating)
                        }
                        Divider().overlay(.white.opacity(0.08))
                        TimeRow(Title: "Morning quiz", Symbol: "sunrise.fill", Tint: Palette.Accent,
                                Time: Binding(get: { Store.Morning.DateValue }, set: { Store.Morning = ReminderTime(DateValue: $0); UpdateReminders() }))
                            .disabled(IsUpdating)
                        TimeRow(Title: "Evening quiz", Symbol: "moon.stars.fill", Tint: Palette.Accent,
                                Time: Binding(get: { Store.Evening.DateValue }, set: { Store.Evening = ReminderTime(DateValue: $0); UpdateReminders() }))
                            .disabled(IsUpdating)
                    }
                    .padding(21)
                    .FrostedCard(CornerRadius: 27)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 14) {
                            Image(systemName: "iphone")
                                .font(.system(size: 20))
                                .foregroundStyle(Palette.Accent)
                                .frame(width: 48, height: 48)
                                .background(Palette.Accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 15))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Xcode renewal")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Text("A reminder before your free install may expire")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Palette.Muted)
                            }
                            Spacer()
                            Toggle("Xcode renewal reminder", isOn: Binding(
                                get: { Store.RenewalReminderEnabled },
                                set: { Enabled in
                                    Store.RenewalReminderEnabled = Enabled
                                    if Enabled && Store.XcodeInstalledAt == nil { Store.XcodeInstalledAt = .now }
                                    UpdateRenewalReminder()
                                }
                            ))
                            .labelsHidden()
                            .tint(Palette.Accent)
                            .disabled(IsUpdating)
                        }
                        if Store.RenewalReminderEnabled {
                            Divider().overlay(.white.opacity(0.08))
                            if let InstalledAt = Store.XcodeInstalledAt,
                               let ReminderAt = ReminderScheduler.RenewalDate(From: InstalledAt) {
                                Text(ReminderAt > .now
                                     ? "Next reminder: \(ReminderAt.formatted(date: .abbreviated, time: .shortened))"
                                     : "Time to reinstall from Xcode.")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Palette.Muted)
                            }
                            Button("I reinstalled from Xcode") {
                                Store.XcodeInstalledAt = .now
                                UpdateRenewalReminder()
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.Accent)
                            .disabled(IsUpdating)
                            Text("Tap after each Xcode install to restart the six-day countdown.")
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.Muted)
                        }
                    }
                    .padding(21)
                    .FrostedCard(CornerRadius: 27)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionEyebrow(Title: "Your data")
                        Text("Your words and quiz history stay on this iPhone. Export your words from My words before removing the app.")
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.Muted)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(23)
                    .FrostedCard(CornerRadius: 25)

                    Text("WordRevisit · Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0")")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.Muted.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 35)
            }
        }
        .alert("Notifications unavailable", isPresented: Binding(
            get: { Notice != nil }, set: { if !$0 { Notice = nil } }
        )) { Button("OK") { Notice = nil } } message: { Text(Notice ?? "") }
    }

    private func UpdateReminders() {
        Store.SaveSettings()
        IsUpdating = true
        Task {
            let Scheduled = await ReminderScheduler.Set(Enabled: Store.RemindersEnabled,
                                                        Morning: Store.Morning, Evening: Store.Evening)
            if !Scheduled {
                Store.RemindersEnabled = false
                Store.SaveSettings()
                Notice = "Allow notifications in iPhone Settings, then turn reminders on again."
            }
            IsUpdating = false
        }
    }

    private func UpdateRenewalReminder() {
        Store.SaveSettings()
        IsUpdating = true
        Task {
            let Scheduled = await ReminderScheduler.SetRenewal(Enabled: Store.RenewalReminderEnabled,
                                                               InstalledAt: Store.XcodeInstalledAt)
            if !Scheduled {
                Store.RenewalReminderEnabled = false
                Store.SaveSettings()
                Notice = "Allow notifications in iPhone Settings, then turn Xcode renewal on again."
            }
            IsUpdating = false
        }
    }
}

private struct TimeRow: View {
    let Title: String
    let Symbol: String
    let Tint: Color
    @Binding var Time: Date

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: Symbol)
                .foregroundStyle(Tint)
                .frame(width: 26)
            Text(Title).font(.system(size: 15, weight: .medium))
            Spacer()
            DatePicker(Title, selection: $Time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Tint)
        }
    }
}
