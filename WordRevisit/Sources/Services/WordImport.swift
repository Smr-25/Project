import Foundation

struct ImportPreview {
    var AddedEntries: [WordEntry] = []
    var UpdatedEntries: [WordEntry] = []
    var Unchanged = 0
    var Updated: Int { UpdatedEntries.count }
    var Duplicates = 0
    var Errors: [String] = []
    var Added: Int { AddedEntries.count }
    var NewSynonymFamilies = 0

    func Applying(to Entries: [WordEntry]) -> [WordEntry] {
        let Updates = Dictionary(uniqueKeysWithValues: UpdatedEntries.map { ($0.Id, $0) })
        return Entries.map { Updates[$0.Id] ?? $0 } + AddedEntries
    }

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
        var Incoming: [WordEntry] = []
        var Positions: [String: Int] = [:]
        let ByTerm = Dictionary(uniqueKeysWithValues: Existing.map { (QuizPlanner.Normalize($0.Term), $0) })
        for (Index, Row) in Rows.enumerated() {
            func Value(_ Index: Int?) -> String {
                guard let Index, Row.indices.contains(Index) else { return "" }
                return Row[Index].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let Term = Value(English), Translation = Value(Azerbaijani), Key = QuizPlanner.Normalize(Term)
            guard !Term.isEmpty, !QuizPlanner.Meanings(Translation).isEmpty else {
                Errors.append("Row \(Index + (Paste ? 1 : 2)): English and Azerbaijani are required."); continue
            }
            if let Position = Positions[Key] {
                Incoming[Position].Translation = SynonymCatalog.Merge(Incoming[Position].Translation, Translation)
                Incoming[Position].Group = SynonymCatalog.Merge(Incoming[Position].Group, Value(Group))
                Duplicates += 1
            } else {
                Positions[Key] = Incoming.count
                Incoming.append(WordEntry(Term: Term, Translation: Translation, Group: Value(Group)))
            }
        }
        for var Word in Incoming {
            Word.Group = SynonymCatalog.CanonicalGroups(Word.Group, Term: Word.Term)
            if let Old = ByTerm[QuizPlanner.Normalize(Word.Term)] {
                Word.Id = Old.Id
                Word.Term = Old.Term
                if Group == nil { Word.Group = Old.Group }
                if Word == Old { Unchanged += 1 } else { UpdatedEntries.append(Word) }
            } else { AddedEntries.append(Word) }
        }
        let Before = Set(VocabularyGroup.Make(Existing).map(\.Code))
        NewSynonymFamilies = Set(VocabularyGroup.Make(Applying(to: Existing)).map(\.Code)).subtracting(Before).count
    }
}
