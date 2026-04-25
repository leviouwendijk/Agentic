public struct CoreFileMutationHistoryToolSet: AgentToolSet {
    public let store: any AgentFileMutationStore
    public let artifactStore: (any AgentArtifactStore)?

    public init(
        store: any AgentFileMutationStore,
        artifactStore: (any AgentArtifactStore)? = nil
    ) {
        self.store = store
        self.artifactStore = artifactStore
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register {
            ListFileMutationsTool(
                store: store
            )

            InspectFileMutationTool(
                store: store,
                artifactStore: artifactStore
            )
        }
    }
}
