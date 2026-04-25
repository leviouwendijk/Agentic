public struct AgentSkillDraft: Sendable, Hashable {
    public var identifier: AgentSkillIdentifier
    public var name: String?
    public var summary: String?
    public var body: String
    public var domains: [AgentSkillDomain]
    public var requiredTools: [AgentToolReference]
    public var optionalTools: [AgentToolReference]
    public var tags: [String]
    public var attributes: [String: String]

    public init(
        identifier: AgentSkillIdentifier,
        name: String? = nil,
        summary: String? = nil,
        body: String,
        domains: [AgentSkillDomain] = [],
        requiredTools: [AgentToolReference] = [],
        optionalTools: [AgentToolReference] = [],
        tags: [String] = [],
        attributes: [String: String] = [:]
    ) {
        self.identifier = identifier
        self.name = name
        self.summary = summary
        self.body = body
        self.domains = domains
        self.requiredTools = requiredTools
        self.optionalTools = optionalTools
        self.tags = tags
        self.attributes = attributes
    }

    public func build() -> AgentSkill {
        AgentSkill(
            identifier: identifier,
            name: normalized(
                name
            ) ?? identifier.rawValue,
            summary: normalized(
                summary
            ) ?? "",
            body: body,
            metadata: .init(
                domains: domains,
                tools: .init(
                    required: requiredTools,
                    optional: optionalTools
                ),
                tags: tags,
                attributes: attributes
            )
        )
    }
}

public extension AgentSkillDraft {
    func name(
        _ name: String
    ) -> Self {
        var copy = self
        copy.name = name
        return copy
    }

    func summary(
        _ summary: String
    ) -> Self {
        var copy = self
        copy.summary = summary
        return copy
    }

    func domain(
        _ domain: AgentSkillDomain
    ) -> Self {
        var copy = self

        if !copy.domains.contains(
            domain
        ) {
            copy.domains.append(
                domain
            )
        }

        return copy
    }

    func domains(
        _ domains: AgentSkillDomain...
    ) -> Self {
        var copy = self

        for domain in domains where !copy.domains.contains(domain) {
            copy.domains.append(
                domain
            )
        }

        return copy
    }

    func requires(
        _ identifiers: AgentToolIdentifier...
    ) -> Self {
        requires(
            identifiers.map {
                .tool($0)
            }
        )
    }

    func requires(
        _ references: AgentToolReference...
    ) -> Self {
        requires(
            references
        )
    }

    func requires(
        _ references: [AgentToolReference]
    ) -> Self {
        var copy = self
        copy.requiredTools.append(
            contentsOf: references
        )
        return copy
    }

    func optionally(
        _ identifiers: AgentToolIdentifier...
    ) -> Self {
        optionally(
            identifiers.map {
                .tool($0)
            }
        )
    }

    func optionally(
        _ references: AgentToolReference...
    ) -> Self {
        optionally(
            references
        )
    }

    func optionally(
        _ references: [AgentToolReference]
    ) -> Self {
        var copy = self
        copy.optionalTools.append(
            contentsOf: references
        )
        return copy
    }

    func tags(
        _ tags: String...
    ) -> Self {
        var copy = self
        copy.tags.append(
            contentsOf: tags
        )
        return copy
    }

    func attribute(
        _ key: String,
        _ value: String
    ) -> Self {
        var copy = self
        copy.attributes[key] = value
        return copy
    }
}

public func skill(
    _ identifier: AgentSkillIdentifier,
    body: () -> String
) -> AgentSkillDraft {
    .init(
        identifier: identifier,
        body: body()
    )
}

private func normalized(
    _ value: String?
) -> String? {
    guard let value else {
        return nil
    }

    let trimmed = value.trimmingCharacters(
        in: .whitespacesAndNewlines
    )

    return trimmed.isEmpty ? nil : trimmed
}
