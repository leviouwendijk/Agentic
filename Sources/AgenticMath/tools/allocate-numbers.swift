import Agentic
import Foundation
import Macros
import Math
import Schema

public extension Math.Tools {
    @Tool("allocate_numbers")
    struct AllocateNumbers: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let total: String
            public let weights: [String]
            public let scale: Int?
            public init(total: String, weights: [String], scale: Int? = nil) {
                self.total = total
                self.weights = weights
                self.scale = scale
            }
        }
        @JSONSchema
        public struct Output: HashableResult {
            public let allocations: [String]
            public let reconciled_total: String
            public init(allocations: [String], reconciled_total: String) {
                self.allocations = allocations
                self.reconciled_total = reconciled_total
            }
        }
        public static let purpose = "Allocate a decimal total across nonnegative weights using deterministic largest remainders and exact quantized-total reconciliation. No currency, tax or accounting policy."
        public static let risk: ActionRisk = .observe
        public init() {}
        public static func validate(_ input: Input) throws {
            _ = try DecimalArithmetic.parse(input.total)
            guard !input.weights.isEmpty, input.weights.count <= 256 else { throw DecimalAllocation.Failure.emptyWeights }
            guard (0...16).contains(input.scale ?? 2) else { throw DecimalArithmetic.Failure.invalidScale(input.scale ?? 2) }
            for weight in input.weights { _ = try DecimalArithmetic.parse(weight) }
        }
        public static func evaluate(_ input: Input) throws -> Output {
            try validate(input)
            let total = try DecimalArithmetic.parse(input.total)
            let weights = try input.weights.map(DecimalArithmetic.parse)
            let shares = try DecimalAllocation.proportional(total: total, weights: weights, scale: input.scale ?? 2)
            let sum = try DecimalAggregation.sum(shares)
            return .init(allocations: shares.map(DecimalArithmetic.string), reconciled_total: DecimalArithmetic.string(sum))
        }
        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            try Self.validate(input)
            return .init(tool: Self.definition.identifier, risk: Self.definition.risk,
                         summary: "Allocate decimal total across \(input.weights.count) weights", sideEffects: [])
        }
        public func call(_ input: Input, in _: ToolContext) async throws -> Output { try Self.evaluate(input) }
    }
}
