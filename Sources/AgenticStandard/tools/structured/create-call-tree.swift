import Agentic
import Macros
import Primitives
import Schema

public extension Standard.Tools {
    @Tool("create_call_tree")
    struct CreateCallTree: Tool {
        /// A flat authoring record. Array order establishes sibling order.
        @JSONSchema
        public struct Call: HashableSource {
            /// Stable call-occurrence identity, not a callable/symbol identity.
            public let id: String
            /// Callable identity. Multiple occurrences may share one symbol.
            public let symbol_id: String
            /// Nil identifies a root call.
            public let parent_id: String?
            public let label: String?
            public let value: JSONValue?

            public init(
                id: String,
                symbol_id: String,
                parent_id: String? = nil,
                label: String? = nil,
                value: JSONValue? = nil
            ) {
                self.id = id
                self.symbol_id = symbol_id
                self.parent_id = parent_id
                self.label = label
                self.value = value
            }
        }

        @JSONSchema
        public struct Input: HashableSource {
            /// Flat, ordered call occurrences. Order within a parent is significant.
            public let calls: [Call]

            public init(calls: [Call]) {
                self.calls = calls
            }
        }

        /// Parent identity is intentionally excluded: reparenting is a topology
        /// change, not an automatic change to the call's semantic value.
        @JSONSchema
        public struct Occurrence: HashableSource {
            public let id: String
            public let symbol_id: String
            public let label: String
            public let value: JSONValue?

            public init(id: String, symbol_id: String, label: String, value: JSONValue?) {
                self.id = id
                self.symbol_id = symbol_id
                self.label = label
                self.value = value
            }
        }

        @JSONSchema
        public enum Provenance: String, Sendable, Codable, Hashable, CaseIterable {
            case proposed
            case observed
        }

        public struct Output: HashableResult {
            public let tree: Tree<Occurrence>
            public let provenance: Provenance

            public init(tree: Tree<Occurrence>, provenance: Provenance) {
                self.tree = tree
                self.provenance = provenance
            }

            public static var jsonschema: JSONSchema {
                .object(
                    properties: [
                        .init(name: "tree", schema: .any, required: true),
                        .init(name: "provenance", schema: Provenance.jsonschema, required: true),
                    ],
                    additionalProperties: .disallowed
                )
            }
        }

        public enum Failure: Error, Sendable, Equatable {
            case too_many_calls(Int)
            case empty_id(Int)
            case empty_symbol_id(String)
            case empty_parent_id(String)
            case empty_label(String)
            case duplicate_id(String)
            case unknown_parent(call: String, parent: String)
            case self_parent(String)
            case cycle(String)
            case excessive_depth(String)
        }

        public static let purpose =
            "Construct a validated ordered forest of call occurrences from flat parent references. Occurrence IDs are unique even when callable symbols repeat. Returns proposed structured data, not a runtime-observed trace; does not execute calls, inspect source, or render."
        public static let risk: ActionRisk = .observe

        private static let maximum_calls = 512
        private static let maximum_depth = 64

        public init() {}

        public static func evaluate(_ input: Input) throws -> Output {
            guard input.calls.count <= maximum_calls else {
                throw Failure.too_many_calls(input.calls.count)
            }

            var by_id: [String: Call] = [:]
            for (index, call) in input.calls.enumerated() {
                guard has_content(call.id) else { throw Failure.empty_id(index) }
                guard has_content(call.symbol_id) else {
                    throw Failure.empty_symbol_id(call.id)
                }
                if let parent_id = call.parent_id, !has_content(parent_id) {
                    throw Failure.empty_parent_id(call.id)
                }
                if let label = call.label, !has_content(label) {
                    throw Failure.empty_label(call.id)
                }
                guard by_id[call.id] == nil else { throw Failure.duplicate_id(call.id) }
                by_id[call.id] = call
            }

            var roots: [Call] = []
            var children_by_parent: [String: [Call]] = [:]
            for call in input.calls {
                guard let parent_id = call.parent_id else {
                    roots.append(call)
                    continue
                }
                guard parent_id != call.id else { throw Failure.self_parent(call.id) }
                guard by_id[parent_id] != nil else {
                    throw Failure.unknown_parent(call: call.id, parent: parent_id)
                }
                children_by_parent[parent_id, default: []].append(call)
            }

            var visiting: Set<String> = []
            var visited: Set<String> = []
            func make_node(_ call: Call, depth: Int) throws -> Tree<Occurrence>.Node {
                guard depth <= maximum_depth else { throw Failure.excessive_depth(call.id) }
                guard visiting.insert(call.id).inserted else { throw Failure.cycle(call.id) }
                defer { visiting.remove(call.id) }
                let children = try (children_by_parent[call.id] ?? []).map {
                    try make_node($0, depth: depth + 1)
                }
                visited.insert(call.id)
                return .init(
                    .init(
                        id: call.id,
                        symbol_id: call.symbol_id,
                        label: call.label ?? call.symbol_id,
                        value: call.value
                    ),
                    children: children
                )
            }

            let built_roots = try roots.map { try make_node($0, depth: 0) }
            if let unreachable = input.calls.first(where: { !visited.contains($0.id) }) {
                throw Failure.cycle(unreachable.id)
            }
            // A model-authored tool invocation can only produce proposed data.
            return .init(tree: .init(roots: built_roots), provenance: .proposed)
        }

        private static func has_content(_ string: String) -> Bool {
            string.contains(where: { !$0.isWhitespace })
        }

        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            _ = try Self.evaluate(input)
            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Construct proposed call tree with \(input.calls.count) occurrences",
                sideEffects: []
            )
        }

        public func call(_ input: Input, in _: ToolContext) async throws -> Output {
            try Self.evaluate(input)
        }
    }
}
