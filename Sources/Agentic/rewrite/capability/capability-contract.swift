import Schema

/// A semantic declaration for an executable or invokable Capability.
/// Domain declarations are deliberately not required to conform: a Domain
/// identifies a namespace, not an individual invocation contract.
public protocol CapabilityDefinition: Definition {
    associatedtype Identifier: Sendable & Codable & Hashable

    var identifier: Identifier { get }
    var purpose: String { get }
}

/// Shared authored contract. Each capability family retains its own
/// execution requirements; Producer already supplies typed Input and Output.
public protocol Capability: Producer {
    associatedtype DefinitionType: CapabilityDefinition

    static var definition: DefinitionType { get }
    static var reference: CapabilityReference { get }
}

/// Derives both schemas from the authored Swift types, before any JSON
/// lowering at a dynamic registration or model-transport boundary.
public struct CapabilityContract: Sendable {
    public let input: JSONSchema
    public let output: JSONSchema

    public init(
        input: JSONSchema,
        output: JSONSchema
    ) {
        self.input = input
        self.output = output
    }
}

public extension Capability {
    static var contract: CapabilityContract {
        .init(
            input: Input.jsonschema,
            output: Output.jsonschema
        )
    }
}

/// Only the model-facing envelope is JSON-schema shaped. The semantic
/// capability input remains typed and separate from provider transport.
public enum CapabilityModelInputSchema {
    public static func envelope(
        semanticInput: JSONSchema,
        execution: JSONSchema? = nil
    ) -> JSONSchema {
        if let execution {
            return .object {
                JSONSchema.property(
                    "arguments",
                    schema: semanticInput,
                    required: true
                )
                JSONSchema.property(
                    "execution",
                    schema: execution,
                    required: false
                )
            }
        }
        return .object {
            JSONSchema.property(
                "arguments",
                schema: semanticInput,
                required: true
            )
        }
    }
}
