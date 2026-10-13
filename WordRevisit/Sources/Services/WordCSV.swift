import Foundation

enum WordCSV {
    enum CSVError: LocalizedError {
        case InvalidQuotes
        case MissingColumns

        var errorDescription: String? {
            switch self {
            case .InvalidQuotes: "The CSV contains an unfinished quoted field."
            case .MissingColumns: "CSV needs one English and one Azerbaijani header. Group is optional and must appear at most once."
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

        return Rows.filter { !$0.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty } }
    }

    static func Encode(_ Entries: [WordEntry]) -> String {
        (["English,Azerbaijani,Group"] + Entries.map { [$0.Term, $0.Translation, $0.Group].map(Escape).joined(separator: ",") }).joined(separator: "\n") + "\n"
    }

    private static func Escape(_ Value: String) -> String {
        if Value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) {
            return "\"" + Value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return Value
    }
}
