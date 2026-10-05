import Foundation
import Primitives
import Schema
import Workspace

/// Registry-facing executable representation of one canonical typed Tool.
///
/// Registration captures every operation that requires the concrete
/// Self/Input/Output types. The registry never needs to reopen a Tool
/// existential afterward.
public struct RegisteredTool: Sendable {
    public enum Reconciliation: Sendable {
        case applied(ToolExecutionResult)
        case applied_without_output
        case not_applied
        case unknown

        public var state: Recovery.State {
            switch self {
            case .applied,
                 .applied_without_output:
                .init(
                    reconciled: .applied
                )

            case .not_applied:
                .init(
                    reconciled: .not_applied
                )

            case .unknown:
                .init(
                    reconciled: .unknown
                )
            }
        }
    }

    private enum ReconciliationExecution: Sendable {
        case applied(
            output: JSONValue,
            projection: ToolCall.ResultProjection?
        )
        case applied_without_output
        case not_applied
        case unknown
    }

    public let definition: ToolDefinition
    public let modelContract: ToolModelContract

    public var semanticInputSchema: JSONSchema? {
        modelContract.semanticInputSchema
    }

    public var isModelFacing: Bool {
        modelContract.isModelFacing
    }

    public var modelFacingDescriptor: ToolDescriptor? {
        guard let inputSchema = modelContract.modelFacingInputSchema else {
            return nil
        }

        return ToolDescriptor(
            identifier: definition.identifier,
            description: definition.purpose,
            inputSchema: inputSchema.jsonvalue,
            risk: definition.risk
        )
    }
    private let preflightHandler:
        @Sendable (
            ToolCall,
            ToolContext
        ) async throws -> ToolPreflight

    private let callHandler:
        @Sendable (
            ToolCall,
            ToolContext
        ) async throws -> (
            output: JSONValue,
            projection: ToolCall.ResultProjection?,
            isError: Bool
        )

    private let reconcileHandler:
        @Sendable (
            ToolCall,
            ToolCall.Failure,
            ToolContext
        ) async throws -> ReconciliationExecution?

    public init<T>(
        _ tool: T,
        modelContract: ToolModelContract? = nil
    ) where T: Tool {
        let semanticInputSchema = T.Input.jsonschema
        let resolvedModelContract =
            modelContract
                ?? .modelFacing(
                    inputSchema: semanticInputSchema
                )

        self.definition = T.definition
        self.modelContract = resolvedModelContract

        self.preflightHandler = { call, context in
            let input: T.Input

            do {
                input = try call.input.decode(
                    T.Input.self
                )
            } catch {
                throw phasedToolCallError(
                    tool: tool,
                    call: call,
                    phase: .decode,
                    error: error
                )
            }

            let preflight: ToolPreflight

            do {
                preflight = try await tool.preflight(
                    input,
                    in: context
                )
            } catch {
                throw phasedToolCallError(
                    tool: tool,
                    call: call,
                    phase: .preflight,
                    input: input,
                    error: error
                )
            }

            return preflight
        }

        self.callHandler = { call, context in
            let input: T.Input

            do {
                input = try call.input.decode(
                    T.Input.self
                )
            } catch {
                throw phasedToolCallError(
                    tool: tool,
                    call: call,
                    phase: .decode,
                    error: error
                )
            }

            let output: T.Output
            let isError: Bool

            do {
                output = try await tool.call(
                    input,
                    in: context
                )
                isError = false
            } catch let failure as AgentToolReportedFailure<T.Output> {
                output = failure.output
                isError = true
            } catch {
                throw phasedToolCallError(
                    tool: tool,
                    call: call,
                    phase: .call,
                    input: input,
                    error: error
                )
            }

            let projection: ToolCall.ResultProjection?

            do {
                projection = try tool.process(
                    output,
                    input: input
                )
            } catch {
                throw phasedToolCallError(
                    tool: tool,
                    call: call,
                    phase: .process,
                    input: input,
                    error: error
                )
            }

            let encodedOutput: JSONValue

            do {
                encodedOutput = try JSONValue.encoding(
                    output
                )
            } catch {
                throw phasedToolCallError(
                    tool: tool,
                    call: call,
                    phase: .encode,
                    input: input,
                    error: error
                )
            }

            return (
                output: encodedOutput,
                projection: projection,
                isError: isError
            )
        }

        self.reconcileHandler = { call, failure, context in
            let input: T.Input

            do {
                input = try call.input.decode(
                    T.Input.self
                )
            } catch {
                throw phasedToolCallError(
                    tool: tool,
                    call: call,
                    phase: .decode,
                    error: error
                )
            }

            guard let reconciliation = try await tool.reconcile(
                input,
                after: failure,
                in: context
            ) else {
                return nil
            }

            switch reconciliation {
            case .applied(let output):
                let projection: ToolCall.ResultProjection?

                do {
                    projection = try tool.process(
                        output,
                        input: input
                    )
                } catch {
                    throw phasedToolCallError(
                        tool: tool,
                        call: call,
                        phase: .process,
                        input: input,
                            error: error
                    )
                }

                let encodedOutput: JSONValue

                do {
                    encodedOutput = try JSONValue.encoding(
                        output
                    )
                } catch {
                    throw phasedToolCallError(
                        tool: tool,
                        call: call,
                        phase: .encode,
                        input: input,
                            error: error
                    )
                }

                return .applied(
                    output: encodedOutput,
                    projection: projection
                )

            case .applied_without_output:
                return .applied_without_output

            case .not_applied:
                return .not_applied

            case .unknown:
                return .unknown
            }
        }
    }

