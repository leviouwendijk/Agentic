import Guidelines
import Macros
import Schema

public enum Reference:
    Sendable,
    Codable,
    Hashable,
    JSONSchemaProviding
{
    @JSONSchema
    public enum Kind:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case guideline
    }

    case guideline(Guideline)

    public var kind: Kind {
        switch self {
        case .guideline:
            .guideline
        }
    }
}

public extension Reference {
    @JSONSchema
    struct Guideline:
        Sendable,
        Codable,
        Hashable
    {
        public let reference: GuidelineReference
        public let disposition: Disposition
        public let reasoning: String?

        public init(
            reference: GuidelineReference,
            disposition: Disposition,
            reasoning: String? = nil
        ) {
            self.reference = reference
            self.disposition = disposition
            self.reasoning = reasoning
        }

        public init(
            _ disposition: Disposition,
            guideline: some GuidelineReferencing,
            reasoning: String? = nil
        ) {
            self.init(
                reference: GuidelineReference(
                    guideline
                ),
                disposition: disposition,
                reasoning: reasoning
            )
        }
    }
}

public extension Reference.Guideline {
    @JSONSchema
    enum Disposition:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case addresses
        case upholds
        case verifies
        case deviates
    }
}

public extension Reference {
    static var jsonschema: JSONSchema {
        .object(
            properties: [
                .init(
                    name: "kind",
                    schema: Kind.jsonschema,
                    required: true
                ),
                .init(
                    name: "guideline",
                    schema: Guideline.jsonschema,
                    required: true
                ),
            ],
            additionalProperties: .disallowed
        )
    }
}

extension Reference {
    private enum CodingKeys:
        String,
        CodingKey
    {
        case kind
        case guideline
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        let kind = try container.decode(
            Kind.self,
            forKey: .kind
        )

        switch kind {
        case .guideline:
            self = .guideline(
                try container.decode(
                    Guideline.self,
                    forKey: .guideline
                )
            )
        }
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            kind,
            forKey: .kind
        )

        switch self {
        case .guideline(let guideline):
            try container.encode(
                guideline,
                forKey: .guideline
            )
        }
    }
}
