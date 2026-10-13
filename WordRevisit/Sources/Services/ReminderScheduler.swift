import Foundation
import UserNotifications

enum ReminderScheduler {
    private static let RenewalId = "WordRevisit.XcodeRenewal"

    static func RenewalDate(From InstalledAt: Date, Calendar: Calendar = .current) -> Date? {
        Calendar.date(byAdding: .day, value: 6, to: InstalledAt)
    }

    static func RemoveStudyReminders() async {
        let Center = UNUserNotificationCenter.current()
        let Pending = await Center.pendingNotificationRequests()
        Center.removePendingNotificationRequests(withIdentifiers: Pending.filter { $0.identifier != RenewalId && $0.identifier.hasPrefix("WordRevisit.") }.map(\.identifier))
        let Delivered = await Center.deliveredNotifications()
        Center.removeDeliveredNotifications(withIdentifiers: Delivered.filter { $0.request.identifier != RenewalId && $0.request.identifier.hasPrefix("WordRevisit.") }.map { $0.request.identifier })
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
