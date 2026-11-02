import Agentic
import Macros
import Primitives
import Schema

public extension Standard.Tools {
    @Tool("create_graph")
    struct CreateGraph: Tool {
        @JSONSchema
        public struct Node: HashableSource {
            public let id: String
            public let value: JSONValue

            public init(id: String, value: JSONValue) {
                self.id = id
                self.value = value
            }
        }

        @JSONSchema
        public struct Edge: HashableSource {
            public let id: String
            public let source: String
            public let destination: String
            public let value: JSONValue

            public init(id: String, source: String, destination: String, value: JSONValue) {
                self.id = id
                self.source = source
                self.destination = destination
                self.value = value
            }
        }

        @JSONSchema
        public struct Reference: HashableSource {
            public let id: String
            public let target: String

            public init(id: String, target: String) {
                self.id = id
                self.target = target
            }
        }

        @JSONSchema
        public struct Input: HashableSource {
            public let nodes: [Node]
            public let edges: [Edge]
            public let references: [Reference]

            public init(nodes: [Node], edges: [Edge], references: [Reference] = []) {
                self.nodes = nodes
                self.edges = edges
                self.references = references
            }
        }

        public struct Output: HashableResult {
            public let graph: Graph<String, JSONValue, String, JSONValue>
            public let references: ReferenceSet<String, String>

            public init(
                graph: Graph<String, JSONValue, String, JSONValue>,
                references: ReferenceSet<String, String>
            ) {
                self.graph = graph
                self.references = references
            }

            public static var jsonschema: JSONSchema {
                .object(
                    properties: [
                        .init(name: "graph", schema: .object(properties: [
                            .init(name: "nodes", schema: .array(items: .any), required: true),
                            .init(name: "edges", schema: .array(items: .any), required: true),
                        ], additionalProperties: .disallowed), required: true),
                        .init(name: "references", schema: .object(properties: [
                            .init(name: "references", schema: .array(items: .any), required: true),
                        ], additionalProperties: .disallowed), required: true),
                    ],
                    additionalProperties: .disallowed
                )
            }
        }

        public static let purpose = "Construct a validated, generic directed multigraph with arbitrary JSON node and edge values and optional identified references. Returns structured data; does not render, write files, or certify provenance. Parallel edges and cycles are permitted."
        public static let risk: ActionRisk = .observe

        public init() {}

        public static func evaluate(_ input: Input) throws -> Output {
            let graph = try Graph<String, JSONValue, String, JSONValue>(
                nodes: input.nodes.map { .init(id: $0.id, value: $0.value) },
                edges: input.edges.map {
                    .init(id: $0.id, source: $0.source, destination: $0.destination, value: $0.value)
                }
            )
            let references = try ReferenceSet<String, String>(
                references: input.references.map { .init(id: $0.id, target: $0.target) }
            )
            // External/off-graph references remain legal. A caller can explicitly
            // enforce target closure with ReferenceSet.validate_targets(in:).
            return .init(graph: graph, references: references)
        }

        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            _ = try Self.evaluate(input)
            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Construct graph with \(input.nodes.count) nodes and \(input.edges.count) edges",
                sideEffects: []
            )
        }

        public func call(_ input: Input, in _: ToolContext) async throws -> Output {
            try Self.evaluate(input)
        }
    }
}
