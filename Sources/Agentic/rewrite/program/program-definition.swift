public struct ProgramDefinition:
    Definition,
    Codable,
    Hashable
{
    public let identifier: ProgramIdentifier
    public let purpose: String
    public let title: String?
    public let tags: [String]

    public init(
        identifier: ProgramIdentifier,
        purpose: String,
        title: String? = nil,
        tags: [String] = []
    ) {
        self.identifier = identifier
        self.purpose = purpose
        self.title = title
        self.tags = tags
    }
}
