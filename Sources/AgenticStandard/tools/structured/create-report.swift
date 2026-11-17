import Agentic
import DSL
import Foundation
import Macros
import Math
import ParsersStructuredContent
import Primitives
import Reporting
import Schema
import Search

public extension Standard.Tools {
    @Tool("create_report")
    struct CreateReport: Tool {
        @JSONSchema
        public enum ValueKind: String, Sendable, Codable, Hashable, CaseIterable {
            case text
            case integer
            case decimal
            case date
            case boolean
        }

        @JSONSchema
        public enum BlockKind: String, Sendable, Codable, Hashable, CaseIterable {
            /// Markdown in `text`.
            case narrative
            /// `dataset` and `columns`.
            case table
            /// `dataset`, `x` and a numeric `y`.
            case bar
            case line
            /// Labeled values in `facts`.
            case facts
            /// Markdown in `text`, set apart by `tone`.
            case callout
            /// Rows of `dataset` as spans over time: `start` and `end` name
            /// date columns; optional `lane`, `label` and `mark` columns.
            case timeline
        }

        @JSONSchema
        public enum Tone: String, Sendable, Codable, Hashable, CaseIterable {
            case info
            case success
            case warning
            case failure
        }

        @JSONSchema
        public struct Column: HashableSource {
            public let name: String
            public let kind: ValueKind
            /// For a dataset read from a call: dotted path to the value
            /// inside each row object, such as `estimate.minutes`; each
            /// leading `../` reads from the object one `*` up, such as
            /// `../participant`. Defaults to `name`.
            public let field: String?

            public init(name: String, kind: ValueKind, field: String? = nil) {
                self.name = name
                self.kind = kind
                self.field = field
            }
        }

        @JSONSchema
        public struct Source: HashableSource {
            public let namespace: String
            public let identifier: String

            public init(namespace: String, identifier: String) {
                self.namespace = namespace
                self.identifier = identifier
            }
        }

        @JSONSchema
        public struct Row: HashableSource {
            /// Null means a missing cell. Exact decimals must be JSON strings.
            public let values: [JSONValue]
            /// Model-authored source references are unverified claims.
            public let sources: [Source]

            public init(values: [JSONValue], sources: [Source] = []) {
                self.values = values
                self.sources = sources
            }
        }

        @JSONSchema
        public struct Dataset: HashableSource {
            public let id: String
            public let columns: [Column]
            /// Inline rows. Leave empty when `from_call` is given.
            public let rows: [Row]
            /// A previous call whose result supplies the rows, instead of
            /// copying them: complete and traceable to that call.
            public let from_call: String?
            /// Dotted path to the array of row objects in that call's
            /// result, such as `candidates`; `*` takes every element of an
            /// array on the way, such as `participants.*.entries`. Empty or
            /// absent: the result itself is the array.
            public let rows_path: String?

            public init(
                id: String,
                columns: [Column],
                rows: [Row] = [],
                from_call: String? = nil,
                rows_path: String? = nil
            ) {
                self.id = id
                self.columns = columns
                self.rows = rows
                self.from_call = from_call
                self.rows_path = rows_path
            }
        }

        @JSONSchema
        public struct Fact: HashableSource {
            public let label: String
            public let value: String

            public init(label: String, value: String) {
                self.label = label
                self.value = value
            }
        }

        @JSONSchema
        public struct Block: HashableSource {
            public let kind: BlockKind
            public let title: String?
            public let text: String?
            public let dataset: String?
            public let columns: [String]?
            public let x: String?
            public let y: String?
            public let facts: [Fact]?
            public let tone: Tone?
            /// Timeline: the date column where each span starts.
            public let start: String?
            /// Timeline: the date column where each span ends.
            public let end: String?
            /// Timeline: the column naming each span's lane, such as a
            /// person. Absent: one lane.
            public let lane: String?
            /// Timeline: the column labelling each span.
            public let label: String?
            /// Timeline: the column saying what a span is. Read as occupied
            /// (also busy, blocking), reserved, available (also offer, open),
            /// highlight (also proposed, candidate) or transit (also
            /// travel); other values are left off. Absent: occupied.
            public let mark: String?
            /// Timeline: IANA zone for the axis.
            public let time_zone: String?

