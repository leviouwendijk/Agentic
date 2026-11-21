import Agentic
import Foundation
import Primitives
import Schema
import Macros

/// Self-review over this session's durable log: every step every run took,
/// including failures, denials, skips and command output that never reached
/// the model's context. The host installs the session's log as a service
/// (`any Sessions.LogReading`).
public extension Sessions.Tools {
    @Tool("read_log")
    struct Log: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// Only these kinds; all when omitted.
            public let kinds: [Sessions.LogKind]?
            /// Only entries of this run.
            public let run: String?
            /// Only entries about this function call, e.g. one whose result
            /// was elided from context.
            public let call: String?
            /// Start after this sequence number.
            public let after: Int?
            /// Defaults to 50 entries.
            public let limit: Int?
            /// Read the most recent entries first.
            public let latestFirst: Bool

            public init(
                kinds: [Sessions.LogKind]? = nil,
                run: String? = nil,
                call: String? = nil,
                after: Int? = nil,
                limit: Int? = nil,
                latestFirst: Bool = false
            ) {
                self.kinds = kinds
                self.run = run
                self.call = call
                self.after = after
                self.limit = limit
                self.latestFirst = latestFirst
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let session: String
            public let totalEntryCount: Int
            public let lines: [Sessions.LogLine]
        }

        public static let purpose =
            "List the steps of this session's durable log: requests, messages, calls, responses, approvals, denials, skips, failures, command output. One line each; read a step in full with sessions_tool_read_step."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Read this session's log.",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            let log = try context.require((any Sessions.LogReading).self)
            let contents = try await log.lines()
            var lines = contents.lines.filter { line in
                (input.kinds.map { $0.contains(line.kind) } ?? true)
                    && (input.run.map { $0 == line.run } ?? true)
                    && (input.call.map { $0 == line.call } ?? true)
                    && (input.after.map { line.seq > $0 } ?? true)
            }
            if input.latestFirst {
                lines.reverse()
            }
            return .init(
                session: contents.session,
                totalEntryCount: contents.lines.count,
                lines: Array(lines.prefix(max(1, input.limit ?? 50)))
            )
        }
    }

    @Tool("read_step")
    struct Step: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// The step's sequence number from sessions_tool_read_log.
            public let seq: Int

            public init(seq: Int) {
                self.seq = seq
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let line: Sessions.LogLine
            /// The entry with its stored bodies filled in. A request lists
            /// its messages by id, role and digest; read one with
            /// sessions_tool_read_payload.
            public let detail: JSONValue
        }

        public static let purpose =
            "Read one step of this session's log in full: the exact input of a call, the full response, the event, or the composition of a model request."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Read step \(input.seq) of this session's log.",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            let log = try context.require((any Sessions.LogReading).self)
            guard let step = try await log.step(seq: input.seq) else {
                throw Sessions.LogError.stepNotFound(input.seq)
            }
            return .init(
                line: step.line,
                detail: step.detail
            )
        }
    }

    @Tool("read_payload")
    struct Payload: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// A digest named by sessions_tool_read_step.
            public let digest: String

            public init(digest: String) {
                self.digest = digest
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let digest: String
            public let value: JSONValue
        }

        public static let purpose =
            "Read a stored body of this session's log by its digest, e.g. one message of a recorded model request."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Read payload \(input.digest.prefix(12)) of this session's log.",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            let log = try context.require((any Sessions.LogReading).self)
            return .init(
                digest: input.digest,
                value: try await log.payload(digest: input.digest)
            )
        }
    }
}

public extension Sessions {
    enum LogError: Error, Sendable, Equatable, LocalizedError {
        case stepNotFound(Int)

        public var errorDescription: String? {
            switch self {
            case .stepNotFound(let seq):
                "No step \(seq) in this session's log."
            }
        }
    }
}
