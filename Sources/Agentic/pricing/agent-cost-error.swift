import Foundation

public enum AgentCostError: Error, Sendable, LocalizedError {
    case currencyMismatch(expected: String, actual: String)
    case missingPricingComponent(PricingComponentKind)
    case missingPricingForModel(ModelPricingKey)
    case emptyProvider
    case emptyModel
    case emptyCurrencyCode

    public var errorDescription: String? {
        switch self {
        case .currencyMismatch(let expected, let actual):
            return "Pricing currency mismatch. Expected '\(expected)', got '\(actual)'."

        case .missingPricingComponent(let kind):
            return "Missing pricing component '\(kind.rawValue)'."

        case .missingPricingForModel(let key):
            return "Missing pricing for provider '\(key.provider)', model '\(key.model)', region '\(key.region ?? "default")'."

        case .emptyProvider:
            return "Pricing provider cannot be empty."

        case .emptyModel:
            return "Pricing model cannot be empty."

        case .emptyCurrencyCode:
            return "Pricing currency code cannot be empty."
        }
    }
}