            public init(
                kind: BlockKind,
                title: String? = nil,
                text: String? = nil,
                dataset: String? = nil,
                columns: [String]? = nil,
                x: String? = nil,
                y: String? = nil,
                facts: [Fact]? = nil,
                tone: Tone? = nil,
                start: String? = nil,
                end: String? = nil,
                lane: String? = nil,
                label: String? = nil,
                mark: String? = nil,
                time_zone: String? = nil
            ) {
                self.kind = kind
                self.title = title
                self.text = text
                self.dataset = dataset
                self.columns = columns
                self.x = x
                self.y = y
                self.facts = facts
                self.tone = tone
                self.start = start
                self.end = end
                self.lane = lane
                self.label = label
                self.mark = mark
                self.time_zone = time_zone
            }
        }

        @JSONSchema
        public struct Input: HashableSource {
            public let title: String
            public let datasets: [Dataset]
            public let blocks: [Block]

            public init(title: String, datasets: [Dataset], blocks: [Block]) {
                self.title = title
                self.datasets = datasets
                self.blocks = blocks
            }
        }

        public struct Output: HashableResult {
            public let document: ReportDocument

            public init(document: ReportDocument) {
                self.document = document
            }

            public static var jsonschema: JSONSchema {
                .object(
                    properties: [.init(name: "document", schema: .any, required: true)],
                    additionalProperties: .disallowed
                )
            }
        }

        public enum Failure: Error, Sendable, Equatable {
            case invalid_value(dataset: String, row: Int, column: String)
            case invalid_block(Int)
            /// `from_call` with inline rows, or a call without a recorded result.
            case invalid_source(dataset: String, reason: String)
        }

        public static let purpose = "Construct a validated structured ReportDocument containing datasets, Markdown narratives, callouts, facts, tables, bar/line charts and timelines. Prefer datasets read from a previous call (`from_call`, `rows_path`, column `field` paths) over copying values: those are complete and traced to the call. Inline decimal cells must be exact JSON strings; other cells must match declared types. Inline datasets have unknown completeness, regardless of source references. Does not persist; the user sees the report."
        public static let risk: ActionRisk = .observe

        public init() {}

        /// Builds the document from inline datasets only.
        public static func evaluate(_ input: Input) throws -> Output {
            try evaluate(input, resolved: [:])
        }

