extension AgentModelProfile {
    private enum CodingKeys: String, CodingKey {
        case identifier
        case gatewayIdentifier
        case model
        case modelID
        case title
        case kind
        case operations
        case purposes
        case capabilities
        case cost
        case latency
        case privacy
        case limits
        case metadata
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            identifier: try values.decode(AgentModelProfileIdentifier.self, forKey: .identifier),
            gatewayIdentifier: try values.decode(AgentModelGatewayIdentifier.self, forKey: .gatewayIdentifier),
            model: try values.decode(String.self, forKey: .model),
            modelID: try values.decodeIfPresent(AgentModelID.self, forKey: .modelID),
            title: try values.decodeIfPresent(String.self, forKey: .title),
            kind: try values.decode(AgentModelKind.self, forKey: .kind),
            operations: try values.decodeIfPresent(Set<AgentModelOperation>.self, forKey: .operations),
            purposes: try values.decode(Set<AgentModelRoutePurpose>.self, forKey: .purposes),
            capabilities: try values.decode(Set<AgentModelCapability>.self, forKey: .capabilities),
            cost: try values.decode(AgentModelCostClass.self, forKey: .cost),
            latency: try values.decode(AgentModelLatencyClass.self, forKey: .latency),
            privacy: try values.decode(AgentModelPrivacyClass.self, forKey: .privacy),
            limits: try values.decode(AgentModelLimits.self, forKey: .limits),
            metadata: try values.decode([String: String].self, forKey: .metadata)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(identifier, forKey: .identifier)
        try values.encode(gatewayIdentifier, forKey: .gatewayIdentifier)
        try values.encode(model, forKey: .model)
        try values.encodeIfPresent(modelID, forKey: .modelID)
        try values.encodeIfPresent(title, forKey: .title)
        try values.encode(kind, forKey: .kind)
        try values.encode(operations, forKey: .operations)
        try values.encode(purposes, forKey: .purposes)
        try values.encode(capabilities, forKey: .capabilities)
        try values.encode(cost, forKey: .cost)
        try values.encode(latency, forKey: .latency)
        try values.encode(privacy, forKey: .privacy)
        try values.encode(limits, forKey: .limits)
        try values.encode(metadata, forKey: .metadata)
    }
}
