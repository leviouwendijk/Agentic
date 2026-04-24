import Foundation

public struct ModelPricingSnapshot: Sendable, Codable, Hashable {
    public var provider: String
    public var model: String
    public var region: String?
    public var source: PricingSource
    public var sourceVersion: String?
    public var currencyCode: String
    public var components: [ModelPricingComponent]
    public var effectiveAt: Date?
    public var fetchedAt: Date?
    public var metadata: [String: String]

    public init(
        provider: String,
        model: String,
        region: String? = nil,
        source: PricingSource = .manual,
        sourceVersion: String? = nil,
        currencyCode: String = "USD",
        components: [ModelPricingComponent],
        effectiveAt: Date? = nil,
        fetchedAt: Date? = nil,
        metadata: [String: String] = [:]
    ) throws {
        let provider = provider.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let model = model.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let currencyCode = currencyCode.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).uppercased()

        guard !provider.isEmpty else {
            throw AgentCostError.emptyProvider
        }

        guard !model.isEmpty else {
            throw AgentCostError.emptyModel
        }

        guard !currencyCode.isEmpty else {
            throw AgentCostError.emptyCurrencyCode
        }

        self.provider = provider
        self.model = model
        self.region = normalized(
            region
        )
        self.source = source
        self.sourceVersion = normalized(
            sourceVersion
        )
        self.currencyCode = currencyCode
        self.components = components
        self.effectiveAt = effectiveAt
        self.fetchedAt = fetchedAt
        self.metadata = metadata
    }

    public var key: ModelPricingKey {
        .init(
            provider: provider,
            model: model,
            region: region
        )
    }
}

public extension ModelPricingSnapshot {
    static func tokenPricing(
        provider: String,
        model: String,
        region: String? = nil,
        source: PricingSource = .manual,
        sourceVersion: String? = nil,
        currencyCode: String = "USD",
        inputMicrosPerMillionTokens: Int64,
        outputMicrosPerMillionTokens: Int64,
        cachedInputReadMicrosPerMillionTokens: Int64? = nil,
        cachedInputWriteMicrosPerMillionTokens: Int64? = nil,
        reasoningOutputMicrosPerMillionTokens: Int64? = nil,
        effectiveAt: Date? = nil,
        fetchedAt: Date? = nil,
        metadata: [String: String] = [:]
    ) throws -> Self {
        var components: [ModelPricingComponent] = [
            .init(
                kind: .inputTokens,
                unit: .perMillionTokens,
                priceMicros: inputMicrosPerMillionTokens,
                description: "Input tokens"
            ),
            .init(
                kind: .outputTokens,
                unit: .perMillionTokens,
                priceMicros: outputMicrosPerMillionTokens,
                description: "Output tokens"
            )
        ]

        if let cachedInputReadMicrosPerMillionTokens {
            components.append(
                .init(
                    kind: .cachedInputReadTokens,
                    unit: .perMillionTokens,
                    priceMicros: cachedInputReadMicrosPerMillionTokens,
                    description: "Cached input read tokens"
                )
            )
        }

        if let cachedInputWriteMicrosPerMillionTokens {
            components.append(
                .init(
                    kind: .cachedInputWriteTokens,
                    unit: .perMillionTokens,
                    priceMicros: cachedInputWriteMicrosPerMillionTokens,
                    description: "Cached input write tokens"
                )
            )
        }

        if let reasoningOutputMicrosPerMillionTokens {
            components.append(
                .init(
                    kind: .reasoningOutputTokens,
                    unit: .perMillionTokens,
                    priceMicros: reasoningOutputMicrosPerMillionTokens,
                    description: "Reasoning output tokens"
                )
            )
        }

        return try .init(
            provider: provider,
            model: model,
            region: region,
            source: source,
            sourceVersion: sourceVersion,
            currencyCode: currencyCode,
            components: components,
            effectiveAt: effectiveAt,
            fetchedAt: fetchedAt,
            metadata: metadata
        )
    }

    func component(
        _ kind: PricingComponentKind
    ) -> ModelPricingComponent? {
        components.first {
            $0.kind == kind
        }
    }
}

private func normalized(
    _ value: String?
) -> String? {
    guard let value else {
        return nil
    }

    let trimmed = value.trimmingCharacters(
        in: .whitespacesAndNewlines
    )

    return trimmed.isEmpty ? nil : trimmed
}
