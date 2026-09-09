import Schema

public enum AgentResponseFormat: Sendable, Hashable {
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
