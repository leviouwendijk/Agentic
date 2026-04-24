import Tokens

public enum AgentCostCalculator {
    public static func project(
        inputEstimate: TokenEstimate,
        reservedOutputTokens: Int = 0,
        pricing: ModelPricingSnapshot,
        metadata: [String: String] = [:]
    ) -> AgentCostProjection {
        calculate(
            usage: .init(
                inputEstimate: inputEstimate,
                reservedOutputTokens: reservedOutputTokens,
                metadata: metadata
            ),
            pricing: pricing,
            tokenEstimate: inputEstimate,
            confidence: .estimated,
            metadata: metadata
        )
    }

    public static func project(
        usage: AgentCostUsage,
        pricing: ModelPricingSnapshot,
        metadata: [String: String] = [:]
    ) -> AgentCostProjection {
        calculate(
            usage: usage,
            pricing: pricing,
            tokenEstimate: nil,
            confidence: .estimated,
            metadata: metadata
        )
    }

    public static func actual(
        providerUsage: AgentUsage,
        pricing: ModelPricingSnapshot,
        metadata: [String: String] = [:]
    ) -> AgentCostProjection {
        calculate(
            usage: .init(
                providerUsage: providerUsage,
                metadata: metadata
            ),
            pricing: pricing,
            tokenEstimate: nil,
            confidence: .providerReported,
            metadata: metadata
        )
    }

    public static func unavailable(
        usage: AgentCostUsage = .init(),
        reason: String,
        metadata: [String: String] = [:]
    ) -> AgentCostProjection {
        .init(
            status: .unavailable,
            confidence: .unavailable,
            usage: usage,
            issues: [
                .init(
                    kind: .pricingUnavailable,
                    message: reason
                )
            ],
            metadata: metadata
        )
    }
}

private extension AgentCostCalculator {
    static func calculate(
        usage: AgentCostUsage,
        pricing: ModelPricingSnapshot,
        tokenEstimate: TokenEstimate?,
        confidence: AgentCostProjectionConfidence,
        metadata: [String: String]
    ) -> AgentCostProjection {
        var lineItems: [AgentCostLineItem] = []
        var issues: [AgentCostProjectionIssue] = []

        appendTokenLineItem(
            kind: .inputTokens,
            quantity: usage.inputTokens,
            pricing: pricing,
            lineItems: &lineItems,
            issues: &issues
        )

        appendTokenLineItem(
            kind: .outputTokens,
            quantity: usage.outputTokens,
            pricing: pricing,
            lineItems: &lineItems,
            issues: &issues
        )

        appendTokenLineItem(
            kind: .cachedInputReadTokens,
            quantity: usage.cachedInputReadTokens,
            pricing: pricing,
            lineItems: &lineItems,
            issues: &issues
        )

        appendTokenLineItem(
            kind: .cachedInputWriteTokens,
            quantity: usage.cachedInputWriteTokens,
            pricing: pricing,
            lineItems: &lineItems,
            issues: &issues
        )

        appendTokenLineItem(
            kind: .reasoningOutputTokens,
            quantity: usage.reasoningOutputTokens,
            pricing: pricing,
            lineItems: &lineItems,
            issues: &issues
        )

        appendRequestLineItem(
            quantity: usage.requestCount,
            pricing: pricing,
            lineItems: &lineItems
        )

        if usage.totalKnownTokens == 0, usage.requestCount == 0 {
            issues.append(
                .init(
                    kind: .zeroUsage,
                    message: "Cost usage has no billable token or request quantities."
                )
            )
        }

        let amount = totalAmount(
            lineItems: lineItems,
            currencyCode: pricing.currencyCode,
            issues: &issues
        )

        let status: AgentCostProjectionStatus
        if amount == nil {
            status = .unavailable
        } else if issues.contains(where: { $0.kind == .missingPricingComponent }) {
            status = .partial
        } else {
            status = .available
        }

        return .init(
            status: status,
            confidence: confidence,
            pricing: pricing,
            usage: usage,
            tokenEstimate: tokenEstimate,
            amount: amount,
            lineItems: lineItems,
            issues: issues,
            metadata: metadata
        )
    }

