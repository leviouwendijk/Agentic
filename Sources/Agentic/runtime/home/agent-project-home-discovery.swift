import Foundation

public struct AgentProjectHomeDiscovery: Sendable, Codable, Hashable {
    public let projectroot: URL
    public let agenticdir: URL
    public let projectConfigurationExists: Bool
    public let localConfigurationExists: Bool

    public init(
        projectroot: URL,
        agenticdir: URL,
        projectConfigurationExists: Bool,
        localConfigurationExists: Bool
    ) {
        self.projectroot = projectroot.standardizedFileURL
        self.agenticdir = agenticdir.standardizedFileURL
        self.projectConfigurationExists = projectConfigurationExists
        self.localConfigurationExists = localConfigurationExists
    }

    public var projectConfigurationFileURL: URL {
        agenticdir.appendingPathComponent(
            "project.json",
            isDirectory: false
        )
    }

    public var localConfigurationFileURL: URL {
        agenticdir.appendingPathComponent(
            "local.json",
            isDirectory: false
        )
    }

    public var projectHome: AgentHome {
        .init(
            root: agenticdir,
            kind: .project_local
        )
    }
}
