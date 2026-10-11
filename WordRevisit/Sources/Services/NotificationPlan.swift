import Foundation

struct PlannedReminder {
    let Id: String
    let Date: Date
    let Title: String
    let Body: String
}

enum NotificationPlan {
    static func Make(Data: LearningData, Enabled: Bool, Morning: ReminderTime, Evening: ReminderTime, Now: Date = .now, Calendar: Calendar = .current) -> [PlannedReminder] {
        let Settings = Data.Settings
        var Result: [PlannedReminder] = []
        func Quiet(_ Hour: Int) -> Bool {
            if Settings.QuietStart == Settings.QuietEnd { return false }
            return Settings.QuietStart > Settings.QuietEnd ? Hour >= Settings.QuietStart || Hour < Settings.QuietEnd : Hour >= Settings.QuietStart && Hour < Settings.QuietEnd
        }
        if Enabled {
            for Offset in 0..<7 {
                guard let Day = Calendar.date(byAdding: .day, value: Offset, to: Calendar.startOfDay(for: Now)) else { continue }
                var Used: Set<Date> = []
                for (Index, Time) in [Morning, Evening, ReminderTime(Hour: 22, Minute: 0)].enumerated() {
                    guard !Quiet(Time.Hour), let At = Calendar.date(bySettingHour: Time.Hour, minute: Time.Minute, second: 0, of: Day), At > Now, Used.insert(At).inserted else { continue }
                    let Key = StudyCalendar.Key(At, Hour: Settings.DayStartHour, Calendar: Calendar)
                    let Stats = Data.Days.first { $0.id == Key }
                    if Stats?.MinimumMet == true { continue }
                    if Index == 2 && (!(Stats?.Introduced.isEmpty ?? true) || !(Stats?.Reviewed.isEmpty ?? true)) { continue }
                    let Remaining = Stats.map { max(0, $0.Target - $0.Completed.count) }
                    Result.append(PlannedReminder(Id: "WordRevisit.Plan.\(Offset).\(Index)", Date: At,
                        Title: Index == 2 ? "A small step still counts" : "A moment for your words",
                        Body: Remaining.map { "\($0) words remain in your plan. Pick up where you left off." } ?? "Your daily learning plan is ready. Start with a few words."))
                }
            }
            if let Due = Data.Session?.Cards.filter({ $0.Result == nil }).map(\.ReadyAt).min(), Due > Now {
                let Hour = Calendar.component(.hour, from: Due)
                let Key = StudyCalendar.Key(Due, Hour: Settings.DayStartHour, Calendar: Calendar)
                if !Quiet(Hour) && Data.Days.first(where: { $0.id == Key })?.MinimumMet != true {
                    Result.append(PlannedReminder(Id: "WordRevisit.Plan.Session", Date: Due, Title: "Ready to recall?", Body: "Your saved session has a word ready for its next step."))
                }
            }
        }
        if Settings.BackupReminder {
            let Base = Data.LastBackupAt ?? Data.CreatedAt
            let Due = Calendar.date(byAdding: .day, value: Settings.BackupDays, to: Base) ?? Now
            let Day = max(Due, Now.addingTimeInterval(60))
            let Noon = Calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Day) ?? Day
            var At = Noon > Now ? Noon : (Calendar.date(byAdding: .day, value: 1, to: Noon) ?? Day)
            if Quiet(Calendar.component(.hour, from: At)) {
                At = Calendar.nextDate(after: At, matching: DateComponents(hour: Settings.QuietEnd, minute: 0), matchingPolicy: .nextTime) ?? At
            }
            if !Quiet(Calendar.component(.hour, from: At)) {
                Result.append(PlannedReminder(Id: "WordRevisit.Plan.Backup", Date: At, Title: "Keep your learning safe", Body: "Export a full WordRevisit backup to Files."))
            }
        }
        return Result
    }
}
