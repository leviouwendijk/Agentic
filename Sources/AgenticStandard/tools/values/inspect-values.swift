import Agentic
import Primitives
import Macros
import Schema

public enum ValueInspectionFailure: Error, Sendable {
    case tooManyKeys
    case duplicateKeys
}

public extension Standard.Tools {
    /// Inspects JSON value categories, not Swift static/metatype identities.
    @Tool("inspect_values")
    struct InspectValues: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// Named JSON values to inspect. An omitted key is distinct from an explicit null.
            public let values: [String: JSONValue]
            /// Keys to inspect, including possibly absent keys. Nil inspects all present keys.
            public let keys: [String]?

            public init(values: [String: JSONValue], keys: [String]? = nil) {
                self.values = values
                self.keys = keys
            }
        }

        @JSONSchema
        public struct Entry: HashableResult {
            public let key: String
            public let isPresent: Bool
            public let isNull: Bool
            /// Nil only for a missing key; explicit null has type 'null'.
            public let jsonType: JSONValue.Kind?

            public init(key: String, isPresent: Bool, isNull: Bool, jsonType: JSONValue.Kind?) {
                self.key = key
                self.isPresent = isPresent
                self.isNull = isNull
                self.jsonType = jsonType
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let entries: [Entry]
            /// Nil if fewer than two entries or any requested key is missing.
            /// Includes JSON null as its own distinct category.
            public let allSameJSONType: Bool?
            public let anyMissing: Bool
            public let anyNull: Bool

            public init(
                entries: [Entry],
                allSameJSONType: Bool?,
                anyMissing: Bool,
                anyNull: Bool
            ) {
                self.entries = entries
                self.allSameJSONType = allSameJSONType
                self.anyMissing = anyMissing
                self.anyNull = anyNull
            }
        }

        public static let purpose =
            "Inspect JSON value types and distinguish absent keys from explicit nulls. Compare canonical JSONValue.Kind categories (including distinct integer and number), not Swift runtime metatypes."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            let keys = try Self.selectedKeys(input)
            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Inspect \(keys.count) JSON value(s)",
                sideEffects: []
            )
        }

        public func call(_ input: Input, in _: ToolContext) async throws -> Output {
            let keys = try Self.selectedKeys(input)
            let entries = keys.map { key -> Entry in
                guard let value = input.values[key] else {
                    return .init(key: key, isPresent: false, isNull: false, jsonType: nil)
                }
                let category = value.kind
                return .init(
                    key: key,
                    isPresent: true,
                    isNull: category == .null,
                    jsonType: category
                )
            }

            let sameType: Bool?
            if entries.count < 2 || entries.contains(where: { !$0.isPresent }) {
                sameType = nil
            } else {
                sameType = entries.dropFirst().allSatisfy {
                    $0.jsonType == entries[0].jsonType
                }
            }
            return .init(
                entries: entries,
                allSameJSONType: sameType,
                anyMissing: entries.contains(where: { !$0.isPresent }),
                anyNull: entries.contains(where: { $0.isNull })
            )
        }

        private static func selectedKeys(_ input: Input) throws -> [String] {
            let keys = input.keys ?? input.values.keys.sorted()
            guard keys.count <= 64 else { throw ValueInspectionFailure.tooManyKeys }
            guard Set(keys).count == keys.count else {
                throw ValueInspectionFailure.duplicateKeys
            }
            return keys
        }

    }
}
