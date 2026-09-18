import Primitives
import Schema
import Workspace
import Foundation
import AgenticRecovery

public struct ToolIdentifier: StringIdentifier {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public struct ToolDefinition:
    Definition,
    Codable,
    Hashable,
    Identifiable
{
    public let identifier: ToolIdentifier
    public let purpose: String
    public let risk: ActionRisk

    public init(
        identifier: ToolIdentifier,
        purpose: String,
        risk: ActionRisk = .observe
    ) {
        self.identifier = identifier
        self.purpose = purpose
        self.risk = risk
    }

    public var id: ToolIdentifier {
        identifier
    }
}

public protocol ToolInput: 
    Sendable 
    & Decodable 
    & JSONSchemaProviding 
{}
    // var repository: String? { get }
// }

// extension ToolInput {
//     var repository: String? {
//         nil
//     }
// }

public protocol ToolOutput: 
    Sendable 
    & Encodable 
{}

// public protocol ToolEnvironment: 
//     Sendable 
// {}

// -------------------------------

public protocol ToolContract: Sendable {
    associatedtype Input: ToolInput
    associatedtype Output: ToolOutput
}

public protocol ToolRecovery: ToolContract {
    func classify(
        _ error: any Error,
        phase: ToolCall.Phase,
        input: Input?
    ) -> Recovery.Incident?

    func reconcile(
        _ input: Input,
        after failure: ToolCall.Failure,
        workspace: WorkspaceContext?
    ) async throws -> ToolCall.Reconciliation<Output>?
}

public protocol ToolProjection: ToolContract {
    func process(
        _ output: Output,
        input: Input
    ) throws -> ToolCall.ResultProjection?
}

public protocol Tool:
    ToolContract,
    ToolRecovery,
    ToolProjection
{
    typealias Arguments = ToolInput
    typealias Result = ToolOutput

    // REMOVED: Input and Output are canonically owned by ToolContract.
    // associatedtype Input: Arguments
    // associatedtype Output: Result

    // REMOVED: arbitrary per-tool environments recreate the generic construction problem.
    // associatedtype Environment: Sendable

    static var definition: ToolDefinition { get }

    func preflight(
        _ input: Input,
        workspace: WorkspaceContext?
    ) async throws -> ToolPreflight

    func call(
        _ input: Input,
        workspace: WorkspaceContext?
    ) async throws -> Output
}

// Defaults:

public extension Tool {
    func preflight(
        _ input: Input,
        workspace: WorkspaceContext?
    ) async throws -> ToolPreflight {
        _ = input
        _ = workspace

        return ToolPreflight(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary: Self.definition.purpose,
            sideEffects: Self.definition.risk.defaultSideEffects
        )
    }
}

public extension ToolRecovery {
    func classify(
        _ error: any Error,
        phase: ToolCall.Phase,
        input: Input?
    ) -> Recovery.Incident? {
        nil
    }

    func reconcile(
        _ input: Input,
        after failure: ToolCall.Failure,
        workspace: WorkspaceContext?
    ) async throws -> ToolCall.Reconciliation<Output>? {
        nil
    }
}

public extension ToolProjection {
    func process(
        _ output: Output,
        input: Input
    ) throws -> ToolCall.ResultProjection? {
        nil
    }
}