    /// Parse one raw model/provider ToolCall into its canonical invocation.
    ///
    /// This layer parses only the framework-owned invocation envelope. Semantic
    /// Tool arguments remain JSONValue until the registered typed Tool boundary.
    public func invocation(
        for call: ToolCall
    ) throws -> ToolInvocation {
        guard isModelFacing else {
            throw RegisteredToolError.hostOnly(
                definition.identifier.rawValue
            )
        }

        let components = try modelInvocationComponents(
            for: call.input
        )

        return ToolInvocation(
            id: call.id,
            tool: call.tool,
            arguments: components.arguments,
            execution: components.execution
        )
    }

    private func modelInvocationComponents(
        for input: JSONValue
    ) throws -> (
        arguments: JSONValue,
        execution: ToolInvocation.Execution?
    ) {
        let object = try input.objectValue

        guard let arguments = object["arguments"] else {
            throw RegisteredToolError.invalidModelCall(
                tool: definition.identifier.rawValue,
                reason: "Model call is missing required 'arguments'."
            )
        }

        let execution = try object["execution"]?.decode(
            ToolInvocation.Execution.self
        )

        return (
            arguments: arguments,
            execution: execution
        )
    }

    public func preflight(
        _ call: ToolCall,
        workspace: WorkspaceContext? = nil
    ) async throws -> ToolPreflight {
        try await preflight(
            call,
            context: .init(
                workspace: workspace
            )
        )
    }

    public func preflight(
        _ call: ToolCall,
        context: ToolContext
    ) async throws -> ToolPreflight {
        try await preflightHandler(
            call,
            context
        )
    }

    public func execute(
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

    public func execute(
        _ call: ToolCall,
        context: ToolContext
    ) async throws -> ToolExecutionResult {
        let (value, observations) = try await ToolExecutionObservations.capture(callID: call.id) {
            try await executeObserved(
                call,
                context: context
            )
        }
        var result = value
        result.observations = observations
        return result
    }

    private func executeObserved(
        _ call: ToolCall,
        context: ToolContext
    ) async throws -> ToolExecutionResult {
        let execution = try await callHandler(
            call,
            context
        )

        return ToolExecutionResult(
            result: ToolResult(
                toolCallID: call.id,
                tool: definition.identifier,
                output: execution.output,
                projection: execution.projection,
                isError: execution.isError
            )
        )
    }

    public func reconcile(
        _ call: ToolCall,
        failure: ToolCall.Failure,
        context: ToolContext
    ) async throws -> Reconciliation? {
        let (value, observations) = try await ToolExecutionObservations.capture(
            callID: call.id,
            kind: .reconcile
        ) {
            try await reconcileObserved(
                call,
                failure: failure,
                context: context
            )
        }
        if case .some(.applied(var result)) = value {
            result.observations = observations
            return .applied(result)
        }
        return value
    }

    private func reconcileObserved(
        _ call: ToolCall,
        failure: ToolCall.Failure,
        context: ToolContext
    ) async throws -> Reconciliation? {
        guard
            failure.tool == definition.identifier,
            failure.toolCallID == call.id,
            failure.phase == .call
        else {
            throw RegisteredToolError.invalidFailure(
                tool: definition.identifier.rawValue,
                callID: call.id
            )
        }

        guard let reconciliation = try await reconcileHandler(
            call,
            failure,
            context
        ) else {
            return nil
        }

        switch reconciliation {
        case .applied(let output, let projection):
            return .applied(
                ToolExecutionResult(
                    result: ToolResult(
                        toolCallID: call.id,
                        tool: definition.identifier,
                        output: output,
                        projection: projection,
                        isError: false
                    )
                )
            )

        case .applied_without_output:
            return .applied_without_output

        case .not_applied:
            return .not_applied

        case .unknown:
            return .unknown
        }
    }
}


public enum RegisteredToolError:
    Error,
    Sendable,
    LocalizedError
{
    case hostOnly(String)

    case invalidModelCall(
        tool: String,
        reason: String
    )

    case invalidFailure(
        tool: String,
        callID: String
    )

    public var errorDescription: String? {
        switch self {
        case .hostOnly(let tool):
            "Registered tool '\(tool)' is host-only and cannot be invoked by a model."

        case .invalidModelCall(
            let tool,
            let reason
        ):
            "Cannot parse model input for registered tool '\(tool)': \(reason)"

        case .invalidFailure(
            let tool,
            let callID
        ):
            "Cannot reconcile tool '\(tool)' for call '\(callID)' from an unrelated or non-call failure."
        }
    }
}

private func recoveryIncidentCapturingEvidence(
    _ incident: Recovery.Incident,
    error: any Error
) -> Recovery.Incident {
    guard incident.report == nil else {
        return incident
    }

    return Recovery.Incident(
        capturing: error,
        kind: incident.kind,
        stage: incident.stage,
        effectState: incident.effectState,
        retrySafety: incident.retrySafety,
        scope: incident.scope,
        message: incident.message,
        metadata: incident.metadata
    )
}

private func phasedToolCallError<T: Tool>(
    tool: T,
    call: ToolCall,
    phase: ToolCall.Phase,
    input: T.Input? = nil,
    error: any Error
) -> ToolCall.Error {
    if let error = error as? ToolCall.Error {
        return error
    }

    let classifiedIncident = tool.classify(
        error,
        phase: phase,
        input: input
    )
    let incident = classifiedIncident.map {
        recoveryIncidentCapturingEvidence(
            $0,
            error: error
        )
    }

    return ToolCall.Error(
        tool: T.definition.identifier,
        toolCallID: call.id,
        phase: phase,
        underlying: error,
        incident: incident
    )
}