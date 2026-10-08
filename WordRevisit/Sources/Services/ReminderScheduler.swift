import Foundation
import UserNotifications

enum ReminderScheduler {
    private static let Ids = ["WordRevisit.Morning", "WordRevisit.Evening"]
    private static let RenewalId = "WordRevisit.XcodeRenewal"

    static func RenewalDate(From InstalledAt: Date, Calendar: Calendar = .current) -> Date? {
        Calendar.date(byAdding: .day, value: 6, to: InstalledAt)
    }

    static func Set(Enabled: Bool, Morning: ReminderTime, Evening: ReminderTime) async -> Bool {
        let Center = UNUserNotificationCenter.current()
        Center.removePendingNotificationRequests(withIdentifiers: Ids)
        guard Enabled else { return true }

        do {
            guard try await Center.requestAuthorization(options: [.alert, .badge, .sound]) else { return false }
            for (Index, Time) in [Morning, Evening].enumerated() {
                let Content = UNMutableNotificationContent()
                Content.title = Index == 0 ? "A fresh start for your words" : "One more round before the day ends"
                Content.body = "Your WordRevisit quiz is ready. Take a few minutes to remember more."
                Content.sound = .default
                let Trigger = UNCalendarNotificationTrigger(
                    dateMatching: DateComponents(hour: Time.Hour, minute: Time.Minute), repeats: true
                )
                try await Center.add(UNNotificationRequest(identifier: Ids[Index], content: Content, trigger: Trigger))
            }
            return true
        } catch {
            return false
        }
    }

    static func SetRenewal(Enabled: Bool, InstalledAt: Date?) async -> Bool {
        let Center = UNUserNotificationCenter.current()
        Center.removePendingNotificationRequests(withIdentifiers: [RenewalId])
        guard Enabled, let InstalledAt, let ReminderAt = RenewalDate(From: InstalledAt) else { return true }

        do {
            guard try await Center.requestAuthorization(options: [.alert, .badge, .sound]) else { return false }
            let Seconds = ReminderAt.timeIntervalSinceNow
            guard Seconds > 0 else { return true }
            let Content = UNMutableNotificationContent()
            Content.title = "WordRevisit may need renewal tomorrow"
            Content.body = "Your free Xcode install may expire soon. Connect your iPhone and run the app from Xcode again."
            Content.sound = .default
            let Trigger = UNTimeIntervalNotificationTrigger(timeInterval: Seconds, repeats: false)
            try await Center.add(UNNotificationRequest(identifier: RenewalId, content: Content, trigger: Trigger))
            return true
        } catch {
            return false
        }
    }
}
