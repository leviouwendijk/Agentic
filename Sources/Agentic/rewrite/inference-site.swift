import Primitives

public struct InferenceSiteIdentifier: StringIdentifier {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public struct InferenceSite<
    InferenceType: Inference
>:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let identifier: InferenceSiteIdentifier

    public init(
        identifier: InferenceSiteIdentifier
    ) {
        self.identifier = identifier
    }

    public var id: InferenceSiteIdentifier {
        identifier
    }

    public var inference: InferenceIdentifier {
        InferenceType.definition.identifier
    }
}
