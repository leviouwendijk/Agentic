import Agentic
import Foundation
import Macros
import Matching
import Primitives
import Schema
import Search

public enum SearchResultsError: Error, Sendable {
    case archiveUnavailable
    case noTerms
}

public extension Standard.Tools {
    /// Searches what earlier calls returned, from the session's record: the
    /// full output, not only what the model was shown, and without running
    /// anything again.
    @Tool
    struct SearchResults: Tool {
        @JSONSchema
        public enum Strategy: String, Sendable, Codable, Hashable, CaseIterable {
            /// The text as written, anywhere. The default.
            case contains
            /// The whole field, as written: for a record field such as severity.
            case exact
            /// Tolerates typos and partial words.
            case fuzzy
            /// Whole identifier-like words.
            case identifier
            /// A regular expression (ICU).
            case regex

            var search: SearchStrategy {
                switch self {
                case .contains: .contains
                case .exact: .exact
                case .fuzzy: .fuzzy
                case .identifier: .identifier
                case .regex: .regex
                }
            }
        }

        @JSONSchema
        public enum Role: String, Sendable, Codable, Hashable, CaseIterable {
            /// Every hit matches it.
            case required
            /// Ranks hits that match it higher.
            case preferred
            /// No hit matches it.
            case excluded

            var search: SearchProbeRole {
                switch self {
                case .required: .required
                case .preferred: .preferred
                case .excluded: .excluded
                }
            }
        }

        @JSONSchema
        public struct Probe: HashableSource {
            public let text: String
            /// required by default.
            public let role: Role?
            /// contains by default.
            public let strategy: Strategy?
            /// Match one field of a record (such as severity or file) instead of the whole text.
            public let field: String?

            public init(text: String, role: Role? = nil, strategy: Strategy? = nil, field: String? = nil) {
                self.text = text
                self.role = role
                self.strategy = strategy
                self.field = field
            }
        }

        @JSONSchema
        public struct Input: HashableSource {
            /// Literal text to find. The short form: one required term.
            public let query: String?
            /// A regular expression to find. The short form, beside or instead of query.
            public let pattern: String?
            /// Several terms with roles and strategies; combined with query and pattern.
            /// Preferred terms rank the hits; without them hits come newest result first, in line order.
            public let probes: [Probe]?
            /// Only these calls' results, by call id.
            public let calls: [String]?
            /// Only results of these tools, such as swift_build.
            public let tools: [String]?
            /// Only these segments, such as stdout, stderr or text (what you were shown).
            public let segments: [String]?
            /// Only failed results (true) or only successful ones (false).
            public let failed: Bool?
            /// Lines shown before and after each hit, from the same segment. Defaults to 0.
            public let contextLines: Int?
            /// Defaults to false.
            public let caseSensitive: Bool?
            /// One hit per distinct text across results, with how often it occurred. Defaults to false.
            public let unique: Bool?
            /// How many of the session's latest results to search. Defaults to 100.
            public let recent: Int?
            /// At most this many hits. Defaults to 20.
            public let limit: Int?
            /// Skip this many hits, to page. Defaults to 0.
            public let offset: Int?

            public init(
                query: String? = nil,
                pattern: String? = nil,
                probes: [Probe]? = nil,
                calls: [String]? = nil,
                tools: [String]? = nil,
                segments: [String]? = nil,
                failed: Bool? = nil,
                contextLines: Int? = nil,
                caseSensitive: Bool? = nil,
                unique: Bool? = nil,
                recent: Int? = nil,
                limit: Int? = nil,
                offset: Int? = nil
            ) {
                self.query = query
                self.pattern = pattern
                self.probes = probes
                self.calls = calls
                self.tools = tools
                self.segments = segments
                self.failed = failed
                self.contextLines = contextLines
                self.caseSensitive = caseSensitive
                self.unique = unique
                self.recent = recent
                self.limit = limit
                self.offset = offset
            }
        }

