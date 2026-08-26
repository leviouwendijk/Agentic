import Foundation
import Primitives

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
        _ call: AgentToolCall,
        context: AgentToolExecutionContext
    ) async throws -> AgentToolResult {
        guard let tool = tool(
            named: call.name
        ) else {
            throw ToolRegistryExecutionError.missingTool(
                call.name
            )
        }

        let output = try await tool.call(
            input: call.input,
            context: context.withToolCallID(
                call.id
            )
        )

        let processing = tool.processResult(
            input: call.input,
            output: output,
            workspace: context.workspace
        )

        let resolvedProcessing: AgentToolResultProcessing?
        let receipt: AgentToolReceipt?

        if processing.isEmpty {
            receipt = tool.receipt(
                input: call.input,
                output: output,
                workspace: context.workspace
            )

            resolvedProcessing = receipt.map { receipt in
                .init(
                    projection: .init(
                        receipt
                    )
                )
            }
        } else {
            resolvedProcessing = processing

            receipt = processing.projection.map { projection in
                AgentToolReceipt(
                    projection
                )
            }
        }

        return .init(
            toolCallID: call.id,
            name: call.name,
            output: output,
            processing: resolvedProcessing,
            receipt: receipt
        )
    }
}
