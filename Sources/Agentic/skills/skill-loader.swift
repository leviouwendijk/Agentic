import Foundation

public struct SkillLoader: Sendable {
    public init() {}

    public func loadSkills(
        from directory: URL
    ) throws -> [AgentSkill] {
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        var skills: [AgentSkill] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.lastPathComponent == "SKILL.md" else {
                continue
            }

            let text = try String(
                contentsOf: fileURL,
                encoding: .utf8
            )
            let document = SkillFrontmatter.parse(text)
            let directoryName = fileURL
                .deletingLastPathComponent()
                .lastPathComponent

            let id = normalizedMetadataValue(
                document.metadata["id"]
            )
                ?? normalizedMetadataValue(
                    document.metadata["name"]
                )
                ?? directoryName

            let name = normalizedMetadataValue(
                document.metadata["name"]
            ) ?? id

            let summary = normalizedMetadataValue(
                document.metadata["summary"]
            )
                ?? normalizedMetadataValue(
                    document.metadata["description"]
                )
                ?? ""

            skills.append(
                AgentSkill(
                    id: id,
                    name: name,
                    summary: summary,
                    body: document.body,
                    metadata: document.metadata
                )
            )
        }

        return skills.sorted { lhs, rhs in
            if lhs.name == rhs.name {
                return lhs.id < rhs.id
            }

            return lhs.name < rhs.name
        }
    }
}

private extension SkillLoader {
    func normalizedMetadataValue(
        _ value: String?
    ) -> String? {
        let trimmed = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let trimmed,
              !trimmed.isEmpty
        else {
            return nil
        }

        return trimmed
    }
}
