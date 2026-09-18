import AgenticRecovery
import Foundation
import Macros
import Primitives

public struct InferenceRealizationIdentifier:
    StringIdentifier
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public struct InferenceStrategyIdentifier:
    StringIdentifier
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

@StringIdentifiers
public extension InferenceStrategyIdentifier {
    static var direct: Self
    static var native_reasoning: Self
    static var sampled: Self
    static var refining: Self
}

public struct InferenceAdapterIdentifier:
    StringIdentifier
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public struct InferenceDemonstration:
    Sendable,
    Codable,
    Hashable
{
    public var input: JSONValue
    public var output: JSONValue
    public var metadata: [String: String]

    public init(
        input: JSONValue,
        output: JSONValue,
        metadata: [String: String] = [:]
    ) {
        self.input = input
        self.output = output
        self.metadata = metadata
    }
}

public enum InferenceBudgetParsingError:
    Error,
    Sendable,
    LocalizedError
{
    case nonPositiveMaximumAttempts(Int)
    case nonPositiveMaximumTotalTokens(Int)
    case invalidMaximumEstimatedUsd(Double)

    public var errorDescription: String? {
        switch self {
        case .nonPositiveMaximumAttempts(let value):
            return "Inference maximum attempts must be positive; received \(value)."

        case .nonPositiveMaximumTotalTokens(let value):
            return "Inference maximum total tokens must be positive; received \(value)."

        case .invalidMaximumEstimatedUsd(let value):
            return "Inference maximum estimated USD must be finite and non-negative; received \(value)."
        }
    }
}

public struct InferenceBudget:
    Sendable,
    Codable,
    Hashable
{
    public let maximumAttempts: Int
    public let maximumTotalTokens: Int?
    public let maximumEstimatedUsd: Double?

    private enum CodingKeys:
        String,
        CodingKey
    {
        case maximumAttempts
        case maximumTotalTokens
        case maximumEstimatedUsd
    }

    private init(
        validatedMaximumAttempts maximumAttempts: Int,
        maximumTotalTokens: Int?,
        maximumEstimatedUsd: Double?
    ) {
        self.maximumAttempts = maximumAttempts
        self.maximumTotalTokens = maximumTotalTokens
        self.maximumEstimatedUsd = maximumEstimatedUsd
    }

    public init(
        maximumAttempts: Int,
        maximumTotalTokens: Int? = nil,
        maximumEstimatedUsd: Double? = nil
    ) throws {
        guard maximumAttempts > 0 else {
            throw InferenceBudgetParsingError
                .nonPositiveMaximumAttempts(
                    maximumAttempts
                )
        }

        if let maximumTotalTokens {
            guard maximumTotalTokens > 0 else {
                throw InferenceBudgetParsingError
                    .nonPositiveMaximumTotalTokens(
                        maximumTotalTokens
                    )
            }
        }

        if let maximumEstimatedUsd {
            guard
                maximumEstimatedUsd.isFinite,
                maximumEstimatedUsd >= 0
            else {
                throw InferenceBudgetParsingError
                    .invalidMaximumEstimatedUsd(
                        maximumEstimatedUsd
                    )
            }
        }

        self.maximumAttempts = maximumAttempts
        self.maximumTotalTokens = maximumTotalTokens
        self.maximumEstimatedUsd = maximumEstimatedUsd
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        try self.init(
            maximumAttempts: try container.decode(
                Int.self,
                forKey: .maximumAttempts
            ),
            maximumTotalTokens: try container.decodeIfPresent(
                Int.self,
                forKey: .maximumTotalTokens
            ),
            maximumEstimatedUsd: try container.decodeIfPresent(
                Double.self,
                forKey: .maximumEstimatedUsd
            )
        )
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            maximumAttempts,
            forKey: .maximumAttempts
        )
        try container.encodeIfPresent(
            maximumTotalTokens,
            forKey: .maximumTotalTokens
        )
        try container.encodeIfPresent(
            maximumEstimatedUsd,
            forKey: .maximumEstimatedUsd
        )
    }

    public static let singleAttempt = Self(
        validatedMaximumAttempts: 1,
        maximumTotalTokens: nil,
        maximumEstimatedUsd: nil
    )
}

public struct InferenceRealizationConfiguration:
    Sendable,
    Codable,
    Hashable
{
    public var strategy: InferenceStrategyIdentifier
    public var adapter: InferenceAdapterIdentifier?
    public var modelSelection: AgentModelSelection
    public var instructions: String
    public var demonstrations: [InferenceDemonstration]
    public var generation: AgentGenerationConfiguration
    public var budget: InferenceBudget
    public var recovery: Recovery.Policy?
    public var metadata: [String: String]

    public init(
        strategy: InferenceStrategyIdentifier,
        modelSelection: AgentModelSelection,
        instructions: String,
        budget: InferenceBudget,
        recovery: Recovery.Policy? = nil,
        adapter: InferenceAdapterIdentifier? = nil,
        demonstrations: [InferenceDemonstration] = [],
        generation: AgentGenerationConfiguration = .default,
        metadata: [String: String] = [:]
    ) {
        self.strategy = strategy
        self.adapter = adapter
        self.modelSelection = modelSelection
        self.instructions = instructions
        self.demonstrations = demonstrations
        self.generation = generation
        self.budget = budget
        self.recovery = recovery
        self.metadata = metadata
    }
}

public struct InferenceRealizationDefinition<
    InferenceType: Inference
>:
    Definition,
    Sendable,
    Codable,
    Hashable
{
    public let identifier: InferenceRealizationIdentifier
    public let configuration: InferenceRealizationConfiguration

    public init(
        identifier: InferenceRealizationIdentifier,
        configuration: InferenceRealizationConfiguration
    ) {
        self.identifier = identifier
        self.configuration = configuration
    }
}

public protocol InferenceRealization:
    Sendable
{
    associatedtype InferenceType: Inference

    static var strategy: InferenceStrategyIdentifier { get }
    static var adapter: InferenceAdapterIdentifier? { get }
    static var modelSelection: AgentModelSelection { get }
    static var instructions: String { get }
    static var demonstrations: [InferenceDemonstration] { get }
    static var generation: AgentGenerationConfiguration { get }
    static var budget: InferenceBudget { get }
    static var recovery: Recovery.Policy? { get }
    static var metadata: [String: String] { get }

    static var definition:
        InferenceRealizationDefinition<InferenceType>
    { get }
}

public extension InferenceRealization {
    static var adapter: InferenceAdapterIdentifier? {
        nil
    }

    static var modelSelection: AgentModelSelection {
        .executor
    }

    static var demonstrations: [InferenceDemonstration] {
        []
    }

    static var generation: AgentGenerationConfiguration {
        .default
    }

    static var budget: InferenceBudget {
        .singleAttempt
    }

    static var recovery: Recovery.Policy? {
        nil
    }

    static var metadata: [String: String] {
        [:]
    }
}
