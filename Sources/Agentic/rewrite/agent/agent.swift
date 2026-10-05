import Primitives
import Schema

public struct AgentIdentifier:
    StringIdentifier,
    JSONSchemaProviding
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public static var jsonschema: JSONSchema {
        .string()
    }
}

public struct AgentDefinition:
    Definition,
    Codable,
    Hashable
{
    public let identifier: AgentIdentifier
    public let purpose: String
    public let instructions: String?
    public let capabilities: AgentCapabilities
    public let modelSelection: AgentModelSelection
    public let delegation: AgentDelegationPolicy

    public init(
        identifier: AgentIdentifier,
        purpose: String,
        instructions: String? = nil,
        capabilities: AgentCapabilities = .none,
        modelSelection: AgentModelSelection = .init(
            purpose: .executor
        ),
        delegation: AgentDelegationPolicy = .disabled
    ) {
        self.identifier = identifier
        self.purpose = purpose
        self.instructions = instructions
        self.capabilities = capabilities
        self.modelSelection = modelSelection
        self.delegation = delegation
    }
}

public protocol Agent:
    Producer
{
    static var definition: AgentDefinition { get }
    static var purpose: String { get }
    static var instructions: String? { get }
    static var capabilities: AgentCapabilities { get }
    static var modelSelection: AgentModelSelection { get }
    static var delegation: AgentDelegationPolicy { get }
}

public extension Agent {
    static var instructions: String? {
        nil
    }

    static var capabilities: AgentCapabilities {
        .none
    }

    static var modelSelection: AgentModelSelection {
        .init(
            purpose: .executor
        )
    }

    static var delegation: AgentDelegationPolicy {
        .disabled
    }
}
