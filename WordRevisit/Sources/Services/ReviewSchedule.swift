import Foundation

enum ReviewSchedule {
    static func IsDue(_ Entry: WordEntry, Now: Date = .now) -> Bool {
        (Entry.NextReviewAt ?? .distantPast) <= Now
    }

    static func Record(_ Entry: inout WordEntry, IsCorrect: Bool, Now: Date = .now,
                       Calendar: Calendar = .current, UpdatesSchedule: Bool = true) {
        if IsCorrect { Entry.CorrectCount += 1 }
        else { Entry.IncorrectCount += 1 }
        Entry.LastReviewedAt = Now
        guard UpdatesSchedule else { return }
        if IsCorrect {
            let Intervals = [1, 3, 7, 14, 30]
            let Stage = min(max(Entry.ReviewStreak, 0), Intervals.count - 1)
            Entry.ReviewStreak = min(Stage + 1, Intervals.count)
            Entry.NextReviewAt = Calendar.date(byAdding: .day, value: Intervals[Stage], to: Now)
        } else {
            Entry.ReviewStreak = 0
            Entry.NextReviewAt = Now
        }
    }
}
