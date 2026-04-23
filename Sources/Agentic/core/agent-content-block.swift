public enum AgentContentBlock: Sendable, Codable, Hashable {
    case text(String)
    case tool_call(AgentToolCall)
    case tool_result(AgentToolResult)

    private enum CodingKeys: String, CodingKey {
        case kind
        case text
        case tool_call
        case tool_result
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case toolcall = "toolCall"
        case toolresult = "toolResult"
    }

    private enum Kind: String, Codable {
        case text
        case tool_call
        case tool_result

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            switch rawValue {
            case "text":
                self = .text

            case "tool_call", "toolCall":
                self = .tool_call

            case "tool_result", "toolResult":
                self = .tool_result

            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unsupported AgentContentBlock.Kind '\(rawValue)'."
                )
            }
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        let legacyContainer = try decoder.container(
            keyedBy: LegacyCodingKeys.self
        )
        let kind = try container.decode(
            Kind.self,
            forKey: .kind
        )

        switch kind {
        case .text:
            self = .text(
                try container.decode(
                    String.self,
                    forKey: .text
                )
            )

        case .tool_call:
            if let value = try container.decodeIfPresent(
                AgentToolCall.self,
                forKey: .tool_call
            ) {
                self = .tool_call(value)
            } else {
                self = .tool_call(
                    try legacyContainer.decode(
                        AgentToolCall.self,
                        forKey: .toolcall
                    )
                )
            }

        case .tool_result:
            if let value = try container.decodeIfPresent(
                AgentToolResult.self,
                forKey: .tool_result
            ) {
                self = .tool_result(value)
            } else {
                self = .tool_result(
                    try legacyContainer.decode(
                        AgentToolResult.self,
                        forKey: .toolresult
                    )
                )
            }
        }
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        switch self {
        case .text(let value):
            try container.encode(
                Kind.text,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .text
            )

        case .tool_call(let value):
            try container.encode(
                Kind.tool_call,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .tool_call
            )

        case .tool_result(let value):
            try container.encode(
                Kind.tool_result,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .tool_result
            )
        }
    }
}
