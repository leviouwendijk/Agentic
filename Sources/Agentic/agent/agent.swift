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
    CapabilityDefinition,
    Codable,
    Hashable
{
    public let identifier: AgentIdentifier
    public let purpose: String
    public let instructions: String?
    private let source: Instructions?
    public var instructionSnapshot: InstructionSnapshot? {
        instructions.map {
            InstructionSnapshot(content: $0, composition: source)
        }
    }
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
        self.source = nil
        self.capabilities = capabilities
        self.modelSelection = modelSelection
        self.delegation = delegation
    }

    public init<Source: InstructionSource>(
        identifier: AgentIdentifier,
        purpose: String,
        instructions: Source,
        capabilities: AgentCapabilities = .none,
        modelSelection: AgentModelSelection = .init(purpose: .executor),
        delegation: AgentDelegationPolicy = .disabled
    ) {
        let snapshot = instructions.instructionSnapshot
        self.identifier = identifier
        self.purpose = purpose
        self.instructions = snapshot?.content
        self.source = snapshot?.composition
        self.capabilities = capabilities
        self.modelSelection = modelSelection
        self.delegation = delegation
    }

}

public protocol Agent:
    Capability
where DefinitionType == AgentDefinition
{
    static var purpose: String { get }
    associatedtype InstructionSourceType: InstructionSource = String?
    static var instructions: InstructionSourceType { get }
    static var capabilities: AgentCapabilities { get }
    static var modelSelection: AgentModelSelection { get }
    static var delegation: AgentDelegationPolicy { get }
}

public extension Agent where InstructionSourceType == String? {
    static var instructions: String? {
        nil
    }
}

public extension Agent {
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
