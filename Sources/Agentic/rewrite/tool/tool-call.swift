import Foundation
import Macros
import Primitives
import Schema

@JSONSchema
public struct ToolCall:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let id: String
    public let tool: ToolIdentifier
    public let input: JSONValue

    public init(
        id: String,
        tool: ToolIdentifier,
        input: JSONValue
    ) {
        self.id = id
        self.tool = tool
        self.input = input
    }
}

extension ToolCall {
    // convenience: drops full input for purely reference purposes
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

        public init(
            _ call: ToolCall
        ) {
            self.init(
                id: call.id,
                tool: call.tool
            )
        }
    }

    public var reference: Reference {
        Reference(self)
    }
}

extension ToolCall {
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

extension ToolCall {
    public struct Failure:
        Sendable,
        Codable,
        Hashable
    {
        public let call: Reference
        public let phase: Phase
        public let message: String
        public let errorType: String
        public let incident: Recovery.Incident?

        public init(
            call: Reference,
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
            call: Reference,
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

extension ToolCall {
    public enum Reconciliation<Output>: Sendable
    where Output: Result
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

extension ToolCall {
    public struct ResultProjection:
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