        /// Builds the document; `resolved` holds rows read from earlier calls,
        /// by dataset id.
        static func evaluate(_ input: Input, resolved: [String: [ReportDataset.Row]]) throws -> Output {
            let datasets = try input.datasets.map { draft -> ReportDataset in
                let columns = draft.columns.map { StructuredField($0.name, kind: structuredKind($0.kind)) }
                if let rows = resolved[draft.id] {
                    return try ReportDataset(id: draft.id, columns: columns, rows: rows, coverage: .complete)
                }
                if draft.from_call != nil {
                    // Preflight sees the declaration before the call is read.
                    return try ReportDataset(id: draft.id, columns: columns, rows: [], coverage: .unknown)
                }
                let rows = try draft.rows.enumerated().map { index, row -> ReportDataset.Row in
                    guard row.values.count == draft.columns.count else {
                        throw ReportDataset.Failure.invalidRow(index)
                    }
                    let values = try zip(row.values, draft.columns).map { raw, column -> StructuredValue? in
                        if raw == .null { return nil }
                        guard let value = try parse(raw, as: column.kind) else {
                            throw Failure.invalid_value(dataset: draft.id, row: index, column: column.name)
                        }
                        return value
                    }
                    return .init(
                        values: values,
                        sources: row.sources.map {
                            ReportSource(namespace: $0.namespace, identifier: $0.identifier)
                        }
                    )
                }
                return try ReportDataset(
                    id: draft.id,
                    columns: columns,
                    rows: rows,
                    coverage: .unknown
                )
            }

            var byID: [String: ReportDataset] = [:]
            for dataset in datasets { byID[dataset.id] = dataset }
            let blocks = try input.blocks.enumerated().map { index, block -> ReportBlock in
                func require(_ condition: Bool) throws {
                    guard condition else { throw Failure.invalid_block(index) }
                }
                let noTimeline = block.start == nil && block.end == nil && block.lane == nil
                    && block.label == nil && block.mark == nil && block.time_zone == nil
                try require(block.kind == .timeline || noTimeline)
                let noData = block.dataset == nil && block.columns == nil && block.x == nil && block.y == nil
                switch block.kind {
                case .narrative:
                    guard let text = block.text else { throw Failure.invalid_block(index) }
                    try require(block.title == nil && noData && block.facts == nil && block.tone == nil)
                    return .narrative(MarkdownStructuredContentParser.parse(text))
                case .callout:
                    guard let text = block.text, let tone = block.tone else { throw Failure.invalid_block(index) }
                    try require(noData && block.facts == nil)
                    return .callout(.init(
                        tone: callout(tone),
                        title: block.title,
                        content: MarkdownStructuredContentParser.parse(text)
                    ))
                case .facts:
                    guard let facts = block.facts, !facts.isEmpty else { throw Failure.invalid_block(index) }
                    try require(noData && block.text == nil && block.tone == nil)
                    return .facts(.init(title: block.title, facts: facts.map { .init($0.label, $0.value) }))
                case .table:
                    guard let dataset = block.dataset, let columns = block.columns else {
                        throw Failure.invalid_block(index)
                    }
                    try require(!columns.isEmpty && block.text == nil && block.x == nil && block.y == nil
                        && block.facts == nil && block.tone == nil)
                    return .table(.init(dataset: dataset, columns: columns, title: block.title))
                case .bar, .line:
                    guard let dataset = block.dataset, let x = block.x, let y = block.y else {
                        throw Failure.invalid_block(index)
                    }
                    try require(block.text == nil && block.columns == nil && block.facts == nil && block.tone == nil)
                    let kind: ReportBlock.Chart.Kind = block.kind == .bar ? .bar : .line
                    return .chart(.init(dataset: dataset, kind: kind, x: x, y: y, title: block.title))
                case .timeline:
                    guard let id = block.dataset, let dataset = byID[id],
                          let start = block.start, let end = block.end else {
                        throw Failure.invalid_block(index)
                    }
                    try require(block.text == nil && block.columns == nil && block.x == nil && block.y == nil
                        && block.facts == nil && block.tone == nil)
                    if let zone = block.time_zone {
                        try require(TimeZone(identifier: zone) != nil)
                    }
                    return try timeline(block, dataset: dataset, start: start, end: end, index: index)
                }
            }
            return .init(document: try ReportDocument(title: input.title, datasets: datasets, blocks: blocks))
        }

        /// Spans from rows; the window runs from the first start to the last
        /// end, in whole hours. Rows without both times are left off.
        static func timeline(
            _ block: Block,
            dataset: ReportDataset,
            start: String,
            end: String,
            index: Int
        ) throws -> ReportBlock {
            func column(_ name: String?, kinds: [StructuredValueKind]) throws -> Int? {
                guard let name else { return nil }
                guard let position = dataset.columnIndex(name), kinds.contains(dataset.columns[position].kind) else {
                    throw Failure.invalid_block(index)
                }
                return position
            }
            let startColumn = try column(start, kinds: [.date])!
            let endColumn = try column(end, kinds: [.date])!
            let laneColumn = try column(block.lane, kinds: [.text])
            let labelColumn = try column(block.label, kinds: [.text, .integer, .decimal, .boolean, .date])
            let markColumn = try column(block.mark, kinds: [.text])

            var order: [String] = []
            var lanes: [String: [ReportBlock.Timeline.Span]] = [:]
            for row in dataset.rows {
                guard case .date(let from)? = row.values[startColumn],
                      case .date(let to)? = row.values[endColumn], from <= to else { continue }
                var mark = ReportBlock.Timeline.Mark.occupied
                if let markColumn {
                    guard case .text(let value)? = row.values[markColumn], let read = Self.mark(value) else { continue }
                    mark = read
                }
                let lane = laneColumn.flatMap { position -> String? in
                    if case .text(let text)? = row.values[position] { return text }
                    return nil
                } ?? block.title ?? dataset.id
                let label = labelColumn.flatMap { row.values[$0] }.map { value -> String in
                    if case .text(let text) = value { return text }
                    return "\(value)"
                }
                if lanes[lane] == nil { order.append(lane) }
                lanes[lane, default: []].append(.init(start: from, end: to, mark: mark, label: label))
            }
            let spans = lanes.values.flatMap { $0 }
            guard let first = spans.map(\.start).min(), let last = spans.map(\.end).max() else {
                return .narrative(.paragraph([.text((block.title.map { "\($0): " } ?? "") + "no times to show.")]))
            }
            let zone = block.time_zone.flatMap(TimeZone.init(identifier:)) ?? .current
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = zone
            let from = calendar.dateInterval(of: .hour, for: first)?.start ?? first
            var to = calendar.dateInterval(of: .hour, for: last)?.end ?? last
            if last > from, calendar.dateInterval(of: .hour, for: last)?.start == last { to = last }
            if to <= from { to = from.addingTimeInterval(3600) }
            return .timeline(.init(
                title: block.title,
                start: from,
                end: to,
                timeZone: zone.identifier,
                lanes: order.map { .init(label: $0, spans: lanes[$0] ?? []) }
            ))
        }

