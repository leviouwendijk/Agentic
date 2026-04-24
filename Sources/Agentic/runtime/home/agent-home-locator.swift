import Foundation
import Milieu

public struct AgentHomeLocator: Sendable {
    public init() {}

    public func resolveHome(
        explicitRootURL: URL? = nil,
        allowLegacyHome: Bool = true
    ) -> AgentHome {
        if let explicitRootURL {
            return .init(
                root: explicitRootURL,
                kind: .user_global
            )
        }

        if let raw = AgenticEnvironmentVariable.agentic_home.optionalValue() {
            return .init(
                root: Self.expandedDirectoryURL(
                    raw
                ),
                kind: .user_global
            )
        }

        let canonical = Self.canonicalGlobalHomeURL()

        if allowLegacyHome,
           !FileManager.default.fileExists(atPath: canonical.path),
           FileManager.default.fileExists(atPath: Self.legacyHomeURL().path) {
            return .init(
                root: Self.legacyHomeURL(),
                kind: .user_global
            )
        }

        return .init(
            root: canonical,
            kind: .user_global
        )
    }

    public func resolveEphemeralHome() -> AgentHome {
        .init(
            root: FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "agentic-\(UUID().uuidString)",
                    isDirectory: true
                ),
            kind: .ephemeral
        )
    }

    public func findNearestProjectHome(
        from startURL: URL = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath,
            isDirectory: true
        )
    ) -> AgentProjectHomeDiscovery? {
        var current = startURL.standardizedFileURL

        while true {
            let agenticDirectoryURL = current.appendingPathComponent(
                ".agentic",
                isDirectory: true
            )

            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(
                atPath: agenticDirectoryURL.path,
                isDirectory: &isDirectory
            )

            if exists, isDirectory.boolValue {
                let projectConfigurationFileURL = agenticDirectoryURL
                    .appendingPathComponent(
                        "project.json",
                        isDirectory: false
                    )
                let localConfigurationFileURL = agenticDirectoryURL
                    .appendingPathComponent(
                        "local.json",
                        isDirectory: false
                    )

                return .init(
                    projectroot: current,
                    agenticdir: agenticDirectoryURL,
                    projectConfigurationExists: FileManager.default.fileExists(
                        atPath: projectConfigurationFileURL.path
                    ),
                    localConfigurationExists: FileManager.default.fileExists(
                        atPath: localConfigurationFileURL.path
                    )
                )
            }

            let parent = current.deletingLastPathComponent()

            guard parent.path != current.path else {
                return nil
            }

            current = parent
        }
    }

    public func loadProjectConfiguration(
        from discovery: AgentProjectHomeDiscovery
    ) throws -> AgentProjectConfiguration? {
        guard discovery.projectConfigurationExists else {
            return nil
        }

        return try AgentProjectConfiguration.load(
            from: discovery.projectConfigurationFileURL
        )
    }

    public func loadProjectLocalConfiguration(
        from discovery: AgentProjectHomeDiscovery
    ) throws -> AgentProjectLocalConfiguration? {
        guard discovery.localConfigurationExists else {
            return nil
        }

        return try AgentProjectLocalConfiguration.load(
            from: discovery.localConfigurationFileURL
        )
    }
}

public extension AgentHomeLocator {
    static func canonicalGlobalHomeURL() -> URL {
        if let raw = AgenticEnvironmentVariable.xdg_config_home.optionalValue() {
            return expandedDirectoryURL(
                raw
            )
            .appendingPathComponent(
                "agentic",
                isDirectory: true
            )
            .standardizedFileURL
        }

        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(
                ".config",
                isDirectory: true
            )
            .appendingPathComponent(
                "agentic",
                isDirectory: true
            )
            .standardizedFileURL
    }

    static func legacyHomeURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(
                ".agentic",
                isDirectory: true
            )
            .standardizedFileURL
    }
}

private extension AgentHomeLocator {
    static func expandedDirectoryURL(
        _ raw: String
    ) -> URL {
        let trimmed = raw.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if trimmed == "~" {
            return FileManager.default.homeDirectoryForCurrentUser
                .standardizedFileURL
        }

        if trimmed.hasPrefix("~/") {
            let suffix = String(
                trimmed.dropFirst(2)
            )

            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(
                    suffix,
                    isDirectory: true
                )
                .standardizedFileURL
        }

        return URL(
            fileURLWithPath: trimmed,
            isDirectory: true
        )
        .standardizedFileURL
    }
}
