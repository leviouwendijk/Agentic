import Schema

public enum TranscriptEvent:
    Sendable,
    Codable,
    Hashable,
    Identifiable,
    JSONSchemaProviding
{
    case message(Message)
    case call(FunctionCall)
    case result(FunctionCall.Response)
    case session_branch(SessionBranchEvent)
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

            case "tool_call":
                self = .tool_call

            case "tool_result":
                self = .tool_result

            case "session_branch":
                self = .session_branch

            case "note":
                self = .note

            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unsupported TranscriptEvent.Kind '\(rawValue)'."
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
        let kind = try container.decode(
            Kind.self,
            forKey: .kind
        )

        switch kind {
        case .message:
            self = .message(
                try container.decode(
                    Message.self,
                    forKey: .message
                )
            )

        case .tool_call:
            self = .call(
                try container.decode(
                    FunctionCall.self,
                    forKey: .tool_call
                )
            )

        case .tool_result:
            self = .result(
                try container.decode(
                    FunctionCall.Response.self,
                    forKey: .tool_result
                )
            )

        case .session_branch:
            self = .session_branch(
                try container.decode(
                    SessionBranchEvent.self,
                    forKey: .session_branch
                )
            )

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

        case .call(let call):
            try container.encode(
                Kind.tool_call,
                forKey: .kind
            )
            try container.encode(
                call,
                forKey: .tool_call
            )

        case .result(let result):
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

    public static var jsonschema: JSONSchema {
        .oneOf([
            .object(
                properties: [
                    .init(
                        name: "kind",
                        schema: .string(
                            cases: [
                                "message",
                            ]
                        ),
                        required: true
                    ),
                    .init(
                        name: "message",
                        schema: .any,
                        required: true
                    ),
                ],
                additionalProperties: .disallowed
            ),
            .object(
                properties: [
                    .init(
                        name: "kind",
                        schema: .string(
                            cases: [
                                "tool_call",
                            ]
                        ),
                        required: true
                    ),
                    .init(
                        name: "tool_call",
                        schema: .any,
                        required: true
                    ),
                ],
                additionalProperties: .disallowed
            ),
            .object(
                properties: [
                    .init(
                        name: "kind",
                        schema: .string(
                            cases: [
                                "tool_result",
                            ]
                        ),
                        required: true
                    ),
                    .init(
                        name: "tool_result",
                        schema: .any,
                        required: true
                    ),
                ],
                additionalProperties: .disallowed
            ),
            .object(
                properties: [
                    .init(
                        name: "kind",
                        schema: .string(
                            cases: [
                                "session_branch",
                            ]
                        ),
                        required: true
                    ),
                    .init(
                        name: "session_branch",
                        schema: .any,
                        required: true
                    ),
                ],
                additionalProperties: .disallowed
            ),
            .object(
                properties: [
                    .init(
                        name: "kind",
                        schema: .string(
                            cases: [
                                "note",
                            ]
                        ),
                        required: true
                    ),
                    .init(
                        name: "id",
                        schema: .string(),
                        required: true
                    ),
                    .init(
                        name: "text",
                        schema: .string(),
                        required: true
                    ),
                ],
                additionalProperties: .disallowed
            ),
        ])
    }

    public var id: String {
        switch self {
        case .message(let message):
            return message.id

        case .call(let call):
            return call.id

        case .result(let result):
            return result.call.id

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

        case .call(let call):
            return call.name

        case .result(let result):
            return result.call.name

        case .session_branch(let event):
            return event.summaryText

        case .note(_, let text):
            return text
        }
    }
}
