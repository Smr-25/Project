import Foundation

struct SynonymFamily {
    let Code: String
    let Head: String
    let Sense: String
    let Terms: [String]
}

extension SynonymCatalog {
    static func Parts(_ Value: String) -> [String] {
        Value.split(separator: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    static func Merge(_ Left: String, _ Right: String) -> String {
        var Seen: Set<String> = []
        return (Parts(Left) + Parts(Right)).filter { Seen.insert(QuizPlanner.Normalize($0)).inserted }.joined(separator: "; ")
    }

    static func CanonicalGroups(_ Value: String, Term: String) -> String {
        let Parts = Parts(Value)
        let Custom = Parts.filter { !LegacyGroups.contains(QuizPlanner.Normalize($0)) }
        guard Parts.contains(where: { LegacyGroups.contains(QuizPlanner.Normalize($0)) }) else { return Merge("", Value) }
        let Codes = Families.filter { $0.Terms.contains(QuizPlanner.Normalize(Term)) }.map(\.Code)
        return Merge(Custom.joined(separator: "; "), Codes.joined(separator: "; "))
    }

    static func Related(_ Left: String, _ Right: String) -> Bool {
        let L = QuizPlanner.Normalize(Left), R = QuizPlanner.Normalize(Right)
        return L == R || Families.contains { $0.Terms.contains(L) && $0.Terms.contains(R) }
    }
}
