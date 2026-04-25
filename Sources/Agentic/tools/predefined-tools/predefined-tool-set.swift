public struct CoreFileToolSet: AgentToolSet {
    public let fileMutationRecorder: AgentFileMutationRecorder?

    public init(
        fileMutationRecorder: AgentFileMutationRecorder? = nil
    ) {
        self.fileMutationRecorder = fileMutationRecorder
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register {
            ReadFileTool()
            WriteFileTool(
                recorder: fileMutationRecorder
            )
            EditFileTool(
                recorder: fileMutationRecorder
            )
            ScanPathsTool()
        }
    }
}

public struct CoreInteractionToolSet: AgentToolSet {
    public init() {}

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register {
            ClarifyWithUserTool()
        }
    }
}

public struct CoreToolSet: AgentToolSet {
    public let contextComposer: ContextComposer
    public let includeInteractionTools: Bool
    public let fileMutationRecorder: AgentFileMutationRecorder?

    public init(
        contextComposer: ContextComposer = .init(),
        includeInteractionTools: Bool = false,
        fileMutationRecorder: AgentFileMutationRecorder? = nil
    ) {
        self.contextComposer = contextComposer
        self.includeInteractionTools = includeInteractionTools
        self.fileMutationRecorder = fileMutationRecorder
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register {
            CoreFileToolSet(
                fileMutationRecorder: fileMutationRecorder
            )

            CoreContextToolSet(
                composer: contextComposer
            )

            if includeInteractionTools {
                CoreInteractionToolSet()
            }
        }
    }
}
