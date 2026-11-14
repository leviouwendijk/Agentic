import Agentic

/// Shared task vocabulary, so every Agent that reads or writes a contract
/// interprets its fields and provenances the same way.
public extension Tasks.Instructions {
    @Instruction
    enum Contract: Instruction {
        public static let content = """
        TASK CONTRACT

        A task contract is the binding description of one bounded assignment:
            - objective: the change and its expected outcome.
            - writeScope: the only paths that may be mutated. Empty means
              inspect and report only.
            - constraints: statements the result must respect, each with
              a provenance.
            - candidateSites: locations likely to need change; not exhaustive.
            - exclusions: related work that is out of scope.
            - acceptance: the conditions the result is judged against.

        Constraint provenance:
            - user_instruction: the user stated it. An invariant.
            - accepted_decision: the coordinator settled it. An invariant
              until the coordinator reopens it.
            - observed: someone inspected it. A claim that may prove wrong.
            - hypothesis: assumed, not verified. A claim to check.

        An invariant cannot hold, a needed change lies outside writeScope,
        or a claim proves false: that is a contract conflict. Report it in
        contractConflicts; never work around the contract.

        A recorded attempt is evidence for a decision, not the decision:
        only \(Tasks.Tools.AcceptTask.identifier.rawValue) completes a task
        and unblocks its dependents.
        """
    }
}
