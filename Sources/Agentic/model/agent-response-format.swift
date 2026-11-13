import Schema

public enum AgentResponseFormat: Sendable, Codable, Hashable {
    case text
    case jsonschema(JSONSchema)

    public var requiredCapabilities: Set<AgentModelCapability> {
        switch self {
        case .text:
            [
                .text,
            ]

        case .jsonschema:
            [
                .text,
                .structured_output,
            ]
        }
    }
}
