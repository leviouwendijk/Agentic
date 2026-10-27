import Agentic
import Macros
import Math
import Schema

public extension Math.Tools {
    @Tool("compare_numbers")
    struct CompareNumbers: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let lhs: String
            public let rhs: String
            /// Optional absolute tolerance; supplied as a decimal string.
            public let tolerance: String?

            public init(lhs: String, rhs: String, tolerance: String? = nil) {
                self.lhs = lhs
                self.rhs = rhs
                self.tolerance = tolerance
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let relation: String
            public let exceedsTolerance: Bool?

            public init(relation: String, exceedsTolerance: Bool?) {
                self.relation = relation
                self.exceedsTolerance = exceedsTolerance
            }
        }

        public static let purpose = """
        Compare two base-10 decimal literals without converting through Double; optionally report whether their difference exceeds a tolerance.
        """

        public static let risk: ActionRisk = .observe

        public init() {}

        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            _ = try DecimalArithmetic.parse(input.lhs)
            _ = try DecimalArithmetic.parse(input.rhs)
            if let tolerance = input.tolerance {
                _ = try DecimalArithmetic.parse(tolerance)
            }
            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Compare two decimal values",
                sideEffects: []
            )
        }

        public func call(_ input: Input, in _: ToolContext) async throws -> Output {
            let lhs = try DecimalArithmetic.parse(input.lhs)
            let rhs = try DecimalArithmetic.parse(input.rhs)
            let exceeds: Bool?
            if let literal = input.tolerance {
                let tolerance = try DecimalArithmetic.parse(literal)
                // Exact subtraction here, not the rounded arithmetic tool operation.
                exceeds = DecimalComparison.exceeds(lhs - rhs, tolerance: tolerance)
            } else {
                exceeds = nil
            }
            return .init(
                relation: DecimalComparison.compare(lhs, rhs).rawValue,
                exceedsTolerance: exceeds
            )
        }
    }
}
