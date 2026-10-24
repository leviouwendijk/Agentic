extension AgentModelSelection {
    private enum CodingKeys: String, CodingKey {
        case purpose
        case operation
        case kind
        case requirements
        case preferences
        case constraints
        case metadata
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let previousKind = try values.decodeIfPresent(AgentModelKind.self, forKey: .kind)
        self.init(
            purpose: try values.decode(AgentModelRoutePurpose.self, forKey: .purpose),
            operation: try values.decodeIfPresent(AgentModelOperation.self, forKey: .operation)
                ?? (previousKind == .decision ? .decision : .generation),
            requirements: try values.decode(AgentModelRequirements.self, forKey: .requirements),
            preferences: try values.decode(AgentModelPreferences.self, forKey: .preferences),
            constraints: try values.decode(AgentModelConstraints.self, forKey: .constraints),
            metadata: try values.decode([String: String].self, forKey: .metadata)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(purpose, forKey: .purpose)
        try values.encode(operation, forKey: .operation)
        try values.encode(requirements, forKey: .requirements)
        try values.encode(preferences, forKey: .preferences)
        try values.encode(constraints, forKey: .constraints)
        try values.encode(metadata, forKey: .metadata)
    }
}
