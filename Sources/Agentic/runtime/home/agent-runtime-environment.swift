import Foundation
import Path

public struct AgentRuntimeEnvironment: Sendable {
    public let home: AgentHome
    public let workspace: AgentWorkspace?
    public let projectDiscovery: AgentProjectHomeDiscovery?
    public let projectConfiguration: AgentProjectConfiguration?
    public let projectLocalConfiguration: AgentProjectLocalConfiguration?
    public let sessionStorageMode: SessionStorageMode

    public init(
        home: AgentHome,
        workspace: AgentWorkspace? = nil,
        projectDiscovery: AgentProjectHomeDiscovery? = nil,
        projectConfiguration: AgentProjectConfiguration? = nil,
        projectLocalConfiguration: AgentProjectLocalConfiguration? = nil,
        sessionStorageMode: SessionStorageMode = .global_home
    ) {
        self.home = home
        self.workspace = workspace
        self.projectDiscovery = projectDiscovery
        self.projectConfiguration = projectConfiguration
        self.projectLocalConfiguration = projectLocalConfiguration
        self.sessionStorageMode = sessionStorageMode
    }
}

public extension AgentRuntimeEnvironment {
    static func resolve(
        explicitHome: AgentHome? = nil,
        explicitHomeRootURL: URL? = nil,
        explicitWorkspace: AgentWorkspace? = nil,
        currentdir: URL = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath,
            isDirectory: true
        ),
        sessionStorageMode explicitSessionStorageMode: SessionStorageMode? = nil,
        attachWorkspaceIfProjectDiscovered: Bool = true,
        createHomeDirectories: Bool = true
    ) throws -> Self {
        let locator = AgentHomeLocator()
        let projectDiscovery = locator.findNearestProjectHome(
            from: currentdir
        )
        let projectConfiguration = try projectDiscovery.flatMap {
            try locator.loadProjectConfiguration(
                from: $0
            )
        }
        let projectLocalConfiguration = try projectDiscovery.flatMap {
            try locator.loadProjectLocalConfiguration(
                from: $0
            )
        }

        let home = explicitHome ?? locator.resolveHome(
            explicitRootURL: explicitHomeRootURL
        )

        if createHomeDirectories, home.kind != .ephemeral {
            try home.ensureBaseDirectoriesExist()
        }

        let effectiveSessionStorageMode = explicitSessionStorageMode
            ?? projectLocalConfiguration?.sessionStorageMode
            ?? projectConfiguration?.defaultSessionStorageMode
            ?? .global_home

        let workspace = try explicitWorkspace ?? resolvedWorkspace(
            projectDiscovery: projectDiscovery,
            projectConfiguration: projectConfiguration,
            attachWorkspaceIfProjectDiscovered: attachWorkspaceIfProjectDiscovered
        )

        return .init(
            home: home,
            workspace: workspace,
            projectDiscovery: projectDiscovery,
            projectConfiguration: projectConfiguration,
            projectLocalConfiguration: projectLocalConfiguration,
            sessionStorageMode: effectiveSessionStorageMode
        )
    }

    func sessiondir(
        sessionID: String
    ) -> URL? {
        switch sessionStorageMode {
        case .global_home:
            return home.layout.sessiondir(
                sessionID: sessionID
            )

        case .project_local:
            return projectDiscovery?.agenticdir
                .appendingPathComponent(
                    "sessions",
                    isDirectory: true
                )
                .appendingPathComponent(
                    sessionID,
                    isDirectory: true
                )

        case .custom(let rootURL):
            return rootURL
                .appendingPathComponent(
                    "sessions",
                    isDirectory: true
                )
                .appendingPathComponent(
                    sessionID,
                    isDirectory: true
                )

        case .ephemeral:
            return nil
        }
    }

    func checkpointFileURL(
        sessionID: String
    ) -> URL? {
        sessiondir(
            sessionID: sessionID
        )?
        .appendingPathComponent(
            "checkpoint.json",
            isDirectory: false
        )
    }

    func transcriptFileURL(
        sessionID: String
    ) -> URL? {
        switch sessionStorageMode {
        case .global_home:
            return home.layout.transcriptFileURL(
                sessionID: sessionID
            )

        case .project_local:
            return projectDiscovery?.agenticdir
                .appendingPathComponent(
                    "transcripts",
                    isDirectory: true
                )
                .appendingPathComponent(
                    "\(sessionID).jsonl",
                    isDirectory: false
                )

        case .custom(let rootURL):
            return rootURL
                .appendingPathComponent(
                    "transcripts",
                    isDirectory: true
                )
                .appendingPathComponent(
                    "\(sessionID).jsonl",
                    isDirectory: false
                )

        case .ephemeral:
            return nil
        }
    }

    func approvalsFileURL(
        sessionID: String
    ) -> URL? {
        switch sessionStorageMode {
        case .global_home:
            return home.layout.approvalsFileURL(
                sessionID: sessionID
            )

        case .project_local:
            return projectDiscovery?.agenticdir
                .appendingPathComponent(
                    "approvals",
                    isDirectory: true
                )
                .appendingPathComponent(
                    "\(sessionID).jsonl",
                    isDirectory: false
                )

        case .custom(let rootURL):
            return rootURL
                .appendingPathComponent(
                    "approvals",
                    isDirectory: true
                )
                .appendingPathComponent(
                    "\(sessionID).jsonl",
                    isDirectory: false
                )

        case .ephemeral:
            return nil
        }
    }

    func artifactdir(
        sessionID: String
    ) -> URL? {
        switch sessionStorageMode {
        case .global_home:
            return home.layout.artifactdir(
                sessionID: sessionID
            )

        case .project_local:
            return projectDiscovery?.agenticdir
                .appendingPathComponent(
                    "artifacts",
                    isDirectory: true
                )
                .appendingPathComponent(
                    sessionID,
                    isDirectory: true
                )

        case .custom(let rootURL):
            return rootURL
                .appendingPathComponent(
                    "artifacts",
                    isDirectory: true
                )
                .appendingPathComponent(
                    sessionID,
                    isDirectory: true
                )

        case .ephemeral:
            return nil
        }
    }

    func createSessionDirectories(
        sessionID: String
    ) throws {
        let urls = [
            sessiondir(
                sessionID: sessionID
            ),
            transcriptFileURL(
                sessionID: sessionID
            )?.deletingLastPathComponent(),
            approvalsFileURL(
                sessionID: sessionID
            )?.deletingLastPathComponent(),
            artifactdir(
                sessionID: sessionID
            )
        ]
        .compactMap { $0 }

        for url in urls {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}

private extension AgentRuntimeEnvironment {
    static func resolvedWorkspace(
        projectDiscovery: AgentProjectHomeDiscovery?,
        projectConfiguration: AgentProjectConfiguration?,
        attachWorkspaceIfProjectDiscovered: Bool
    ) throws -> AgentWorkspace? {
        guard attachWorkspaceIfProjectDiscovered,
              let projectDiscovery else {
            return nil
        }

        let workspaceRootURL = resolveWorkspaceRootURL(
            projectRootURL: projectDiscovery.projectroot,
            rawWorkspaceRoot: projectConfiguration?.workspaceRoot
        )

        let root = StandardPath(
            fileURL: workspaceRootURL,
            terminalHint: .directory,
            inferFileType: false
        )

        return try AgentWorkspace(
            root: root
        )
    }

    static func resolveWorkspaceRootURL(
        projectRootURL: URL,
        rawWorkspaceRoot: String?
    ) -> URL {
        guard let rawWorkspaceRoot,
              !rawWorkspaceRoot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return projectRootURL.standardizedFileURL
        }

        let trimmed = rawWorkspaceRoot.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if trimmed.hasPrefix("/") {
            return URL(
                fileURLWithPath: trimmed,
                isDirectory: true
            )
            .standardizedFileURL
        }

        if trimmed == "." {
            return projectRootURL.standardizedFileURL
        }

        return URL(
            fileURLWithPath: trimmed,
            relativeTo: projectRootURL
        )
        .standardizedFileURL
    }
}
