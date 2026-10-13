import Foundation

struct ImportPreview {
    var AddedEntries: [WordEntry] = []
    var Duplicates = 0
    var Errors: [String] = []
    var Added: Int { AddedEntries.count }

    init(Text: String, Existing: [WordEntry], Paste: Bool = false) throws {
        var Rows: [[String]]
        let English: Int, Azerbaijani: Int, Group: Int?
        if Paste {
            Rows = Text.split(whereSeparator: \.isNewline).map { Line in
                let Value = String(Line)
                guard let Range = Value.range(of: " - ") else { return [Value] }
                return [String(Value[..<Range.lowerBound]), String(Value[Range.upperBound...])]
            }
            English = 0; Azerbaijani = 1; Group = nil
        } else {
            Rows = try WordCSV.Rows(Text)
            guard let Header = Rows.first else { throw WordCSV.CSVError.MissingColumns }
            let Keys = Header.map(QuizPlanner.Normalize)
            guard Keys.filter({ $0 == "english" }).count == 1, Keys.filter({ $0 == "azerbaijani" }).count == 1,
                  Keys.filter({ $0 == "group" }).count <= 1,
                  let E = Keys.firstIndex(of: "english"), let A = Keys.firstIndex(of: "azerbaijani") else { throw WordCSV.CSVError.MissingColumns }
            English = E; Azerbaijani = A; Group = Keys.firstIndex(of: "group")
            Rows.removeFirst()
        }
        var Seen = Set(Existing.map { QuizPlanner.Normalize($0.Term) })
        for (Index, Row) in Rows.enumerated() {
            func Value(_ Index: Int?) -> String {
                guard let Index, Row.indices.contains(Index) else { return "" }
                return Row[Index].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let Term = Value(English), Translation = Value(Azerbaijani)
            guard !Term.isEmpty, !QuizPlanner.Meanings(Translation).isEmpty else {
                Errors.append("Row \(Index + (Paste ? 1 : 2)): English and Azerbaijani are required."); continue
            }
            guard Seen.insert(QuizPlanner.Normalize(Term)).inserted else { Duplicates += 1; continue }
            AddedEntries.append(WordEntry(Term: Term, Translation: Translation, Group: Value(Group)))
        }
    }
}
