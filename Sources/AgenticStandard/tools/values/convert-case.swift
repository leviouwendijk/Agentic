import Agentic
import Macros
import Primitives
import Schema

public extension Standard.Tools {
    /// Deterministic text casing, without filesystem or mutation authority.
    @Tool("convert_case")
    struct ConvertCase: Tool {
        public struct Input: HashableSource {
            /// Text to convert. For filenames, pass the stem, not the full path.
            public let value: String
            /// Target casing, using the canonical Primitives.Casing values.
            public let to: Casing
            /// Optional source separator characters. Nil uses Primitives' common set.
            public let separators: String?

            public init(
                value: String,
                to: Casing,
                separators: String? = nil
            ) {
                self.value = value
                self.to = to
                self.separators = separators
            }

            /// Describe the imported Casing enum without duplicating its cases
            /// or adding a retroactive conformance to Primitives.
            public static var jsonschema: JSONSchema {
                .object(
                    properties: [
                        .init(
                            name: "value",
                            schema: .string(),
                            required: true
                        ),
                        .init(
                            name: "to",
                            schema: .string(
                                cases: Casing.allCases.map(\.rawValue)
                            ),
                            required: true
                        ),
                        .init(
                            name: "separators",
                            schema: .string(),
                            required: false
                        ),
                    ],
                    additionalProperties: .disallowed
                )
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let original: String
            public let converted: String
            public let changed: Bool

            public init(
                original: String,
                converted: String,
                changed: Bool
            ) {
                self.original = original
                self.converted = converted
                self.changed = changed
            }
        }

        public static let purpose = "Deterministically convert a supplied string to a Primitives casing style. Accepts text only; does not inspect paths, rename files, modify content, or authorize filesystem operations. For filename renames, supply only the stem and preserve extensions separately."

        public static let risk: ActionRisk = .observe

        public init() {}

        public static func transform(_ input: Input) -> Output {
            let separators = input.separators.map {
                Separators($0)
            } ?? .common

            let converted = Case.convert(
                input.value,
                to: input.to,
                separators: separators
            )

            return .init(
                original: input.value,
                converted: converted,
                changed: converted != input.value
            )
        }

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Convert text to \(input.to.rawValue) casing",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in _: ToolContext
        ) async throws -> Output {
            Self.transform(input)
        }
    }
}
