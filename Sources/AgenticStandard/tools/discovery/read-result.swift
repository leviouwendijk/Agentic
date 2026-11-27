import Agentic
import Macros
import Primitives
import Schema

public enum ReadResultError: Error, Sendable {
    case notRecorded(String)
    case archiveUnavailable
    /// The call's result has no such segment; the ones it has.
    case noSegment(String, available: [String])
}

public extension Standard.Tools {
    /// Reads a result by line from the session's record: what the model was
    /// shown, or one segment of the full output.
    @Tool
    struct ReadResult: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// The call whose result to read, as named in the shortened result.
            public let call: String
            /// A segment of the full output, as standard_tool_search_results names it (stdout, stderr, …). Defaults to what you were shown.
            public let segment: String?
            /// First line to read, from 1. Defaults to 1.
            public let offset: Int?
            /// Lines to read. Defaults to 200.
            public let limit: Int?

            public init(call: String, segment: String? = nil, offset: Int? = nil, limit: Int? = nil) {
                self.call = call
                self.segment = segment
                self.offset = offset
                self.limit = limit
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let call: String
            public let segment: String?
            /// First line returned, from 1.
            public let from: Int
            /// Last line returned.
            public let to: Int
            public let total: Int
            public let text: String

            public init(call: String, segment: String? = nil, from: Int, to: Int, total: Int, text: String) {
                self.call = call
                self.segment = segment
                self.from = from
                self.to = to
                self.total = total
                self.text = text
            }
        }

        public static let purpose =
            "Read a result by line: the rest of one shown only in part (the shortened result names the call and where to continue), or a segment of its full output (standard_tool_search_results names them)."
        public static let risk: ActionRisk = .observe
        public static let defaultLimit = 200

        public init() {}

        public func call(_ input: Input, in context: CapabilityContext) async throws -> Output {
            guard let archive = try? context.require(ResultArchive.self) else {
                throw ReadResultError.archiveUnavailable
            }
            guard let response = try await archive.response(call: input.call) else {
                throw ReadResultError.notRecorded(input.call)
            }
            let lines: [Substring]
            if let name = input.segment {
                let recorded = RecordedOutput(response)
                guard let segment = recorded.segment(named: name) else {
                    throw ReadResultError.noSegment(name, available: recorded.segments.map(\.name))
                }
                lines = segment.elements.map { Substring($0.text) }
            } else {
                lines = ResultLines.lines(of: response.modelText)
            }
            let from = min(max(1, input.offset ?? 1), max(1, lines.count))
            let to = min(lines.count, from - 1 + max(1, input.limit ?? Self.defaultLimit))
            return Output(
                call: input.call,
                segment: input.segment,
                from: from,
                to: to,
                total: lines.count,
                text: lines[(from - 1)..<to].joined(separator: "\n")
            )
        }

        public func render(_ output: Output, input: Input) -> String? {
            guard output.to < output.total else {
                return output.text
            }
            let segment = output.segment.map { ", \"segment\": \"\($0)\"" } ?? ""
            return output.text + "\n[Lines \(output.from)–\(output.to) of \(output.total). "
                + "standard_tool_read_result {\"call\": \"\(output.call)\"\(segment), \"offset\": \(output.to + 1)} continues.]"
        }
    }
}
