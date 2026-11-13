import Macros
import Schema
/// Descriptive metadata for a resource.
@JSONSchema
public struct AgentResourceMetadata:
    Sendable,
    Codable,
    Hashable
{
    /// Human-readable title.
    public var title: String?
    /// Original filename, when the resource came from a file.
    public var filename: String?
    /// Free-form string attributes.
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
