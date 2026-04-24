import Foundation

public struct ModelPricingCatalogDocument: Sendable, Codable, Hashable {
    public var version: Int
    public var snapshots: [ModelPricingSnapshot]
    public var createdAt: Date
    public var updatedAt: Date
    public var metadata: [String: String]

    public init(
        version: Int = 1,
        snapshots: [ModelPricingSnapshot] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.version = max(
            1,
            version
        )
        self.snapshots = snapshots
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }
}
