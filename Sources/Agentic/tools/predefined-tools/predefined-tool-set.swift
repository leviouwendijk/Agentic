public struct CoreFileToolSet: AgentToolSet {
    public init() {}

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register(
            [
                ReadFileTool(),
                WriteFileTool(),
                EditFileTool(),
                ScanPathsTool()
            ]
        )
    }
}

public struct CoreToolSet: AgentToolSet {
    public let contextComposer: ContextComposer

    public init(
        contextComposer: ContextComposer = .init()
    ) {
        self.contextComposer = contextComposer
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register(
            CoreFileToolSet()
        )
        try registry.register(
            CoreContextToolSet(
                composer: contextComposer
            )
        )
    }
}
