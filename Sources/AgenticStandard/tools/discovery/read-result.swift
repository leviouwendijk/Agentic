import Agentic
import Macros
import Primitives
import Schema

public enum ReadResultError: Error, Sendable {
    case notRecorded(String)
    case archiveUnavailable
}

public extension Standard.Tools {
    /// Reads a result the model was shown only in part, by line, from the
    /// session's record.
    @Tool
    struct ReadResult: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// The call whose result to read, as named in the shortened result.
            public let call: String
            /// First line to read, from 1. Defaults to 1.
            public let offset: Int?
            /// Lines to read. Defaults to 200.
            public let limit: Int?

            public init(call: String, offset: Int? = nil, limit: Int? = nil) {
                self.call = call
                self.offset = offset
                self.limit = limit
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let call: String
            /// First line returned, from 1.
            public let from: Int
            /// Last line returned.
            public let to: Int
            public let total: Int
            public let text: String

            public init(call: String, from: Int, to: Int, total: Int, text: String) {
                self.call = call
                self.from = from
                self.to = to
                self.total = total
                self.text = text
            }
        }

        public static let purpose =
            "Read the rest of a result that was shown only in part, by line; the shortened result names the call and where to continue."
        public static let risk: ActionRisk = .observe
        public static let defaultLimit = 200

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            guard let archive = try? context.require(ResultArchive.self) else {
                throw ReadResultError.archiveUnavailable
            }
            guard let response = try await archive.response(call: input.call) else {
                throw ReadResultError.notRecorded(input.call)
            }
            let lines = ResultLines.lines(of: response.modelText)
            let from = min(max(1, input.offset ?? 1), max(1, lines.count))
            let to = min(lines.count, from - 1 + max(1, input.limit ?? Self.defaultLimit))
            return Output(
                call: input.call,
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
            return output.text + "\n[Lines \(output.from)–\(output.to) of \(output.total). "
                + "read_result {\"call\": \"\(output.call)\", \"offset\": \(output.to + 1)} continues.]"
        }
    }
}
