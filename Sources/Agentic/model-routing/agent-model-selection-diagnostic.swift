public struct AgentModelSelectionDiagnostic: Sendable, Codable, Hashable {
    public enum Severity: String, Sendable, Codable, Hashable, CaseIterable {
        case info
        case warning
    }

    public enum Code: String, Sendable, Codable, Hashable, CaseIterable {
        case preferred_profile_selected
        case preferred_model_selected
        case purpose_default_selected
        case purpose_match_selected
        case fallback_selected
        case global_default_selected
        case preference_unavailable
        case preference_rejected_by_constraint
        case external_provider_disallowed
        case required_capability_missing
        case required_capacity_missing
    }

    public var code: Code
    public var severity: Severity
    public var message: String?
    public var metadata: [String: String]

    public init(
        code: Code,
        severity: Severity = .info,
        message: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.code = code
        self.severity = severity
        self.message = message
        self.metadata = metadata
    }
}
