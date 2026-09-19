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
