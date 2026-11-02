import Agentic
import Foundation
import Macros
import Math
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
            case narrative
            case table
            case bar
            case line
        }

        @JSONSchema
        public struct Column: HashableSource {
            public let name: String
            public let kind: ValueKind

            public init(name: String, kind: ValueKind) {
                self.name = name
                self.kind = kind
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
            public let rows: [Row]

            public init(id: String, columns: [Column], rows: [Row]) {
                self.id = id
                self.columns = columns
                self.rows = rows
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

            public init(
                kind: BlockKind,
                title: String? = nil,
                text: String? = nil,
                dataset: String? = nil,
                columns: [String]? = nil,
                x: String? = nil,
                y: String? = nil
            ) {
                self.kind = kind
                self.title = title
                self.text = text
                self.dataset = dataset
                self.columns = columns
                self.x = x
                self.y = y
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
        }

        public static let purpose = "Construct a validated structured ReportDocument containing datasets, narratives, tables and bar/line charts. Decimal cells must be exact JSON strings; other cells must match declared types. All model-authored datasets have unknown completeness, regardless of source references. Does not persist or render."
        public static let risk: ActionRisk = .observe

        public init() {}

        public static func evaluate(_ input: Input) throws -> Output {
            let datasets = try input.datasets.map { draft -> ReportDataset in
                let columns = draft.columns.map { column -> StructuredField in
                    let kind: StructuredValueKind
                    switch column.kind {
                    case .text: kind = .text
                    case .integer: kind = .integer
                    case .decimal: kind = .decimal
                    case .date: kind = .date
                    case .boolean: kind = .boolean
                    }
                    return StructuredField(column.name, kind: kind)
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
                switch block.kind {
                case .narrative:
                    guard let text = block.text, block.title == nil,
                          block.dataset == nil, block.columns == nil,
                          block.x == nil, block.y == nil else {
                        throw Failure.invalid_block(index)
                    }
                    return .narrative(.paragraph([.text(text)]))
                case .table:
                    guard let dataset = block.dataset, let columns = block.columns,
                          !columns.isEmpty, block.text == nil,
                          block.x == nil, block.y == nil else {
                        throw Failure.invalid_block(index)
                    }
                    return .table(.init(dataset: dataset, columns: columns, title: block.title))
                case .bar, .line:
                    guard let dataset = block.dataset, let x = block.x, let y = block.y,
                          block.text == nil, block.columns == nil else {
                        throw Failure.invalid_block(index)
                    }
                    let kind: ReportBlock.Chart.Kind = block.kind == .bar ? .bar : .line
                    return .chart(.init(dataset: dataset, kind: kind, x: x, y: y, title: block.title))
                }
            }
            return .init(document: try ReportDocument(title: input.title, datasets: datasets, blocks: blocks))
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
            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Construct report with \(input.datasets.count) datasets and \(input.blocks.count) blocks",
                sideEffects: []
            )
        }

        public func call(_ input: Input, in _: ToolContext) async throws -> Output {
            try Self.evaluate(input)
        }
    }
}
