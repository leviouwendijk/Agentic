public struct AgentCostLineItem: Sendable, Codable, Hashable, Identifiable {
    public var id: String
    public var componentKind: PricingComponentKind
    public var unit: PricingUnit
    public var quantity: Int
    public var priceMicros: Int64
    public var amount: AgentCostAmount
    public var description: String?

    public init(
        componentKind: PricingComponentKind,
        unit: PricingUnit,
        quantity: Int,
        priceMicros: Int64,
        amount: AgentCostAmount,
        description: String? = nil
    ) {
        self.id = "\(componentKind.rawValue):\(unit.rawValue)"
        self.componentKind = componentKind
        self.unit = unit
        self.quantity = max(
            0,
            quantity
        )
        self.priceMicros = max(
            0,
            priceMicros
        )
        self.amount = amount
        self.description = description
    }
}