        @JSONSchema
        public struct Hit: HashableResult {
            public let call: String
            public let tool: String
            public let segment: String
            /// The element's position in its segment, from 1; for lines, the line number.
            public let line: Int
            public let text: String
            public let before: [String]
            public let after: [String]
            /// With unique: how many results or lines carried this text.
            public let occurrences: Int?

            public init(
                call: String,
                tool: String,
                segment: String,
                line: Int,
                text: String,
                before: [String] = [],
                after: [String] = [],
                occurrences: Int? = nil
            ) {
                self.call = call
                self.tool = tool
                self.segment = segment
                self.line = line
                self.text = text
                self.before = before
                self.after = after
                self.occurrences = occurrences
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let hits: [Hit]
            /// Hits before limit and offset.
            public let total: Int
            /// Results searched.
            public let searched: Int

            public init(hits: [Hit], total: Int, searched: Int) {
                self.hits = hits
                self.total = total
                self.searched = searched
            }
        }

        public static let purpose =
            "Search what earlier calls returned, in full and without rerunning them: their output by segment (stdout, stderr, records, the text you were shown). Give query or pattern; narrow by calls, tools or segments."
        public static let risk: ActionRisk = .observe
        public static let defaultRecent = 100
        public static let defaultLimit = 20
        /// Reading and searching results are not themselves searched.
        public static let unsearched: Set<String> = [
            ReadResult.identifier.rawValue,
            identifier.rawValue,
        ]

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            guard let archive = try? context.require(ResultArchive.self) else {
                throw SearchResultsError.archiveUnavailable
            }
            let probes = Self.probes(input)
            guard !probes.isEmpty else {
                throw SearchResultsError.noTerms
            }
            let outputs = try await Self.outputs(input, archive: archive)
            let candidates = Self.candidates(of: outputs, segments: input.segments)
            let result = TextSearch.search(
                probes: probes,
                in: candidates,
                options: SearchOptions(
                    mode: .exhaustive,
                    strategy: .contains,
                    caseSensitive: input.caseSensitive ?? false,
                    minimumScore: nil,
                    maximumResults: nil
                )
            )
            // Exhaustive results keep candidate order: newest result first,
            // then segment and line. Preferred terms rank instead.
            let ranked = probes.contains { $0.role == .preferred }
            let order = Dictionary(
                candidates.enumerated().map { ($1.matchID, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            let matched = ranked
                ? result.hits.compactMap { order[$0.documentID] }
                : result.hits.compactMap { order[$0.documentID] }.sorted()
            let hits = Self.hits(
                matched.map { candidates[$0] },
                unique: input.unique ?? false,
                context: max(0, input.contextLines ?? 0)
            )
            let offset = max(0, input.offset ?? 0)
            let limit = max(1, input.limit ?? Self.defaultLimit)
            return Output(
                hits: Array(hits.dropFirst(offset).prefix(limit)),
                total: hits.count,
                searched: outputs.count
            )
        }

        public func render(_ output: Output, input: Input) -> String? {
            guard !output.hits.isEmpty else {
                return "No hits in \(output.searched) results."
            }
            var lines: [String] = []
            var heading: String?
            for hit in output.hits {
                let current = "\(hit.call) \(hit.tool) · \(hit.segment)"
                if current != heading {
                    lines.append(current)
                    heading = current
                }
                let first = hit.line - hit.before.count
                for (index, text) in hit.before.enumerated() {
                    lines.append("  \(first + index)- \(text)")
                }
                let count = hit.occurrences.map { $0 > 1 ? " (×\($0))" : "" } ?? ""
                lines.append("  \(hit.line): \(hit.text)\(count)")
                for (index, text) in hit.after.enumerated() {
                    lines.append("  \(hit.line + 1 + index)- \(text)")
                }
            }
            let shown = max(0, input.offset ?? 0) + output.hits.count
            if shown < output.total {
                lines.append("[\(output.hits.count) of \(output.total) hits; offset \(shown) continues.]")
            }
            if let hit = output.hits.first {
                lines.append("read_result {\"call\": \"\(hit.call)\", \"segment\": \"\(hit.segment)\", \"offset\": \(max(1, hit.line - 5))} reads around a hit.")
            }
            return lines.joined(separator: "\n")
        }
    }
}

extension Standard.Tools.SearchResults {
    typealias Located = RecordedOutput.Candidate

