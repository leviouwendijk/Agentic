import Foundation
import Schema

public enum Decision {}

public extension Decision {
    enum Error:
        Swift.Error,
        Sendable,
        Equatable,
        LocalizedError
    {
        case invalidProbability(Double)
        case invalidConfidence(Double)
        case invalidIdentifier(String)
        case invalidStructuredContent
        case emptyInstructions
        case emptyOptions
        case duplicateIdentifier(String)
        case duplicateValue
        case invalidDistribution
        case invalidSelection
        case invalidScale
        case invalidScore
        case questionMismatch
        case answerMismatch(String)
        case modelExecutionUnavailable

        public var errorDescription: String? {
            switch self {
            case .invalidProbability(let value):
                "Decision probability must be finite and within 0...1; received \(value)."

            case .invalidConfidence(let value):
                "Decision confidence must be finite and within 0...1; received \(value)."

            case .invalidIdentifier(let value):
                "Decision identifier must be nonempty without surrounding whitespace: '\(value)'."

            case .invalidStructuredContent:
                "Structured decision content must encode as a JSON object or array."

            case .emptyInstructions:
                "Decision text instructions must not be empty."

            case .emptyOptions:
                "A decision choice must contain at least one option."

            case .duplicateIdentifier(let value):
                "Duplicate decision identifier: '\(value)'."

            case .duplicateValue:
                "Decision options or levels contain duplicate application values."

            case .invalidDistribution:
                "Decision probabilities must cover the offered alternatives and sum to one within 0.000001."

            case .invalidSelection:
                "Selected decision value must belong to the offered distribution."

            case .invalidScale:
                "A decision scale requires at least two distinct ordered levels."

            case .invalidScore:
                "Decision score must equal the probability-weighted position on its ordered scale."

            case .questionMismatch:
                "Decision response question identifiers do not match the prepared query."

            case .answerMismatch(let id):
                "Decision answer does not match the prepared question '\(id)'."

            case .modelExecutionUnavailable:
                "Decision inference requires decision model invocation support; the current generative invocation path cannot execute it."
            }
        }
    }

    struct Probability:
        Sendable,
        Codable,
        Hashable,
        JSONSchemaProviding
    {
        public let value: Double

        public init(
            _ value: Double
        ) throws {
            guard value.isFinite,
                  (0...1).contains(value)
            else {
                throw Error.invalidProbability(
                    value
                )
            }

            self.value = value
        }

        public init(
            from decoder: any Decoder
        ) throws {
            let container = try decoder.singleValueContainer()
            try self.init(
                container.decode(Double.self)
            )
        }

        public func encode(
            to encoder: any Encoder
        ) throws {
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }

        public static var jsonschema: JSONSchema {
            Double.jsonschema
        }
    }

    struct Confidence:
        Sendable,
        Codable,
        Hashable,
        JSONSchemaProviding
    {
        public let value: Double

        public init(
            _ value: Double
        ) throws {
            guard value.isFinite,
                  (0...1).contains(value)
            else {
                throw Error.invalidConfidence(
                    value
                )
            }

            self.value = value
        }

        public init(
            from decoder: any Decoder
        ) throws {
            let container = try decoder.singleValueContainer()
            try self.init(
                container.decode(Double.self)
            )
        }

        public func encode(
            to encoder: any Encoder
        ) throws {
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }

        public static var jsonschema: JSONSchema {
            Double.jsonschema
        }
    }

    static func expectedPosition(
        of probabilities: [Probability]
    ) throws -> Double {
        try requireDistribution(
            probabilities
        )

        return probabilities
            .enumerated()
            .reduce(0.0) {
                $0
                    + Double($1.offset)
                    * $1.element.value
            }
    }
}

extension Decision {
    static let probabilityTolerance = 0.000001

    static func requireIdentifier(
        _ value: String
    ) throws {
        guard !value.isEmpty,
              value == value.trimmingCharacters(
                in: .whitespacesAndNewlines
              )
        else {
            throw Error.invalidIdentifier(
                value
            )
        }
    }

    static func requireDistribution(
        _ values: [Probability]
    ) throws {
        guard !values.isEmpty,
              abs(
                values.reduce(0) {
                    $0 + $1.value
                }
                    - 1
              ) <= probabilityTolerance
        else {
            throw Error.invalidDistribution
        }
    }
}
