import Primitives

/// Provider-neutral function declaration. The model transport does not know
/// whether execution resolves to a Tool, Program, Inference, or Agent.
/// Semantic target identity and authorization stay in Runtime's projection.
public struct ModelFunctionDescriptor:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let name: String
    public let description: String
    public let input: JSONValue?

    public init(
        name: String,
        description: String,
        input: JSONValue? = nil
    ) {
        self.name = name
        self.description = description
        self.input = input
    }

    public var id: String {
        name
    }
}
