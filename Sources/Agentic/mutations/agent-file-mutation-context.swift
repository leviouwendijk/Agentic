import Foundation
import Path
import Writers

public struct AgentFileMutationContext: Sendable, Codable, Hashable {
    public var rootID: PathAccessRootIdentifier?
    public var toolCallID: String?
    public var preparedIntentID: PreparedIntentIdentifier?
    public var metadata: [String: String]

    public init(
        rootID: PathAccessRootIdentifier? = nil,
        toolCallID: String? = nil,
        preparedIntentID: PreparedIntentIdentifier? = nil,
        metadata: [String: String] = [:]
    ) {
        self.rootID = rootID
        self.toolCallID = toolCallID
        self.preparedIntentID = preparedIntentID
        self.metadata = metadata
    }

    public static let empty = Self()
}

public struct AgentFileEditOptions: Sendable {
    public var encoding: String.Encoding
    public var write: SafeWriteOptions?
    public var mutation: AgentFileMutationContext

    public init(
        encoding: String.Encoding = .utf8,
        write: SafeWriteOptions? = nil,
        mutation: AgentFileMutationContext = .empty
    ) {
        self.encoding = encoding
        self.write = write
        self.mutation = mutation
    }

    public static let `default` = Self()
}
