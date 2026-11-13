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

/// One prepared capability execution retains the exact, versioned operation
/// alongside its review projection. It is data, not an authorization grant.
/// The executor is responsible for an authoritative approval/claim transition.
public struct CapabilityPreparation<Review: Sendable & Codable & Hashable>:
    Sendable, Codable, Hashable
{
    public let review: Review
    public let operation: PreparedOperation.Envelope?

    public init(review: Review, operation: PreparedOperation.Envelope? = nil) {
        self.review = review
        self.operation = operation
    }
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
