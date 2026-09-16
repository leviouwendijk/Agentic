import Primitives

public struct AgentModelProviderID: Sendable, Codable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: String
    ) {
        self.init(
            rawValue: value
        )
    }

    public init(
        _ value: String
    ) {
        self.init(
            rawValue: value
        )
    }
}

public struct AgentModelID: StringIdentifier {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        provider: AgentModelProviderID,
        name: String
    ) {
        self.init(
            rawValue: "\(provider.rawValue):\(name)"
        )
    }

    public var provider: AgentModelProviderID {
        .init(
            legacyComponents.provider
        )
    }

    public var name: String {
        legacyComponents.name
    }

    public init(
        from decoder: any Decoder
    ) throws {
        if let container = try? decoder.singleValueContainer(),
           let rawValue = try? container.decode(String.self)
        {
            self.init(
                rawValue: rawValue
            )
            return
        }

        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        let provider: AgentModelProviderID
        if let decoded = try? container.decode(
            AgentModelProviderID.self,
            forKey: .provider
        ) {
            provider = decoded
        } else {
            provider = .init(
                try container.decode(
                    String.self,
                    forKey: .provider
                )
            )
        }

        self.init(
            provider: provider,
            name: try container.decode(
                String.self,
                forKey: .name
            )
        )
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.singleValueContainer()
        try container.encode(
            rawValue
        )
    }
}

private extension AgentModelID {
    enum CodingKeys:
        String,
        CodingKey
    {
        case provider
        case name
    }

    struct LegacyComponents {
        let provider: String
        let name: String
    }

    var legacyComponents: LegacyComponents {
        guard let separator = rawValue.firstIndex(of: ":") else {
            return .init(
                provider: "",
                name: rawValue
            )
        }

        return .init(
            provider: String(
                rawValue[..<separator]
            ),
            name: String(
                rawValue[
                    rawValue.index(after: separator)...
                ]
            )
        )
    }
}

