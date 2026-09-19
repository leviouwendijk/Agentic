import Primitives

public struct InferenceIdentifier: StringIdentifier {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public struct InferenceDefinition:
    Definition,
    Codable,
    Hashable
{
    public let identifier: InferenceIdentifier
    public let purpose: String

    public init(
        identifier: InferenceIdentifier,
        purpose: String
    ) {
        self.identifier = identifier
        self.purpose = purpose
    }
}

public protocol Inference:
    InferenceContract
{
    static var definition: InferenceDefinition { get }
}
