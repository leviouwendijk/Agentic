import Primitives

public struct OptimizationIdentifier: StringIdentifier {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public struct OptimizationDefinition:
    Definition,
    Codable,
    Hashable
{
    public let identifier: OptimizationIdentifier
    public let purpose: String

    public init(
        identifier: OptimizationIdentifier,
        purpose: String
    ) {
        self.identifier = identifier
        self.purpose = purpose
    }
}

public protocol Optimization: Sendable {
    static var definition: OptimizationDefinition { get }
}
