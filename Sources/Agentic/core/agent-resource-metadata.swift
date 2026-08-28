public struct AgentResourceMetadata:
    Sendable,
    Codable,
    Hashable
{
    public var title: String?
    public var filename: String?
    public var attributes: [String: String]

    public init(
        title: String? = nil,
        filename: String? = nil,
        attributes: [String: String] = [:]
    ) {
        self.title = title
        self.filename = filename
        self.attributes = attributes
    }

    public static let empty = Self()
}
