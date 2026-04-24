import Foundation

public struct AgentArtifact: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let sessionID: String
    public let kind: AgentArtifactKind
    public let title: String?
    public let filename: String
    public let contentType: String
    public let byteCount: Int
    public let createdAt: Date
    public let metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        sessionID: String,
        kind: AgentArtifactKind,
        title: String? = nil,
        filename: String,
        contentType: String,
        byteCount: Int,
        createdAt: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.sessionID = sessionID
        self.kind = kind
        self.title = title
        self.filename = filename
        self.contentType = contentType
        self.byteCount = byteCount
        self.createdAt = createdAt
        self.metadata = metadata
    }
}

public struct AgentArtifactDraft: Sendable, Codable, Hashable {
    public var kind: AgentArtifactKind
    public var title: String?
    public var filename: String?
    public var contentType: String?
    public var content: String
    public var metadata: [String: String]

    public init(
        kind: AgentArtifactKind,
        title: String? = nil,
        filename: String? = nil,
        contentType: String? = nil,
        content: String,
        metadata: [String: String] = [:]
    ) {
        self.kind = kind
        self.title = title
        self.filename = filename
        self.contentType = contentType
        self.content = content
        self.metadata = metadata
    }
}

public struct AgentArtifactRecord: Sendable, Codable, Hashable {
    public let artifact: AgentArtifact
    public let content: String

    public init(
        artifact: AgentArtifact,
        content: String
    ) {
        self.artifact = artifact
        self.content = content
    }
}
