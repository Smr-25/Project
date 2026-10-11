import Foundation

enum StudyCalendar {
    static func Key(_ Date: Date, Hour: Int, Calendar: Calendar = .current) -> String {
        let Shifted = Calendar.date(byAdding: .hour, value: -Hour, to: Date) ?? Date
        let Parts = Calendar.dateComponents([.year, .month, .day], from: Shifted)
        return String(format: "%04d-%02d-%02d", Parts.year!, Parts.month!, Parts.day!)
    }

    static func Day(_ Key: String) -> Date? {
        let Formatter = DateFormatter()
        Formatter.locale = Locale(identifier: "en_US_POSIX")
        Formatter.timeZone = TimeZone(secondsFromGMT: 0)
        Formatter.dateFormat = "yyyy-MM-dd"
        Formatter.isLenient = false
        guard let Date = Formatter.date(from: Key), Formatter.string(from: Date) == Key else { return nil }
        return Date
    }

    static func Gap(_ Earlier: String, _ Later: String) -> Int {
        guard let A = Day(Earlier), let B = Day(Later) else { return 0 }
        return Int((B.timeIntervalSince(A) / 86400).rounded())
    }

    static func Streak(_ Days: [LearningDay], Today: String, Settings: LearningSettings) -> StreakSummary {
        var Value = StreakSummary()
        var Last: String?
        var Earned = 0
        for Day in Days.filter({ $0.MinimumMet && $0.id <= Today }).sorted(by: { $0.id < $1.id }) {
            if let Last {
                let Missed = max(0, Gap(Last, Day.id) - 1)
                if Missed > Value.Freezes { Value.Current = 0; Value.Freezes = max(0, Value.Freezes - Missed) }
                else { Value.Current += Missed; Value.Freezes -= Missed }
                if Missed > 0 { Earned = 0 }
            }
            Value.Current += 1
            Earned += 1
            if Earned % Settings.FreezeEvery == 0 { Value.Freezes = min(Settings.MaxFreezes, Value.Freezes + 1) }
            Value.Best = max(Value.Best, Value.Current)
            Last = Day.id
        }
        if let Last {
            let Missed = max(0, Gap(Last, Today) - 1)
            if Missed > Value.Freezes { Value.Current = 0 }
            else { Value.Current += Missed }
            Value.Freezes = max(0, Value.Freezes - Missed)
        }
        Value.Best = max(Value.Best, Value.Current)
        return Value
    }
}
