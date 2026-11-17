import Agentic
import Foundation
import Primitives
import Schema
import Macros

public extension Sessions.Tools {
    /// Finds text across recorded sessions, as `rg` would over their
    /// transcripts: each hit is a line with the session and message it is
    /// in, so `read_session_history` can open it there.
    @Tool("search_sessions")
    struct Search: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// Literal text to find.
            public let query: String?
            /// A regular expression to find, instead of query; `^` and `$` match at line ends.
            public let pattern: String?
            /// Search only this session. Omit to search all, most recent first.
            public let sessionID: String?
            /// Defaults to false.
            public let caseSensitive: Bool
            /// Also search tool calls and results, not only messages. Defaults to true.
            public let includeTools: Bool
            /// Defaults to 30 hits; at most 10 per session.
            public let limit: Int?

            public init(
                query: String? = nil,
                pattern: String? = nil,
                sessionID: String? = nil,
                caseSensitive: Bool = false,
                includeTools: Bool = true,
                limit: Int? = nil
            ) {
                self.query = query
                self.pattern = pattern
                self.sessionID = sessionID
                self.caseSensitive = caseSensitive
                self.includeTools = includeTools
                self.limit = limit
            }
        }

        @JSONSchema
        public struct Hit: Sendable, Codable, Hashable {
            public let sessionID: String
            public let sessionTitle: String?
            /// The transcript event's position and ID (a message ID for messages).
            public let eventIndex: Int
            public let eventID: String
            /// user, assistant, tool_call or tool_result.
            public let source: String
            public let line: Int
            public let text: String
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let hits: [Hit]
            public let searchedSessionCount: Int
            /// More hits exist than were returned.
            public let truncated: Bool
        }

        public static let purpose = "Search the transcripts of recorded sessions for text or a regular expression."
        public static let risk: ActionRisk = .observe
        static let maximumPerSession = 10
        static let maximumLineCharacters = 200

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            _ = try expression(for: input)
            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Search "
                    + (input.sessionID.map { "session \($0)" } ?? "recorded sessions")
                    + " for \(input.pattern.map { "/\($0)/" } ?? "\"\(input.query ?? "")\"").",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            let expression = try expression(for: input)
            let catalog = try context.require((any Sessions.CatalogReading).self)
            let sessions: [Sessions.Summary]
            if let sessionID = input.sessionID {
                sessions = [try await catalog.session(id: sessionID)]
            } else {
                sessions = try await catalog.sessions(statuses: [], includeArchived: true)
                    .sorted { $0.metadata.updatedAt > $1.metadata.updatedAt }
            }
            let limit = max(1, input.limit ?? 30)

            var hits: [Hit] = []
            var truncated = false
            for session in sessions {
                var found = 0
                let events = try await catalog.transcript(sessionID: session.metadata.sessionID)
                for (index, event) in events.enumerated() {
                    guard let (source, text) = Self.searchable(event, includeTools: input.includeTools) else {
                        continue
                    }
                    for (number, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                        let line = String(line)
                        let range = NSRange(line.startIndex..<line.endIndex, in: line)
                        guard expression.firstMatch(in: line, range: range) != nil else {
                            continue
                        }
                        guard hits.count < limit, found < Self.maximumPerSession else {
                            truncated = true
                            break
                        }
                        found += 1
                        hits.append(.init(
                            sessionID: session.metadata.sessionID,
                            sessionTitle: session.metadata.title,
                            eventIndex: index,
                            eventID: event.id,
                            source: source,
                            line: number + 1,
                            text: line.count > Self.maximumLineCharacters
                                ? line.prefix(Self.maximumLineCharacters) + "…"
                                : line
                        ))
                    }
                }
                if hits.count >= limit {
                    truncated = truncated || session.metadata.sessionID != sessions.last?.metadata.sessionID
                    break
                }
            }
            return .init(hits: hits, searchedSessionCount: sessions.count, truncated: truncated)
        }

        /// Hits grouped by session; each line names its event, as
        /// `read_session_history(fromMessageID:)` takes it.
        public func render(
            _ output: Output,
            input _: Input
        ) -> String? {
            var lines = [
                "\(output.hits.count) hit\(output.hits.count == 1 ? "" : "s") in \(output.searchedSessionCount) session\(output.searchedSessionCount == 1 ? "" : "s")"
                    + (output.truncated ? " (more exist: narrow with sessionID or a longer query)" : ""),
            ]
            var current: String?
            for hit in output.hits {
                if hit.sessionID != current {
                    current = hit.sessionID
                    lines.append("")
                    lines.append("session \(hit.sessionID)" + (hit.sessionTitle.map { "  \"\($0)\"" } ?? ""))
                }
                lines.append("  #\(hit.eventIndex) \(hit.source) \(hit.eventID):\(hit.line): \(hit.text)")
            }
            return lines.joined(separator: "\n")
        }

        private func expression(
            for input: Input
        ) throws -> NSRegularExpression {
            let source: String
            switch (input.query.flatMap { $0.isEmpty ? nil : $0 }, input.pattern.flatMap { $0.isEmpty ? nil : $0 }) {
            case (let query?, nil):
                source = NSRegularExpression.escapedPattern(for: query)
            case (nil, let pattern?):
                source = pattern
            default:
                throw Sessions.SearchError.query
            }
            do {
                return try NSRegularExpression(
                    pattern: source,
                    options: input.caseSensitive ? [] : [.caseInsensitive]
                )
            } catch {
                throw Sessions.SearchError.pattern(source)
            }
        }

        private static func searchable(
            _ event: TranscriptEvent,
            includeTools: Bool
        ) -> (source: String, text: String)? {
            switch event {
            case .message(let message):
                return (message.role.rawValue, message.content.text)
            case .call(let call) where includeTools:
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
                let input = (try? encoder.encode(call.input)).map { String(decoding: $0, as: UTF8.self) } ?? ""
                return ("tool_call", call.name + " " + input)
            case .result(let response) where includeTools:
                return ("tool_result", response.modelText)
            case .note(_, let text):
                return ("note", text)
            default:
                return nil
            }
        }
    }
}

public extension Sessions {
    enum SearchError: Error, Sendable, LocalizedError {
        case query
        case pattern(String)

        public var errorDescription: String? {
            switch self {
            case .query:
                "Give exactly one of query (literal text) or pattern (a regular expression)."
            case .pattern(let pattern):
                "'\(pattern)' is not a valid regular expression."
            }
        }
    }
}
