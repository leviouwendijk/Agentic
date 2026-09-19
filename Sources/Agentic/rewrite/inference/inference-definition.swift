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
