public enum ToolInvocation {}

public extension ToolInvocation {
    struct Review: Sendable, Codable, Hashable {
        public let call: AgentToolCall
        public let preflight: ToolPreflight
        public let requirement: ApprovalRequirement

        public init(
            call: AgentToolCall,
            preflight: ToolPreflight,
            requirement: ApprovalRequirement
        ) {
            self.call = call
            self.preflight = preflight
            self.requirement = requirement
        }
    }

    struct Result: Sendable, Codable, Hashable {
        public let review: Review
        public let decision: ApprovalDecision
        public let toolResult: AgentToolResult?

        public init(
            review: Review,
            decision: ApprovalDecision,
            toolResult: AgentToolResult?
        ) {
            self.review = review
            self.decision = decision
            self.toolResult = toolResult
        }

        public var executed: Bool {
            toolResult != nil
        }
    }
}
