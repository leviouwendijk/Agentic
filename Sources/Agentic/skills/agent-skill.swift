public struct AgentSkill: Sendable, Codable, Hashable, Identifiable {
    public let identifier: AgentSkillIdentifier
    public let name: String
    public let summary: String
    public let body: String
    public let metadata: AgentSkillMetadata

    public init(
        identifier: AgentSkillIdentifier,
        name: String,
        summary: String,
        body: String,
        metadata: AgentSkillMetadata = .empty
    ) {
        self.identifier = identifier
        self.name = name
        self.summary = summary
        self.body = body
        self.metadata = metadata
    }
}

extension AgentSkill: InstructionSource {
    public var instructionSnapshot: InstructionSnapshot? {
        instruction.instructionSnapshot
    }
}

public extension AgentSkill {
    /// Transitional authored-content view; the Skill registry does not own
    /// another copy of the instruction or its revision.
    var instruction: InstructionDefinition {
        InstructionDefinition(
            identifier: .init(rawValue: "skill.\(identifier.rawValue)"),
            content: contextText,
            source: metadata.attributes["skill_file"]
        )
    }

    var id: AgentSkillIdentifier {
        identifier
    }

    var descriptionLine: String {
        let renderedSummary = summary.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if renderedSummary.isEmpty {
            return "- \(identifier.rawValue): \(name)"
        }

        return "- \(identifier.rawValue): \(renderedSummary)"
    }

    var contextText: String {
        var sections: [String] = [
            "# Skill: \(name)",
            "Skill ID: \(identifier.rawValue)"
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