    static func appendTokenLineItem(
        kind: PricingComponentKind,
        quantity: Int,
        pricing: ModelPricingSnapshot,
        lineItems: inout [AgentCostLineItem],
        issues: inout [AgentCostProjectionIssue]
    ) {
        guard quantity > 0 else {
            return
        }

        guard let component = pricing.component(
            kind
        ) else {
            issues.append(
                .init(
                    kind: .missingPricingComponent,
                    message: "Missing pricing component for \(kind.rawValue).",
                    componentKind: kind
                )
            )

            return
        }

        let micros: Int64

        switch component.unit {
        case .perMillionTokens:
            micros = costMicrosPerMillion(
                quantity: quantity,
                priceMicrosPerMillion: component.priceMicros
            )

        case .perRequest, .fixed:
            micros = 0
            issues.append(
                .init(
                    kind: .missingPricingComponent,
                    message: "Pricing component \(kind.rawValue) has unsupported unit \(component.unit.rawValue) for token usage.",
                    componentKind: kind
                )
            )
        }

        guard micros > 0 else {
            return
        }

        lineItems.append(
            .init(
                componentKind: kind,
                unit: component.unit,
                quantity: quantity,
                priceMicros: component.priceMicros,
                amount: .init(
                    currencyCode: pricing.currencyCode,
                    micros: micros
                ),
                description: component.description
            )
        )
    }

    static func appendRequestLineItem(
        quantity: Int,
        pricing: ModelPricingSnapshot,
        lineItems: inout [AgentCostLineItem]
    ) {
        guard quantity > 0,
              let component = pricing.component(.request),
              component.unit == .perRequest
        else {
            return
        }

        let quantity = Int64(
            clamping: quantity
        )
        let result = quantity.multipliedReportingOverflow(
            by: component.priceMicros
        )
        let micros = result.overflow ? Int64.max : result.partialValue

        guard micros > 0 else {
            return
        }

        lineItems.append(
            .init(
                componentKind: .request,
                unit: .perRequest,
                quantity: Int(
                    clamping: quantity
                ),
                priceMicros: component.priceMicros,
                amount: .init(
                    currencyCode: pricing.currencyCode,
                    micros: micros
                ),
                description: component.description
            )
        )
    }

    static func totalAmount(
        lineItems: [AgentCostLineItem],
        currencyCode: String,
        issues: inout [AgentCostProjectionIssue]
    ) -> AgentCostAmount? {
        guard !lineItems.isEmpty else {
            return .zero(
                currencyCode: currencyCode
            )
        }

        var amount = AgentCostAmount.zero(
            currencyCode: currencyCode
        )

        do {
            for lineItem in lineItems {
                amount = try amount.adding(
                    lineItem.amount
                )
            }

            return amount
        } catch {
            issues.append(
                .init(
                    kind: .currencyMismatch,
                    message: error.localizedDescription
                )
            )

            return nil
        }
    }

    static func costMicrosPerMillion(
        quantity: Int,
        priceMicrosPerMillion: Int64
    ) -> Int64 {
        guard quantity > 0, priceMicrosPerMillion > 0 else {
            return 0
        }

        let quantity = Int64(
            clamping: quantity
        )
        let product = quantity.multipliedReportingOverflow(
            by: priceMicrosPerMillion
        )

        guard !product.overflow else {
            return Int64.max
        }

        return divideRoundingUp(
            product.partialValue,
            by: 1_000_000
        )
    }

    static func divideRoundingUp(
        _ value: Int64,
        by denominator: Int64
    ) -> Int64 {
        guard value > 0 else {
            return 0
        }

        return (value + denominator - 1) / denominator
    }
}
