import Foundation
import Math

public extension Math.Calculation {
    enum Failure: Error, Sendable {
        case emptySteps
        case tooManySteps
        case invalidID(String)
        case duplicateID(String)
        case invalidArity(String)
        case invalidRounding(String)
        case invalidOperand(String)
        case unknownReference(String)
        case invalidOutputs
        case invalidScale(Int)
    }

    enum Evaluator {
        public static func validate(
            _ input: Math.Tools.Calculate.Input
        ) throws {
            guard !input.steps.isEmpty else { throw Failure.emptySteps }
            guard input.steps.count <= 32 else { throw Failure.tooManySteps }
            let scale = input.scale ?? 12
            guard (0...16).contains(scale) else {
                throw Failure.invalidScale(scale)
            }

            var declared = Set<String>()
            for step in input.steps {
                guard step.id.range(
                    of: #"^[A-Za-z][A-Za-z0-9_]{0,63}$"#,
                    options: .regularExpression
                ) != nil else {
                    throw Failure.invalidID(step.id)
                }
                guard !declared.contains(step.id) else {
                    throw Failure.duplicateID(step.id)
                }
                switch step.operation {
                case .round:
                    guard step.operands.count == 1 else {
                        throw Failure.invalidArity(step.id)
                    }
                    guard let rounding = step.rounding,
                          (0...16).contains(rounding.scale) else {
                        throw Failure.invalidRounding(step.id)
                    }
                case .add, .subtract, .multiply, .divide:
                    guard step.operands.count == 2 else {
                        throw Failure.invalidArity(step.id)
                    }
                    guard step.rounding == nil else {
                        throw Failure.invalidRounding(step.id)
                    }
                }

                for operand in step.operands {
                    switch (operand.literal, operand.reference) {
                    case (.some(let literal), .none):
                        _ = try DecimalArithmetic.parse(literal)
                    case (.none, .some(let reference)):
                        guard declared.contains(reference) else {
                            throw Failure.unknownReference(reference)
                        }
                    default:
                        throw Failure.invalidOperand(step.id)
                    }
                }
                declared.insert(step.id)
            }

            if let outputs = input.outputs {
                guard !outputs.isEmpty,
                      outputs.allSatisfy({ declared.contains($0) })
                else {
                    throw Failure.invalidOutputs
                }
            }
        }

        public static func evaluate(
            _ input: Math.Tools.Calculate.Input
        ) throws -> Math.Tools.Calculate.Output {
            try validate(input)

            var resolved: [String: Decimal] = [:]
            var results: [Math.Calculation.Value] = []
            let scale = input.scale ?? 12

            for step in input.steps {
                let lhs = try operand(step.operands[0], in: resolved)
                let number: Decimal

                switch step.operation {
                case .round:
                    // validate(_:) guarantees presence and scale bounds.
                    guard let rounding = step.rounding else {
                        throw Failure.invalidRounding(step.id)
                    }
                    let mode: DecimalArithmetic.RoundingMode
                    switch rounding.mode ?? .plain {
                    case .plain: mode = .plain
                    case .bankers: mode = .bankers
                    case .down: mode = .down
                    case .up: mode = .up
                    }
                    number = try DecimalArithmetic.round(
                        lhs,
                        scale: rounding.scale,
                        mode: mode
                    )
                case .add, .subtract, .multiply, .divide:
                    let rhs = try operand(step.operands[1], in: resolved)
                    let operation: DecimalArithmetic.Operation
                    switch step.operation {
                    case .add: operation = .add
                    case .subtract: operation = .subtract
                    case .multiply: operation = .multiply
                    case .divide: operation = .divide
                    case .round: preconditionFailure("Handled above")
                    }
                    // Retain the existing scale behavior for older callers.
                    number = try DecimalArithmetic.calculate(
                        operation, lhs: lhs, rhs: rhs, scale: scale
                    )
                }
                resolved[step.id] = number
                results.append(
                    .init(id: step.id, value: DecimalArithmetic.string(number))
                )
            }

            let wanted = input.outputs ?? [input.steps[input.steps.count - 1].id]
            let valuesByID = Dictionary(uniqueKeysWithValues: results.map {
                ($0.id, $0)
            })
            let outputs = wanted.compactMap { valuesByID[$0] }

            return .init(results: results, outputs: outputs, scale: scale)
        }

        private static func operand(
            _ operand: Math.Calculation.Operand,
            in resolved: [String: Decimal]
        ) throws -> Decimal {
            if let literal = operand.literal {
                return try DecimalArithmetic.parse(literal)
            }
            if let reference = operand.reference,
               let value = resolved[reference] {
                return value
            }
            throw Failure.invalidOperand("unresolvable operand")
        }
    }
}
