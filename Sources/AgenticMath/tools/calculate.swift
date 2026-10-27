import Agentic
import Macros
import Primitives
import Schema

public extension Math.Tools {
    @Tool("calculate")
    struct Calculate: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// Ordered decimal steps. The unary `round` operation accepts one
            /// operand and a `rounding` policy; binary arithmetic accepts two.
            /// Each reference must point to an earlier step.
            public let steps: [Math.Calculation.Step]
            /// Result IDs to return. Defaults to the final step.
            public let outputs: [String]?
            /// Base-10 fractional digits, 0...16; defaults to 12.
            public let scale: Int?

            public init(
                steps: [Math.Calculation.Step],
                outputs: [String]? = nil,
                scale: Int? = nil
            ) {
                self.steps = steps
                self.outputs = outputs
                self.scale = scale
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let results: [Math.Calculation.Value]
            public let outputs: [Math.Calculation.Value]
            public let scale: Int

            public init(
                results: [Math.Calculation.Value],
                outputs: [Math.Calculation.Value],
                scale: Int
            ) {
                self.results = results
                self.outputs = outputs
                self.scale = scale
            }
        }

        public static let purpose =
            "Evaluate up to 32 ordered decimal operations, including explicit one-operand rounding (scale 0...16; plain, bankers, down, up). Inputs are decimal strings or prior step IDs. Binary operations retain a default intermediate scale of 12."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            try Math.Calculation.Evaluator.validate(input)
            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Calculate \(input.steps.count) ordered decimal step(s)",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in _: ToolContext
        ) async throws -> Output {
            try Math.Calculation.Evaluator.evaluate(input)
        }
    }
}
