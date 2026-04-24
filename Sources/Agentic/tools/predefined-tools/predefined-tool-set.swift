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

public struct CoreInteractionToolSet: AgentToolSet {
    public init() {}

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register(
            [
                ClarifyWithUserTool()
            ]
        )
    }
}

public struct CoreToolSet: AgentToolSet {
    public let contextComposer: ContextComposer
    public let includeInteractionTools: Bool

    public init(
        contextComposer: ContextComposer = .init(),
        includeInteractionTools: Bool = false
    ) {
        self.contextComposer = contextComposer
        self.includeInteractionTools = includeInteractionTools
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

        if includeInteractionTools {
            try registry.register(
                CoreInteractionToolSet()
            )
        }
    }
}
