import Foundation
import Primitives
import Schema
import Workspace

/// Registry-facing executable representation of one canonical typed Tool.
///
/// Registration captures every operation that requires the concrete
/// Self/Input/Output types. The registry never needs to reopen a Tool
/// existential afterward.
public struct ToolBinding: CapabilityBinding {
    public var reference: CapabilityReference {
        .tool(definition.identifier)
    }
    public enum Reconciliation: Sendable {
        case applied(ToolExecution.Result)
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
            projection: ToolExecution.Projection?
        )
        case applied_without_output
        case not_applied
        case unknown
    }

    public let definition: ToolDefinition
    /// Always retains the typed contract, even for a host-only Tool.
    public let contract: CapabilityContract
    public let modelContract: ToolModelContract
    /// Optional DSL/inventory grouping; never changes executable Tool behavior.
    public private(set) var collection: AgentToolCollectionMetadata?

    public var semanticInputSchema: JSONSchema? {
        modelContract.semanticInputSchema
    }

    public var isModelFacing: Bool {
        modelContract.isModelFacing
    }

    /// Final model-facing `{ arguments, execution? }` envelope schema.
    ///
    /// This is the schema advertised to the model surface, distinct from the
    /// authored semantic `T.Input` schema. The host may consume this directly
    /// instead of reconstructing the model envelope from semantic input or
    /// re-deriving it from a lowered `ToolDescriptor.input`.
    public var modelFacingInputSchema: JSONSchema? {
        modelContract.modelFacingInputSchema
    }

    public var modelFacingDescriptor: ToolDescriptor? {
        guard let inputSchema = modelContract.modelFacingInputSchema else {
            return nil
        }

        return ToolDescriptor(
            identifier: definition.identifier,
            description: definition.purpose,
            input: inputSchema.jsonvalue,
            risk: definition.risk
        )
    }
    private let preparationHandler:
        @Sendable (
            ToolInvocation,
            ToolContext
        ) async throws -> CapabilityPreparation<ToolPreflight>

    private let callHandler:
        @Sendable (
            ToolInvocation,
            PreparedOperation.Envelope?,
            ToolContext
        ) async throws -> (
            output: JSONValue,
            projection: ToolExecution.Projection?,
            isError: Bool,
            text: String?
        )

    private let reconcileHandler:
        @Sendable (
            ToolInvocation,
            ToolExecution.Failure,
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
        self.contract = T.contract
        self.modelContract = resolvedModelContract
        self.collection = nil

        self.preparationHandler = { call, context in
            let input: T.Input

            do {
                input = try call.arguments.decode(
                    T.Input.self
                )
            } catch {
                throw phasedToolError(
                    tool: tool,
                    call: call,
                    phase: .decode,
                    error: error
                )
            }

            let preparation: CapabilityPreparation<ToolPreflight>

            do {
                preparation = try await tool.prepare(
                    input,
                    in: context
                )
            } catch {
                throw phasedToolError(
                    tool: tool,
                    call: call,
                    phase: .preflight,
                    input: input,
                    error: error
                )
            }

            return preparation
        }

        self.callHandler = { call, preparedOperation, context in
            let input: T.Input

            do {
                input = try call.arguments.decode(
                    T.Input.self
                )
            } catch {
                throw phasedToolError(
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
                    prepared: preparedOperation,
                    in: context
                )
                isError = false
            } catch let failure as AgentToolReportedFailure<T.Output> {
                output = failure.output
                isError = true
            } catch {
                throw phasedToolError(
                    tool: tool,
                    call: call,
                    phase: .call,
                    input: input,
                    error: error
                )
            }

            let projection: ToolExecution.Projection?

            do {
                projection = try tool.process(
                    output,
                    input: input
                )
            } catch {
                throw phasedToolError(
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
                throw phasedToolError(
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
                isError: isError,
                text: tool.render(
                    output,
                    input: input
                )
            )
        }

        self.reconcileHandler = { call, failure, context in
            let input: T.Input

            do {
                input = try call.arguments.decode(
                    T.Input.self
                )
            } catch {
                throw phasedToolError(
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
                let projection: ToolExecution.Projection?

                do {
                    projection = try tool.process(
                        output,
                        input: input
                    )
                } catch {
                    throw phasedToolError(
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
                    throw phasedToolError(
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

    /// Returns an independently grouped copy for declarative tool inventories.
    /// Does not alter the binding's executable contract.
    public func assigning(
        collection: AgentToolCollectionMetadata
    ) -> Self {
        var binding = self
        binding.collection = collection
        return binding
    }

    /// Parse one model function call into its canonical invocation.
    ///
    /// This layer parses only the framework-owned invocation envelope. Semantic
    /// Tool arguments remain JSONValue until the registered typed Tool boundary.
    public func invocation(
        for call: FunctionCall
    ) throws -> ToolInvocation {
        guard isModelFacing else {
            throw ToolBindingError.hostOnly(
                definition.identifier.rawValue
            )
        }

        let components = try modelInvocationComponents(
            for: call.input
        )

        return ToolInvocation(
            id: call.id,
            tool: ToolIdentifier(call.name),
            arguments: components.arguments,
            execution: components.execution
        )
    }

    private func modelInvocationComponents(
        for input: JSONValue
    ) throws -> (
        arguments: JSONValue,
        execution: ToolInvocation.Target?
    ) {
        let object = try input.objectValue
        let unexpected = object.keys
            .filter { $0 != "arguments" && $0 != "execution" }
            .sorted()

        guard unexpected.isEmpty else {
            throw ToolBindingError.invalidModelCall(
                tool: definition.identifier.rawValue,
                reason: "Unexpected outer envelope field(s): \(unexpected.joined(separator: ", ")). Put semantic fields inside 'arguments'."
            )
        }

        guard let arguments = object["arguments"] else {
            throw ToolBindingError.invalidModelCall(
                tool: definition.identifier.rawValue,
                reason: "Model call is missing required 'arguments'."
            )
        }

        if case .object(let fields) = arguments {
            let declared: [String: JSONValue]
            if let schema = semanticInputSchema?.jsonvalue,
               case .object(let schemaFields) = schema,
               let properties = schemaFields["properties"],
               case .object(let semanticProperties) = properties {
                declared = semanticProperties
            } else {
                declared = [:]
            }

            if declared["execution"] == nil,
               let nested = fields["execution"],
               case .object(let nestedFields) = nested,
               nestedFields["workspace"] != nil {
                throw ToolBindingError.invalidModelCall(
                    tool: definition.identifier.rawValue,
                    reason: "Misplaced arguments.execution.workspace. Put 'execution' beside 'arguments', not inside it."
                )
            }

            if declared["arguments"] == nil,
               let nested = fields["arguments"],
               case .object = nested,
               fields.keys.allSatisfy({ $0 == "arguments" || $0 == "execution" }) {
                throw ToolBindingError.invalidModelCall(
                    tool: definition.identifier.rawValue,
                    reason: "Misplaced arguments.arguments. Put semantic input fields directly inside the outer 'arguments'."
                )
            }
        }

        let execution = try object["execution"]?.decode(
            ToolInvocation.Target.self
        )

        return (
            arguments: arguments,
            execution: execution
        )
    }

    public func preflight(
        _ call: ToolInvocation,
        workspace: WorkspaceContext? = nil
    ) async throws -> ToolPreflight {
        try await preflight(
            call,
            context: .init(
                workspace: workspace
            )
        )
    }

    public func prepare(
        _ call: ToolInvocation,
        context: ToolContext
    ) async throws -> CapabilityPreparation<ToolPreflight> {
        try await preparationHandler(call, context)
    }

    public func preflight(
        _ call: ToolInvocation,
        context: ToolContext
    ) async throws -> ToolPreflight {
        try await prepare(call, context: context).review
    }

    public func execute(
        _ call: ToolInvocation,
        workspace: WorkspaceContext? = nil
    ) async throws -> ToolExecution.Result {
        try await execute(
            call,
            context: .init(
                workspace: workspace
            )
        )
    }

    public func execute(
        _ call: ToolInvocation,
        context: ToolContext,
        preparedOperation: PreparedOperation.Envelope? = nil
    ) async throws -> ToolExecution.Result {
        let (value, observations) = try await ToolExecutionObservations.capture(call: call.reference) {
            try await executeObserved(
                call,
                context: context,
                preparedOperation: preparedOperation
            )
        }
        var result = value
        result.observations = observations
        return result
    }

    private func executeObserved(
        _ call: ToolInvocation,
        context: ToolContext,
        preparedOperation: PreparedOperation.Envelope?
    ) async throws -> ToolExecution.Result {
        let execution = try await callHandler(
            call,
            preparedOperation,
            context
        )

        return ToolExecution.Result(
            result: FunctionCall.Response(
                call: .init(call.reference),
                output: execution.output,
                projection: execution.projection,
                isError: execution.isError,
                text: execution.text
            )
        )
    }

    public func reconcile(
        _ call: ToolInvocation,
        failure: ToolExecution.Failure,
        context: ToolContext
    ) async throws -> Reconciliation? {
        let (value, observations) = try await ToolExecutionObservations.capture(
            call: call.reference,
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
        _ call: ToolInvocation,
        failure: ToolExecution.Failure,
        context: ToolContext
    ) async throws -> Reconciliation? {
        guard
            failure.call.tool == definition.identifier,
            failure.call.id == call.id,
            failure.phase == .call
        else {
            throw ToolBindingError.invalidFailure(
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
                ToolExecution.Result(
                    result: FunctionCall.Response(
                        call: .init(call.reference),
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


public enum ToolBindingError:
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

private func phasedToolError<T: Tool>(
    tool: T,
    call: ToolInvocation,
    phase: ToolExecution.Phase,
    input: T.Input? = nil,
    error: any Error
) -> ToolExecution.Error {
    if let error = error as? ToolExecution.Error {
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

    return ToolExecution.Error(
        call: .init(
            id: call.id,
            tool: T.definition.identifier
        ),
        phase: phase,
        underlying: error,
        incident: incident
    )
}