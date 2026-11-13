import Macros
import Schema

/// One block of message content.
///
/// Encoded as a single-key object naming the block, e.g. `{"text": "hi"}` or
/// `{"call": {...}}`.
public enum MessageContentBlock: Sendable, Codable, Hashable, JSONSchemaProviding {
    /// Plain text.
    case text(String)
    /// An attached resource, such as an image or document.
    case resource(AgentResource)
    /// A function call emitted by the model.
    case call(FunctionCall)
    /// The response returned to the model for a function call.
    case result(FunctionCall.Response)

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case text
        case resource
        case call
        case result
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard container.allKeys.count == 1, let key = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: container.codingPath,
                    debugDescription: "A content block has exactly one of: \(CodingKeys.allCases.map(\.rawValue).joined(separator: ", "))."
                )
            )
        }

        switch key {
        case .text:
            self = .text(try container.decode(String.self, forKey: key))
        case .resource:
            self = .resource(try container.decode(AgentResource.self, forKey: key))
        case .call:
            self = .call(try container.decode(FunctionCall.self, forKey: key))
        case .result:
            self = .result(try container.decode(FunctionCall.Response.self, forKey: key))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let value):
            try container.encode(value, forKey: .text)
        case .resource(let value):
            try container.encode(value, forKey: .resource)
        case .call(let value):
            try container.encode(value, forKey: .call)
        case .result(let value):
            try container.encode(value, forKey: .result)
        }
    }

    public static var jsonschema: JSONSchema {
        JSONSchema(
            form: .oneOf([
                variant(.text, String.jsonschema, "Plain text."),
                variant(.resource, AgentResource.jsonschema, "An attached resource, such as an image or document."),
                variant(.call, FunctionCall.jsonschema, "A function call emitted by the model."),
                variant(.result, FunctionCall.Response.jsonschema, "The response returned to the model for a function call."),
            ]),
            description: "One block of message content."
        )
    }

    private static func variant(
        _ key: CodingKeys,
        _ schema: JSONSchema,
        _ description: String
    ) -> JSONSchema {
        .object(additionalProperties: .disallowed) {
            JSONSchema.Property(
                name: key.rawValue,
                schema: schema,
                required: true,
                description: description
            )
        }
    }
}
