import Foundation

enum DuplicatePolicy: String, CaseIterable, Identifiable {
    case Merge = "Merge translations", Separate = "Keep separate", Skip = "Skip existing words"
    var id: String { rawValue }
}

struct ImportPreview {
    var Entries: [WordEntry]
    var Added = 0
    var Merged = 0
    var Duplicates = 0
    var Errors: [String] = []

    init(Text: String, Existing: [WordEntry], Policy: DuplicatePolicy, Paste: Bool = false) throws {
        Entries = Existing
        let Rows: [[String]]
        if Paste {
            Rows = Text.split(whereSeparator: \.isNewline).map { Line in
                let Value = String(Line)
                guard let Range = Value.range(of: " - ") else { return [Value] }
                return [String(Value[..<Range.lowerBound]), String(Value[Range.upperBound...])]
            }
        } else { Rows = try WordCSV.Rows(Text) }
        for (Index, Row) in Rows.enumerated() {
            guard let Entry = try? WordCSV.Entry(Row) else { Errors.append("Row \(Index + 1): English and Azerbaijani are required."); continue }
            if Entries.contains(where: { QuizPlanner.Normalize($0.Term) == QuizPlanner.Normalize(Entry.Term) && LearningEngine.Meanings($0.Translation) == LearningEngine.Meanings(Entry.Translation) }) {
                Duplicates += 1; continue
            }
            if let Match = Entries.firstIndex(where: { QuizPlanner.Normalize($0.Term) == QuizPlanner.Normalize(Entry.Term) }) {
                if Policy == .Skip { Duplicates += 1; continue }
                if Policy == .Merge {
                    let Known = LearningEngine.Meanings(Entries[Match].Translation)
                    let Extra = Entry.Translation.split(separator: ";").map(String.init).filter { !Known.contains(QuizPlanner.Normalize($0)) }
                    if !Extra.isEmpty { Entries[Match].Translation += "; " + Extra.joined(separator: "; ") }
                    if Entries[Match].Group.isEmpty { Entries[Match].Group = Entry.Group }
                    if Entries[Match].Definition.isEmpty { Entries[Match].Definition = Entry.Definition }
                    if Entries[Match].ExampleSentences.isEmpty { Entries[Match].ExampleSentences = Entry.ExampleSentences }
                    Merged += 1; continue
                }
            }
            Entries.append(Entry); Added += 1
        }
    }
}
