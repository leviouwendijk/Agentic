public struct AgentCostAmount: Sendable, Codable, Hashable {
    public var currencyCode: String
    public var micros: Int64

    public init(
        currencyCode: String = "USD",
        micros: Int64 = 0
    ) {
        self.currencyCode = currencyCode.uppercased()
        self.micros = max(
            0,
            micros
        )
    }

    public static func zero(
        currencyCode: String = "USD"
    ) -> Self {
        .init(
            currencyCode: currencyCode,
            micros: 0
        )
    }

    public var majorUnitsApproximation: Double {
        Double(micros) / 1_000_000
    }

    public func adding(
        _ other: AgentCostAmount
    ) throws -> AgentCostAmount {
        guard currencyCode == other.currencyCode else {
            throw AgentCostError.currencyMismatch(
                expected: currencyCode,
                actual: other.currencyCode
            )
        }

        let result = micros.addingReportingOverflow(
            other.micros
        )

        return .init(
            currencyCode: currencyCode,
            micros: result.overflow ? Int64.max : result.partialValue
        )
    }
}
