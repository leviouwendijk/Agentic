import Foundation
import Primitives
import Schema

public struct AgentDelegationRequest<AgentType: Agent>:
    Sendable,
    Codable,
    JSONSchemaProviding
{
    public let input: AgentType.Input

    public init(
        input: AgentType.Input
    ) {
        self.input = input
    }

    public init(
        from decoder: any Decoder
    ) throws {
        input = try AgentType.Input(
            from: decoder
        )
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        try input.encode(
            to: encoder
        )
    }

    public static var jsonschema: JSONSchema {
        AgentType.Input.jsonschema
    }
}

