public protocol ToolApprovalHandler: Sendable {
    func decide(
        on preflight: ToolPreflight,
        requirement: ApprovalRequirement
    ) async throws -> ApprovalDecision
}

public extension ToolApprovalHandler {
    func decide(
        on preflight: ToolPreflight,
        requirement: ApprovalRequirement
    ) async throws -> ApprovalDecision {
        requirement.decision
    }
}
