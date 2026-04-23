public struct AgentSkill: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let summary: String
    public let body: String
    public let metadata: [String: String]

    public init(
        id: String,
        name: String,
        summary: String,
        body: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.body = body
        self.metadata = metadata
    }
}

public extension AgentSkill {
    var descriptionLine: String {
        let renderedSummary = summary.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if renderedSummary.isEmpty {
            return "- \(id): \(name)"
        }

        return "- \(id): \(renderedSummary)"
    }

    var contextText: String {
        var sections: [String] = [
            "# Skill: \(name)",
            "Skill ID: \(id)"
        ]

        let renderedSummary = summary.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !renderedSummary.isEmpty {
            sections.append("Summary: \(renderedSummary)")
        }

        let trimmedBody = body.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !trimmedBody.isEmpty {
            sections.append(trimmedBody)
        }

        return sections.joined(separator: "\n\n")
    }
}
