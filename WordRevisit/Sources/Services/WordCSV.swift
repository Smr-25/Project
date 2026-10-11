import Foundation

enum WordCSV {
    enum CSVError: LocalizedError {
        case InvalidQuotes
        case MissingColumns

        var errorDescription: String? {
            switch self {
            case .InvalidQuotes: "The CSV contains an unfinished quoted field."
            case .MissingColumns: "Each row needs an English word and an Azerbaijani translation."
            }
        }
    }

    static func Rows(_ Text: String) throws -> [[String]] {
        var Rows: [[String]] = []
        var Row: [String] = []
        var Field = ""
        var IsQuoted = false
        let Characters = Array(Text.replacingOccurrences(of: "\u{FEFF}", with: "").replacingOccurrences(of: "\r\n", with: "\n"))
        var Index = 0

        while Index < Characters.count {
            let Character = Characters[Index]
            if Character == "\"" {
                if IsQuoted && Index + 1 < Characters.count && Characters[Index + 1] == "\"" {
                    Field.append("\"")
                    Index += 1
                } else {
                    IsQuoted.toggle()
                }
            } else if Character == "," && !IsQuoted {
                Row.append(Field)
                Field = ""
            } else if Character == "\n" && !IsQuoted {
                Row.append(Field)
                Rows.append(Row)
                Row = []
                Field = ""
            } else {
                Field.append(Character)
            }
            Index += 1
        }
        if IsQuoted { throw CSVError.InvalidQuotes }
        if !Row.isEmpty || !Field.isEmpty {
            Row.append(Field)
            Rows.append(Row)
        }

        if let First = Rows.first, First.first?.lowercased() == "english" {
            Rows.removeFirst()
        }
        return Rows.filter { !$0.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty } }
    }

    static func Entry(_ Columns: [String]) throws -> WordEntry {
        guard Columns.count >= 2, !Columns[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !Columns[1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw CSVError.MissingColumns }
        func Value(_ Index: Int) -> String { Columns.indices.contains(Index) ? Columns[Index].trimmingCharacters(in: .whitespacesAndNewlines) : "" }
        var Entry = WordEntry(Term: Value(0), Translation: Value(1), Definition: Value(2), ExampleSentences: Value(3))
        Entry.PartOfSpeech = Value(4); Entry.Group = Value(5); Entry.Mnemonic = Value(6); Entry.MySentence = Value(7)
        return Entry
    }

    static func Decode(_ Text: String) throws -> [WordEntry] { try Rows(Text).map(Entry) }

    static func Encode(_ Entries: [WordEntry]) -> String {
        let Rows = Entries.map { Entry in
            [Entry.Term, Entry.Translation, Entry.Definition, Entry.ExampleSentences, Entry.PartOfSpeech, Entry.Group, Entry.Mnemonic, Entry.MySentence].map(Escape).joined(separator: ",")
        }
        return (["English,Azerbaijani,Definition,Examples,PartOfSpeech,Group,Mnemonic,MySentence"] + Rows).joined(separator: "\n") + "\n"
    }

    private static func Escape(_ Value: String) -> String {
        if Value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) {
            return "\"" + Value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return Value
    }
}
