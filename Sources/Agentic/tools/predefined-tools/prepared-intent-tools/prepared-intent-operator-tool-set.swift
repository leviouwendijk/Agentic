public struct PreparedIntentOperatorToolSet: AgentToolSet {
    public let manager: PreparedIntentManager

    public init(
        manager: PreparedIntentManager
    ) {
        self.manager = manager
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register(
            [
                ListPreparedIntentsTool(
                    manager: manager
                ),
                ReadPreparedIntentTool(
                    manager: manager
                ),
                ReviewPreparedIntentTool(
                    manager: manager
                )
            ]
        )
    }
}
