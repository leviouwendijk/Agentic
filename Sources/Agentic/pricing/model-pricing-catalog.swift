import Tokens

public protocol ModelPricingCatalog: Sendable {
    func pricing(
        for key: ModelPricingKey
    ) throws -> ModelPricingSnapshot
}

public struct StaticModelPricingCatalog: ModelPricingCatalog {
    public var snapshots: [ModelPricingKey: ModelPricingSnapshot]

    public init(
        snapshots: [ModelPricingSnapshot] = []
    ) {
        self.snapshots = Dictionary(
            uniqueKeysWithValues: snapshots.map {
                (
                    $0.key,
                    $0
                )
            }
        )
    }

    public func pricing(
        for key: ModelPricingKey
    ) throws -> ModelPricingSnapshot {
        if let exact = snapshots[key] {
            return exact
        }

        if key.region != nil {
            let fallback = ModelPricingKey(
                provider: key.provider,
                model: key.model,
                region: nil
            )

            if let fallback = snapshots[fallback] {
                return fallback
            }
        }

        throw AgentCostError.missingPricingForModel(
            key
        )
    }
}

public extension StaticModelPricingCatalog {
    mutating func insert(
        _ snapshot: ModelPricingSnapshot
    ) {
        snapshots[snapshot.key] = snapshot
    }
}

public extension ModelPricingCatalog {
    func projectCost(
        provider: String,
        model: String,
        region: String? = nil,
        inputEstimate: TokenEstimate,
        reservedOutputTokens: Int = 0,
        metadata: [String: String] = [:]
    ) -> AgentCostProjection {
        do {
            let pricing = try pricing(
                for: .init(
                    provider: provider,
                    model: model,
                    region: region
                )
            )

            return AgentCostCalculator.project(
                inputEstimate: inputEstimate,
                reservedOutputTokens: reservedOutputTokens,
                pricing: pricing,
                metadata: metadata
            )
        } catch {
            return AgentCostCalculator.unavailable(
                usage: .init(
                    inputEstimate: inputEstimate,
                    reservedOutputTokens: reservedOutputTokens,
                    metadata: metadata
                ),
                reason: error.localizedDescription,
                metadata: metadata
            )
        }
    }

    func projectCost(
        provider: String,
        model: String,
        region: String? = nil,
        usage: AgentCostUsage,
        metadata: [String: String] = [:]
    ) -> AgentCostProjection {
        do {
            let pricing = try pricing(
                for: .init(
                    provider: provider,
                    model: model,
                    region: region
                )
            )

            return AgentCostCalculator.project(
                usage: usage,
                pricing: pricing,
                metadata: metadata
            )
        } catch {
            return AgentCostCalculator.unavailable(
                usage: usage,
                reason: error.localizedDescription,
                metadata: metadata
            )
        }
    }

    func actualCost(
        provider: String,
        model: String,
        region: String? = nil,
        providerUsage: AgentUsage,
        metadata: [String: String] = [:]
    ) -> AgentCostProjection {
        do {
            let pricing = try pricing(
                for: .init(
                    provider: provider,
                    model: model,
                    region: region
                )
            )

            return AgentCostCalculator.actual(
                providerUsage: providerUsage,
                pricing: pricing,
                metadata: metadata
            )
        } catch {
            return AgentCostCalculator.unavailable(
                usage: .init(
                    providerUsage: providerUsage,
                    metadata: metadata
                ),
                reason: error.localizedDescription,
                metadata: metadata
            )
        }
    }
}
