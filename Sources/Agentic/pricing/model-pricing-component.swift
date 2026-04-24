public struct ModelPricingComponent: Sendable, Codable, Hashable, Identifiable {
    public var kind: PricingComponentKind
    public var unit: PricingUnit
    public var priceMicros: Int64
    public var description: String?
    public var metadata: [String: String]

    public init(
        kind: PricingComponentKind,
        unit: PricingUnit,
        priceMicros: Int64,
        description: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.kind = kind
        self.unit = unit
        self.priceMicros = max(
            0,
            priceMicros
        )
        self.description = description
        self.metadata = metadata
    }

    public var id: String {
        "\(kind.rawValue):\(unit.rawValue)"
    }
}
