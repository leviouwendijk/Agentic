import Agentic
import Workspace
import Primitives
import Schema
import Macros

@JSONSchema
public struct ListArtifactsInput: Sendable, Codable, Hashable {
    /// Artifact kinds to include. An empty array includes every kind.
    public let kinds: [AgentArtifactKind]
    /// Whether to list newest artifacts first. Defaults to true when omitted.
    public let latestFirst: Bool?
    /// Optional maximum number of artifacts to return.
    public let limit: Int?

    public init(
        kinds: [AgentArtifactKind] = [],
        latestFirst: Bool? = nil,
        limit: Int? = nil
    ) {
        self.kinds = kinds
        self.latestFirst = latestFirst
        self.limit = limit
    }

    public var resolvedLatestFirst: Bool {
        latestFirst ?? true
    }

    public var resolvedLimit: Int? {
        guard let limit else {
            return nil
        }

        return max(
            0,
            limit
        )
    }
}

@JSONSchema
public struct ListArtifactsOutput: Sendable, Codable, Hashable {
    public let artifacts: [AgentArtifact]
    public let count: Int

    public init(
        artifacts: [AgentArtifact]
    ) {
        self.artifacts = artifacts
        self.count = artifacts.count
    }
}

public extension Standard.Tools {
    struct ListArtifacts: Tool {
    public typealias Input = ListArtifactsInput
    public typealias Output = ListArtifactsOutput

    public static let identifier: ToolIdentifier = "list_artifacts"
    public static let description = "List durable artifacts emitted for the current Agentic session."
    public static let risk: ActionRisk = .observe
    public static let definition = ToolDefinition(
        identifier: identifier,
        purpose: description,
        risk: risk
    )

    public var identifier: ToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public let store: any AgentArtifactStore

    public init(
        store: any AgentArtifactStore
    ) {
        self.store = store
    }

    public func preflight(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> ToolPreflight {

        return .init(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary: summary(
                for: input
            ),
            sideEffects: []
        )
    }

    public func call(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> Output {

        let artifacts = try await store.list(
            kinds: input.kinds,
            latestFirst: input.resolvedLatestFirst,
            limit: input.resolvedLimit
        )

        return ListArtifactsOutput(
                artifacts: artifacts
            )
    }
    }
}

private extension Standard.Tools.ListArtifacts {
    func summary(
        for input: ListArtifactsInput
    ) -> String {
        guard !input.kinds.isEmpty else {
            return "List session artifacts"
        }

        return "List session artifacts filtered to \(input.kinds.map(\.rawValue).joined(separator: ", "))"
    }
}