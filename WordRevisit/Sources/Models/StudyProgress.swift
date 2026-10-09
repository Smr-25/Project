import Foundation

struct StudyDay: Identifiable {
    let Date: Date
    let Answers: Int
    var id: Date { Date }
}

struct StudyProgress {
    let Week: [StudyDay]
    let Streak: Int
    let Accuracy: Int

    var WeeklyAnswers: Int { Week.reduce(0) { $0 + $1.Answers } }
    var ActiveDays: Int { Week.filter { $0.Answers > 0 }.count }

    init(History: [QuizRecord], Now: Date = .now, Calendar: Calendar = .current) {
        let Completed = History.filter { $0.Date <= Now && $0.Total > 0 }
        let Today = Calendar.startOfDay(for: Now)
        let ByDay = Dictionary(grouping: Completed) { Calendar.startOfDay(for: $0.Date) }
        Week = (-6...0).compactMap { Offset in
            guard let Date = Calendar.date(byAdding: .day, value: Offset, to: Today) else { return nil }
            return StudyDay(Date: Date, Answers: ByDay[Date, default: []].reduce(0) { $0 + $1.Total })
        }
        let Total = Completed.reduce(0) { $0 + $1.Total }
        Accuracy = Total == 0 ? 0 : Int(Double(Completed.reduce(0) { $0 + $1.Correct }) / Double(Total) * 100)

        var Day = ByDay[Today] == nil ? Calendar.date(byAdding: .day, value: -1, to: Today) : Today
        var Count = 0
        while let Current = Day, ByDay[Current] != nil {
            Count += 1
            Day = Calendar.date(byAdding: .day, value: -1, to: Current)
        }
        Streak = Count
    }
}