    static func probes(
        _ input: Input
    ) -> [SearchProbe] {
        var probes: [SearchProbe] = []
        if let query = input.query, !query.isEmpty {
            probes.append(SearchProbe(query, role: .required, strategy: .contains))
        }
        if let pattern = input.pattern, !pattern.isEmpty {
            probes.append(SearchProbe(pattern, role: .required, strategy: .regex))
        }
        for probe in input.probes ?? [] where !probe.text.isEmpty {
            probes.append(SearchProbe(
                probe.text,
                role: (probe.role ?? .required).search,
                strategy: (probe.strategy ?? .contains).search,
                field: probe.field
            ))
        }
        return probes
    }

    /// The recorded outputs searched, newest first.
    static func outputs(
        _ input: Input,
        archive: ResultArchive
    ) async throws -> [RecordedOutput] {
        let responses: [FunctionCall.Response]
        if let calls = input.calls, !calls.isEmpty {
            var found: [FunctionCall.Response] = []
            for call in calls {
                if let response = try await archive.response(call: call) {
                    found.append(response)
                }
            }
            responses = found
        } else {
            responses = try await archive.recent(limit: max(1, input.recent ?? defaultRecent))
        }
        let tools = input.tools.map(Set.init)
        return responses
            .filter { !unsearched.contains($0.call.name) }
            .filter { tools?.contains($0.call.name) ?? true }
            .filter { response in input.failed.map { response.isError == $0 } ?? true }
            .map(RecordedOutput.init)
    }

    static func candidates(
        of outputs: [RecordedOutput],
        segments: [String]?
    ) -> [Located] {
        let named = segments.map(Set.init)
        return outputs.flatMap { output in
            output.candidates().filter { named?.contains($0.segment.name) ?? true }
        }
    }

    /// Hits in order. A line of the rendering (`text`) that repeats a hit in
    /// one of the same result's derived segments is left out; with `unique`,
    /// one hit per text across results.
    static func hits(
        _ located: [Located],
        unique: Bool,
        context: Int
    ) -> [Hit] {
        func trimmed(_ item: Located) -> String {
            item.element.text.trimmingCharacters(in: .whitespaces)
        }
        let derived = Set(located
            .filter { $0.segment.name != RecordedOutput.textSegment }
            .map { $0.output.call.id + "\u{0}" + trimmed($0) })
        var hits: [Hit] = []
        var seen: [String: Int] = [:]
        var counts: [Int: Int] = [:]
        for item in located {
            let text = trimmed(item)
            if item.segment.name == RecordedOutput.textSegment,
               derived.contains(item.output.call.id + "\u{0}" + text) {
                continue
            }
            if unique {
                if let index = seen[text] {
                    counts[index, default: 1] += 1
                    continue
                }
                seen[text] = hits.count
            }
            let elements = item.segment.elements
            let position = item.element.ordinal - 1
            let before = elements[max(0, position - context)..<position].map(\.text)
            let after = elements[(position + 1)..<min(elements.count, position + 1 + context)].map(\.text)
            hits.append(Hit(
                call: item.output.call.id,
                tool: item.output.call.name,
                segment: item.segment.name,
                line: item.element.ordinal,
                text: item.element.text,
                before: before,
                after: after
            ))
        }
        guard unique else {
            return hits
        }
        return hits.enumerated().map { index, hit in
            Hit(
                call: hit.call,
                tool: hit.tool,
                segment: hit.segment,
                line: hit.line,
                text: hit.text,
                before: hit.before,
                after: hit.after,
                occurrences: counts[index] ?? 1
            )
        }
    }
}
