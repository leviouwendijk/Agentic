import Agentic

/// Shared task vocabulary, so every Agent that reads or writes a contract
/// interprets its fields and provenances the same way.
public extension Tasks.Instructions {
    /// Rendered from the contract and report types and their doc comments;
    /// renaming or documenting a field changes this text with it.
    @Instruction
    enum Contract: Instruction {
        public static let content = """
        TASK CONTRACT

        A contract is the binding description of one bounded assignment. Its fields:
        \(SchemaInstructionText.fields(of: AgentTaskContract.self))

        Each constraint states something the result must respect:
        \(SchemaInstructionText.fields(of: AgentTaskConstraint.self))

        Constraint provenances:
        \(SchemaInstructionText.values(of: AgentTaskConstraintProvenance.self))

        \(invariants) constraints bind the result. The others are claims; \
        check them before relying on them.

        When an invariant cannot hold, a needed change lies outside the write \
        scope, or a claim proves false, that is a contract conflict: report it \
        in the attempt report and never work around the contract.

        An attempt report's fields:
        \(SchemaInstructionText.fields(of: AgentTaskAttemptReport.self))

        Mutation states:
        \(SchemaInstructionText.values(of: AgentTaskMutationState.self))

        A recorded attempt is evidence for a decision, not the decision: only \
        \(Tasks.Tools.AcceptTask.identifier.rawValue) completes a task and \
        unblocks its dependents.
        """

        private static var invariants: String {
            AgentTaskConstraintProvenance.allCases
                .filter(\.isInvariant)
                .map(\.rawValue)
                .joined(separator: " and ")
        }
    }
}
