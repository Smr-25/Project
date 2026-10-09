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

    static func Decode(_ Text: String) throws -> [WordEntry] {
        var Rows: [[String]] = []
        var Row: [String] = []
        var Field = ""
        var IsQuoted = false
        let Characters = Array(Text.replacingOccurrences(of: "\r\n", with: "\n"))
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
        return try Rows.filter { !$0.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty } }
            .map { Columns in
                guard Columns.count >= 2,
                      !Columns[0].trimmingCharacters(in: .whitespaces).isEmpty,
                      !Columns[1].trimmingCharacters(in: .whitespaces).isEmpty else {
                    throw CSVError.MissingColumns
                }
                return WordEntry(
                    Term: Columns[0].trimmingCharacters(in: .whitespacesAndNewlines),
                    Translation: Columns[1].trimmingCharacters(in: .whitespacesAndNewlines),
                    Definition: Columns.count > 2 ? Columns[2].trimmingCharacters(in: .whitespacesAndNewlines) : "",
                    ExampleSentences: Columns.count > 3 ? Columns[3].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                )
            }
    }

    static func Encode(_ Entries: [WordEntry]) -> String {
        let Rows = Entries.map { Entry in
            [Entry.Term, Entry.Translation, Entry.Definition, Entry.ExampleSentences].map(Escape).joined(separator: ",")
        }
        return (["English,Azerbaijani,Definition,Examples"] + Rows).joined(separator: "\n") + "\n"
    }

    private static func Escape(_ Value: String) -> String {
        if Value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) {
            return "\"" + Value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return Value
    }
}
