import Agentic
import Foundation
import Macros
import Math
import Schema

public extension Math.Tools {
    @Tool("analyze_series")
    struct AnalyzeSeries: Tool {
        @JSONSchema
        public enum Operation: String, Codable, Sendable, Hashable, CaseIterable {
            case difference
            case relative_change
            case cumulative
            case moving_mean
            case normalize
        }
        @JSONSchema
        public struct Point: HashableSource {
            public let x: String
            public let value: String
            public init(x: String, value: String) { self.x = x; self.value = value }
        }
        @JSONSchema
        public struct Input: HashableSource {
            public let operation: Operation
            public let points: [Point]
            public let window: Int?
            public let scale: Int?
            public init(operation: Operation, points: [Point], window: Int? = nil, scale: Int? = nil) {
                self.operation = operation
                self.points = points
                self.window = window
                self.scale = scale
            }
        }
        @JSONSchema
        public struct Output: HashableResult {
            public let operation: Operation
            public let points: [Point]
            public let input_count: Int
            public init(operation: Operation, points: [Point], input_count: Int) {
                self.operation = operation
                self.points = points
                self.input_count = input_count
            }
        }
        public enum Failure: Error, Sendable { case invalidLength; case invalidWindow; case unexpectedWindow }
        public static let purpose = "Transform bounded decimal series into plot-ready keyed points. Differences and relative changes align to the later X; moving means align to each window end. No chart rendering."
        public static let risk: ActionRisk = .observe
        public init() {}
        public static func validate(_ input: Input) throws {
            guard !input.points.isEmpty, input.points.count <= 256 else { throw Failure.invalidLength }
            guard (0...16).contains(input.scale ?? 12) else { throw DecimalArithmetic.Failure.invalidScale(input.scale ?? 12) }
            for point in input.points { _ = try DecimalArithmetic.parse(point.value) }
            if input.operation == .moving_mean {
                guard let window = input.window, window > 0, window <= input.points.count else { throw Failure.invalidWindow }
            } else if input.window != nil { throw Failure.unexpectedWindow }
        }
        public static func evaluate(_ input: Input) throws -> Output {
            try validate(input)
            let values = try input.points.map { try DecimalArithmetic.parse($0.value) }
            let scale = input.scale ?? 12
            let results: [Decimal]
            let first: Int
            switch input.operation {
            case .difference:
                results = try DecimalSeries.difference(values)
                first = 1
            case .relative_change:
                results = try DecimalSeries.relative_change(values, scale: scale)
                first = 1
            case .cumulative:
                results = try DecimalSeries.cumulative(values)
                first = 0
            case .moving_mean:
                guard let window = input.window else { throw Failure.invalidWindow }
                results = try DecimalSeries.moving_mean(values, window: window, scale: scale)
                first = window - 1
            case .normalize:
                results = try DecimalSeries.normalize(values, scale: scale)
                first = 0
            }
            let keyed = results.enumerated().map { index, decimal in
                Point(x: input.points[first + index].x, value: DecimalArithmetic.string(decimal))
            }
            return .init(operation: input.operation, points: keyed, input_count: input.points.count)
        }
        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            try Self.validate(input)
            return .init(tool: Self.definition.identifier, risk: Self.definition.risk,
                         summary: "Analyze a series of \(input.points.count) decimal points", sideEffects: [])
        }
        public func call(_ input: Input, in _: ToolContext) async throws -> Output { try Self.evaluate(input) }
    }
}
