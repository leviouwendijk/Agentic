import Foundation

public enum AgentProjectInitializer {
    public static func initialize(
        projectroot: URL = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath,
            isDirectory: true
        ),
        configuration: AgentProjectConfiguration = .init(),
        createLocalGitIgnoreEntries: Bool = true
    ) throws -> AgentProjectHomeDiscovery {
        let root = projectroot.standardizedFileURL
        let agenticdir = root.appendingPathComponent(
            ".agentic",
            isDirectory: true
        )
        let projectConfigurationFileURL = agenticdir.appendingPathComponent(
            "project.json",
            isDirectory: false
        )

        try FileManager.default.createDirectory(
            at: agenticdir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        if !FileManager.default.fileExists(
            atPath: projectConfigurationFileURL.path
        ) {
            try configuration.write(
                to: projectConfigurationFileURL
            )
        }

        if createLocalGitIgnoreEntries {
            try ensureGitIgnoreEntries(
                projectroot: root
            )
        }

        let localConfigurationFileURL = agenticdir.appendingPathComponent(
            "local.json",
            isDirectory: false
        )

        return .init(
            projectroot: root,
            agenticdir: agenticdir,
            projectConfigurationExists: true,
            localConfigurationExists: FileManager.default.fileExists(
                atPath: localConfigurationFileURL.path
            )
        )
    }
}

private extension AgentProjectInitializer {
    static func ensureGitIgnoreEntries(
        projectroot: URL
    ) throws {
        let gitdir = projectroot.appendingPathComponent(
            ".git",
            isDirectory: true
        )

        guard FileManager.default.fileExists(
            atPath: gitdir.path
        ) else {
            return
        }

        let gitIgnoreURL = projectroot.appendingPathComponent(
            ".gitignore",
            isDirectory: false
        )

        let entries = [
            ".agentic/local.json",
            ".agentic/local/",
            ".agentic/sessions/",
            ".agentic/transcripts/",
            ".agentic/approvals/",
            ".agentic/cache/",
            ".agentic/artifacts/"
        ]

        let existing: String
        if FileManager.default.fileExists(
            atPath: gitIgnoreURL.path
        ) {
            existing = try String(
                contentsOf: gitIgnoreURL,
                encoding: .utf8
            )
        } else {
            existing = ""
        }

        let existingLines = Set(
            existing
                .split(
                    separator: "\n",
                    omittingEmptySubsequences: false
                )
                .map {
                    String($0).trimmingCharacters(
                        in: .whitespaces
                    )
                }
        )

        let missing = entries.filter {
            !existingLines.contains($0)
        }

        guard !missing.isEmpty else {
            return
        }

        var updated = existing

        if !updated.isEmpty,
           !updated.hasSuffix("\n") {
            updated += "\n"
        }

        updated += "\n# Agentic private runtime state\n"
        updated += missing.joined(
            separator: "\n"
        )
        updated += "\n"

        try updated.write(
            to: gitIgnoreURL,
            atomically: true,
            encoding: .utf8
        )
    }
}
