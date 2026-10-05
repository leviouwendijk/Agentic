import Foundation
import Workspace

public enum ToolRegistryExecutionError: Error, Sendable, LocalizedError {
    case missingTool(String)

    public var errorDescription: String? {
        switch self {
        case .missingTool(let name):
            return "No tool is registered with name '\(name)'."
        }
    }
}

public extension ToolRegistry {
    func execute(
        _ call: ToolCall,
        workspace: WorkspaceContext? = nil
    ) async throws -> ToolExecutionResult {
        try await execute(
            call,
            context: .init(
                workspace: workspace
            )
        )
    }

    func execute(
        _ call: ToolCall,
        context: ToolContext
    ) async throws -> ToolExecutionResult {
        guard let registered =
            registeredTool(
                identifiedBy: call.tool
            )
        else {
            throw ToolRegistryExecutionError.missingTool(
                call.tool.rawValue
            )
        }

        return try await registered.execute(
            call,
            context: context
        )
    }

    func reconcile(
        _ call: ToolCall,
        failure: ToolCall.Failure,
        context: ToolContext
    ) async throws -> RegisteredAgentTool.Reconciliation? {
        guard let registered =
            registeredTool(
                identifiedBy: call.tool
            )
        else {
            throw ToolRegistryExecutionError.missingTool(
                call.tool.rawValue
            )
        }

        return try await registered.reconcile(
            call,
            failure: failure,
            context: context
        )
    }
}
