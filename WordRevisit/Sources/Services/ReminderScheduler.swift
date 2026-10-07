import Foundation
import UserNotifications

enum ReminderScheduler {
    private static let Ids = ["WordRevisit.Morning", "WordRevisit.Evening"]

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
}
