import Foundation
import Primitives

/// Canonical mechanical result of one tool execution operation.
///
/// `result` preserves the operation-facing tool contract. `failure` preserves
/// the exact durable tool-call failure when the terminal error result was produced
/// from one. `recovery` preserves mechanical recovery and reconciliation evidence
/// accumulated while executing the operation.
public enum ToolExecution {}

public extension ToolExecution {
    struct Result:
        Sendable,
        Codable,
        Hashable
    {
        public var result: ToolExecution.Response
        public var observations: [ToolResultObservation]
        public var failure: ToolExecution.Failure?
        public var recovery: Recovery.Record?

        public init(
            result: ToolExecution.Response,
            observations: [ToolResultObservation] = [],
            failure: ToolExecution.Failure? = nil,
            recovery: Recovery.Record? = nil
        ) {
            self.result = result
            self.observations = observations
            self.failure = failure
            self.recovery = recovery
        }

        private enum CodingKeys: String, CodingKey {
            case result, observations, failure, recovery
        }

        public init(from decoder: any Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            self.init(
                result: try values.decode(ToolExecution.Response.self, forKey: .result),
                observations: try values.decodeIfPresent([ToolResultObservation].self, forKey: .observations) ?? [],
                failure: try values.decodeIfPresent(ToolExecution.Failure.self, forKey: .failure),
                recovery: try values.decodeIfPresent(Recovery.Record.self, forKey: .recovery)
            )
        }
    }

}

extension ToolExecution {
    public enum Phase:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case decode
        case preflight
        case call
        case process
        case encode
    }
}

extension ToolExecution {
    public struct Failure:
        Sendable,
        Codable,
        Hashable
    {
        public let call: ToolExecution.Reference
        public let phase: Phase
        public let message: String
        public let errorType: String
        public let incident: Recovery.Incident?

        public init(
            call: ToolExecution.Reference,
            phase: Phase,
            message: String,
            errorType: String,
            incident: Recovery.Incident? = nil
        ) {
            self.call = call
            self.phase = phase
            self.message = message
            self.errorType = errorType
            self.incident = incident
        }
    }

    public struct Error:
        Swift.Error,
        Sendable,
        LocalizedError
    {
        public let failure: Failure

        public init(
            failure: Failure
        ) {
            self.failure = failure
        }

        public init(
            call: ToolExecution.Reference,
            phase: Phase,
            underlying error: any Swift.Error,
            incident: Recovery.Incident? = nil
        ) {
            self.init(
                failure: .init(
                    call: call,
                    phase: phase,
                    message: Self.message(
                        for: error
                    ),
                    errorType: String(
                        reflecting: type(
                            of: error
                        )
                    ),
                    incident: incident
                )
            )
        }

        public var errorDescription: String? {
            "Tool '\(failure.call.tool.rawValue)' failed during \(failure.phase.rawValue) for call '\(failure.call.id)': \(failure.message)"
        }

        private static func message(
            for error: any Swift.Error
        ) -> String {
            if let localized = error as? any LocalizedError,
               let description = localized.errorDescription
            {
                return description
            }

            return String(
                describing: error
            )
        }
    }
}

extension ToolExecution {
    public enum Reconciliation<Output>: Sendable
    // Agentic's semantic Result, not ToolExecution.Result.
    where Output: Contract.Result
    {
        case applied(Output)
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
}

extension ToolExecution {
    public struct Projection:
        Sendable,
        Codable,
        Hashable
    {
        public let status: String
        public let summary: String?
        public let facts: [Fact]

        public init(
            status: String,
            summary: String? = nil,
            facts: [Fact] = []
        ) {
            self.status = status
            self.summary = summary
            self.facts = facts
        }

        public struct Fact:
            Sendable,
            Codable,
            Hashable
        {
            public let label: String
            public let value: String

            public init(
                label: String,
                value: String
            ) {
                self.label = label
                self.value = value
            }
        }
    }
}

extension ToolExecution {
    /// Identity of one tool call without its payload.
    public struct Reference:
        Sendable,
        Codable,
        Hashable,
        Identifiable
    {
        public let id: String
        public let tool: ToolIdentifier

        public init(
            id: String,
            tool: ToolIdentifier
        ) {
            self.id = id
            self.tool = tool
        }
    }
}

/// What the caller (and the model) sees of one tool execution.
public extension ToolExecution {
    struct Response:
        Sendable,
        Codable,
        Hashable
    {
        public let call: ToolExecution.Reference
        public let output: JSONValue
        public let projection: ToolExecution.Projection?
        public let isError: Bool

        public init(
            call: ToolExecution.Reference,
            output: JSONValue,
            projection: ToolExecution.Projection? = nil,
            isError: Bool = false
        ) {
            self.call = call
            self.output = output
            self.projection = projection
            self.isError = isError
        }
    }
}


