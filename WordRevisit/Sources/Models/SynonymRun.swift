import Foundation

enum SynonymMode: String, Codable, CaseIterable, Identifiable {
    case Grouping, Easy
    var id: String { rawValue }
}

struct SynonymChip: Codable, Identifiable {
    let Word: WordEntry
    let Family: String
    let Options: [String]
    var id: UUID { Word.Id }
    var IsReview: Bool { Options.count < 2 }
}

struct SynonymRound: Codable, Identifiable {
    var id = UUID()
    let Mode: SynonymMode
    let Families: [VocabularyGroup]
    let Chips: [SynonymChip]
    var Assignments: [String: String] = [:]
    var RetryAssignments: [String: String] = [:]
    var Index = 0
    var IsRetry = false
    var Revealed = false
    var IsFinished = false
    var ActiveChips: [SynonymChip] { IsRetry ? Chips.filter { !Correct($0, Retry: false) } : Chips }
    var Current: SynonymChip? { ActiveChips.indices.contains(Index) && !IsFinished ? ActiveChips[Index] : nil }
    var Inputs: [String: String] { IsRetry ? RetryAssignments : Assignments }
    var CanCheck: Bool { !IsFinished && !Revealed && !ActiveChips.isEmpty && ActiveChips.allSatisfy { Inputs[$0.id.uuidString] != nil } }
    var ScoredChips: [SynonymChip] { Mode == .Easy ? Chips.filter { !$0.IsReview } : Chips }
    var Score: Int { ScoredChips.filter { Correct($0, Retry: false) }.count }

    func Correct(_ Chip: SynonymChip, Retry: Bool) -> Bool {
        let Input = (Retry ? RetryAssignments : Assignments)[Chip.id.uuidString]
        return Input == (Mode == .Grouping ? Chip.Family : Chip.Word.Term)
    }

    mutating func Assign(_ Value: String, Chip Id: UUID) -> Bool {
        guard !IsFinished, !Revealed, let Chip = ActiveChips.first(where: { $0.id == Id }) else { return false }
        if Mode == .Grouping {
            guard Families.contains(where: { $0.Code == Value }) else { return false }
        } else {
            guard Current?.id == Id, Chip.Options.contains(Value) else { return false }
        }
        if IsRetry { RetryAssignments[Id.uuidString] = Value } else { Assignments[Id.uuidString] = Value }
        if Mode == .Easy { Revealed = true }
        return true
    }

    mutating func Check() -> Bool {
        guard Mode == .Grouping, CanCheck else { return false }
        Revealed = true
        return true
    }

    mutating func Advance() -> Bool {
        guard Revealed, !IsFinished else { return false }
        Revealed = false
        Index += 1
        if Mode == .Grouping || Index >= ActiveChips.count {
            if !IsRetry && Chips.contains(where: { !Correct($0, Retry: false) }) { IsRetry = true; Index = 0 }
            else { IsFinished = true }
        }
        return true
    }
}

struct SynonymBag: Codable {
    var Cycle = 1
    var Known: [String] = []
    var Remaining: [String] = []
    var PreferredMode = SynonymMode.Grouping
    var Round: SynonymRound?
    var Notice: String?
    var CycleComplete: Bool { !Known.isEmpty && Remaining.isEmpty && Round?.IsFinished == true }

    mutating func Reconcile(_ Groups: [VocabularyGroup]) {
        let Codes = Set(Groups.map(\.Code)), Previous = Set(Known)
        Remaining = Remaining.filter { Codes.contains($0) }
        Remaining.append(contentsOf: Codes.subtracting(Previous).sorted())
        if let Round, !Round.IsFinished {
            let Changed = Round.Families.contains { Old in
                !Groups.contains { $0.Code == Old.Code && $0.Words == Old.Words }
            }
            if Changed {
                for Code in Round.Families.map(\.Code) where Codes.contains(Code) && !Remaining.contains(Code) { Remaining.append(Code) }
                self.Round = nil
                Notice = "Vocabulary changed. Start a new synonym round; your cycle is retained."
            }
        }
        Known = Groups.map(\.Code)
    }

