import Agentic
import Foundation
import Macros
import Math
import Schema

public extension Math.Tools {
    @Tool("aggregate_numbers")
    struct AggregateNumbers: Tool {
        @JSONSchema
        public enum Operation: String, Codable, Sendable, Hashable, CaseIterable {
            case sum
            case mean
            case weighted_mean
            case minimum
            case maximum
            case median
            case population_variance
            case sample_variance
        }
        @JSONSchema
        public struct Input: HashableSource {
            public let operation: Operation
            public let values: [String]
            public let weights: [String]?
            public let scale: Int?
            public init(operation: Operation, values: [String], weights: [String]? = nil, scale: Int? = nil) {
                self.operation = operation
                self.values = values
                self.weights = weights
                self.scale = scale
            }
        }
        @JSONSchema
        public struct Output: HashableResult {
            public let operation: Operation
            public let value: String
            public let count: Int
            public init(operation: Operation, value: String, count: Int) {
                self.operation = operation
                self.value = value
                self.count = count
            }
        }
        public static let purpose = "Aggregate bounded decimal-string collections using sum, mean, weighted mean, extremes, median or variance. Weighted mean requires corresponding nonnegative weights."
        public static let risk: ActionRisk = .observe
        public init() {}
        public static func validate(_ input: Input) throws {
            guard !input.values.isEmpty, input.values.count <= 256 else { throw DecimalAggregation.Failure.emptyValues }
            guard (0...16).contains(input.scale ?? 12) else { throw DecimalArithmetic.Failure.invalidScale(input.scale ?? 12) }
            for value in input.values { _ = try DecimalArithmetic.parse(value) }
            if input.operation == .weighted_mean {
                guard let weights = input.weights, weights.count == input.values.count else {
                    throw DecimalAggregation.Failure.mismatchedWeights
                }
                for weight in weights { _ = try DecimalArithmetic.parse(weight) }
            } else if input.weights != nil {
                throw DecimalAggregation.Failure.mismatchedWeights
            }
        }
        public static func evaluate(_ input: Input) throws -> Output {
            try validate(input)
            let values = try input.values.map(DecimalArithmetic.parse)
            let scale = input.scale ?? 12
            let value: Decimal
            switch input.operation {
            case .sum: value = try DecimalAggregation.sum(values)
            case .mean: value = try DecimalAggregation.mean(values, scale: scale)
            case .weighted_mean:
                guard let strings = input.weights else { throw DecimalAggregation.Failure.mismatchedWeights }
                value = try DecimalAggregation.weighted_mean(values, weights: strings.map(DecimalArithmetic.parse), scale: scale)
            case .minimum: value = try DecimalAggregation.minimum(values)
            case .maximum: value = try DecimalAggregation.maximum(values)
            case .median: value = try DecimalAggregation.median(values, scale: scale)
            case .population_variance: value = try DecimalStatistics.population_variance(values, scale: scale)
            case .sample_variance: value = try DecimalStatistics.sample_variance(values, scale: scale)
            }
            return .init(operation: input.operation, value: DecimalArithmetic.string(value), count: values.count)
        }
        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            try Self.validate(input)
            return .init(tool: Self.definition.identifier, risk: Self.definition.risk,
                         summary: "Aggregate \(input.values.count) decimal values", sideEffects: [])
        }
        public func call(_ input: Input, in _: ToolContext) async throws -> Output { try Self.evaluate(input) }
    }
}
