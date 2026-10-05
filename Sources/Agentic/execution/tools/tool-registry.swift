import Workspace
import Schema

public struct ToolRegistry: Sendable {
    private var tools:
        [ToolIdentifier: RegisteredTool]

    public init() {
        self.tools = [:]
    }

    public var definitions: [ToolDefinition] {
        registeredTools.map(
            \.definition
        )
    }

    public var modelFacingDefinitions: [ToolDescriptor] {
        registeredTools.compactMap(
            \.modelFacingDescriptor
        )
    }

    public func modelFacingDefinition(
        identifiedBy identifier: ToolIdentifier
    ) -> ToolDescriptor? {
        registeredTool(
            identifiedBy: identifier
        )?.modelFacingDescriptor
    }

    public func modelFacingDefinitions(
        for identifiers: [ToolIdentifier]
    ) throws -> [ToolDescriptor] {
        var seen:
            Set<ToolIdentifier> = []
        var definitions:
            [ToolDescriptor] = []

        for identifier in identifiers {
            guard seen.insert(
                identifier
            ).inserted else {
                continue
            }

            guard let definition =
                modelFacingDefinition(
                    identifiedBy: identifier
                )
            else {
                throw ToolRegistryError
                    .missingModelFacingTool(
                        identifier.rawValue
                    )
            }

            definitions.append(
                definition
            )
        }

        return definitions.sorted { lhs, rhs in
            lhs.name < rhs.name
        }
    }

    var registeredTools: [RegisteredTool] {
        tools.values.sorted { lhs, rhs in
            lhs.definition.identifier.rawValue
                < rhs.definition.identifier.rawValue
        }
    }

    public var isEmpty: Bool {
        tools.isEmpty
    }

    public var count: Int {
        tools.count
    }

    public mutating func register<T>(
        _ tool: T,
        modelContract: ToolModelContract? = nil
    ) throws where T: Tool {
        try register(
            RegisteredTool(
                tool,
                modelContract: modelContract
            )
        )
    }

    public mutating func register(
        _ registered: RegisteredTool
    ) throws {
        let identifier =
            registered.definition.identifier

        guard tools[identifier] == nil else {
            throw ToolRegistryError.duplicateTool(
                identifier.rawValue
            )
        }

        tools[identifier] = registered
    }

    public mutating func register(
        from provider: any AgentToolProvider
    ) throws {
        try provider.registerTools(
            into: &self
        )
    }

    public func registeredTool(
        identifiedBy identifier: ToolIdentifier
    ) -> RegisteredTool? {
        tools[identifier]
    }

    public func registeredTool(
        named name: String
    ) -> RegisteredTool? {
        registeredTool(
            identifiedBy:
                .init(
                    name
                )
        )
    }

    public func invocation(
        for call: ToolCall
    ) throws -> ToolInvocation {
        guard let registered =
            registeredTool(
                named: call.tool.rawValue
            )
        else {
            throw RegisteredToolError
                .invalidModelCall(
                    tool: call.tool.rawValue,
                    reason:
                        "No registered tool has this identifier."
                )
        }

        return try registered.invocation(
            for: call
        )
    }

    public func preflight(
        _ toolCall: ToolCall,
        workspace: WorkspaceContext? = nil
    ) async throws -> ToolPreflight {
        try await preflight(
            toolCall,
            context: .init(
                workspace: workspace
            )
        )
    }

    public func preflight(
        _ toolCall: ToolCall,
        context: ToolContext
    ) async throws -> ToolPreflight {
        guard let registered =
            registeredTool(
                named: toolCall.tool.rawValue
            )
        else {
            throw ToolRegistryExecutionError.missingTool(
                toolCall.tool.rawValue
            )
        }

        return try await registered.preflight(
            toolCall,
            context: context
        )
    }

    public func call(
        _ toolCall: ToolCall,
        workspace: WorkspaceContext?
    ) async throws -> ToolExecutionResult {
        try await execute(
            toolCall,
            workspace: workspace
        )
    }
}


