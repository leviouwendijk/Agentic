import Agentic
import Macros
import Math
import Schema

public extension Math.Tools {
    @Tool("verify_numbers")
    struct VerifyNumbers: Tool {
        @JSONSchema
        public enum Operation: String, Codable, Sendable, Hashable, CaseIterable {
            case expected
            case percentage
        }

        @JSONSchema
        public struct Input: HashableSource {
            public let operation: Operation
            public let observed: String
            public let expected: String?
            public let base: String?
            /// Percentage points; "21" means 21%, not 0.21%.
            public let rate: String?
            public let tolerance: String?
            /// Required for percentage, 0...16.
            public let scale: Int?
            public let rounding: Math.Calculation.RoundingMode?

            public init(
                operation: Operation,
                observed: String,
                expected: String? = nil,
                base: String? = nil,
                rate: String? = nil,
                tolerance: String? = nil,
                scale: Int? = nil,
                rounding: Math.Calculation.RoundingMode? = nil
            ) {
                self.operation = operation
                self.observed = observed
                self.expected = expected
                self.base = base
                self.rate = rate
                self.tolerance = tolerance
                self.scale = scale
                self.rounding = rounding
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let expected: String
            public let observed: String
            public let difference: String
            public let tolerance: String
            public let matches: Bool

            public init(
                expected: String,
                observed: String,
                difference: String,
                tolerance: String,
                matches: Bool
            ) {
                self.expected = expected
                self.observed = observed
                self.difference = difference
                self.tolerance = tolerance
                self.matches = matches
            }
        }

        public enum Failure: Error, Sendable {
            case invalidOperands
        }

        public static let purpose = """
        Deterministically verify an observed decimal. For 'expected', supply only expected and observed. For 'percentage', supply base, rate (percentage points), observed, and scale; optionally rounding. An optional nonnegative tolerance applies inclusively. Returns signed observed-minus-expected difference; no accounting/tax assumptions.
        """

        public static let risk: ActionRisk = .observe

        public init() {}

        public static func evaluate(_ input: Input) throws -> Output {
            let observed = try DecimalArithmetic.parse(input.observed)
            let tolerance = try DecimalArithmetic.parse(input.tolerance ?? "0")
            guard tolerance >= .zero else {
                throw DecimalAssertion.Failure.negativeTolerance
            }

            let result: DecimalAssertion.Result
            switch input.operation {
            case .expected:
                guard let literal = input.expected,
                      input.base == nil, input.rate == nil,
                      input.scale == nil, input.rounding == nil else {
                    throw Failure.invalidOperands
                }
                result = try DecimalAssertion.verify(
                    expected: DecimalArithmetic.parse(literal),
                    observed: observed,
                    tolerance: tolerance
                )
            case .percentage:
                guard input.expected == nil,
                      let base = input.base,
                      let rate = input.rate,
                      let scale = input.scale else {
                    throw Failure.invalidOperands
                }
                guard (0...16).contains(scale) else {
                    throw DecimalArithmetic.Failure.invalidScale(scale)
                }
                let mode: DecimalArithmetic.RoundingMode
                switch input.rounding ?? .plain {
                case .plain: mode = .plain
                case .bankers: mode = .bankers
                case .down: mode = .down
                case .up: mode = .up
                }
                result = try DecimalAssertion.percentage(
                    of: DecimalArithmetic.parse(base),
                    rate: DecimalArithmetic.parse(rate),
                    observed: observed,
                    scale: scale,
                    mode: mode,
                    tolerance: tolerance
                )
            }

            return .init(
                expected: DecimalArithmetic.string(result.expected),
                observed: DecimalArithmetic.string(result.observed),
                difference: DecimalArithmetic.string(result.difference),
                tolerance: DecimalArithmetic.string(result.tolerance),
                matches: result.matches
            )
        }

        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            _ = try Self.evaluate(input)
            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Verify a decimal value using \(input.operation.rawValue)",
                sideEffects: []
            )
        }

        public func call(_ input: Input, in _: ToolContext) async throws -> Output {
            try Self.evaluate(input)
        }
    }
}
