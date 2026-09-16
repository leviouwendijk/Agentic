import Foundation
import Macros
import Primitives

public extension AgentModel {
    struct Pricing:
        Sendable,
        Codable,
        Hashable
    {
        public let profile: AgentModelProfileIdentifier
        public let effectiveAt: Foundation.Date
        public let currency: Currency
        public let input: Price?
        public let output: Price?
        public let cacheRead: Price?
        public let cacheWrite: Price?
        public let reasoning: Price?
        public let modalities: [AgentModality: Price]

        public init(
            profile: AgentModelProfileIdentifier,
            effectiveAt: Foundation.Date,
            currency: Currency,
            input: Price? = nil,
            output: Price? = nil,
            cacheRead: Price? = nil,
            cacheWrite: Price? = nil,
            reasoning: Price? = nil,
            modalities: [AgentModality: Price] = [:]
        ) {
            self.profile = profile
            self.effectiveAt = effectiveAt
            self.currency = currency
            self.input = input
            self.output = output
            self.cacheRead = cacheRead
            self.cacheWrite = cacheWrite
            self.reasoning = reasoning
            self.modalities = modalities
        }
    }

    struct Evaluation:
        Sendable,
        Codable,
        Hashable
    {
        public let model: ID
        public let profile: AgentModelProfileIdentifier?
        public let artifact: Artifact.ID?
        public let benchmark: Benchmark
        public let metric: Metric
        public let score: Double
        public let measuredAt: Foundation.Date?
        public let metadata: [String: String]

        public init(
            model: ID,
            profile: AgentModelProfileIdentifier? = nil,
            artifact: Artifact.ID? = nil,
            benchmark: Benchmark,
            metric: Metric,
            score: Double,
            measuredAt: Foundation.Date? = nil,
            metadata: [String: String] = [:]
        ) {
            self.model = model
            self.profile = profile
            self.artifact = artifact
            self.benchmark = benchmark
            self.metric = metric
            self.score = score
            self.measuredAt = measuredAt
            self.metadata = metadata
        }
    }

    struct Telemetry:
        Sendable,
        Codable,
        Hashable
    {
        public let profile: AgentModelProfileIdentifier
        public let artifact: Artifact.ID?
        public let observedAt: Foundation.Date
        public let samples: UInt
        public let averageLatencyMilliseconds: Double?
        public let p95LatencyMilliseconds: Double?
        public let firstTokenMilliseconds: Double?
        public let tokensPerSecond: Double?
        public let failureRate: Double?
        public let toolCallValidityRate: Double?
        public let structuredOutputValidityRate: Double?

        public init(
            profile: AgentModelProfileIdentifier,
            artifact: Artifact.ID? = nil,
            observedAt: Foundation.Date,
            samples: UInt,
            averageLatencyMilliseconds: Double? = nil,
            p95LatencyMilliseconds: Double? = nil,
            firstTokenMilliseconds: Double? = nil,
            tokensPerSecond: Double? = nil,
            failureRate: Double? = nil,
            toolCallValidityRate: Double? = nil,
            structuredOutputValidityRate: Double? = nil
        ) {
            self.profile = profile
            self.artifact = artifact
            self.observedAt = observedAt
            self.samples = samples
            self.averageLatencyMilliseconds = averageLatencyMilliseconds
            self.p95LatencyMilliseconds = p95LatencyMilliseconds
            self.firstTokenMilliseconds = firstTokenMilliseconds
            self.tokensPerSecond = tokensPerSecond
            self.failureRate = failureRate
            self.toolCallValidityRate = toolCallValidityRate
            self.structuredOutputValidityRate = structuredOutputValidityRate
        }
    }
}

public extension AgentModel.Pricing {
    struct Currency: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    enum Unit:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case per_million_tokens
        case per_thousand_tokens
        case per_request
        case per_second
        case per_image
        case per_audio_minute
    }

    struct Price:
        Sendable,
        Codable,
        Hashable
    {
        public let amount: Double
        public let unit: Unit

        public init(
            amount: Double,
            unit: Unit
        ) {
            self.amount = amount
            self.unit = unit
        }
    }
}

@StringIdentifiers
public extension AgentModel.Pricing.Currency {
    static var usd: Self
    static var eur: Self
}

public extension AgentModel.Evaluation {
    struct Benchmark: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    struct Metric: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}
