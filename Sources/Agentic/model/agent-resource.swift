import Macros
import Schema
import Foundation

/// A resource attached to a message, referenced rather than inlined.
@JSONSchema
public struct AgentResource:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    /// Stable resource identifier.
    public let id: String
    /// Kind of media the resource holds.
    public var modality: AgentModality
    /// Where the resource's bytes can be found.
    public var source: AgentResourceSource
    /// MIME type, when known.
    public var contentType: String?
    /// Size in bytes, when known.
    public var byteCount: Int?
    /// Descriptive metadata.
    public var metadata: AgentResourceMetadata

    public init(
        id: String = UUID().uuidString,
        modality: AgentModality,
        source: AgentResourceSource,
        contentType: String? = nil,
        byteCount: Int? = nil,
        metadata: AgentResourceMetadata = .empty
    ) {
        self.id = id
        self.modality = modality
        self.source = source
        self.contentType = contentType
        self.byteCount = byteCount
        self.metadata = metadata
    }
}
