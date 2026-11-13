import Foundation

public struct AgentResource:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let id: String
    public var modality: AgentModality
    public var source: AgentResourceSource
    public var contentType: String?
    public var byteCount: Int?
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