    mutating func Start(_ Groups: [VocabularyGroup]) {
        Reconcile(Groups)
        guard !Groups.isEmpty, Round == nil || Round!.IsFinished else { return }
        if Remaining.isEmpty { Cycle += 1; Remaining = Known.shuffled() }
        var Chosen: [VocabularyGroup] = []
        var Terms: Set<String> = []
        for Group in Groups.filter({ Remaining.contains($0.Code) }).shuffled() {
            let Members = Set(Group.Words.map { QuizPlanner.Normalize($0.Term) })
            guard Members.isDisjoint(with: Terms) else { continue }
            Chosen.append(Group); Terms.formUnion(Members)
            if Chosen.count == (PreferredMode == .Easy ? 1 : 3) { break }
        }
        guard !Chosen.isEmpty else { return }
        let Mode: SynonymMode = Chosen.count == 1 ? .Easy : PreferredMode
        let AllWords = Groups.flatMap(\.Words)
        let Chips = Chosen.flatMap { Group in
            Group.Words.dropFirst().map { Word in
                var Seen: Set<String> = [QuizPlanner.Normalize(Word.Term)]
                let Distractors = AllWords.shuffled().filter { Other in
                    !Group.Words.contains(where: { SynonymCatalog.Related($0.Term, Other.Term) || QuizPlanner.SharesMeaning($0, Other) }) &&
                    Seen.insert(QuizPlanner.Normalize(Other.Term)).inserted
                }.prefix(3).map(\.Term)
                return SynonymChip(Word: Word, Family: Group.Code, Options: (Array(Distractors) + [Word.Term]).shuffled())
            }
        }.shuffled()
        let Selected = Set(Chosen.map(\.Code))
        Remaining.removeAll { Selected.contains($0) }
        Round = SynonymRound(Mode: Mode, Families: Chosen, Chips: Chips)
        Notice = nil
    }

    func IsValid(_ Groups: [VocabularyGroup]) -> Bool {
        let Codes = Set(Groups.map(\.Code))
        guard Cycle > 0, Set(Known) == Codes, Known.count == Codes.count,
              Set(Remaining).count == Remaining.count, Set(Remaining).isSubset(of: Codes) else { return false }
        guard let Round else { return true }
        let Families = Set(Round.Families.map(\.Code)), Chips = Set(Round.Chips.map { $0.id.uuidString })
        guard !Round.Families.isEmpty, Families.count == Round.Families.count,
              Round.Chips.count == Chips.count, !Chips.isEmpty,
              Set(Round.Assignments.keys).isSubset(of: Chips), Set(Round.RetryAssignments.keys).isSubset(of: Chips),
              Round.Index >= 0, Round.IsFinished || Round.Current != nil,
              Round.IsFinished || Families.isDisjoint(with: Remaining) && Families.isSubset(of: Codes),
              Round.Chips.allSatisfy({ Chip in
                  Round.Families.contains { $0.Code == Chip.Family && $0.Words.dropFirst().contains(where: { $0.Id == Chip.id }) } &&
                  !Chip.Options.isEmpty && Set(Chip.Options).count == Chip.Options.count && Chip.Options.contains(Chip.Word.Term)
              }) else { return false }
        let Members = Round.Families.flatMap { $0.Words.map { QuizPlanner.Normalize($0.Term) } }
        let ExpectedChips = Set(Round.Families.flatMap { $0.Words.dropFirst().map { $0.Id.uuidString } })
        guard Round.Families.allSatisfy({ $0.Words.count >= 2 }), Set(Members).count == Members.count,
              ExpectedChips == Chips else { return false }
        if Round.IsRetry && Set(Round.Assignments.keys) != Chips { return false }
        if Round.Mode == .Grouping {
            guard Round.Index == (Round.IsFinished ? 1 : 0) else { return false }
            if Round.Revealed || Round.IsFinished {
                guard Set(Round.Inputs.keys) == Set(Round.ActiveChips.map { $0.id.uuidString }) else { return false }
            }
        } else {
            guard Round.Index <= Round.ActiveChips.count,
                  !Round.IsFinished || Round.Index == Round.ActiveChips.count else { return false }
            let AnswerCount = Round.IsFinished ? Round.ActiveChips.count : Round.Index + (Round.Revealed ? 1 : 0)
            guard Set(Round.Inputs.keys) == Set(Round.ActiveChips.prefix(AnswerCount).map { $0.id.uuidString }) else { return false }
        }
        for Chip in Round.Chips {
            for Inputs in [Round.Assignments, Round.RetryAssignments] {
                if let Value = Inputs[Chip.id.uuidString], !(Round.Mode == .Grouping ? Families.contains(Value) : Chip.Options.contains(Value)) { return false }
            }
        }
        return true
    }
}
