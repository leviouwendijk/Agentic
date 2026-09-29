public enum MessageContentBlock: Sendable, Codable, Hashable {
    case text(String)
    case resource(AgentResource)
    case tool_call(ToolCall)
    case tool_result(ToolResult)

    private enum CodingKeys: String, CodingKey {
        case kind
        case text
        case resource
        case tool_call
        case tool_result
    }

    private enum Kind: String, Codable {
        case text
        case resource
        case tool_call
        case tool_result

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            switch rawValue {
            case "text":
                self = .text

            case "resource":
                self = .resource

            case "tool_call":
                self = .tool_call

            case "tool_result":
                self = .tool_result

            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unsupported MessageContentBlock.Kind '\(rawValue)'."
                )
            }
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
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

        case .resource:
            self = .resource(
                try container.decode(
                    AgentResource.self,
                    forKey: .resource
                )
            )

        case .tool_call:
            self = .tool_call(
                try container.decode(
                    ToolCall.self,
                    forKey: .tool_call
                )
            )

        case .tool_result:
            self = .tool_result(
                try container.decode(
                    ToolResult.self,
                    forKey: .tool_result
                )
            )
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

        case .resource(let value):
            try container.encode(
                Kind.resource,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .resource
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
