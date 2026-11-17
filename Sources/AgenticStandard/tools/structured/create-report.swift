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
            /// inside each row object, such as `estimate.minutes`. Defaults
            /// to `name`.
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
            /// result, such as `candidates`. Empty or absent: the result
            /// itself is the array.
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

            public init(
                kind: BlockKind,
                title: String? = nil,
                text: String? = nil,
                dataset: String? = nil,
                columns: [String]? = nil,
                x: String? = nil,
                y: String? = nil,
                facts: [Fact]? = nil,
                tone: Tone? = nil
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

        public static let purpose = "Construct a validated structured ReportDocument containing datasets, Markdown narratives, callouts, facts, tables and bar/line charts. Prefer datasets read from a previous call (`from_call`, `rows_path`, column `field` paths) over copying values: those are complete and traced to the call. Inline decimal cells must be exact JSON strings; other cells must match declared types. Inline datasets have unknown completeness, regardless of source references. Does not persist; the user sees the report."
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

            let blocks = try input.blocks.enumerated().map { index, block -> ReportBlock in
                func require(_ condition: Bool) throws {
                    guard condition else { throw Failure.invalid_block(index) }
                }
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
                }
            }
            return .init(document: try ReportDocument(title: input.title, datasets: datasets, blocks: blocks))
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

        static func rows(_ draft: Dataset, from output: JSONValue, call: String) throws -> [ReportDataset.Row] {
            let path = draft.rows_path ?? ""
            guard case .array(let items)? = value(at: path, in: output) else {
                throw Failure.invalid_source(dataset: draft.id, reason: "'\(path)' is not an array in the result of '\(call)'")
            }
            return try items.enumerated().map { index, item in
                let values = try draft.columns.map { column -> StructuredValue? in
                    guard let raw = value(at: column.field ?? column.name, in: item), raw != .null else {
                        return nil
                    }
                    guard let value = try coerce(raw, as: column.kind) else {
                        throw Failure.invalid_value(dataset: draft.id, row: index, column: column.name)
                    }
                    return value
                }
                let identifier = path.isEmpty ? "\(call)#\(index)" : "\(call)#\(path).\(index)"
                return .init(values: values, sources: [.init(namespace: "tool_call", identifier: identifier)])
            }
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
