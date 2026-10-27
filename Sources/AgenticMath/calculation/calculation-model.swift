import Agentic
import Macros
import Primitives
import Schema

public extension Math {
    enum Calculation {
        @JSONSchema
        public enum Operation: String, Sendable, Codable, Hashable, CaseIterable {
            case add
            case subtract
            case multiply
            case divide
            case round
        }

        @JSONSchema
        public enum RoundingMode: String, Sendable, Codable, Hashable, CaseIterable {
            case plain
            case bankers
            case down
            case up
        }

        @JSONSchema
        public struct Rounding: HashableSource {
            public let scale: Int
            public let mode: RoundingMode?

            public init(scale: Int, mode: RoundingMode? = nil) {
                self.scale = scale
                self.mode = mode
            }
        }

        /// Exactly one of literal/reference must be supplied.
        @JSONSchema
        public struct Operand: HashableSource {
            public let literal: String?
            public let reference: String?

            public init(literal: String? = nil, reference: String? = nil) {
                self.literal = literal
                self.reference = reference
            }

            public static func value(_ value: String) -> Self {
                .init(literal: value)
            }

            public static func ref(_ id: String) -> Self {
                .init(reference: id)
            }
        }

        @JSONSchema
        public struct Step: HashableSource {
            public let id: String
            public let operation: Operation
            public let operands: [Operand]
            /// Required for unary round; forbidden for arithmetic operations.
            public let rounding: Rounding?

            public init(
                id: String,
                operation: Operation,
                operands: [Operand],
                rounding: Rounding? = nil
            ) {
                self.id = id
                self.operation = operation
                self.operands = operands
                self.rounding = rounding
            }
        }

        @JSONSchema
        public struct Value: HashableResult {
            public let id: String
            public let value: String

            public init(id: String, value: String) {
                self.id = id
                self.value = value
            }
        }
    }
}
