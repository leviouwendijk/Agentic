import Foundation
import Primitives
import Schema

public struct AgentCall:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let id: String
    public let agent: AgentIdentifier
    public let input: JSONValue

    public init(
        id: String,
        agent: AgentIdentifier,
        input: JSONValue
    ) {
        self.id = id
        self.agent = agent
        self.input = input
    }
}

public struct AgentResult:
    Sendable,
    Codable,
    Hashable
{
    public let agentCallID: String
    public let agent: AgentIdentifier
    public let output: JSONValue
    public let isError: Bool

    public init(
        agentCallID: String,
        agent: AgentIdentifier,
        output: JSONValue,
        isError: Bool = false
    ) {
        self.agentCallID = agentCallID
        self.agent = agent
        self.output = output
        self.isError = isError
    }
}

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