        /// The vocabulary tools use for time, read as timeline marks.
        static func mark(_ value: String) -> ReportBlock.Timeline.Mark? {
            switch value.lowercased() {
            case "occupied", "busy", "blocking", "commitment", "tentative": .occupied
            case "reserved": .reserved
            case "available", "offer", "offered", "open", "free": .available
            case "highlight", "proposed", "proposal", "candidate", "recommended": .highlight
            case "transit", "travel": .transit
            default: nil
            }
        }

        /// Reads every `from_call` dataset from the session's recorded results.
        static func resolve(
            _ input: Input,
            archive: ResultArchive?
        ) async throws -> [String: [ReportDataset.Row]] {
            var resolved: [String: [ReportDataset.Row]] = [:]
            for draft in input.datasets {
                guard let call = draft.from_call else { continue }
                guard draft.rows.isEmpty else {
                    throw Failure.invalid_source(dataset: draft.id, reason: "give either rows or from_call, not both")
                }
                guard let archive else {
                    throw Failure.invalid_source(dataset: draft.id, reason: "results of earlier calls are not available in this session")
                }
                guard let response = try await archive.response(call: call), !response.isError else {
                    throw Failure.invalid_source(dataset: draft.id, reason: "no successful result recorded for call '\(call)'")
                }
                resolved[draft.id] = try rows(draft, from: response.output, call: call)
            }
            return resolved
        }

        /// One row object found along `rows_path`, with the objects each
        /// `*` passed through (nearest last) and its concrete path.
        struct Located {
            let item: JSONValue
            let ancestors: [JSONValue]
            let path: String
        }

        static func rows(_ draft: Dataset, from output: JSONValue, call: String) throws -> [ReportDataset.Row] {
            let path = draft.rows_path ?? ""
            guard let located = locate(path, in: output) else {
                throw Failure.invalid_source(dataset: draft.id, reason: "'\(path)' is not an array in the result of '\(call)'")
            }
            return try located.enumerated().map { index, row in
                let values = try draft.columns.map { column -> StructuredValue? in
                    guard let raw = value(at: column.field ?? column.name, in: row), raw != .null else {
                        return nil
                    }
                    guard let value = try coerce(raw, as: column.kind) else {
                        throw Failure.invalid_value(dataset: draft.id, row: index, column: column.name)
                    }
                    return value
                }
                return .init(values: values, sources: [.init(namespace: "tool_call", identifier: "\(call)#\(row.path)")])
            }
        }

        /// Every row object at `path`; `*` expands arrays. Nil when the path
        /// does not end in an array.
        static func locate(_ path: String, in root: JSONValue) -> [Located]? {
            var frontier = [Located(item: root, ancestors: [], path: "")]
            for segment in path.split(separator: ".").map(String.init) {
                var next: [Located] = []
                for entry in frontier {
                    func join(_ part: String) -> String { entry.path.isEmpty ? part : entry.path + "." + part }
                    if segment == "*" {
                        guard case .array(let items) = entry.item else { return nil }
                        for (offset, item) in items.enumerated() {
                            next.append(.init(item: item, ancestors: entry.ancestors + [item], path: join(String(offset))))
                        }
                    } else {
                        guard let child = value(at: segment, in: entry.item) else { return nil }
                        next.append(.init(item: child, ancestors: entry.ancestors, path: join(segment)))
                    }
                }
                frontier = next
            }
            // Ending in `*`: the elements themselves are the rows.
            if path.split(separator: ".").last == "*" {
                return frontier.map { .init(item: $0.item, ancestors: Array($0.ancestors.dropLast()), path: $0.path) }
            }
            var rows: [Located] = []
            for entry in frontier {
                guard case .array(let items) = entry.item else { return nil }
                for (offset, item) in items.enumerated() {
                    let path = entry.path.isEmpty ? String(offset) : entry.path + "." + String(offset)
                    rows.append(.init(item: item, ancestors: entry.ancestors, path: path))
                }
            }
            return rows
        }

