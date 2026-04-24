import Foundation

public enum ModelPricingCatalogError: Error, Sendable, LocalizedError {
    case durableStorageRequired
    case unreadableCatalog(URL)
    case duplicatePricingKey(ModelPricingKey)

    public var errorDescription: String? {
        switch self {
        case .durableStorageRequired:
            return "Pricing catalog operations require durable Agentic storage."

        case .unreadableCatalog(let url):
            return "Pricing catalog at '\(url.path)' is unreadable."

        case .duplicatePricingKey(let key):
            return "Duplicate pricing entry for provider '\(key.provider)', model '\(key.model)', region '\(key.region ?? "default")'."
        }
    }
}
