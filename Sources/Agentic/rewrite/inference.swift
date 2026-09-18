import Primitives
import Schema

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

public protocol Inference: Sendable {
    associatedtype Input:
        Codable & Sendable

    associatedtype Output:
        JSONSchemaProviding & Codable & Sendable

    static var definition: InferenceDefinition { get }
}
