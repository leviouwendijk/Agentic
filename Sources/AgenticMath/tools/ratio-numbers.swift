import Agentic
import Foundation
import Macros
import Math
import Schema

public extension Math.Tools {
    @Tool("ratio_numbers")
    struct RatioNumbers: Tool {
        @JSONSchema
        public enum Operation: String, Codable, Sendable, Hashable, CaseIterable {
            case divide
            case proportion
            case relative_change
            case percentage_change
        }

        @JSONSchema
        public struct Input: HashableSource {
            public let operation: Operation
            public let lhs: String
            public let rhs: String
            public let scale: Int?
            public init(operation: Operation, lhs: String, rhs: String, scale: Int? = nil) {
                self.operation = operation
                self.lhs = lhs
                self.rhs = rhs
                self.scale = scale
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let operation: Operation
            public let value: String
            public init(operation: Operation, value: String) {
                self.operation = operation
                self.value = value
            }
        }

        public static let purpose = "Compute exact-base-10 division/proportion or signed relative/percentage change. lhs=previous and rhs=current for changes; relative_change returns a fraction, percentage_change returns percent points."
        public static let risk: ActionRisk = .observe
        public init() {}

        public static func validate(_ input: Input) throws {
            _ = try DecimalArithmetic.parse(input.lhs)
            _ = try DecimalArithmetic.parse(input.rhs)
            guard (0...16).contains(input.scale ?? 12) else {
                throw DecimalArithmetic.Failure.invalidScale(input.scale ?? 12)
            }
        }

        public static func evaluate(_ input: Input) throws -> Output {
            try validate(input)
            let lhs = try DecimalArithmetic.parse(input.lhs)
            let rhs = try DecimalArithmetic.parse(input.rhs)
            let scale = input.scale ?? 12
            let value: Decimal
            switch input.operation {
            case .divide: value = try DecimalRatio.divide(lhs, by: rhs, scale: scale)
            case .proportion: value = try DecimalRatio.proportion(lhs, of: rhs, scale: scale)
            case .relative_change: value = try DecimalRatio.relative_change(from: lhs, to: rhs, scale: scale)
            case .percentage_change: value = try DecimalRatio.percentage_change(from: lhs, to: rhs, scale: scale)
            }
            return .init(operation: input.operation, value: DecimalArithmetic.string(value))
        }
        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            try Self.validate(input)
            return .init(tool: Self.definition.identifier, risk: Self.definition.risk,
                         summary: "Compute a decimal ratio", sideEffects: [])
        }
        public func call(_ input: Input, in _: ToolContext) async throws -> Output {
            try Self.evaluate(input)
        }
    }
}
