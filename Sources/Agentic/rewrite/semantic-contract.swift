import Schema

public protocol SemanticInput:
    Codable,
    Sendable
{}

public protocol SemanticOutput:
    Codable,
    Sendable
{}

public protocol InferredOutput:
    SemanticOutput,
    JSONSchemaProviding
{}

public protocol SemanticContract: Sendable {
    associatedtype Input: SemanticInput
    associatedtype Output: SemanticOutput
}

public protocol InferenceContract:
    SemanticContract
where Output: InferredOutput
{}
