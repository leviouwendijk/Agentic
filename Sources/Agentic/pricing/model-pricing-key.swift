public struct ModelPricingKey: Sendable, Codable, Hashable {
    public var provider: String
    public var model: String
    public var region: String?

    public init(
        provider: String,
        model: String,
        region: String? = nil
    ) {
        self.provider = provider
        self.model = model
        self.region = region
    }
}
