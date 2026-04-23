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

            let body = try String(contentsOf: fileURL, encoding: .utf8)
            let name = fileURL.deletingLastPathComponent().lastPathComponent

            skills.append(
                AgentSkill(
                    id: name,
                    name: name,
                    summary: "",
                    body: body
                )
            )
        }

        return skills.sorted { lhs, rhs in
            lhs.name < rhs.name
        }
    }
}