        /// A field of a row; each leading `../` reads from one `*` further up.
        static func value(at field: String, in row: Located) -> JSONValue? {
            var rest = Substring(field)
            var up = 0
            while rest.hasPrefix("../") {
                up += 1
                rest = rest.dropFirst(3)
            }
            guard up > 0 else { return value(at: field, in: row.item) }
            guard up <= row.ancestors.count else { return nil }
            return value(at: String(rest), in: row.ancestors[row.ancestors.count - up])
        }

        /// Dotted path lookup; numeric segments index arrays.
        static func value(at path: String, in root: JSONValue) -> JSONValue? {
            var current = root
            for segment in path.split(separator: ".").map(String.init) {
                switch current {
                case .object(let fields):
                    guard let next = fields[segment] else { return nil }
                    current = next
                case .array(let items):
                    guard let index = Int(segment), items.indices.contains(index) else { return nil }
                    current = items[index]
                default:
                    return nil
                }
            }
            return current
        }

        /// Tool output is already typed; accept its natural JSON forms.
        private static func coerce(_ raw: JSONValue, as kind: ValueKind) throws -> StructuredValue? {
            switch (kind, raw) {
            case (.text, .int(let value)): return .text(String(value))
            case (.text, .double(let value)): return .text(String(value))
            case (.text, .bool(let value)): return .text(value ? "true" : "false")
            case (.text, .array(let values)):
                let parts = values.compactMap { value -> String? in
                    if case .string(let text) = value { return text }
                    return nil
                }
                return parts.count == values.count ? .text(parts.joined(separator: ", ")) : nil
            case (.decimal, .int(let value)): return .decimal(Decimal(value))
            case (.decimal, .double(let value)): return .decimal(try DecimalArithmetic.parse(String(value)))
            default: return try parse(raw, as: kind)
            }
        }

        private static func structuredKind(_ kind: ValueKind) -> StructuredValueKind {
            switch kind {
            case .text: .text
            case .integer: .integer
            case .decimal: .decimal
            case .date: .date
            case .boolean: .boolean
            }
        }

        private static func callout(_ tone: Tone) -> ReportBlock.Callout.Tone {
            switch tone {
            case .info: .info
            case .success: .success
            case .warning: .warning
            case .failure: .failure
            }
        }

        private static func parse(_ raw: JSONValue, as kind: ValueKind) throws -> StructuredValue? {
            switch (kind, raw) {
            case (.text, .string(let value)):
                return .text(value)
            case (.integer, .int(let value)):
                return .integer(Int64(value))
            case (.decimal, .string(let literal)):
                return .decimal(try DecimalArithmetic.parse(literal))
            case (.boolean, .bool(let value)):
                return .boolean(value)
            case (.date, .string(let literal)):
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: literal) { return .date(date) }
                formatter.formatOptions = [.withInternetDateTime]
                return formatter.date(from: literal).map(StructuredValue.date)
            default:
                return nil
            }
        }

        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            _ = try Self.evaluate(input)
            let traced = input.datasets.filter { $0.from_call != nil }.count
            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Construct report with \(input.datasets.count) datasets (\(traced) from earlier calls) and \(input.blocks.count) blocks",
                sideEffects: []
            )
        }

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let archive = try? context.require(ResultArchive.self)
            return try Self.evaluate(input, resolved: try await Self.resolve(input, archive: archive))
        }

        /// The model already knows what it laid out; it reads a summary,
        /// the user sees the document.
        public func render(_ output: Output, input _: Input) -> String? {
            let rows = output.document.datasets.map { "\($0.id): \($0.rows.count) rows" }
            return "Report '\(output.document.title)' created with \(output.document.blocks.count) blocks"
                + (rows.isEmpty ? "." : " (" + rows.joined(separator: ", ") + ").")
                + " The user sees it as an attachment."
        }

        public func present(_ output: Output, input _: Input) -> ToolPresentation? {
            .init(output.document)
        }
    }
}
