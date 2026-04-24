public enum AgentTranscriptEvent: Sendable, Codable, Hashable, Identifiable {
    case message(AgentMessage)
    case tool_call(AgentToolCall)
    case tool_result(AgentToolResult)
    case session_branch(AgentSessionBranchEvent)
    case note(id: String, text: String)

    private enum CodingKeys: String, CodingKey {
        case kind
        case id
        case text
        case message
        case tool_call
        case tool_result
        case session_branch
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case toolcall = "toolCall"
        case toolresult = "toolResult"
        case sessionbranch = "sessionBranch"
    }

    private enum Kind: String, Codable {
        case message
        case tool_call
        case tool_result
        case session_branch
        case note

        init(
            from decoder: any Decoder
        ) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(
                String.self
            )

            switch rawValue {
            case "message":
                self = .message

            case "tool_call", "toolCall":
                self = .tool_call

            case "tool_result", "toolResult":
                self = .tool_result

            case "session_branch", "sessionBranch":
                self = .session_branch

            case "note":
                self = .note

            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unsupported AgentTranscriptEvent.Kind '\(rawValue)'."
                )
            }
        }
    }

    public init(
        from decoder: any Decoder
    ) throws {
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
        case .message:
            self = .message(
                try container.decode(
                    AgentMessage.self,
                    forKey: .message
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

        case .session_branch:
            if let value = try container.decodeIfPresent(
                AgentSessionBranchEvent.self,
                forKey: .session_branch
            ) {
                self = .session_branch(value)
            } else {
                self = .session_branch(
                    try legacyContainer.decode(
                        AgentSessionBranchEvent.self,
                        forKey: .sessionbranch
                    )
                )
            }

        case .note:
            self = .note(
                id: try container.decode(
                    String.self,
                    forKey: .id
                ),
                text: try container.decode(
                    String.self,
                    forKey: .text
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
        case .message(let message):
            try container.encode(
                Kind.message,
                forKey: .kind
            )
            try container.encode(
                message,
                forKey: .message
            )

        case .tool_call(let call):
            try container.encode(
                Kind.tool_call,
                forKey: .kind
            )
            try container.encode(
                call,
                forKey: .tool_call
            )

        case .tool_result(let result):
            try container.encode(
                Kind.tool_result,
                forKey: .kind
            )
            try container.encode(
                result,
                forKey: .tool_result
            )

        case .session_branch(let event):
            try container.encode(
                Kind.session_branch,
                forKey: .kind
            )
            try container.encode(
                event,
                forKey: .session_branch
            )

        case .note(let id, let text):
            try container.encode(
                Kind.note,
                forKey: .kind
            )
            try container.encode(
                id,
                forKey: .id
            )
            try container.encode(
                text,
                forKey: .text
            )
        }
    }

    public var id: String {
        switch self {
        case .message(let message):
            return message.id

        case .tool_call(let call):
            return call.id

        case .tool_result(let result):
            return result.toolCallID

        case .session_branch(let event):
            return event.id

        case .note(let id, _):
            return id
        }
    }

    public var summaryText: String {
        switch self {
        case .message(let message):
            return message.content.text

        case .tool_call(let call):
            return call.name

        case .tool_result(let result):
            return result.name ?? result.toolCallID

        case .session_branch(let event):
            return event.summaryText

        case .note(_, let text):
            return text
        }
    }
}
